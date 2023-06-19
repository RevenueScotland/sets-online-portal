# frozen_string_literal: true

# Filter class used to control search of users on the page, see also search
class UserFilter < BaseFilter
  attr_accessor :full_name, :user_is_current

  validates :full_name, length: { maximum: 255 }

  # Define the ref data codes associated with the attributes but which won't becached in this model
  # @return [Hash] <attribute> => <ref data composite key>
  def uncached_ref_data_codes
    { user_is_current: YESNO_COMP_KEY }
  end

  # This is used for finding which of the object includes a piece of data that matches from
  # the fields for filtering out the table.
  # @return [Boolean] true or false depending on the contents of the filter fields.
  def include?(user)
    BaseFilter.string_includes?(user.full_name, full_name) &&
      BaseFilter.string_matches?(user.user_is_current, user_is_current)
  end

  # Provides filterd request params
  def self.params(params)
    params.fetch(:user_filter, {}).permit(:full_name, :user_is_current)
  end
end
