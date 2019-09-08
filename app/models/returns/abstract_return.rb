# frozen_string_literal: true

# module to organise tax return models
module Returns
  # Common returns superclass with methods common to returns.
  class AbstractReturn < FLApplicationRecord
    # Not included in the list allowed from forms so it can't be posted and changed, ie to prevent data injection.
    # tare_reference is the string the user is shown to identify this return eg RS1000847NRSD
    # tare_refno is the number the back office uses to identify this return (probably the primary key)
    # form_type is the status of the return 'D' for draft, 'C' for calculate, 'F' for final
    attr_accessor :tare_reference, :tare_refno, :form_type, :version

    # @return [Boolean] whether or not this return is an amendment based on the version number and form type
    def amendment?
      @version.to_i > 1 || (@version.to_i == 1 && @form_type != 'D')
    end

    # Sets form type to draft and calls #save
    # @param requested_by [User] the user saving the return (ie current_user)
    def save_draft(requested_by)
      @form_type = 'D'
      save(requested_by)
    end

    # Sets form type to latest and calls #save
    # @param requested_by [User] the user saving the return (ie current_user)
    def save_latest(requested_by)
      @form_type = 'L'
      save(requested_by)
    end

    # Load a return from the back office.
    # Calls a #convert_back_office_hash method on the model.
    # @param operation [Symbol] the service client operation to call eg :slft_tax_return_details
    # @param refno_version [String] The tare_refno combined with version and separated by '-', ie unique, ID to load
    # @param requested_by [User] user requesting the operation
    # @param response_element [Symbol] expected element in the response body eg. :slft_tax_return
    def self.find(operation, refno_version, requested_by, response_element)
      ref_no, version = refno_version.include?('-') ? refno_version.split('-') : refno_version
      load_request = { 'ins1:TareRefno': ref_no, Version: version, Username: requested_by.username,
                       ParRefno: requested_by.party_refno }
      call_ok?(operation, load_request) do |body|
        refined_hash = convert_back_office_hash(body[response_element])
        output = yield(refined_hash)
        return output if output.present? && output.is_a?(AbstractReturn)

        raise Error::AppError.new(' Load', "Loading #{ref_no} failed")
      end
    end

    # Send the return to the back office to save.  Stores the save reference in tare_reference.
    # Calls #save_operation to get the right type of save (ie new or update) and set any required fields approprately.
    # @param requested_by [User] the user saving the return (ie current_user, public requests will pass nil)
    def save(requested_by) # rubocop:disable Metrics/AbcSize
      call_ok?(save_operation, additional_save_parameters(requested_by).merge!(request_save(requested_by))) do |body|
        @tare_reference = body[:return_reference]
        @tare_refno = body[:return_refno]
        @payment_date = DateFormatting.to_display_date_format(body[:payment_date]) unless body[:payment_date].nil?
        @version = body[:version] unless body[:version].nil?
        raise Error::AppError.new('Save', 'Return reference missing') if @tare_reference.blank?

        Rails.logger.info("Saved return reference : #{@tare_reference} (#{tare_refno})")
      end
    end

    # Helper method for saving slft returns. @see #save
    def additional_save_parameters(requested_by)
      # NB the order of these is important to conform to the schema
      output = { FormType: @form_type }

      # public/not-logged-in returns
      output[:Authenticated] = 'No' unless requested_by

      output[:TareReference] = @tare_reference unless @tare_reference.nil?
      output[:TareRefno] = @tare_refno unless @tare_refno.nil?
      output[:Version] = @version
      output[:Username] = requested_by.username unless requested_by.nil?
      output[:ParRefno] = requested_by.party_refno unless requested_by.nil?

      output
    end

    # returns the payment types list valid for this return removing DD if this account does not have
    # a valid dd instruction
    # @param account_has_dd_instruction [Boolean] does the account have a dd instruction
    # @return [Array] the array of valid payment types
    def list_payment_types(account_has_dd_instruction = false)
      if account_has_dd_instruction
        lookup_ref_data(:fpay_method).values.sort_by(&:sort_key)
      else
        lookup_ref_data(:fpay_method).delete_if { |k, _v| k == 'DDEBIT' }.values.sort_by(&:sort_key)
      end
    end
  end
end
