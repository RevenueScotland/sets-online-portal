# frozen_string_literal: true

# Models an All return object
module Dashboard
  # This is the all return for the dashboard
  # @note latest_draft_dis_ind is the latest/draft indicator, this can only have one of the three values;
  #   these values are 'L' means it's the latest return, 'D' means its a draft return, '' means that
  #   it is not the latest version or a draft and lastly, 'Y' means it's disregarded.
  #   It's been named this way to be consistent with the back office.
  class DashboardReturn < FLApplicationRecord
    include NumberFormatting
    include Pagination
    attr_accessor :srv_code, :tare_refno,
                  :version, :return_status, :return_balance, :balance_status,
                  :tare_reference, :return_date, :description, :latest_draft_dis_ind,
                  :filing_date, :payment_date,
                  :document_return

    # Define the ref data codes associated with the attributes to be cached in this model
    # @return [Hash] <attribute> => <ref data composite key>
    def cached_ref_data_codes
      { latest_draft_dis_ind: 'RETURN_STATUS.SYS.RSTU' }
    end

    # Instead of using the default 'id' attribute for the value, it is now using this.
    def to_param
      CGI.escape(tare_refno.to_s + '-' + version.to_s)
    end

    # Sets the params for downloading a pdf file of a return.
    def to_download_param
      'reference=' + tare_reference.to_s + '&version=' + version.to_s
    end

    # Creates the path used for amending or continuing a return
    def continue_amend_path
      "returns_#{srv_code.downcase}_load_path".to_sym
    end

    # Sets the params for  a pdf file of a return.
    def to_claim_param
      'reference=' + tare_reference.to_s + '&version=' + version.to_s + '&srv_code=' + srv_code.to_s + '&new= true'
    end

    # The amend action code(s)
    def amend_action
      AuthorisationHelper.const_get("#{srv_code}_AMEND")
    end

    # The continue action code(s)
    def continue_action
      AuthorisationHelper.const_get("#{srv_code}_CONTINUE")
    end

    # Used for determining whether to show an action link when return latest_draft_dis_ind is 'L'.
    # @see TableHelper#include_action? this is used as value for :visible_for symbol
    # @return [Boolean] when the return latest_draft_dis_ind is 'L' then true (then it will be visible)
    def indicator_is_latest
      latest_draft_dis_ind == 'L'
    end

    # Used for determining whether to show an action link when return latest_draft_dis_ind is 'D'
    # @see TableHelper#include_action? this is used as value for :visible_for symbol
    # @return [Boolean] when the return latest_draft_dis_ind is 'D' then true (then it will be visible)
    def indicator_is_draft
      latest_draft_dis_ind == 'D'
    end

    # Used for determining whether to show an action link when the return date is 12 months old or older
    # for a return that is Filed.
    # @see TableHelper#include_action? this is used as value for :visible_for symbol
    def return_is_amendable
      return false unless indicator_is_latest

      # Deducts today's date amendable_days with the filing date. Normally when a return has been filed, that shouldn't
      # be in the future.
      filing_days_old = (Date.today - filing_date).to_i.days
      # If the filing date is 365 days old or younger then true (used for showing the amend)
      (filing_days_old < Rails.configuration.x.returns.amendable_days)
    end

    # returns true or false to display claim link or not forreturns
    def return_is_claimable
      return false unless indicator_is_latest

      filing_days_old = (Date.today - filing_date).to_i.days
      # If the filing date is 365 days old or older then true (used for showing the claim)
      (filing_days_old >= Rails.configuration.x.returns.amendable_days)
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

    # Gets the return's pdf ready to be downloaded.
    # @see back_office_pdf_data
    def self.return_pdf(requested_by, return_data)
      back_office_pdf_data(requested_by, return_data)
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
    # @return [Array] consists of [Boolean, Hash] the Boolean value is used to check if the call was successful and
    #   the Hash consists of data regarding the pdf to be downloaded.
    private_class_method def self.back_office_pdf_data(requested_by, return_data)
      pdf_response = ''
      success = call_ok?(:view_return_pdf, request_pdf_elements(requested_by, return_data)) do |body|
        break if body.blank?

        pdf_response = body
      end

      [success, pdf_response]
    end

    # The request element list to retrieve data of the return which consists of a binary data,
    # this will be used for downloading the pdf that contains the data of that return.
    # @return [Hash] elements used to specify all the compulsory data needed to request data from the back office.
    private_class_method def self.request_pdf_elements(requested_by, return_data)
      { ParRefno: requested_by.party_refno, Username: requested_by.username,
        TareReference: return_data[:reference], ReturnVersion: return_data[:version] }
    end

    # The request element list to retrieve the all return data.
    #
    # The boolean_to_yesno is being used to convert each of the 3 filter attributes
    # from it's boolean value to 'yes'/'no'
    # @return [Hash] elements used to specify what data we want to get from the back office
    private_class_method def self.request_elements(requested_by, filter, pagination)
      { SRVCode: nil, ParRefno: requested_by.party_refno, Username: requested_by.username,
        OutstandingBalance: boolean_to_yesno(filter.outstanding_balance),
        AllVersions: boolean_to_yesno(filter.all_versions),
        DraftOnly: boolean_to_yesno(filter.draft_only) }.merge(request_optional_elements(filter, pagination))
    end

    # The optional request element list to retrieve more specific data.
    # @return [Hash] elements used to specify the optional request we want to do to get data from back office
    # @note REturnStatus is named this way to be consistent with the back office.
    private_class_method def self.request_optional_elements(filter, pagination)
      { Pagination: { 'ins1:StartRow' => pagination.start_row, 'ins1:NumRows' => pagination.num_rows },
        TAREReference: filter.tare_reference, DateOfReturn: DateFormatting.to_xml_date_format(filter.return_date),
        REturnStatus: filter.return_status, DescriptionSearch: filter.description,
        FromReturnDate: DateFormatting.to_xml_date_format(filter.from_return_date),
        ToReturnDate: DateFormatting.to_xml_date_format(filter.to_return_date) }
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
