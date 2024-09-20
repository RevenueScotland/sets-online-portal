# frozen_string_literal: true

# Need to manually require the zip gem as otherwise not loaded in production
require_dependency 'zip'

# Models an All return object
module Dashboard
  # This is the all return for the dashboard
  # @note latest_draft_dis_ind is the latest/draft indicator, this can only have one of the three values;
  #   these values are 'L' means it's the latest return, 'D' means its a draft return, '' means that
  #   it is not the latest version or a draft and lastly, 'Y' means it's disregarded.
  #   It's been named this way to be consistent with the back office.
  class DashboardReturn < FLApplicationRecord # rubocop:disable Metrics/ClassLength
    include NumberFormatting
    include Pagination
    attr_accessor :srv_code, :tare_refno, :tare_reference, :agent_reference,
                  :version, :return_status, :return_balance, :balance_status,
                  :return_date, :description, :latest_draft_dis_ind,
                  :filing_date, :payment_date, :enquiry_open, :draft_present,
                  :document_return, :receipt_available

    # Define the ref data codes associated with the attributes to be cached in this model
    # @return [Hash] <attribute> => <ref data composite key>
    def cached_ref_data_codes
      { latest_draft_dis_ind: comp_key('RETURN_STATUS', 'SYS', 'RSTU') }
    end

    # Instead of using the default 'id' attribute for the value, it is now using this.
    def to_param
      CGI.escape("#{tare_refno}-#{version}-#{srv_code}-#{tare_reference}")
    end

    # Used for splitting up the values of params[:id] of a dashboard_return.
    # To use this outside the model, you'll need to do Dashboard::DashboardReturn.split_param_values(param_id)
    # @see to_param to see where the values are coming from
    # @return [Hash] contains the split values that's assigned to the same name before it was joined in the to_param
    def self.split_param_values(param_id)
      hash = {}
      hash[:tare_refno], hash[:version], hash[:srv_code], hash[:tare_reference] = param_id.split('-')
      hash
    end

    # The amend action code(s)
    def amend_action
      RS::AuthorisationHelper.const_get(:"#{srv_code}_AMEND")
    end

    # The continue action code(s)
    def continue_action
      RS::AuthorisationHelper.const_get(:"#{srv_code}_CONTINUE")
    end

    # The delete action code(s)
    def delete_action
      RS::AuthorisationHelper.const_get(:"#{srv_code}_DELETE")
    end

    # Used to display a summary status
    def summary_status
      return @return_status if balance_status.nil?

      "#{@return_status} (#{@balance_status})"
    end

    # Used for determining whether to show an action link when return latest_draft_dis_ind is 'L'.
    # @see TableHelper#include_action? this is used as value for :visible_for symbol
    # @return [Boolean] when the return latest_draft_dis_ind is 'L' then true (then it will be visible)
    def indicator_is_latest?
      latest_draft_dis_ind == 'L'
    end

    # Used for determining whether to show an action link when return latest_draft_dis_ind is 'D'
    # @see TableHelper#include_action? this is used as value for :visible_for symbol
    # @return [Boolean] when the return latest_draft_dis_ind is 'D' then true (then it will be visible)
    def indicator_is_draft?
      latest_draft_dis_ind == 'D'
    end

    # Used for determining whether to show an "Ongoing Enquiry" text among action link when return enquiry_open is true
    # @see TableHelper#include_action? this is used as value for :visible_for symbol
    # @return [Boolean] when the return enquiry_open is true then true (then it will be visible)
    def enquiry_indicator?
      return true if enquiry_open == true

      false
    end

    # Used for determining whether to show an "Receipt" text among action link when return receipt_available is true
    # and the return should not be draft
    # @see TableHelper#include_action? this is used as value for :visible_for symbol
    # @return [Boolean] when the return receipt_available is true then true (then it will be visible)
    def receipt_indicator?
      return false unless indicator_is_latest?

      return true if receipt_available == true

      false
    end

    # Used for determining whether to show an "Draft present" text among action link when return draft_present is true
    # unless this is a draft version or is there an ongoing enquiry
    # @see TableHelper#include_action? this is used as value for :visible_for symbol
    # @return [Boolean] when the return draft_present is true then true (then it will be visible)
    def draft_present?
      return true if draft_present == true && !indicator_is_draft? && !enquiry_indicator?

      false
    end

    # Used for determining whether to show an action link to continue a draft return
    # this is not shown if there is an enquiry open or it isn't draft
    # @see TableHelper#include_action? this is used as value for :visible_for symbol
    def return_is_continuable?
      return false if enquiry_open == true

      return false if not_continuable_indicator?

      latest_draft_dis_ind == 'D'
    end

    # Used for determining whether to show the Download waste details link.
    # @see TableHelper#include_action? this is used as value for :visible_for symbol
    def return_has_waste?
      srv_code == 'SLFT'
    end

    # Used for determining whether to show an action link when the return date is 12 months old or older
    # for a return that is Filed.
    # @see TableHelper#include_action? this is used as value for :visible_for symbol
    def return_is_amendable?
      return false unless indicator_is_latest?

      return false if enquiry_open == true

      return false if draft_present == true

      remaining_amendable_period.positive?
    end

    # Return the remaining period during which the return is amendable
    # If this is an initial draft version there is no filing date so the result is 'undefined'
    # practically it return nil
    # @return [Days] the number of days
    def remaining_amendable_period
      return if filing_date.blank?

      # The below deals with various types. The parameter is a rails duration of .days if you take an integer from it
      # it assumes the integer is seconds so turn the integer into a days duration
      (Rails.configuration.x.returns.amendable_days - (Time.zone.today - filing_date).to_i.days)
    end

    # Returns the cut off date for the amendable period
    # @return [String] the date
    def amendable_cut_off_date
      DateFormatting.to_display_date_format(remaining_amendable_period.since.to_datetime)
    end

    # Used for determining whether to show warning message or not if less than 7 days remaining to
    # submit a drafted return
    # @return [Boolean] true if the return is in final days(last 7 days) of configurable period
    def not_continuable_warning?
      version.to_i > 1 && !remaining_amendable_period.negative? && indicator_is_draft? &&
        remaining_amendable_period <= Rails.configuration.x.returns.amendable_warning_days
    end

    # delete draft return from back office
    # @param requested_by [Object] is the user who is requesting for the data.
    # @param id [String] this includes the data that we need to pass in to the request to delete the data we want
    #   from the back office. It must include the version, srv_code, tare_refno within the string that's joined
    #   with '-'s.
    # @return [Boolean] true if document delete successfully from back office else false
    def self.delete_return(requested_by, id)
      call_ok?(:delete_draft_tax_return, request_delete_return(requested_by, id))
    end

    # @return a hash suitable for use in a delete drafted return to the back office
    def self.request_delete_return(requested_by, id)
      { 'ins1:TareRefno': id[:tare_refno],
        Version: id[:version],
        SRVCode: id[:srv_code],
        ParRefno: requested_by.party_refno,
        Username: requested_by.username }
    end

    # returns true or false to display claim link or not for returns
    def return_is_claimable?
      return false unless indicator_is_latest?

      filing_days_old = (Time.zone.today - filing_date).to_i.days
      # If the filing date is 365 days old or older then true (used for showing the claim)
      (filing_days_old >= Rails.configuration.x.returns.amendable_days)
    end

    # @return [Boolean] true if return is no longer continuable
    def not_continuable_indicator?
      version.to_i > 1 && indicator_is_draft? && remaining_amendable_period.negative?
    end

    # Finds a specific dashboard_return and returns it's details
    # @param requested_by [Object] the user currently logged-in requesting for data
    # @param return_id [String] the id of the dashboard return to be returned
    # @return [Object] the DashboardReturn with values of the specified return_id
    def self.find(requested_by, return_id)
      # When there's access to the back office, code can be further improved
      all_returns = list_returns(requested_by)
      all_returns[return_id]
    end

    # This is what is used for the controllers. It gets the all return data and the pagination for it.
    # @param requested_by [Object] the user who is requesting for the data.
    # @param page [Integer] the current page.
    # @param filter [Object] an instance of a DashboardReturnFilter object, which may have some data in its attributes.
    # @param num_rows [Integer] it is the limit of number of rows to show.
    # @return [Array] there are two items in this array which are used for getting the all_returns and pagination.
    def self.list_all_returns(requested_by, page, filter, num_rows = 10)
      pagination = Pagination.initialise_pagination(num_rows, page)
      # Checks if the filter fields consists of valid data
      return unless filter.valid?

      all_returns, back_office_pagination = back_office_all_returns_data(requested_by, filter, pagination)
      all_returns = all_returns.values
      pagination = Pagination.paginate_back_office(pagination, back_office_pagination)

      [all_returns, pagination]
    end

    # Gets the return pdf ready to be downloaded.
    # @see back_office_pdf_data
    def self.return_pdf(requested_by, id, pdf_type)
      back_office_pdf_data(requested_by, id, pdf_type)
    end

    # Generates a ZIP file of waste data, where each site's waste data is a separate
    # CSV file.
    # @note Ideally this should use Tempfile.new and Zip::OutputStream.write_buffer to generate the files, as this
    #   would automatically remove any temporary files, but this combination produced ZIP files that where able to be
    #   read with Z-zip, but not with Windows explorer
    # @param requested_by [User] is usually the current_user, who is requesting the data and containing the account id
    # @param id [Hash] The reference number, tare_refno, srv_code and version of the SLFT return to get the waste data.
    # @return [Array] success flag, and ZIP file, return reference and version, if successful
    def self.return_wastes(requested_by, id)
      slft_return = Returns::Slft::SlftReturn.find(id, requested_by)
      raise Error::AppError.new('RETURN', "Cannot find return #{id[:tare_reference]}") if slft_return.nil?

      zip_file = make_tmpname(requested_by, '.zip')
      Dir.mktmpdir do |dir|
        slft_return.export_site_wastes dir
        zip_folder dir, zip_file
      end
      [true, zip_file, slft_return.tare_reference, slft_return.version]
    end

    # @!method self.make_tmpname(ext)
    # Generate a temporary filename
    # @param requested_by [User] is usually the current_user
    # @param ext [String] file extension
    # @return [String] temporary filename
    private_class_method def self.make_tmpname(requested_by, ext)
      ResourceItem.file_temp_storage_path(:download, requested_by.username, "#{SecureRandom.urlsafe_base64}#{ext}")
    end

    # @!method self.zip_folder(dir, zip_file)
    # Add all of the files in the fir folder, into the named ZIP file. Not recursive.
    # @param dir [String] directory containing all of the files to be zipped
    # @param zip_file [String] the output file name
    private_class_method def self.zip_folder(dir, zip_file)
      Zip::File.open(zip_file, Zip::File::CREATE) do |archive|
        entries = Dir.entries(dir) - %w[. ..]
        entries.each do |file|
          archive.add(file, File.join(dir, file))
        end
      end
    end

    # Gets the all returns from the back office according to the requested-by and filtering.
    # @note new_id is used instead of reference so that data won't get lost as reference can
    #   be not unique, this is used for putting the instances on a hash.
    # @return [Hash] a hash of all returns from the back office
    private_class_method def self.back_office_all_returns_data(requested_by, filter, pagination)
      all_returns, pagination_return = {}
      success = call_ok?(:view_all_returns, request_elements(requested_by, filter, pagination)) do |body|
        break if body.blank?

        pagination_return = body[:returns][:pagination]
        ServiceClient.iterate_element(body[:returns][:response]) do |all_return|
          # Uses '<tare_refno>.<version>' as the key for each of the object made
          all_returns[all_return.slice(:tare_refno, :version).values.join('.')] =
            modify_attributes(DashboardReturn.new_from_fl(all_return))
        end
      end

      [all_returns, pagination_return] if success
    end

    # @!method self.back_office_pdf_data(requested_by, return_data)
    # Gets the all the data regarding the version and tare_reference of a return, which will be used for downloading
    # as a pdf file.
    # @param return_data [Hash] this includes the data that we need to pass in to the request to get the data we want
    #   from the back office. It must include the symbol :reference and :version.
    # @param requested_by [Object] is the user who is requesting for the data.
    # @param pdf_type [String] Receipt or Return to send in request xml
    # @return [Array] consists of [Boolean, Hash] the Boolean value is used to check if the call was successful and
    #   the Hash consists of data regarding the pdf to be downloaded.
    private_class_method def self.back_office_pdf_data(requested_by, return_data, pdf_type)
      pdf_response = ''
      success = call_ok?(:view_return_pdf, request_pdf_elements(requested_by, return_data, pdf_type)) do |body|
        break if body.blank?

        pdf_response = body
      end

      [success, pdf_response]
    end

    # The request element list to retrieve data of the return which consists of a binary data,
    # this will be used for downloading the pdf that contains the data of that return.
    # @return [Hash] elements used to specify all the compulsory data needed to request data from the back office.
    # @param pdf_type consist value to send in RequestType eg. Receipt or Return
    # if pdf_type = 'Receipt' response will contain Receipt PDF
    # and if pdf_type = 'Return' response will contain Return PDF
    private_class_method def self.request_pdf_elements(requested_by, return_data, pdf_type)
      { ParRefno: requested_by.party_refno, Username: requested_by.username,
        TareReference: return_data[:tare_reference], ReturnVersion: return_data[:version],
        RequestType: pdf_type }
    end

    # The request element list to retrieve the all return data.
    #
    # We need to downcase the filters from Yes/No as that is what the back office expects
    # @return [Hash] elements used to specify what data we want to get from the back office
    private_class_method def self.request_elements(requested_by, filter, pagination)
      { SRVCode: nil, ParRefno: requested_by.party_refno, Username: requested_by.username,
        OutstandingBalance: filter.lookup_ref_data_value(:outstanding_balance)&.downcase,
        AllVersions: filter.lookup_ref_data_value(:all_versions).downcase,
        DraftOnly: filter.lookup_ref_data_value(:draft_only).downcase,
        MyReturnsOnly: filter.lookup_ref_data_value(:my_returns_only).downcase }
        .merge(request_optional_elements(filter, pagination))
    end

    # The optional request element list to retrieve more specific data.
    # @return [Hash] elements used to specify the optional request we want to do to get data from back office
    # @note ReturnStatus is named this way to be consistent with the back office.
    private_class_method def self.request_optional_elements(filter, pagination)
      { Pagination: { 'ins1:StartRow' => pagination.start_row, 'ins1:NumRows' => pagination.num_rows },
        TAREReference: filter.tare_reference, AgentReference: filter.agent_reference,
        REturnStatus: filter.return_status, DescriptionSearch: filter.description,
        FromReturnDate: DateFormatting.to_xml_date_format(filter.from_return_date),
        ToReturnDate: DateFormatting.to_xml_date_format(filter.to_return_date),
        SortBy: filter.sort_by, ReturnType: filter.return_type }
    end

    # When the back office data is being extracted, this method set the specific attributes
    # with values depending on some of the data retrieved.
    private_class_method def self.modify_attributes(object)
      # For the return status that are nil, get the value of 'Filed' from the reference data/value
      # using cached_ref_data_codes.
      object.return_status ||= object.lookup_ref_data_value(:latest_draft_dis_ind, 'L')
      object
    end
  end
end
