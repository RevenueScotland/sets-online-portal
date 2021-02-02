# frozen_string_literal: true

# Utility helpers keep method used across application
module UtilityHelper # rubocop:disable Metrics/ModuleLength
  # Regex that identifies if text is an english question
  QUESTION_REGEX = /\A((ARE |DO |DOES |HAS |HAVE |HOW |IF |IS |SHOULD |WHAT |WHICH |WHO |WILL ))/i.freeze
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
    width_class = "#{gds_css_class_for_width(options[:width])} "
    class_output = width_class + field_class
    # This will ensure that the class that we get from the html_options will always be '' instead of nil
    html_class = html_options[:class] || ''
    html_class = " #{html_class unless class_output == '' || html_class.blank?}"
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
                       when 'full', 'three-quarters', 'two-thirds', 'one-half', 'one-third', 'one-quarter'
                         "govuk-!-width-#{width}"
                       when 'width-20', 'width-10', 'width-5', 'width-4', 'width-3', 'width-2'
                         "govuk-input--#{width}"
                       end
    end
    css_class_name
  end

  # Creates the standard html options for a button or submit.
  # @example UtilityHelper.submit_html_options(id, options, html_options)
  # @return [Hash] the html options with added data.
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

  # Generate the standard text of an object's attribute
  # This can optionally override the attribute name by calling the object's translation method.
  # It can optionally include value(s) from the object by calling the object's translation_variables method.
  # It supports the following hash keys:
  #   symbol that matches type_text parameter [String] to hard code the text for that attribute
  #   :translation_options [String|Symbol] to be used for doing the translation_variables and
  #   translation_attribute method.
  # @example attribute_text(<object>, <attribute>, :hint)
  #   this will look for the translation of the attribute in
  #   en:
  #   ..activemodel:
  #   ....hints:
  #   ......<object.class.name>:
  #   ........<attribute>: "hint text for the attribute"
  # @param object [Object] the object being processed
  # @param attribute [Symbol] is the attribute of the object that's being processed.
  # @param text_type [Symbol] this is the type of text this is referring to, this could be :hint, :caption or
  #   any type of text to translate.
  # @param options [Hash] may contain a hash with instructions to further modify the text to translate
  # @return [String] the translated text value of the attribute according to the text type.
  def self.attribute_text(object, attribute, text_type, options = {})
    options ||= {}
    return options[text_type] unless options[text_type].nil?

    text_type = text_type.to_s.pluralize.to_sym
    text = I18n.t(UtilityHelper.get_attribute_key(object, attribute, options),
                  **UtilityHelper.get_attribute_extra_translation_options(object, attribute, options)
                               .merge(default: '', scope: get_translation_scope(object, text_type)))

    UtilityHelper.swap_texts(text, options)
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
    text.gsub(Regexp.new("(?<c>[#{Regexp.escape(characters)}])"), '\k<c>&#8203;')&.html_safe
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

  # Gets the extra options for the translation based on the current attribute we're pointing to.
  # The user can get values from within the model to be passed down to the texts in labels or hints.
  # They can also use this to pass options from the model to get the translation done in a specific way.
  # @return [Hash] translation extra options.
  def self.get_attribute_extra_translation_options(object, attribute, options = {})
    return {} unless object.respond_to?(:translation_variables)

    object.translation_variables(attribute, options[:translation_options])
  end

  # Utility helper to give the full path for the given translation key.
  # Effectively this returns the full path that would be used by the normal t(.<key>) Rails operation
  # Used when passing view keys into a partial
  # @see https://github.com/rails/rails/blob/56832e791f3ec3e586cf049c6408c7a183fdd3a1/actionview/lib/action_view/helpers/translation_helper.rb#L123
  # @param key [String] the key to be used
  def full_lazy_lookup_path(key)
    if key.to_s.first == '.'
      raise "Cannot use t(#{key.inspect}) short cut because path is not available" unless @virtual_path

      @virtual_path.gsub(%r{/_?}, '.') + key.to_s
    else
      key
    end
  end

  # Modifies the html text to give each elements the correct standard classes
  # @param html_text [HTML block element] contains the html which the correct classes will be added to.
  # @return [HTML block element] the elements modified to have the correct classes per element.
  def self.standardize_elements(html_text)
    html_text.gsub!('<div>', '<div class="govuk-form-group">')
    html_text.gsub!('<h1>', '<h1 class="govuk-heading-l">')
    html_text.gsub!('<h2>', '<h2 class="govuk-heading-m">')
    html_text.gsub!('<h3>', '<h3 class="govuk-heading-s">')
    html_text.gsub!('<p>', '<p class="govuk-body">')
    html_text.gsub!('<ul>', '<ul class="govuk-list govuk-list--bullet">')
    standardize_table_elements(html_text)
    # Regex means to look for ("<a") + (zero or more characters thats not ">") + (">")
    html_text.gsub!(/<a[^>]*>/) { |link_tag| standardize_link_tag(link_tag) }
    html_text
  end

  # Modifies the html text to give each table elements the correct standard classes
  # @param html_text [HTML block element] see standardize_elements
  # @return [HTML block element] the elements modified to have the correct classes per element.
  private_class_method def self.standardize_table_elements(html_text)
    html_text.gsub!('<table>', '<table class="govuk-table">')
    html_text.gsub!('<thead>', '<thead class="govuk-table__head">')
    html_text.gsub!('<tbody>', '<tbody class="govuk-table__body">')
    html_text.gsub!('<th>', '<th class="govuk-table__header">')
    html_text.gsub!('<tr>', '<tr class="govuk-table__row">')
    html_text.gsub!('<td>', '<td class="govuk-table__cell">')
    html_text
  end

  # Modifies the link tag's properties to have the correct standard properties.
  # @param link_tag [HTML block tag] specific link tag to be modified.
  # @return [HTML block tag] the link tag modified so that it has the correct standard properties.
  private_class_method def self.standardize_link_tag(link_tag)
    link_tag.gsub!('<a', '<a class="govuk-link"') unless link_tag.include?('class=')
    # Added to prevent the anchor tag's security issue of 'reverse tabnabbing'
    link_tag.gsub!('target="_blank"', 'target="_blank" rel="noopener noreferrer"') unless link_tag.include?('rel=')
    link_tag
  end

  # add optional keyword if optional: true is send from view
  # @param label [String] the label of the optional item
  # @param options [Array] an array of options to look for the symbol :optional to determine whether its optional or not
  # @return [String] returns the label with the standard optional keyword if the content is an optional field
  private_class_method def self.append_optional_keyword(label, options = {})
    optional = options[:optional] unless options[:optional] == nil?
    label = "#{label} (#{I18n.t('optional')})" if optional == true
    label
  end

  # Gets the actual label from the translation files
  # @param object [Object] the object being processed
  # @param attribute [symbol] is a string that will be altered and returned.
  # @param options [Hash] may contain a hash with a question key
  # @return [String] the translated label
  private_class_method def self.get_translation(object, attribute, options = {})
    attribute_key = UtilityHelper.get_attribute_key(object, attribute, options)
    key_scope = options[:key_scope] || get_translation_scope(object, :attributes)
    label_translation_options = UtilityHelper.get_attribute_extra_translation_options(object, attribute, options)
                                             .merge(default: attribute_key.to_s.humanize, scope: key_scope)
    I18n.t(attribute_key, **label_translation_options).html_safe
  end

  # Gets the translation scope depending on the passed symbol
  # @param object [Object] the object being processed
  # @param symbol [Symbol] is the part of the key scope, which is either :attributes, :hints or :captions
  # @return [Array] the scope to be used for the :scope of the translation options part of when translating texts.
  private_class_method def self.get_translation_scope(object, symbol)
    [object.i18n_scope, symbol, object.model_name.i18n_key]
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

  # Utility helper to use translation on page description
  # Effectively this returns the t(.<key>) Rails operation
  # @param key [String] the key to be used and @param index of buyer
  def translation_for_index(key, index)
    "#{key}_#{index.to_i > 4 ? 'other' : index.to_s}"
  end
end
