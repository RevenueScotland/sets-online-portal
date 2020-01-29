# frozen_string_literal: true

# Utility helpers keep method used across application
module UtilityHelper
  # Regex that identifies if text is an english question
  QUESTION_REGEX = /\A((ARE |DO |DOES |HAS |HAVE |HOW |IF |IS |SHOULD |WHAT |WHICH |WHO ))/i.freeze
  # The html_options of most fields which includes the standard html options such as the class.
  # @param options [Hash] options containing information which is used to modify parts of the field's html options.
  # @param html_options [Hash] options (element attributes/properties) to be passed into the creation of the element.
  # @param field_class [String] normally this is the field's default class, so for example if this method is being
  #   used in a text_field then this will be 'govuk-input', another one is if this is used by a select field then
  #   this will be 'govuk-select'.
  # @return [Hash] standard html options of most fields.
  def self.field_html_options(options = {}, html_options = {}, field_class = 'govuk-input')
    html_options[:class] = field_css_classes(options, html_options, field_class)
    html_options
  end

  # Generates the string value of the standard gds class(es) for a field.
  # @return [String] standard gds class(es) for a field.
  def self.field_css_classes(options = {}, html_options = {}, field_class)
    # Determines whether the default standard width class is to be used or not.
    width_class = options[:is_not_default_width] ? '' : gds_css_class_for_width(options[:width]) + ' '
    class_output = width_class + field_class
    # This will ensure that the class that we get from the html_options will always be '' instead of nil
    html_class = html_options[:class] || ''
    html_class = ' ' + html_class unless class_output == '' || html_class.blank?
    class_output + html_class
  end

  # Generates a gds class for various control width
  # @example
  #   gds_css_class_for_width('one-half')
  # @param width [String] standard width value, which is normally an information found in options[:width].
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

  # Creates the standard functional options for a button or submit.
  # @example UtilityHelper.submit_options(options)
  # @return [Hash] the options with added data.
  def self.submit_options(options = {})
    options[:is_not_default_width] = true
    options
  end

  # Creates the standard html options for a button or submit.
  # @example UtilityHelper.submit_html_options(id, options, html_options)
  # @return [Hash] the html optins with added data.
  def self.submit_html_options(id, options = {}, html_options = {})
    html_options[:data] = { disable_with: I18n.t('working') } if options[:not_disable].nil?
    html_options[:id] = id || 'submit'
    html_options
  end

  # Generates the standard link class in text
  # @param html_options [Hash] may or may not contain the class option.
  # @return [String] standard GDS link class
  def self.link_class(html_options = {})
    link_class = 'govuk-link'
    link_class += " #{html_options[:class]}" unless html_options[:class].nil?
    link_class
  end

  # Generates a standard label for an attribute on the object
  # It can optionally override the attribute name by calling the object translation_attribute method
  # It supports the following hashes
  #  :label to hard code a label
  #  :optional to add an (optional) suffix
  #  :question, true to add ? or false to stop the code adding one if it is a question
  # @param object [Object] the object being processed
  # @param attribute [symbol] is a string that will be altered and returned.
  # @param options [Hash] may contain a hash with a question key
  def self.label_text(object, attribute, options = {})
    # Make sure we have a hash
    options ||= {}
    return options[:label] unless options[:label].nil?

    label = get_translation(object, attribute, options)
    label = make_question(label, options)
    UtilityHelper.swap_texts(append_optional_keyword(label, options), options)
  end

  # By passing in a label and options with text_link populated by a hash, it should then iterate through that hash
  # and swap each of the text found in label that is an occurrence of the text_link key.
  #
  # This is very useful for when we want to add a hyper link to the text of a label.
  # @example This will swap the text 'home' with a link 'home' that goes to the dashboard home page.
  #   UtilityHelper.swap_texts('Hello world, I want to go home, or do I?',
  #                            text_link: { 'home' => link_to('home', dashboard_home_path) })
  # @example Here is a sample: label = "A cat sat on a mat"
  #   options[:text_link] = { 'a' => 'AAAA' }
  #   If we pass in swap_texts(label, options), we should get an output of:
  #   "A cAAAAt sAAAAt on AAAA mAAAAt"
  # @param label [String] is a string that will be altered and returned.
  # @param options [Hash] should contain a hash of :text_link to swap some String values.
  def self.swap_texts(label, options)
    return label if options[:text_link].blank?

    options[:text_link].each do |text_link|
      label.gsub!(text_link[0], text_link[1])
    end
    label.html_safe
  end

  # This allows us to make the given string of characters a breakable character in a string by adding
  # a zero with space character
  # This used where we have items like references and may want e.g. a '/' to break which is the case in firefox
  # but not in other browsers
  # @example
  #   UtilityHelper.make_character_breakable('Hello/world','/')
  # @param text [String] is a string that will be altered and returned.
  # @param characters [String] is the character that is the break character
  def self.make_characters_breakable(text, characters = '/')
    return if text.blank?

    # Create a regexp where the list of characters in the string is searched for
    text = ERB::Util.html_escape(text)
    text.gsub(Regexp.new('(?<c>[' + Regexp.escape(characters) + '])'), '\k<c>&#8203;')&.html_safe
  end

  # Get attribute key require to translate label,legend or hint text of a form control.
  # User can override default attribute key by providing a translation_attribute on the underlying model
  # @param attribute [Object] the symbol to be translated to a string
  # @param options [Hash] if :translation_options is defined in the options, then it's passed to translation_attribute
  # @return [Symbol] translation key use for translation
  # @note only use :translation_options if there's no other way of avoiding it.
  def self.get_attribute_key(object, attribute, options = {})
    return attribute unless object.respond_to?(:translation_attribute)

    object.translation_attribute(attribute, options[:translation_options])
  end

  # add optional keyword if optional: true is send from view
  # @param label [String] the label of the optional item
  # @param options [Array] an array of options to look for the symbol :optional to determine whether its optional or not
  # @return [String] returns the label with the standard optional keyword if the content is an optional field
  private_class_method def self.append_optional_keyword(label, options = {})
    optional = options[:optional] unless options[:optional] == nil?
    label = label + ' (' + I18n.t('optional') + ')' if optional == true
    label
  end

  # Gets the actual label from the translation files
  # @param object [Object] the object being processed
  # @param attribute [symbol] is a string that will be altered and returned.
  # @param options [Hash] may contain a hash with a question key
  # @return [String] the translated label
  private_class_method def self.get_translation(object, attribute, options = {})
    attribute_key = UtilityHelper.get_attribute_key(object, attribute, options)
    key_scope = options[:key_scope] || [object.i18n_scope, :attributes, object.model_name.i18n_key]
    I18n.t(attribute_key, default: attribute_key.to_s.humanize, scope: key_scope).html_safe
  end

  # Adds a ? to the label string if needed by parsing the string to see if it looks like a question
  # you can override this behaviour by passing an hash with an option of :question as true or false
  # @param label [String] is a string that will be altered and returned.
  # @param options [Hash] may contain a hash with a question key
  private_class_method def self.make_question(label, options = {})
    if options.key?(:question)
      label += '?' if options.delete(:question) == true
    elsif label.match(QUESTION_REGEX)
      label += '?'
    end
    label
  end
end
