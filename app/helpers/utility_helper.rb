# frozen_string_literal: true

# Utility helpers keep method used accross application
module UtilityHelper
  # add css class to control, default it add govuk-!-width-one-third css class in each option
  # but if not require then send default_width to false
  # @param options [Object] extra options to be added to the field
  # @param new_class [String] part of the class name
  # @param default_width [Boolean] determines whether the default width is to be used or not; true => use
  #    {gds_css_class_for_width}
  # @return [String] standard css classes
  def self.add_css_classes(options, new_class = 'govuk-input', default_width = true)
    width = options[:width] unless options[:width] == nil?
    css_class_name = default_width ? gds_css_class_for_width(width) : ''
    select_extra_options(options)
    options = { class: css_class_name + ' ' + new_class }.merge(options) do |_key_value, old_value, new_value|
      old_value + ' ' + new_value
    end
    options
  end

  # Generates a gds class for various control width
  # @example
  #   gds_css_class_for_width('one-half')
  # @param width [String] standard width value
  # @return [String] standard gds class for various control width
  def self.gds_css_class_for_width(width)
    css_class_name = 'govuk-!-width-one-third' # set default class
    unless width.nil?
      css_class_name = case width
                       when 'full', 'three-quarters', 'two-thirds', 'one-half', 'one-quarter'
                         'govuk-!-width-' + width
                       when 'width-20', 'width-10', 'width-5', 'width-4', 'width-3', 'width-2'
                         'govuk-input--' + width
                       end
    end
    css_class_name
  end

  # Generates the standard form-group class with appended class if it exists.
  def self.form_group_class(options)
    return 'govuk-form-group' if options[:class].blank? || !options[:class].is_a?(Hash)

    'govuk-form-group ' + options[:class][:form].to_s
  end

  # Generates the standard label class with appended class if it exists.
  def self.field_label_class(options)
    return 'govuk-label' if options[:class].blank? || !options[:class].is_a?(Hash)

    'govuk-label ' + options[:class][:label].to_s
  end

  # By passing in a label and options with text_link populated by a hash, it should then iterate through that hash
  # and swap each of the text found in label that is an occurence of the text_link key.
  #
  # This is very useful for when we want to add a hyper link to the text of a label.
  # @example Here is a sample: label = "A cat sat on a mat"
  #   options[:text_link] = { 'a' => 'AAAA' }
  #   If we pass in swap_texts(label, options), we should get an output of:
  #   "A cAAAAt sAAAAt on AAAA mAAAAt"
  # @param label [String] is a string that will be altered and returned.
  # @param options [Hash] should contain a hash of :text_link to swap some String values.
  def self.swap_texts(label, options)
    return if options[:text_link].blank?

    options[:text_link].each do |text_link|
      label.gsub!(text_link[0], text_link[1])
    end
  end

  # Adds the extra options for a select field.
  # It currently adds the id 'combobox' used for converting the select field into an autocomplete input field.
  private_class_method def self.select_extra_options(options)
    return options if options[:text_auto_complete].blank?

    options[:class] = "#{options[:class]} combobox" if options[:text_auto_complete]
    options.except!(:text_auto_complete)
    options
  end
end
