# frozen_string_literal: true

# Common code for handling setup and calls to the Foundation Layer back office
# and associated error handling.
# @see ServiceClientConfiguration initializer for the configuration of calls to the back office.
module ServiceClient # rubocop:disable Metrics/ModuleLength
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
  def self.iterate_element(body, &block)
    return if body.nil?

    # this extracts the values for the hash, if these are an array then we have an array of an array so
    # so flatten removes one of the arrays
    body.values.flatten.each(&block)
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

  # Make a call to the back office to using the config_key provided to load the service point details
  # from ServiceClients.services. It will return if the call was successful
  # you can provide an optional lambda to process the response to return objects if the request was successful.
  # Errors are added to the current model.
  # @note: See also {#class_methods.call_ok?} at the class level
  def call_ok?(config_key, request)
    config = RevScot::ServiceClientConfiguration.configuration[config_key]
    Rails.logger.debug { "Calling (instance) #{config[:endpoint]}" }
    success, response_body = ServiceClient.call(config, request)
    Rails.logger.debug { 'Call Failed' } unless success

    ensure_message_on_fail(success, response_body)
    extract_errors(response_body)

    # if successful yield to calling code to extract details
    yield(filtered_attributes(response_body)) if success && block_given?
    success
  end

  # If the call wasn't successful at the class level then this has to be a fatal type error (as there's no model
  # to attach errors to)
  # @note: This is a self. method rather than under ClassMethods so the test code can easily access it.
  # @param success flag from the back office
  # @param response the response from the back office
  def self.assert_not_failure(success, response)
    return if success

    # if we have a failure and no messages then bomb out (message text isn't shown to user so not translated)
    raise Error::AppError.new('NONE', 'Call to back office failed with no messages') unless response.key?(:messages)

    # Raise the first message as the error
    ServiceClient.iterate_element(response[:messages]) do |mess|
      Rails.logger.error("#{mess[:code]} #{mess[:text]}")
      raise Error::AppError.new(mess[:code], mess[:text])
    end
  end

  # Classes that the ActiveSupport::Concern automatically adds as class level methods
  module ClassMethods
    # class equivalent of the instance level class call but without the ability
    # to copy the errors into the current model as there isn't one
    # NOTE: See also {#call_ok?} at the instance level
    def call_ok?(config_key, request)
      config = RevScot::ServiceClientConfiguration.configuration[config_key]
      Rails.logger.debug { "Calling (class) #{config[:endpoint]}" }
      success, response_body = ServiceClient.call(config, request)
      Rails.logger.debug { 'Call Failed' } unless success

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

  # If success is false and response doesn't contain messages, add a message to say it failed without messages.
  def ensure_message_on_fail(success, response)
    return if success || response.key?(:messages)

    response[:messages] = { message: {
      code: 'NONE',
      text: I18n.t('errors.error_report',
                   error_ref: Error::ErrorHandler.log_message('Success == false no messages'))
    } }
  end

  # extract any messages if there are any
  def extract_errors(response)
    return unless response.key?(:messages)

    # below makes sure a singleton hash is turned into an array
    ServiceClient.iterate_element(response[:messages]) do |mess|
      update_ora_error_message(mess)

      add_error_to_model(mess[:logical_data_item], mess[:code], mess[:text])
    end
  end

  # Responses with a code starting "ORA-" or "DB-" and text "An unexpected error occurred" are Oracle error messages
  # which we log and then replace with a user friendly message.
  def update_ora_error_message(mess)
    return unless mess[:code].starts_with?('ORA-') ||
                  (mess[:code].starts_with?('DB-') && mess[:text] == 'An unexpected error occurred')

    mess[:text] = I18n.t('errors.error_report',
                         error_ref: Error::ErrorHandler.log_message("#{mess[:code]} #{mess[:text]}"))
  end

  # Adds a message to the correct model when received from the back office
  # @param back_office_name [String] the back office name for the attribute (needs translation)
  # @param back_office_code [String] an optional back office code for the message
  # @param message [String] the message to issue
  def add_error_to_model(back_office_name, back_office_code, message)
    attribute_name, model_name = translate_back_office_attribute(back_office_name)

    if model_name.nil?
      errors.add(attribute_name, back_office_code.to_sym, message: message)
    else
      send(model_name).errors.add(attribute_name, back_office_code.to_sym, message: message)
    end
  end

  # Translate the back office attribute name into one we recognise if it exists
  # this relies on the underlying model having a routine that returns a translation hash
  # available in back_office_attributes
  # @param back_office_name [String] the back office name
  # @return [Symbol][Symbol] the attribute name to link in the message if found otherwise returns :base
  #                          also returns the model name if the attribute is in a sub model
  def translate_back_office_attribute(back_office_name)
    return :base unless !back_office_name.nil? && respond_to?(:back_office_attributes, true)

    bo_hash = back_office_attributes[back_office_name.to_sym]
    return :base if bo_hash.nil?

    # return the attribute name or base and the optional model
    [bo_hash[:attribute] || :base, bo_hash[:model]]
  end
end
