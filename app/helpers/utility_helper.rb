# frozen_string_literal: true

# Utility helpers keep method used across application
module UtilityHelper # rubocop:disable Metrics/ModuleLength
  # Regex that identifies if text is an english question
  QUESTION_REGEX = /\A((ARE |DO |DOES |HAS |HAVE |HOW |IF |IS |SHOULD |WHAT |WHICH |WHO |WILL ))/i
  # The html_options of most fields which includes the standard html options such as the class.
  # @param html_options [Hash] options (element attributes/properties) to be passed into the creation of the element,
  #   this may be altered
  # @param width [String] The width of the field
  # @param field_class [String] normally this is the field's default class, so for example if this method is being
  #   used in a text_field then this will be 'govuk-input', another one is if this is used by a select field then
  #   this will be 'govuk-select'.
  # @return [Hash] standard html options of most fields.
  def self.field_html_options(html_options, width: nil, field_class: 'govuk-input')
    html_options[:class] = [gds_css_class_for_width(width), field_class, html_options[:class]].compact.join(' ')
    html_options
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
  # @example UtilityHelper.submit_html_options(html_options, id: 'continue')
  # @param html_options [Hash] The current html_options.
  # @param id [id] The id of the field, submit if not supplied
  # @return [Hash] the html options with added data.
  def self.submit_html_options(html_options, id: nil)
    html_options[:data] = { disable_with: I18n.t('working') }
    html_options[:id] = id || 'submit'
    html_options
  end

  # Generates a standard label for an attribute on the object
  # It can optionally override the attribute name by calling the object translation_attribute method
  # It supports the following hashes
  #  :label to hard code a label
  #  :optional to add an (optional) suffix
  #  :question, true to add ? or false to stop the code adding one if it is a question
  # @param object [Object] the object being processed
  # @param attribute [Symbol] is a string that will be altered and returned.
  # @param options [Hash] options for the label
  # @option options [String] :label String to use as a label, overrides other values
  # @option options [Boolean] :optional adds the optional suffix
  # @option options [Boolean] :question is this a question, overrides build in check see #make_question
  # @option options [Hash] :text_links A hash where the string key is replaced with the string in the label
  # @option options [Symbol] :key_scope overrides the standard scope for the translation keys
  # @option options [Object] :translation_options extra info passed to the model object translation routines
  def self.label_text(object, attribute, **options)
    return options[:label] unless options[:label].nil?

    label = get_translation(object, attribute, key_scope: options[:key_scope],
                                               translation_options: options[:translation_options])
    label = make_question(label, question: options[:question])
    UtilityHelper.swap_texts(append_optional_keyword(label, optional: options[:optional]),
                             text_links: options[:text_links])
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
  #   an arbitrary symbol in which case the options needs to contain the text to return
  # @param options [Hash] may contain a hash with instructions to further modify the text to translate
  # @option options [Hash] :text_link keys in the text are replaced by the value in the hash
  # @option options [Object] :translation_options An object that is passed down the model object trans
  # @option options [String] :text_type text based on the text type parameter that is returned
  # @return [String] the translated text value of the attribute according to the text type.
  def self.attribute_text(object, attribute, text_type, **options)
    return options[text_type] unless options[text_type].nil?

    text_type = text_type.to_s.pluralize.to_sym
    text = get_translation(object, attribute, default: false, key_scope: text_type,
                                              translation_options: options[:translation_options])

    UtilityHelper.swap_texts(text, text_links: options[:text_links])
  end

  # By passing in a label and options with text_link populated by a hash, it should then iterate through that hash
  # and swap each of the text found in label that is an occurrence of the text_link key.
  #
  # This is very useful for when we want to add a hyper link to the text of a label.
  # @example This will swap the text 'home' with a link 'home' that goes to the dashboard home page.
  #   UtilityHelper.swap_texts('Hello world, I want to go home, or do I?',
  #                            text_links: { 'home' => link_to('home', dashboard_home_path) })
  # @example Swapping multiple entries
  #   swap_texts("A cat sat on a mat", { 'c' => 'CC', 'm' => 'MM' }), we should get an output of:
  #   "A CCat sat on a MMat"
  # @param label [String] is a string that will be altered and returned.
  # @param text_links [Hash] a hash where the key is the text to swap with a value to swap.
  def self.swap_texts(label, text_links: nil)
    return label if text_links.blank?

    text_links.each do |text_link|
      label.gsub!(text_link[0], text_link[1])
    end
    # If we have swapped texts then there is a link so mark as html safe
    label.html_safe # rubocop:disable Rails/OutputSafety
  end

  # This allows us to make the given string of characters a breakable character in a string by adding
  # a zero with space character
  # This used where we have items like references and may want e.g. a '/' to break which is the case in firefox
  # but not in other browsers
  # @example
  #   UtilityHelper.make_character_breakable('Hello/world','/')
  # @param text [String] is a string that will be altered and returned.
  # @param characters [String] is the character that is the break character
  def self.make_characters_breakable(text, characters: '/')
    return if text.blank?

    # Create a regexp where the list of characters in the string is searched for
    text = ERB::Util.html_escape(text)
    text.gsub(Regexp.new("(?<c>[#{Regexp.escape(characters)}])"), '\k<c>&#8203;')&.html_safe # rubocop:disable Rails/OutputSafety
  end

  # Get attribute key require to translate label,legend or hint text of a form control.
  # User can override default attribute key by providing a translation_attribute on the underlying model
  # @param attribute [Object] the symbol to be translated to a string
  # @param translation_options [Object] Extra information passed to the object translation model, usually a
  #  single string but could be anything
  # @return [Symbol] translation key use for translation
  # @note only use :translation_options if there's no other way of avoiding it.
  def self.get_attribute_key(object, attribute, translation_options: nil)
    return attribute unless object.respond_to?(:translation_attribute)

    object.translation_attribute(attribute, translation_options)
  end

  # Gets the extra options for the translation based on the current attribute we're pointing to.
  # The user can get values from within the model to be passed down to the texts in labels or hints.
  # They can also use this to pass options from the model to get the translation done in a specific way.
  # @return [Hash] translation extra options.
  def self.get_attribute_extra_translation_options(object, attribute, translation_options: nil)
    return {} unless object.respond_to?(:translation_variables)

    object.translation_variables(attribute, translation_options)
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
    # gsub turns the SafeBuffer unsafe so we have to flag it again
    html_text.html_safe # rubocop:disable Rails/OutputSafety
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

  # Add optional keyword if optional: true
  # @param label [String] the label of the optional item
  # @param optional [Boolean] is this field optional, if so add optional keyword
  # @return [String] returns the label with the standard optional keyword if the content is an optional field
  private_class_method def self.append_optional_keyword(label, optional: false)
    label = "#{label} (#{I18n.t('optional')})" if optional == true
    label
  end

  # Gets the actual label from the translation files
  # @param object [Object] the object being processed
  # @param attribute [Symbol] is a string that will be altered and returned.
  # @param default [Boolean] if true apply the default of the attribute name (used for labels).
  # @param key_scope [Array|Symbol] override the standard key scope
  # @param translation_options [Object] extra info passed to the object translation routines
  # @return [String] the translated label
  private_class_method def self.get_translation(object, attribute, default: true, key_scope: nil,
                                                translation_options: nil)
    attribute_key = UtilityHelper.get_attribute_key(object, attribute,
                                                    translation_options: translation_options)
    # Derive the scope from either the passed in array, a symbol or default to attributes
    key_scope = get_translation_scope(object, key_scope || :attributes) unless key_scope.is_a?(Array)
    default_string = attribute_key.to_s.humanize if default
    label_translation_options = UtilityHelper.get_attribute_extra_translation_options(
      object, attribute, translation_options: translation_options
    ).merge(default: default_string || '', scope: key_scope)
    # As we may have html e.g. <br/> in labels we mark as html safe
    I18n.t(attribute_key, **label_translation_options)&.html_safe # rubocop:disable Rails/OutputSafety
  end

  # Gets the translation scope depending on the passed symbol
  # @param object [Object] the object being processed
  # @param symbol [Symbol] is the part of the key scope, which is either :attributes, :hints or :captions
  # @return [Array] the scope to be used for the :scope of the translation options part of when translating texts.
  private_class_method def self.get_translation_scope(object, symbol)
    [object.i18n_scope, symbol, object.model_name.i18n_key]
  end

  # Adds a ? to the label string if needed by parsing the string to see if it looks like a question
  # you can override this behaviour by passing question as true or false
  # @param label [String] is a string that will be altered and returned.
  # @param question [Boolean] Is this a question, overrides the REGEX
  private_class_method def self.make_question(label, question: nil)
    if !question.nil?
      label += '?'.html_safe if question == true
    elsif label.match(QUESTION_REGEX)
      label += '?'.html_safe
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
