# frozen_string_literal: true

module Dashboard
  # DashboardReturnsController handles all the dashboard returns
  class DashboardReturnsController < ApplicationController
    include FileUploadHandler

    authorise requires: AuthorisationHelper::VIEW_RETURNS
    # The index page which would be used for showing the data for all returns and the pagination
    def index
      @dashboard_return_filter = DashboardReturnFilter.new(DashboardReturnFilter.params(params))
      @dashboard_returns, @pagination_collection =
        DashboardReturn.list_all_returns(current_user, params[:page], @dashboard_return_filter)
      # Determines when the find functionality is executed in index page of financial transactions
      @on_filter_find = !params[:dashboard_dashboard_return_filter].nil?
    end

    # The method used to retrieve the file attachment on messages, will update it to pdf
    # The "target: '_blank'" page used to download the pdf file of the return according
    # to its reference and version.
    def download_file
      success, attachment = DashboardReturn.return_pdf(current_user, params.permit(:reference, :version))
      return unless success

      # Download the file
      send_file_data(attachment[:document_return])
    end

    private

    # Sends file to browser for download, which automatically downloads the file.
    def send_file_data(attachment)
      send_data Base64.decode64(attachment[:binary_data]),
                type: attachment[:file_type], filename: attachment[:file_name],
                # This means to download the file, if we want to just view the file
                # this would have to be disposition: 'inline'
                disposition: 'attachment'
    end
  end
end
