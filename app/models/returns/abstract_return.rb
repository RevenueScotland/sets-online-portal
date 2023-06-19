# frozen_string_literal: true

# module to organise tax return models
module Returns
  # Common returns superclass with methods common to returns.
  class AbstractReturn < FLApplicationRecord
    # Not included in the list allowed from forms so it can't be posted and changed, ie to prevent data injection.
    # tare_reference is the string the user is shown to identify this return eg RS1000847NRSD
    # tare_refno is the number the back office uses to identify this return (probably the primary key)
    # form_type is the status of the return 'D' for draft, 'L'/'F' for Latest/Filed
    # previous_pay_method is the payment method used on the previous version of a return (nil for the first return)
    attr_accessor :tare_reference, :tare_refno, :form_type, :previous_form_type, :version, :previous_fpay_method,
                  :non_notifiable_reasons

    # @return [Boolean] whether or not this return is an amendment based on the version number and form type
    def amendment?
      @version.to_i > 1 || (@version.to_i == 1 && @previous_form_type != 'D')
    end

    # Sets form type to draft and calls #save
    # @param requested_by [User] the user saving the return (ie current_user)
    def save_draft(requested_by)
      @form_type = 'D'
      save(requested_by)
    end

    # Gets the return ready to save
    # primarily checks if it is being/has already been submitted and raises an error if it has
    # This is doing optimistic locking where we assume the save latest will work. We have to do this in case the user
    # loses the connection. The return needs to be saved to the cache after calling this routine
    # @return [Boolean] true if the return is prepared
    def prepare_to_save_latest
      errors.add(:base, :has_already_been_submitted) && (return false) if @already_submitted
      @already_submitted = true
      true
    end

    # Sets form type to latest and calls #save
    # Resets the saved flag if there is an error
    # @param requested_by [User] the user saving the return (ie current_user)
    def save_latest(requested_by)
      @form_type = 'L'
      success = save(requested_by)
      # if errors have been added then save failed
      success = false if errors.any?
      if success
        @previous_form_type = 'F' # Use filed, not latest
      else
        # only clear the saving flag if the save failed
        @already_submitted = false
      end
      success
    end

    # @!method self.abstract_find(operation, id, requested_by, response_element)
    # Load a return from the back office.
    # Calls a #convert_back_office_hash method on the model.
    # @param operation [Symbol] the service client operation to call eg :slft_tax_return_details
    # @param id [Hash] The tare_refno, version, srv_code and tare_reference used for finding a return.
    # @param requested_by [User] user requesting the operation
    # @param response_element [Symbol] expected element in the response body eg. :slft_tax_return
    def self.abstract_find(operation, id, requested_by, response_element)
      ref_no = id[:tare_refno]
      load_request = { 'ins0:TareRefno': ref_no, Version: id[:version], Username: requested_by.username,
                       ParRefno: requested_by.party_refno }
      call_ok?(operation, load_request) do |body|
        refined_hash = convert_back_office_hash(body[response_element])
        output = yield(refined_hash)
        return copy_to_previous(output) if output.present? && output.is_a?(AbstractReturn)

        raise Error::AppError.new(' Load', "Loading #{ref_no} failed")
      end
    end

    # Sets the portal variables from the back office values
    def extract_data_from_body(body)
      @tare_reference = body[:return_reference]
      @tare_refno = body[:return_refno]
      @payment_date = DateFormatting.to_display_date_format(body[:payment_date]) unless body[:payment_date].nil?
      @version = body[:version]
      @non_notifiable = body[:non_notifiable]
      @non_notifiable_reasons = []
      ServiceClient.iterate_element(body[:non_notifiable_reasons]) do |reason|
        @non_notifiable_reasons << reason[:reason_text]
      end
      @already_submitted = false if @non_notifiable
    end

    # Send the return to the back office to save.  Stores the save reference in tare_reference.
    # Calls #save_operation to get the right type of save (ie new or update) and set any required fields appropriately.
    # @param requested_by [User] the user saving the return (ie current_user, public requests will pass nil)
    def save(requested_by)
      call_ok?(save_operation, additional_save_parameters(requested_by)
      .merge!(request_save(requested_by, form_type: @form_type))) do |body|
        extract_data_from_body(body)
        if @non_notifiable
          Rails.logger.info("return is non notifiable #{@non_notifiable_reasons.join}")
        else
          raise Error::AppError.new('Save', 'Return reference missing') if @tare_reference.blank?

          Rails.logger.info("Saved return reference : #{@tare_reference} (#{tare_refno}) as version #{version}")
        end
      end
    end

    def non_notifiable?
      (@non_notifiable == true)
    end

    # Helper method for saving slft returns. @see #save
    def additional_save_parameters(requested_by)
      # NB the order of these is important to conform to the schema
      output = { FormType: @form_type }

      # public/not-logged-in returns
      output[:Authenticated] = 'No' unless requested_by

      output[:TareReference] = @tare_reference unless @tare_reference.nil?
      output[:TareRefno] = @tare_refno unless @tare_refno.nil?
      output[:Version] = @version || '1' # if no version set (i.e creating the first version) then set to 1
      unless requested_by.nil?
        output[:Username] = requested_by.username
        output[:ParRefno] = requested_by.party_refno
      end

      output
    end

    # returns the payment types list valid for this return removing DD if this account does not have
    # a valid dd instruction, or the previous method exists and was not DD
    # @see dd_not_available
    # @param account_has_dd_instruction [Boolean] does the account have a dd instruction
    # @return [Array] the array of valid payment types
    def list_payment_types(account_has_dd_instruction: false)
      # Remove DD if the parameter says the account doesn't have DD instruction or there
      # was a previous return and it wasn't paid by DD
      if account_has_dd_instruction && (@previous_fpay_method.blank? || @previous_fpay_method == 'DDEBIT')
        lookup_ref_data(:fpay_method).values.sort_by(&:sort_key)
      else
        lookup_ref_data(:fpay_method).delete_if { |k, _v| k == 'DDEBIT' }.values.sort_by(&:sort_key)
      end
    end

    # returns if DD is not available because the previous payment method was not DD
    # @see list_payment_types
    # @param account_has_dd_instruction [Boolean] does the account have a dd instruction
    # @return [true] If dd was removed from the list of payment methods
    def dd_not_available(account_has_dd_instruction: false)
      # return true if the parameter says account has DD instruction and previous payment method was not DD
      account_has_dd_instruction && @previous_fpay_method.present? && @previous_fpay_method != 'DDEBIT'
    end

    # returns [hash] which contains return reference number and version of the return
    def back_office_receipt_request
      hash = {}
      hash[:tare_reference] = @tare_reference
      hash[:version] = @version

      hash
    end

    # copies the current values to the previous values
    # these are used to store the previous values where we need to know what they were
    private_class_method def self.copy_to_previous(tax_return)
      tax_return.previous_form_type = tax_return.form_type
      tax_return.previous_fpay_method = tax_return.fpay_method
      tax_return
    end
  end
end
