# frozen_string_literal: true

# Common code between the registration wizard and general accounts functionality
module RegistrationAccountsCommon
  extend ActiveSupport::Concern

  private

  # controls the permitted parameters for account registration
  def register_account_params
    filtered_params = params.require(:account).permit(Account.attribute_list.reject { |attr| attr == :taxes })
    filtered_params.merge!(params.require(:account).permit(taxes: []))
    filtered_params.merge!(register_account_type_params)
    filtered_params
  end

  # Returns the account_type parameters
  def register_account_type_params
    return {} unless params[:account][:account_type]

    params.require(:account).require(:account_type).permit(AccountType.attribute_list)
  end

  # Return the parameter list filtered for the attributes of the registration model, that apply
  # to users
  def register_user_params
    filtered_params = {}
    if params[:account] && params[:account][:user]
      filtered_params.merge!(params.require(:account)
                                    .require(:user).permit(User.attribute_list))
    end
    filtered_params
  end

  # Return the parameter list filtered for the attributes of the registration model, that apply
  # to company
  def register_company_params
    return {} unless params[:account] && params[:account][:company]

    params.require(:account).require(:company).permit(Company.attribute_list)
  end

  # Copy email_address(_confirmation) and mobile number from account into user as
  # attributes are the same when an account is created for the initial user
  # @param account [Object] the account
  # @return [Object] the account with attributes copied over to the user
  def copy_account_to_user(account)
    return account if account.current_user.nil?

    account.current_user.contact_number = account.contact_number
    account.current_user.email_address = account.email_address
    account.current_user.email_address_confirmation = account.email_address_confirmation
    account
  end
end
