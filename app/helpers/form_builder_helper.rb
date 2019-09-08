# frozen_string_literal: true

# Helper for creating form specific controls with correct css class and template.
module FormBuilderHelper
  # This class is serving as a proxy for the methods in the FormHelper module.
  # This class, however, allows you to call methods with the model object you are building the form for.
  # Method of this class creates fields with the correct field set structure
  # it also provides additional customisation option to add a label with keyword "Optional"
  # or change the width of controls using  keyword  "width"
  # @example Command to create textbox of width 5 px and label with "optional" text is
  #   form.text_field :full_name, option = (width: 'width-10', optional: true)
  # TODO: CR RSTP-308 as mentioned in the two methods, this could be removed.
  class LabellingFormBuilder < BaseFormBuilder
    include DateFormatting
    # Creates a standard text field with associated hint and error text fields.
    # This creates a standard text field for the user to input data related to
    # the attribute that is passed on to the parameter. Within this element block,
    # the hint and error texts gets added.
    # @param attribute [Object] the symbol to be translated to a string relating to the content
    # @param options [Array] an array of options to be passed to the {::BaseFormBuilder#add_css_classes}
    # @return [HTML block element] the standard text field with hint and error texts.
    def text_field(attribute, options = {})
      field_wrapper(attribute, options) do
        super(attribute, UtilityHelper.add_css_classes(options))
      end
    end

    # Creates the standard date field with associated hint and error date fields.
    # @note It needs to call this in the form:
    #   <% form.current_browser = application_browser %>
    # @example
    #   <%= form.date_field :actual_date %>
    # @param attribute [Object] is the attribute of the object
    # @param options [Hash] is a hash of symbols used for adding extra options.
    # @return [HTML block element] a date_field with the correct classes
    def date_field(attribute, options = {})
      # Sets the value to it's current value, if it's not modified in the view level.
      # For some reason in the date_field it doesn't auto-populate it with the attribute's value so this we do this.
      options[:value] = @object.send(attribute) if options[:value].blank?
      # As the IE version of a date field is non-existent and Edge does something that we don't like, those two
      # browsers uses a text field instead, with the appropriates attributes so that it acts as a date field similar
      # to both Chrome and Firefox.
      if ['INTERNET EXPLORER', 'EDGE', 'SAFARI'].include?(current_browser.upcase)
        options[:placeholder] = 'dd/mm/yyyy'
        options[:class] = 'datepicker '
        options[:value] = DateFormatting.to_display_date_format(options[:value]) if date_parsable?(options[:value])

        return text_field(attribute, UtilityHelper.add_css_classes(options))
      end
      field_wrapper(attribute, options) do
        super(attribute, UtilityHelper.add_css_classes(options))
      end
    end

    # Creates a standard text area with associated.
    #
    # It uses the standard way of creating fields by using the field_wrapper and passing the class
    # needed to give the method the correct the class.
    #
    # @param attribute [Object] symbol to be translated to a string, which is also used as the label of it
    # @param options [Array] an array of HTML/CSS options to be added to its element
    # @return [HTML block element] a text area wrapped with the standard class
    def text_area_field(attribute, options = {})
      options[:width] = 'three-quarters' if options[:width].nil?
      field_wrapper(attribute, options, nil, 'govuk-textarea') do
        text_area(attribute, UtilityHelper.add_css_classes(options, 'govuk-textarea'))
      end
    end

    # Create a password field with the correct label hint and error structure
    # This creates a standard password field for the user to input data related
    # to the attribute passed on to the parameter. Within this element block, the
    # hint and error texts gets added.
    # @param attribute [Object] the symbol to be translated to a string relating to the content
    # @param options [Array] an array of options to be passed to the
    #   {::BaseFormBuilder#add_css_classes}
    # @return [HTML block element] the standard password field with hint and error texts.
    def password_field(attribute, options = {})
      field_wrapper(attribute, options) do
        super(attribute, UtilityHelper.add_css_classes(options))
      end
    end

    # Create a select field with the correct class; the select field is a list of
    # items for the user to select a single item from.
    # collection send to the method has to be inherited from ReferenceValue class
    # @param attribute [Object] symbol to be passed to {::BaseFormBuilder#field_wrapper}
    # @param method [Object] a collection of data [value, code] where the code is to be displayed
    # @param options [Array] an array of options to choose from including the default option, items from the method,
    #                        and allowing overriding of the code and value methods to call on each item in method
    #                        @example - shows the result of to_s in the drop down rather than the default value method.
    #                           <%= f.select :my_code, @my_codes, { :code => :code, :value => :to_s }, {} %>
    #                        @example - leaves the 'Choose from list' as an option even when other option selected
    #                           <%= f.select :my_code, @my_codes, { include_blank: true }, {} %>
    # @param html_options [Array] to be added as classes, which is passed to {::BaseFormBuilder#add_css_classes}
    # @return [HTML block element] the standard select field with the correct class
    def select(attribute, method, options = {}, html_options = {}) # rubocop:disable Metrics/AbcSize
      default_option = options[:include_blank] ? :include_blank : :prompt
      html_options = UtilityHelper.add_css_classes(html_options, 'govuk-select')
      options = options.merge(default_option => @template.t('select_prompt'))
      value_method = options.key?(:value) ? options[:value] : :value
      code_method = options.key?(:code) ? options[:code] : :code
      options[:index] = html_options[:index] if html_options.key?(:index)
      method = method.collect { |p| [p.send(value_method), p.send(code_method)] } if defined? method.collect
      field_wrapper(attribute, options, html_options, ' govuk-select') { super }
    end

    # Create a button field with the correct class
    # Default button will be  disabled when the button is click.it can be override with
    # 'not_disable' option
    # Example to override this:
    # <%= f.button 'signin', {not_disable:''}%>
    # @param id [Object] id of button, and used to get the value from the translations
    # @param options [Array] an array of options to be passed on to the {::BaseFormBuilder#add_css_classes}
    # @return [HTML block element] the standard button field with the correct class
    def button(id, options = {})
      options[:class] = 'scot-rev-button' if options[:class].nil?
      options = UtilityHelper.add_css_classes(options, options[:class], false)
      options[:data] = { disable_with: @template.t('working') } if options[:not_disable].nil?
      options[:id] = id || 'submit'
      if !id.nil?
        super @template.t(id, options), options
      else
        super
      end
    end

    # Create a submit field with the correct class
    # Default button will be disabled when the form is submitted. It can be override with
    # 'not_disable' option
    # Example to override this:
    # <%= f.submit 'submit', {not_disable:''}%>
    # @param id [Object] id of button, and used to get the value from the translations
    # @param options [Array] an array of options to be passed on to the {::BaseFormBuilder#add_css_classes}
    # @return [HTML block element] the standard submit field with the correct class
    def submit(id = nil, options = {})
      span =  @template.content_tag(:span, '', class: 'scot-rev-submit-image')
      options = UtilityHelper.add_css_classes(options, '', false)
      options[:data] = { disable_with: @template.t('working') } if options[:not_disable].nil?
      options[:id] = id || 'submit'
      submit = if !id.nil?
                 super @template.translate(id, options), options
               else
                 super
               end
      @template.content_tag(:div, submit + span, class: 'scot-rev-submit')
    end

    # Create a checkbox field with the correct class
    # @param attribute [Object] used as the label and passed as value of the check_box
    # @param options [Hash] a hash of options used to further modify the check box field
    # @return [HTML block element] the standard checkbox field with the correct classes and label
    def check_box_field(attribute, options = {})
      check_box_field = check_box(attribute, { class: 'govuk-checkboxes__input' }, true, false)
      options[:class] = { label: 'govuk-checkboxes__label' }
      label_field = field_label_wrapper(attribute, options)
      @template.content_tag(:div,
                            error_text(attribute) + @template.content_tag(:div,
                                                                          check_box_field + label_field,
                                                                          class: 'govuk-checkboxes__item'))
    end

    # Creates a collection of check boxes for each item in the collection with correct class and template,
    # associated with a clickable label.
    # Use value_method and text_method to convert items in the collection for use as text/value in check boxes.
    # @param method [Object] the symbol that is passed on to {::BaseFormBuilder#collection_checkbox_wrapper}
    #   and also {::BaseFormBuilder#collection_field_wrapper}
    # @param collection [Object] a collection of data that is passed on to
    #   {::BaseFormBuilder#collection_checkbox_wrapper}
    # @param value_method [Object] the value of the check box passed as parameter values to
    #   {::BaseFormBuilder#collection_checkbox_wrapper}
    # @param text_method [Object] the text of the check box passed as parameter values to
    #   {::BaseFormBuilder#collection_checkbox_wrapper}
    # @return [HTML block element] the standard field for collection of check boxes
    def collection_check_boxes_fields(method, collection, value_method, text_method, options = {})
      check_box_div_inline_tag = collection_checkbox_wrapper(method, collection, value_method, text_method)
      collection_field_wrapper(method, options) { check_box_div_inline_tag }
    end

    # Create a collection of radio inputs with correct class and template
    # for the attribute.
    # Basically this helper will create a radio input associated with a label
    # for each text/value option in the collection,
    # using value_method and text_method to convert these text/value.
    # that will be evaluated for each item in the collection.
    # @example collection_radio_buttons_fields(:user_is_current, CurrentInactive.all, :code, :value)
    # @param method [Object] the symbol that is passed on to {::BaseFormBuilder#collection_radio_buttons_wrapper}
    #   and also {::BaseFormBuilder#collection_field_wrapper}
    # @param collection [Object] a collection of data that is passed on to
    #   {::BaseFormBuilder#collection_radio_buttons_wrapper}
    # @param value_method [Object] the value of the check box passed as parameter values to
    #   {::BaseFormBuilder#collection_radio_buttons_wrapper}
    # @param text_method [Object] the text of the check box passed as parameter values to
    #   {::BaseFormBuilder#collection_radio_buttons_wrapper}
    # @param options [Array] an array of options to customize the radio buttons alignment default set to inline
    #                         to set it vertical need to set alignment = 'vertical' in options.
    # @return [HTML block element] the standard field for collection of radio buttons
    def collection_radio_buttons_fields(method,
                                        collection,
                                        value_method,
                                        text_method,
                                        options = {})
      css_class = if options[:alignment] != nil? && options[:alignment] == 'vertical'
                    'govuk-radios'
                  else
                    'govuk-radios govuk-radios--inline '
                  end
      options = { class: css_class }.merge(options)
      radio_div_inline_tag = collection_radio_buttons_wrapper(method, collection, value_method, text_method, options)
      collection_field_wrapper(method, options) { radio_div_inline_tag }
    end

    # This creates a currency field with pound sign before textbox with
    # the correct label hint and error structure
    # to the attribute passed on to the parameter. Within this element block, the
    # hint and error texts gets added.
    # @param attribute [Object] the symbol to be translated to a string relating to the content
    # @param options [Array] an array of options to be passed to the
    #   {::BaseFormBuilder#add_css_classes}
    # @return [HTML block element] the standard password field with hint and error texts.
    def currency_field(attribute, options = {})
      options = { type: 'CURRENCY' }.merge(options)
      text_field(attribute, options)
    end
  end
end
