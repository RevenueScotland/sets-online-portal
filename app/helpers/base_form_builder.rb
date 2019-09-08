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
  # @param attribute [Object] the symbol to be translated to a string
  # @param css_class_name [Class] the class of the content
  # @return [HTML block element] the standard hint text; consists of span (with the translated text)
  def hint_text(attribute, css_class_name)
    hint = @template.t(get_attribute_key(attribute),
                       default: '', scope: [@object.i18n_scope, :hints, @object.model_name.i18n_key])
    @template.content_tag(:span, hint, class: css_class_name) unless hint == ''
  end

  # Gets the hidden label for those input where no label on screen.
  # This is mainly for accessibility.
  # Check address page for example.
  # The given attribute using the key active_model.hidden_label.[model]
  # @param attribute [Object] the symbol to be translated to a string
  # @return [HTML block element] the standard hint text; consists of span (with the translated text)
  def visually_hidden_label(attribute, options)
    hidden_label = @template.t(get_attribute_key(attribute, options),
                               default: '', scope: [@object.i18n_scope, :hidden_label, @object.model_name.i18n_key])
    @template.content_tag(:span, hidden_label, class: 'govuk-visually-hidden') unless hidden_label == ''
  end

  # Extracts and displays errors for the given attribute for the object that is being processed
  # by the rails rendering engine
  # @param attribute [Object] the symbol to be translated to a string
  # @return [HTML block element] the standard error text; consists of span (with the translated text)
  def error_text(attribute)
    error_html = ''
    unless @object.nil?
      error_text = @object.errors[attribute].join('<br>' + @template.t('this') + ' ')
      error_text = @template.t('this') + ' ' + error_text if error_text != ''
      error_html = @template.content_tag(:span, error_text.html_safe, class: 'govuk-error-message')
    end
    error_html
  end

  # Wrapper for generic label, hint text, error text structure for collection field.
  # @param attribute [Object] the symbol to be translated to a string related to the contents of the collection field
  # @param options [Array] an array of options that is passed to the {#field_label_wrapper}
  # @return [HTML block element] returns the generic label, hint text and error text for a field
  def collection_field_wrapper(attribute, options)
    legend_tag = collection_legend_wrapper(attribute, options)
    hint_text = hint_text(attribute, 'govuk-hint')
    error_text = error_text(attribute)
    fieldset_tag = @template.content_tag(:fieldset,
                                         legend_tag + hint_text + error_text + yield,
                                         class: 'govuk-fieldset')
    css_class = 'govuk-form-group' + add_css_class(attribute, options)
    @template.content_tag(:div, fieldset_tag, class: css_class)
  end

  # Wrapper for generic label, hint text, error text structure and input field.
  # @param attribute [Object] symbol to be translated to a string related to the content
  # @param options [Array] an array of options
  # @return [HTML block element] generic field wrapper which consists of label, hint text,
  #   error text and the input field tag
  def field_wrapper(attribute, options = {}, html_options = nil, gds_input_class_name = 'govuk-input')
    label_tag = field_label_wrapper(attribute, options)
    error_text = error_text(attribute)
    symbol = symbol_label_wrapper(options)
    css_class = UtilityHelper.form_group_class(options) + add_css_class(attribute, options, html_options,
                                                                        gds_input_class_name)
    @template.content_tag(:div, label_tag + hint_text(attribute, 'govuk-hint') + error_text + symbol + yield,
                          class: css_class)
  end

  # Wrapper for generic field label
  # @param attribute [Object] symbol to be translated to string related to the content
  # @param options [Array] an array of options use to add optional keyword
  # @return [HTML block element] generic field label tag consisting of label contents and specific classes
  def field_label_wrapper(attribute, options = {})
    label = label_text(attribute, options)
    # swaps the texts mainly used for changing a text to a hyper link
    UtilityHelper.swap_texts(label, options)
    label = append_optional_keyword(label, options)
    hidden_label = visually_hidden_label(attribute, options)
    label += hidden_label unless hidden_label.nil?
    label_options = { class: UtilityHelper.field_label_class(options) }
    label_options[:index] = options[:index] if options[:index]
    @template.label(@object_name, attribute, label_options) do
      label.html_safe
    end
  end

  # get the label text for a field
  # @param attribute [Object] symbol to be translated to string related to the content
  # @param options [Array] an array of options that is use to determine if :label is present and to use that
  # @return [String] returns the label
  def label_text(attribute, options = {})
    return options[:label] unless options[:label].nil?

    @template.t(get_attribute_key(attribute, options),
                default: '',
                scope: [@object.i18n_scope, :attributes, @object.model_name.i18n_key])
  end

  # add optional keyword if optional: true is send from view
  # @param label [String] the label of the optional item
  # @param options [Array] an array of options to look for the symbol :optional to determine whether its optional or not
  # @return [String] returns the label with the standard optional keyword if the content is an optional field
  def append_optional_keyword(label, options = {})
    optional = options[:optional] unless options[:optional] == nil?
    label = label + ' (' + @template.t('optional') + ')' if optional == true
    label
  end

  # set default class and div to radio buttons used in
  # {FormBuilderHelper.LabellingFormBuilder#collection_radio_buttons_fields}
  # @param method [Object] symbol to be translated to string for the label, hint and error texts
  # @param collection [Array] a collection of data that is directly linked to
  #   the parameter values of value_method and text_method
  # @param value_method [Object] the value of the passed method, shown as a radio button
  # @param text_method [Object] the text of the passed method, to be displayed
  # @param options [Array] an array of options to override the radio button outer div css
  # @return [HTML block element] the standard radio buttons collection wrapper with the appropriate classes
  def collection_radio_buttons_wrapper(method, collection, value_method, text_method,
                                       options)
    radio_buttons = collection_radio_buttons(method, collection, value_method, text_method) do |b|
      @template.content_tag(:div,
                            b.radio_button(class: 'govuk-radios__input') +
                            b.label(class: 'govuk-label govuk-radios__label'),
                            class: 'govuk-radios__item')
    end
    radio_div_inline_tag = @template.content_tag(:div, radio_buttons, options)
    radio_div_inline_tag
  end

  # set default class and div to checkbox used in {FormBuilderHelper.LabellingFormBuilder#collection_check_boxes_fields}
  # @param method [Object] symbol to be translated to string for the label, hint and error texts
  # @param collection [Array] a collection of data that is directly linked to
  #   the parameter values of value_method and text_method
  # @param value_method [Object] the value of the passed method, shown as a check box
  # @param text_method [Object] the text of the passed method, to be displayed
  # @return [HTML block element] the standard checkbox wrapper collection with the appropriate classes
  def collection_checkbox_wrapper(method, collection, value_method, text_method)
    checkbox = collection_check_boxes(method, collection, value_method, text_method) do |b|
      @template.content_tag(:div,
                            b.check_box(class: 'govuk-checkboxes__input') +
                            b.label(class: 'govuk-label govuk-checkboxes__label'),
                            class: 'govuk-checkboxes__item')
    end
    radio_div_inline_tag = @template.content_tag(:div, checkbox,
                                                 class: 'govuk-checkboxes')
    radio_div_inline_tag
  end

  # set default class and div to legend used in {FormBuilderHelper.LabellingFormBuilder#collection_check_boxes_fields}
  # and {FormBuilderHelper.LabellingFormBuilder#collection_radio_buttons_fields}
  # @param attribute [Object] the symbol to be translated to a string
  # @return [HTML block element] the standard legend wrapper; consists of the headings of the content.
  def collection_legend_wrapper(attribute, options)
    attribute_key = get_attribute_key(attribute, options)
    legend = @template.t(attribute_key,
                         default: '', scope: [@object.i18n_scope, :attributes, @object.model_name.i18n_key])
    legend = append_optional_keyword(legend, options)
    # swaps the texts mainly used for changing a text to a hyper link
    UtilityHelper.swap_texts(legend, options)
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

  # Get attribute key require to translate label,legend or hint text of a form control.
  # User can override default attribute key by providing a translation_attribute on the underlying model
  # @param attribute [Object] the symbol to be translated to a string
  # @param options [Hash] if :translation_options is defined in the options, then it's passed to translation_attribute
  # @return [Symbol] translation key use for translation
  # @note only use :translation_options if there's no other way of avoiding it.
  def get_attribute_key(attribute, options = {})
    return attribute unless @object.respond_to?(:translation_attribute)

    @object.translation_attribute(attribute, options[:translation_options])
  end

  private

  # this method add gds class to html control
  # @param attribute [Object] the symbol to be translated to a string
  # @param options [Array] an array of options
  # @param html_options [Array] an array of html options mainly for select tag
  # @param gds_input_class_name gds input css class
  def add_css_class(attribute, options, html_options = nil, gds_input_class_name = 'govuk-input')
    input_css_class, div_css_class = gds_html_error_class(attribute, gds_input_class_name)
    # for select html control css class is part html option
    if html_options.nil?
      option_css_class(options, input_css_class)
    else
      html_option_css_class(html_options, input_css_class)
    end
    div_css_class
  end

  # This method return gds input error related html css class  classes if there if input validation failed
  # and outer div.
  # @param attribute [Object] symbol to be translated to string related to the content
  # @param input_class_name html input control css class
  # @return [Input control error css class, Div error css class] error specific classes
  def gds_html_error_class(attribute, input_class_name)
    return ['', ''] if @object.errors[attribute].empty?

    [input_class_name + '--error ', ' govuk-form-group--error']
  end

  # This method assign css class to html_option of input control
  # @param html_options [Array] an array of html options mainly for select tag
  # @param input_css_class html input control css class
  def html_option_css_class(html_options, input_css_class)
    html_options[:class] = if html_options[:class].blank?
                             input_css_class
                           else
                             html_options[:class] + input_css_class
                           end
    UtilityHelper.add_css_classes(html_options)
  end

  # This method assign css class to options of input control
  # @param options [Array] an array of options
  # @param input_css_class html input control css class
  def option_css_class(options, input_css_class)
    options[:class] = if options[:class].blank?
                        input_css_class
                      else
                        options[:class] + input_css_class
                      end
    UtilityHelper.add_css_classes(options)
  end
end
