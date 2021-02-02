# frozen_string_literal: true

# base form builder is the utility helpers require for form builder
class BaseFormBuilder < ActionView::Helpers::FormBuilder # rubocop:disable Metrics/ClassLength
  include TableFieldsBuilder
  attr_writer :current_browser

  # Used as the global variable to set the browser that is currently being used.
  # Currently if your page has dates then this is one of the must have in your form.
  # @example Simply put this one line in your form, assuming that you name it as 'form'
  #   <% form.current_browser = application_browser %>
  # @see ApplicationHelper::application_browser
  def current_browser
    raise Error::AppError.new('Base Form Builder', 'Browser has not been set for this page.') if @current_browser.nil?

    @current_browser
  end

  protected

  # gets the hint text for the given attribute using the key active_model.hints.[model]
  #
  # When a hint is found, then the hint's id will be added to the aria-describedby of html_options.
  # @param attribute [Object] the symbol to be translated to a string
  # @return [HTML block element] the standard hint text; consists of span (with the translated text)
  def hint_text(attribute, options = {}, html_options = {})
    hint_html_options = { class: 'govuk-hint', id: "#{field_id(attribute, options, html_options)}-hint" }
    hint = UtilityHelper.attribute_text(@object, attribute, :hint, options)
    return '' if hint == ''

    set_aria_describedby(hint_html_options[:id], html_options)
    @template.content_tag(:span, hint, hint_html_options)
  end

  # Creates the standard GDS value for the hint's "id" property.
  # @return [String] This is the "<object>_<attribute>-hint" or the "<label-for>-hint"
  def field_id(attribute, options = {}, html_options = {})
    # Looking at the created label html block, that will be converted into a string, then the string will be scanning
    # until it gets the string which is containing 'for="<value>"' where <value> is the string that is needed.
    # @note Overriding the text of the label is done by adding a :label to the html_options,
    #   in some areas the :label key of the html_options hash is an empty string,
    #   having an empty string would mean that we're not creating the label wrapper,
    #   which will not generate the 'id's needed for the hint and error.
    #   The label: 'ignore' is needed so that we can always generate the id.
    field_label_wrapper(attribute, options.merge(label: 'ignore'), html_options).to_s.scan(/for="([^"]*)"/).last.first
  end

  # Gets the hidden label for those input where no label on screen.
  # This is mainly for accessibility.
  # Check address page for example.
  # The given attribute using the key active_model.hidden_label.[model]
  # @param attribute [Object] the symbol to be translated to a string
  # @return [HTML block element] the standard hint text; consists of span (with the translated text)
  def visually_hidden_label(attribute, options, html_options)
    hidden_label = @template.t(UtilityHelper.get_attribute_key(@object, attribute, options),
                               default: '', scope: [@object.i18n_scope, :hidden_label, @object.model_name.i18n_key])
    return if hidden_label == ''

    hidden_label = table_field_hidden_label(hidden_label, html_options) if using_table_fields?

    @template.content_tag(:span, hidden_label, class: 'govuk-visually-hidden')
  end

  # Extracts and displays errors for the given attribute for the object that is being processed
  # by the rails rendering engine
  #
  # When an error is found, then the hint's id will be added to the aria-describedby of html_options.
  # @param attribute [Object] the symbol to be translated to a string
  # @return [HTML block element] the standard error text; consists of span (with the translated text),
  #   must return a blank string if there are no errors
  def error_text(attribute, options = {}, html_options = {})
    return ''.html_safe if @object.nil? || @object.errors[attribute].empty?

    error_html_options = { id: "#{field_id(attribute, options, html_options)}-error", class: 'govuk-error-message' }
    set_aria_describedby(error_html_options[:id], html_options)

    @template.content_tag(:span, error_content(attribute), error_html_options)
  end

  # Wrapper for generic label, hint text, error text structure for collection field.
  # @param attribute [Object] the symbol to be translated to a string related to the contents of the collection field
  # @param options [Array] an array of options that is passed to the {#field_label_wrapper}
  # @return [HTML block element] returns the generic label, hint text and error text for a field
  def collection_field_wrapper(attribute, options)
    legend_tag = collection_legend_wrapper(attribute, options)
    hint_text = hint_text(attribute, options)
    error_text = error_text(attribute, options)
    fieldset_tag = @template.content_tag(:fieldset,
                                         legend_tag + hint_text + error_text + yield,
                                         class: 'govuk-fieldset')

    @template.content_tag(:div, fieldset_tag, class: field_wrapper_class(field_wrapper_error_class(attribute)))
  end

  # Wrapper for generic label, hint text, error text structure and input field.
  # @param attribute [Object] symbol to be translated to a string related to the content
  # @param options [Array] an array of options
  # @return [HTML block element] generic field wrapper which consists of label, hint text,
  #   error text and the input field tag
  def field_wrapper(attribute, options = {}, html_options = {}, input_class = 'govuk-input')
    header_texts = field_wrapper_header_texts(attribute, options, html_options)
    symbol = symbol_label_wrapper(options)
    error_class = field_wrapper_error_class_setup(attribute, html_options, input_class)
    input_field = options[:type] == 'PERCENTAGE' ? (yield + symbol) : (symbol + yield)
    output = @template.content_tag(:div, header_texts + input_field.html_safe, class: field_wrapper_class(error_class))

    # Wraps the multiple field wrapper depending on the type of multiple field it's using.
    multiple_fields_wrapper(output)
  end

  # @param attribute [Object] symbol to be translated to a string related to the content
  # @param options [Array] an array of options
  # @return [HTML block element] generic field wrapper which consists of label, hint text,
  # @return [Array] label, hint text, error text structure in 'header_texts' for generic field wrapper
  def field_wrapper_header_texts(attribute, options, html_options)
    field_label_wrapper(attribute, options, html_options) +
      hint_text(attribute, options, html_options) +
      error_text(attribute, options, html_options)
  end

  # Adds the error class to the input before it's yielded in.
  def field_wrapper_error_class_setup(attribute, html_options, input_class)
    error_class = field_wrapper_error_class(attribute)
    set_input_class_to_error(html_options, input_class) unless error_class.blank?

    error_class
  end

  # Wrapper for generic field label
  # @param attribute [Object] symbol to be translated to string related to the content
  # @param options [Hash] hash of options to manipulate the outcome of the label.
  #   In order to change the html class of this, use :label_class
  # @param html_options [Hash] hash of html options related to changing of the label,
  #   this doesn't accept the :value and :class as those are more specific to the field this is associated with.
  # @return [HTML block element] generic field label tag consisting of label contents and specific classes
  def field_label_wrapper(attribute, options = {}, html_options = {})
    label = UtilityHelper.label_text(@object, attribute, options)

    label_options = field_label_html_options(options, html_options)
    hidden_label = visually_hidden_label(attribute, options, label_options)

    label = add_label_to_table_fields_options(attribute, label, html_options) if using_table_fields?
    label += hidden_label unless hidden_label.nil?
    # If we're creating an empty label then we don't create it.
    return ''.html_safe if label.blank?

    @template.label(@object_name, attribute, label_options) do
      label.html_safe
    end
  end

  # Depending on the contents of the global options @table_options and @fieldset_options that comes from
  # the form_builder_helper, this will wrap another layer on the output if the field is being used as part of a
  # fieldset or a table of fields.
  def multiple_fields_wrapper(output)
    unless @fieldset_options.nil? || @fieldset_options[:direction] == :vertical
      return @template.content_tag(:div, output, class: 'fieldset-input__item')
    end
    return table_data_tag(output, class: 'remove_border_bottom_line') if using_table_fields?

    output
  end

  # Wrapper for the group of fields, which is creating a single label, hint and the fields without their separate label
  # @param heading [Hash] should contain the title of the fieldset, may contain other data related to the heading.
  # @param fields [HTML block element] Contains the html block of each of the fields, which is to be placed into a div
  #   container.
  def fieldset_wrapper(heading, fields)
    output = field_label_wrapper(heading[:attribute], label: heading[:label])
    output += hint_text(heading[:attribute], hint: heading[:hint])
    output += @template.content_tag(:div, fields.html_safe, class: 'fieldset-input')

    @template.content_tag(:div,
                          @template.content_tag(:fieldset, output, class: 'govuk-fieldset'),
                          class: 'govuk-form-group')
  end

  # Merges all the contents of the passed options with the fieldset_options or table_options hash of
  # html_options or options.
  # @note currently in fields like text_field, date_field etc. it only requires the options hash which also includes
  #   the html_options hash of fields. In fields like a select, the html_options is separated from the options, so
  #   this should handle both type of options.
  # @param type [Symbol] when used, this should either be :options or :html_options.
  # @param options [Hash] the field's initial options (or html_options) to be merged.
  # @return [Hash] options (or html_options) merged with the fieldset_option or table_options options
  #   (or html_options) hash.
  def form_options(type, options = {})
    return options if @fieldset_options.nil? && @table_options.nil?

    # If the fieldset_options[type] has data then the table_options should be nil, and the other way around too.
    # Setting any options from the field itself should take priority over the default ones from the
    # fieldset/table_options. However, when using table_fields, we must not override then index as that is used
    # to associate the fields with a specific object.
    options = @fieldset_options[type].merge(options) unless @fieldset_options.nil?
    options = @table_options[type].merge(options) if using_table_fields?
    options
  end

  # Creates the standard wrapper for a collection of radio buttons.
  # See {FormBuilderHelper.LabellingFormBuilder#collection_radio_buttons_fields} for information about the parameters.
  # @return [HTML block element] the standard radio buttons collection wrapper with the appropriate classes
  def collection_radio_buttons_wrapper(method, collection, options, html_options)
    radio_buttons = collection_radio_buttons(method, collection, options[:value_method], options[:text_method]) do |b|
      @template.content_tag(:div,
                            b.radio_button(class: 'govuk-radios__input') +
                            b.label(class: 'govuk-label govuk-radios__label'),
                            class: 'govuk-radios__item')
    end
    @template.content_tag(:div, radio_buttons, html_options)
  end

  # Creates the standard wrapper for a collection of checkboxes.
  # See {FormBuilderHelper.LabellingFormBuilder#collection_check_boxes_fields} for information about the parameters.
  # @return [HTML block element] the standard checkbox wrapper collection with the appropriate classes
  def collection_checkbox_wrapper(method, collection, options, html_options)
    checkbox = collection_check_boxes(method, collection, options[:value_method], options[:text_method]) do |b|
      @template.content_tag(:div,
                            b.check_box(class: 'govuk-checkboxes__input') +
                            b.label(class: 'govuk-label govuk-checkboxes__label'),
                            class: 'govuk-checkboxes__item')
    end
    @template.content_tag(:div, checkbox, html_options)
  end

  # set default class and div to legend used in {FormBuilderHelper.LabellingFormBuilder#collection_check_boxes_fields}
  # and {FormBuilderHelper.LabellingFormBuilder#collection_radio_buttons_fields}
  # @param attribute [Object] the symbol to be translated to a string
  # @return [HTML block element] the standard legend wrapper; consists of the headings of the content.
  def collection_legend_wrapper(attribute, options)
    legend = UtilityHelper.label_text(@object, attribute, options)
    legend += visually_hidden_label(attribute, options, {}) || ''
    h1_tag = @template.content_tag(:h1, legend.html_safe, class: 'govuk-fieldset__heading')
    @template.content_tag(:legend, h1_tag,
                          class: 'govuk-fieldset__legend govuk-fieldset__legend',
                          id: generate_id(attribute))
  end

  # Routine to wraps Action view tags to generate a new id
  def generate_id(attribute)
    ActionView::Base::Tags::Base.new(object_name, attribute, :this_param_is_ignored).send(:tag_id)
  end

  # Wrapper to add symbol next to input control
  # For example if for currency type input field it will display pound symbol
  # @param options [Array] an array of options containing type of symbol to be displayed
  # @return [HTML block element] span tag consisting of symbol and specific classes
  def symbol_label_wrapper(options = {})
    type = options[:type] unless options[:type] == nil?
    case type
    when 'CURRENCY'
      @template.content_tag(:span, '&#163;'.html_safe, class: 'govuk-label currency')
    when 'PERCENTAGE'
      @template.content_tag(:span, '&#37;'.html_safe, class: 'govuk-label percentage')
    else
      ''
    end
  end

  private

  # The standard class for a form's field wrapper, which is 'govuk-form-group'.
  # @return standard field wrapper class with additional class if it exists
  def field_wrapper_class(additional_class = nil)
    standard_gds_class = 'govuk-form-group'
    return standard_gds_class if additional_class.blank?

    "#{standard_gds_class} #{additional_class}"
  end

  # Builds the html options of the field label with some default options.
  def field_label_html_options(options, html_options)
    # The :value html_option is messing up the generated 'for' property, it ends up creating it with the value.
    # As this is also being used to get the 'id's of the hint and error, this will prevent adding the :value
    # to generate the id.
    # The :class is specific to the field, this may otherwise build the label with 'govuk-input' which is incorrect.
    label_html_options = html_options.dup.reject { |key| %i[value class].include?(key) }
    label_class = 'govuk-label'
    label_class += " #{options[:label_class]}" unless options[:label_class].nil?
    label_html_options[:class] = label_class
    label_html_options[:index] = options[:index] if options[:index]
    label_html_options
  end

  # Outputs the form field wrapper's standard class for a field with error.
  def field_wrapper_error_class(attribute, override_error_check: false)
    error_class = "#{field_wrapper_class}--error"
    return error_class if override_error_check

    error_class unless @object.errors[attribute].empty?
  end

  # Sets the input's class to include the standard error class.
  # This is normally only done while the input field is being wrapped with the field wrapper.
  def set_input_class_to_error(html_options = {}, input_class = 'govuk-input')
    html_options[:class] =
      html_options[:class].blank? ? "#{input_class}--error" : "#{html_options[:class]} #{input_class}--error"
  end

  # Sets the id of the aria-describedby property of an element's html options, this can also be used
  # to add another id to the aria-describedby property.
  def set_aria_describedby(id, html_options)
    describedby = html_options['aria-describedby']
    html_options['aria-describedby'] = describedby.nil? ? id : "#{describedby} #{id}"
  end

  # The date field html options if we're using a browser that's incompatble with the standard date field.
  def ie_date_field_html_options(html_options)
    html_options[:placeholder] = 'dd/mm/yyyy'
    html_options[:class] = 'datepicker '
    if date_parsable?(html_options[:value])
      html_options[:value] = DateFormatting.to_display_date_format(html_options[:value])
    end
    html_options
  end

  # Sets up the common options for a standard field
  def setup_standard_field_options(attribute, options, html_options, input_class = 'govuk-input')
    # This should only run if we're using the field with table_fields
    move_field_options_to_table(attribute, options, html_options) if using_table_fields?
    options = form_options(:options, options)

    # The width of the field with symbol cannot have a full width as there won't be enough space for the symbol and
    # it will place the symbol somewhere else. So to ensure that there's enough space for the symbol, the width will
    # be overriden.
    options[:width] = 'three-quarters' if %w[CURRENCY PERCENTAGE].include?(options[:type]) && options[:width] == 'full'

    html_options = UtilityHelper.field_html_options(options, form_options(:html_options, html_options), input_class)
    [options, html_options]
  end

  # Creates the functional options of select, which also includes our own custom functional options.
  # It currently adds the id 'combobox' used for converting the select field into an autocomplete input field.
  # See https://api.rubyonrails.org/classes/ActionView/Helpers/FormOptionsHelper.html
  def select_options(options)
    default_option = options[:include_blank] ? :include_blank : :prompt
    form_options(:options, options).merge(default_option => @template.t('select_prompt'))
  end

  # Creates the html options of select.
  def select_html_options(options, html_options)
    html_options = form_options(:html_options, html_options)
    html_options = UtilityHelper.field_html_options(options, html_options, 'govuk-select')
    html_options[:class] = "#{html_options[:class]} combobox" if options[:text_auto_complete]
    # The :index can only be filled after calling the form_options.
    # Also the :index for a normal select should be in the html_options.
    options[:index] = html_options[:index] if options[:text_auto_complete]

    html_options
  end

  # Creates the error message
  # @return [HTML block element] the text for the start of an inline message
  def error_content(attribute)
    # The hidden error tag for the start of an error message
    error_start = "<span class=\"govuk-visually-hidden\">#{I18n.t('.error')}:</span>"

    (error_start + @object.errors[attribute].join("<br>#{error_start}")).html_safe
  end
end
