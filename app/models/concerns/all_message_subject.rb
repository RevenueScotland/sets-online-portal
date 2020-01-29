# frozen_string_literal: true

# This concern adds the ability to handle the all_message_subject reference value list
# The all message subject list is a list across all of the services filtered by the services available to the user
module AllMessageSubject
  extend ActiveSupport::Concern

  # returns the subject code as the full key with all key parts used on the page
  # @return [String] the full composite key of the subject code
  def subject_code
    return nil if @subject_code.nil?

    "#{@subject_code}>$<#{comp_key(@subject_domain, @srv_code, 'RSTU')}"
  end

  # Sets the individual items based on the composite key
  def subject_code=(value)
    a = value.split('>$<')
    @subject_code = a[0]
    @subject_domain = a[1]
    @srv_code = a[2]
    @wrk_refno = 1 # always 1 for RSTU
  end

  # Returns the list of subjects available for the current user based on their linked services(taxes)
  def subject_description_list(current_user)
    if @subject_description_list.nil?
      # Get the taxes/services for the current user and build a list of the arrays
      account = Account.find(current_user)
      # Get the list of message subjects across all services
      list = ReferenceData::ReferenceValue.list('ALL_MESSAGE_SUBJECT', 'SYS', 'RSTU')

      # Run the filter on the list
      @subject_description_list = list.select do |r|
        (r.service_code == 'SYS') || account.taxes.include?(r.service_code)
      end
    end
    @subject_description_list
  end
end
