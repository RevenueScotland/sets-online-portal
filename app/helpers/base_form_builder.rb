# frozen_string_literal: true

# base form builder is the utility helpers require for form builder
class BaseFormBuilder < ActionView::Helpers::FormBuilder # rubocop:disable Metrics/ClassLength
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
    hint = @template.t(UtilityHelper.get_attribute_key(@object, attribute),
                       default: '', scope: [@object.i18n_scope, :hints, @object.model_name.i18n_key])
    hint = options[:hint] unless options[:hint].nil?
    hint = UtilityHelper.swap_texts(hint, options)
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

    # The index option is used for table_fields.
    index = html_options[:index]
    hidden_label = table_fields_cell_hidden_label(hidden_label, index) unless index.nil?
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
    label_tag = field_wrapper_label(attribute, options, html_options)
    symbol = symbol_label_wrapper(options)

    error_class = field_wrapper_error_class(attribute)
    # Adds the error class to the input before it's yielded in.
    set_input_class_to_error(html_options, input_class) unless error_class.blank?
    # set_aria_describedby(attribute, options, html_options)
    output = @template.content_tag(:div, label_tag + hint_text(attribute, options, html_options) +
                                           error_text(attribute, options, html_options) + symbol + yield,
                                   class: field_wrapper_class(error_class))

    # Wraps the multiple field wrapper depending on the type of multiple field it's using.
    multiple_fields_wrapper(output)
  end

  # The label created specifically for the field_wrapper using the standard label.
  # @note this has to be separated from the field_wrapper method to fit rubocop standards, and
  #   instead of overriding the field_label_wrapper only the data needed are passed into the parameter
  #   as the html_options may contain key(s)/data that shouldn't be passed into the label.
  def field_wrapper_label(attribute, options, html_options)
    # We only need to pass in the index if it exists, as this is used for the table_fields.
    # @note adding a :value or blank :index in the html_options of the label will mess up the 'for' property
    label_html_options = html_options[:index].nil? ? {} : { index: html_options[:index] }
    field_label_wrapper(attribute, options, label_html_options)
  end

  # Wrapper for generic field label
  # @param attribute [Object] symbol to be translated to string related to the content
  # @param options [Array] an array of options use to add optional keyword
  # @return [HTML block element] generic field label tag consisting of label contents and specific classes
  def field_label_wrapper(attribute, options = {}, html_options = {})
    # The :value html_option is messing up the generated 'for' property, it ends up creating it with the value.
    # As this is also being used to get the 'id's of the hint and error, this will prevent adding the :value
    # to generate the id.
    html_options = html_options.dup.reject { |key| key == :value }
    label = UtilityHelper.label_text(@object, attribute, options)

    label_options = field_label_html_options(options, html_options)
    hidden_label = visually_hidden_label(attribute, options, label_options)
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
    return table_data_tag(output, class: 'remove_border_bottom_line') unless @table_options.nil?

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

  # Used for initially setting up the table_options of the table_fields form.
  # @note only used in table_fields method of form_builder_helper.
  # Here is a list of possible options that can be added to the options when the table_fields method is called:
  # 1. :exclude_delete_button [Boolean] partly used for determining if the delete row button should be added.
  # 2. :exclude_add_button [Boolean] used for determining if the add row button should be added.
  def table_fields_options_setup(form, index, options)
    # The key :attributes [Array] will be used to store a list of attributes used when the fields are created
    # so that it can be used to display the table headings for each columns.
    form.table_options = { attributes: [], options: { width: 'two-thirds', label: '' },
                           html_options: { index: index } }.merge(options)
  end

  # Wraps the fields in a table_row <tr> element, which may also include the delete row button.
  # @note only used in table_fields method of form_builder_helper.
  # @param fields [HTML block element] By the time this method is called, the row of fields have already been created,
  #   and this is what it consists.
  def table_fields_row_wrapper(objects, fields, form, index, options)
    delete_button = ''
    # Normally where we have more than one row of object, we want to default the 'delete row' button to be shown.
    if objects.size > 1 && !options[:exclude_delete_button]
      delete_text = @template.t('delete_row')
      button_html_options = { name: 'delete_row', class: 'scot-rev-button_link govuk-link', id: "delete_row_#{index}",
                              value: index, 'aria-label' => table_fields_cell_hidden_label(delete_text, index) }
      delete_button = table_data_tag(@template.button_tag(delete_text, button_html_options),
                                     class: 'remove_border_bottom_line')
      # Adds the table_heading for the 'delete row' button
      form.table_options[:attributes] << :action
    end
    table_row_tag(fields + delete_button)
  end

  # Generates the text to be used for the visually-hidden labels of a field of table_fields
  # @return [String] the text with the row index
  def table_fields_cell_hidden_label(text, index)
    return text if index.nil? || !index.is_a?(Integer)

    @template.t('row', title: text, row: (index + 1))
  end

  # Creates the add row button of the table_fields if certain conditions are met. See code below for conditions.
  # @note only used in {#table_fields_wrapper}.
  def table_fields_add_row_button(options)
    # Normally we want to have an 'add row' button, so we will look for the :exclude_add_button.
    return ''.html_safe if options[:exclude_add_button]

    add_row = button('add_row', class: 'scot-rev-button_link govuk-link', name: 'add_row')
    @template.content_tag(:div, add_row, class: 'govuk-form-group')
  end

  # Creates the table_fields's row of table headings.
  # @note only used in {#table_fields_wrapper}.
  # @param attributes [Array] see table_fields's local variable attributes
  def table_fields_head_wrapper(attributes)
    head = ''
    return head if attributes.blank?

    attributes.each do |attribute|
      translatable_text = attribute == :action ? attribute.to_s : '.' + attribute.to_s
      head += table_heading_tag(@template.t(translatable_text))
    end

    table_head_tag(table_row_tag(head))
  end

  # Creates the standard table of fields output which may also have an add row button.
  # For the description of the param attributes and body see the local variable attributes and body of
  # {FormBuilderHelper.LabellingFormBuilder#table_fields}.
  # @param attributes [Array] see comment above.
  # @param body [HTML block element] see comment above.
  # @param options [Hash] see table_fields_options_setup for some of the contents
  def table_fields_wrapper(attributes, body, options)
    table_tag(table_fields_head_wrapper(attributes) + table_body_tag(body)) + table_fields_add_row_button(options)
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
    options.merge!(@fieldset_options[type]) unless @fieldset_options.nil?
    options.merge!(@table_options[type]) unless @table_options.nil?
    options
  end

  # Appends the attribute used to the @table_options attributes list when a field is created using the table_fields
  # method in the form_builder_helper.
  # @note this is needed on each fields that we want to include in the table_fields method of form_builder_helper.
  def append_table_fields_attribute(attribute)
    @table_options[:attributes] << attribute unless @table_options.nil? || @table_options[:attributes].nil?
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
    h1_tag = @template.content_tag(:h1, legend.html_safe, class: 'govuk-fieldset__heading')
    legend_tag = @template.content_tag(:legend, h1_tag,
                                       class: 'govuk-fieldset__legend govuk-fieldset__legend',
                                       id: generate_id(attribute))
    legend_tag
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
    label_class = 'govuk-label'
    label_class += " #{html_options[:class]}" unless html_options[:class].nil?
    html_options[:class] = label_class
    html_options[:index] = options[:index] if options[:index]
    html_options
  end

  # Outputs the form field wrapper's standard class for a field with error.
  def field_wrapper_error_class(attribute, override_error_check = false)
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

  # Creates the functional options of select, which also includes our own custom functional options.
  # It currently adds the id 'combobox' used for converting the select field into an autocomplete input field.
  # See https://api.rubyonrails.org/classes/ActionView/Helpers/FormOptionsHelper.html
  def select_options(options)
    default_option = options[:include_blank] ? :include_blank : :prompt
    options = form_options(:options, options).merge(default_option => @template.t('select_prompt'))
    options
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
    error_start = '<span class="govuk-visually-hidden">' + I18n.t('.error') + ':</span>'

    (error_start + @object.errors[attribute].join('<br/>' + error_start)).html_safe
  end
end
