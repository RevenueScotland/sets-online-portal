# frozen_string_literal: true

module Dashboard
  # DashboardReturnsController handles all the dashboard returns
  class DashboardReturnsController < ApplicationController
    include Wizard
    include Returns::ControllerHelper
    include FileUploadHandler
    include DownloadHelper

    authorise requires: RS::AuthorisationHelper::VIEW_RETURNS
    authorise route: :load, requires: RS::AuthorisationHelper::LBTT_LOAD
    authorise route: :load, requires: RS::AuthorisationHelper::SLFT_LOAD
    authorise route: :download_pdf, requires: RS::AuthorisationHelper::DOWNLOAD_RETURN_PDF
    authorise route: :download_receipt, requires: RS::AuthorisationHelper::DOWNLOAD_RECEIPT

    # The index page which would be used for showing the data for all returns and the pagination
    def index
      @dashboard_return_filter = DashboardReturnFilter.new(DashboardReturnFilter.params(params))
      @dashboard_returns, @pagination_collection =
        DashboardReturn.list_all_returns(current_user, params[:page], @dashboard_return_filter)
      # Determines when the find functionality is executed in index page of financial transactions
      @on_filter_find = !params[:dashboard_dashboard_return_filter].nil?
    end

    # Loads a (SLfT or LBTT) return and redirects to the summary page of that return
    def load
      load_setup

      return_object, controller = if @srv_code == 'lbtt'
                                    [Returns::Lbtt::LbttReturn.find(@data, current_user), Returns::LbttController]
                                  else
                                    [Returns::Slft::SlftReturn.find(@data, current_user), Returns::SlftController]
                                  end
      wizard_save(return_object, controller)
      Rails.logger.info("Loaded #{@srv_code.capitalize} #{return_object}")

      redirect_to controller: "returns/#{@srv_code}", action: :summary
    end

    # get the current user account type
    def account_type
      User.account_type(current_user)
    end

    # The method used to retrieve the pdf summary of the receipt
    def download_receipt
      pdf_type = 'Receipt'
      return_pdf(pdf_type)
    end

    # The method used to retrieve the pdf summary of the return
    def download_pdf
      pdf_type = 'Return'
      return_pdf(pdf_type)
    end

    # The method used to retrieve the file attachment on messages, will update it to ZIP file
    # The "target: '_blank'" page used to download the ZIP file of the return according
    # to its reference number.
    def download_waste
      success, zip_file, tare_reference, version = DashboardReturn.return_wastes(current_user, dashboard_return_params)
      return unless success

      # Download the file
      send_file_from_path zip_file,
                          filename: "#{tare_reference}-#{version}#{File.extname(zip_file)}",
                          disposition: 'attachment'
    end

    # Delete the return specified by params[:id]
    # call the back-office
    def destroy
      Dashboard::DashboardReturn.delete_return(current_user, dashboard_return_params)
      redirect_to(dashboard_path, status: :see_other)
    end

    private

    # Checks if the contents of params[:id] is valid and gets it's values.
    def load_setup
      validate_load_param
      @data = dashboard_return_params
      @srv_code = @data[:srv_code].downcase unless @data.nil?
    end

    # The method used to retrieve the pdf summary of the return
    # The "target: '_blank'" page used to download the pdf file of the return according
    # to its reference and version.
    def return_pdf(pdf_type)
      success, attachment = DashboardReturn.return_pdf(current_user, dashboard_return_params, pdf_type)
      return unless success

      # Download the file
      send_file_from_attachment(attachment[:document_return])
    end

    # Gets the contents of the params[:id] and splits it up to convert the string into a hash
    # @return [Hash] contents of the id, see {Dashboard::DashboardReturn.split_param_values}
    def dashboard_return_params
      id = params.require(:id)
      Dashboard::DashboardReturn.split_param_values(id)
    end
  end
end
