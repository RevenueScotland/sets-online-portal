# frozen_string_literal: true

# Helper class to re validate a sub object model
module CompleteModelValidationHelper
  extend ActiveSupport::Concern

  # Check if @param objects [Object] is an array and travers validation through each object present in an array.
  def validate_sub_objects(objects, link_id)
    if objects.is_a?(Array)
      objects.each_with_index do |object, i|
        validate_sub_object(object, "#{link_id}_#{i + 1}")
      end
    else
      validate_sub_object(object, link_id)
    end
  end

  private

  # Performs validation on @param object and add an error on parent model
  # @param link_id [String] associates the error with an id, in order to link an error message to particular record
  def validate_sub_object(object, link_id)
    return if object.valid? object.class.attribute_list

    # Clears out existing errors on the parent object and creates new errors in :base context with a suitable message.
    object.errors.clear
    errors.add(:base, :section_not_complete, attr: object.key_info, link_id: link_id)
  end
end
