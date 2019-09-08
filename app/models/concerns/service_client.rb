# frozen_string_literal: true

# Common code for handling setup and calls to the Foundation Layer back office
# and associated error handling.
# @see ServiceClientConfiguration initializer for the configuration of calls to the back office.
module ServiceClient
  extend ActiveSupport::Concern

  # Holds the central list of clients with a key based on the WSDL file
  # As this is accessed via the class functions there is only one hash
  # that is shared across all calls so we only instantiate  each
  # client once
  @clients = {}

  # Gets the client from the internal hash if it already exists otherwise retrieve
  # it from the file
  # @param savon_log [Boolean] see new_client.
  # @return client from internal hash or retrieve it from the file
  def self.get_client(wsdl_file, end_point, service_config, savon_log)
    savon_log = true if savon_log.nil?
    unless @clients.key?(wsdl_file)
      Rails.logger.debug { "Setting up client to #{end_point} using #{wsdl_file}" }
      @clients[wsdl_file] = new_client(wsdl_file, service_config[:root] + end_point, service_config, savon_log)
    end

    @clients[wsdl_file]
  end

  # Allows you to iterate round an element returned from Savon which may be a hash or an array of hashes
  # depending on the data returned you may see hash_key=>[hash, hash] OR hash_key=>hash
  def self.iterate_element(body)
    return if body.nil?

    # this extracts the values for the hash, if these are an array then we have an array of an array so
    # so flatten removes one of the arrays
    body.values.flatten.each do |hash|
      yield(hash)
    end
  end

  # class method to call the client returning the success flag
  # and the body used by the instance and class methods for the calls
  # Benchmark.realtime is the elapsed time used to execute the given block (from do ...to... end)
  def self.call(config, request)
    response = ''
    realtime = Benchmark.realtime do
      response = ServiceClient.get_client(config[:wsdl], config[:endpoint],
                                          config[:service], config[:savon_log])
                              .call(config[:operation], message: request)
    end

    config_response = config[:response]
    log_call_responded(config[:endpoint], config_response, realtime)
    response_body = response.body[config_response]
    [response_body[:success], response_body] # return success flag and response body
  end

  # formats a time in seconds to time in milliseconds
  # @param realtime [Number] the time in seconds
  # @return [Number] the time in milliseconds
  def self.format_time(realtime)
    (realtime * 1000).round
  end

  # if the call wasn't successful at the class level then this is a fatal type error
  # @param success flag from the back office
  # @param response the response from the back office
  def self.assert_not_failure(success, response)
    return if success

    # if we just have a failure and no messages then bomb out
    raise Error::AppError.new('NONE', 'Call to back office failed with no messages') unless response.key?(:messages)

    # Raise the first message as the message text
    ServiceClient.iterate_element(response[:messages]) do |mess|
      Rails.logger.error("#{mess[:code]} #{mess[:text]}")
      raise Error::AppError.new(mess[:code], mess[:text])
    end
  end

  # Make a call to the back office to using the config_key provided to load the service point details
  # from ServiceClients.services. It will return if the call was successful
  # you can provide an optional lambda to process the response to return objects
  # NOTE: See also {#class_methods.call_ok?} at the class level
  def call_ok?(config_key, request)
    config = RevScot::ServiceClientConfiguration.configuration[config_key]
    Rails.logger.debug { "Calling (instance) #{config[:endpoint]} with #{request}" }
    success, response_body = ServiceClient.call(config, request)

    # raise fatal error if the call failed with no messages
    assert_not_failure_without_messages(success, response_body)

    extract_errors(response_body)

    # if successful yield to calling code to extract details
    yield(filtered_attributes(response_body)) if success && block_given?
    success
  end

  # Classes that the ActiveSupport::Concern automatically adds as class level methods
  module ClassMethods
    # class equivalent of the instance level class call but without the ability
    # to copy the errors into the rails error structure as there isn't one
    # NOTE: See also {#call_ok?} at the instance level
    def call_ok?(config_key, request)
      config = RevScot::ServiceClientConfiguration.configuration[config_key]
      Rails.logger.debug { "Calling (class) #{config[:endpoint]} with #{request}" }
      success, response_body = ServiceClient.call(config, request)

      # A class level call should not really fail, so any failure is fatal type
      ServiceClient.assert_not_failure(success, response_body)

      # if successful yield to calling code to extract details
      yield(filtered_attributes(response_body)) if success && block_given?
      success
    end

    # Method to filter attributes in the response body.
    # We need to remove items that we don't want in the model object created such as the success flag and errors
    # If you want to remove other items consider extending this or overriding this in your individual class
    # @param body is the response body to have some of it's values filtered
    def filtered_attributes(body)
      body.reject do |key|
        key.to_s.match(/(\A(success|@xmlns|@xmlns:.*|messages|fatal)\z)/i)
      end
    end
  end

  # Method to filter attributes in the response body.
  # We need to remove items that we don't want in the model object created such as the success flag and errors
  # If you want to remove other items consider extending this or overriding this in your individual class
  # @param body is the response body to have some of it's values filtered
  def filtered_attributes(body)
    body.reject do |key|
      key.to_s.match(/(\A(success|@xmlns|@xmlns:.*|messages|fatal)\z)/i)
    end
  end

  # @!method self.new_client(wsdl_file, full_end_point, service_config, savon_log)
  # private class method to create the client
  #
  # This was made possible because of the Savon.client(...), this built-in method from the
  # savon gem is used to create a client for the service.
  #
  # The {wsdl_location} method is used to get the path location of the wsdl.
  #
  # The {wsse_auth} method is used to get the wsse authentication details.
  # @param savon_log [Boolean] is used to determine if we want to show the logger for the SOAP request
  #   and response. This can be set in any hash of the service details found in the _service_client_configuration.rb.
  # @note Savon::Client is the main object for connecting to a SOAP service.
  # @return [Object] returns a Savon.client object which is the created client.
  private_class_method def self.new_client(wsdl_file, full_end_point, service_config, savon_log)
    wsdl_location = wsdl_location(wsdl_file, service_config)
    wsse_auth_details = wsse_auth(service_config)
    # The hash options :log, :log_level and :logger controls the logging of the SOAP response
    # and SOAP request.
    # @see http://savonrb.com/version1/configuration.html
    #              :log - determines whether if we want to set the logging of it to true/false - log it or not.
    #        :log_level - changing the logger level: Rails.configuration.log_level (consists of the value ':debug')
    #           :logger - is what logger are we using.
    # :pretty_print_xml - will beautify the xml sent which is logged; boolean value needed.
    # setting the :log to false will turn off the logging of the SOAP request and SOAP response
    Savon.client(wsdl: wsdl_location, endpoint: full_end_point, convert_request_keys_to: :none,
                 wsse_auth: wsse_auth_details, log: savon_log, log_level: Rails.configuration.log_level,
                 logger: Rails.logger, proxy: service_config[:proxy],
                 filters: %i[Password OldPassword NewPassword BinaryData ins1:BinaryData],
                 open_timeout: service_config[:timeout], read_timeout: service_config[:timeout])
  end

  # It uses the {https://ruby-doc.org/core-2.2.0/File.html#method-c-join File.join} method
  # which joins the strings passed in the parameters of it and returns a string
  # in this format: "user/mail/inbox".
  # @return [String] the path location of the WSDL
  private_class_method def self.wsdl_location(wsdl_file, service_config)
    File.join(Rails.root, 'config/wsdl', service_config[:wsdl_root], wsdl_file)
  end

  # @return [Array] array of objects about the WSSE Authentication information
  private_class_method def self.wsse_auth(service_config)
    [service_config[:username], service_config[:password], :digest]
  end

  # Log that a was made call to the service and how long it took
  private_class_method def self.log_call_responded(endpoint, response, real_time)
    time_taken = ServiceClient.format_time(real_time)
    Rails.logger.info { "Called #{endpoint} (#{time_taken} ms). Looking for #{response}" }
  end

  private

  # extract any messages if there are any
  def extract_errors(response)
    return unless response.key?(:messages)

    # below makes sure a singleton hash is turned intoan array
    ServiceClient.iterate_element(response[:messages]) do |mess|
      assert_not_ora_error(mess)
      # add error to main class
      @errors = ActiveModel::Errors.new(self) if @errors.nil?
      @errors.add(:base, mess[:code].to_sym, message: mess[:text])
    end
  end

  # if the call wasn't successful and we don't have any messages then raise a fatal error
  # @param success flag from the back office
  # @param response the response from the back office
  def assert_not_failure_without_messages(success, response)
    return if success
    return if response.key?(:messages)

    raise Error::AppError.new('NONE', 'Call to back office failed with no messages')
  end

  # Responses with a code starting "ORA-" or "DB-" are Oracle error messages
  # which we will treat as exceptions to be logged and raised.
  def assert_not_ora_error(mess)
    # ORA errors are fatal, DB errors are fatal if message is an un expected error
    return unless mess[:code].starts_with?('ORA-') ||
                  (mess[:code].starts_with?('DB-') && mess[:text] == 'An unexpected error occurred')

    Rails.logger.error("#{mess[:code]} #{mess[:text]}")
    raise Error::AppError.new(mess[:code], mess[:text])
  end
end
