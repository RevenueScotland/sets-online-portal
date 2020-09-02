# frozen_string_literal: true

# Helper for creating form specific controls with correct css class and template.
# @see https://api.rubyonrails.org/v5.2.3/classes/ActionView/Helpers/FormBuilder.html for more details.
module FormBuilderHelper
  # This class is serving as a proxy for the methods in the FormHelper module.
  # This class, however, allows you to call methods with the model object you are building the form for.
  # Method of this class creates fields with the correct field set structure
  # it also provides additional customisation option to add a label with keyword "Optional"
  # or change the width of controls using  keyword  "width"
  # @example Command to create textbox of width 5 px and label with "optional" text is
  #   form.text_field :full_name, option = (width: 'width-10', optional: true)
  class LabellingFormBuilder < BaseFormBuilder # rubocop:disable Metrics/ClassLength
    include DateFormatting
    include TableBuilderHelper

    # This attribute is used for storing options for when we're creating a table_fields
    attr_accessor :table_options

    # Creates a standard text field with associated hint and error text fields.
    # This creates a standard text field for the user to input data related to
    # the attribute that is passed on to the parameter. Within this element block,
    # the hint and error texts gets added.
    # @param attribute [Object] the symbol to be translated to a string relating to the content
    # @param options [Array] an array of options to be passed to the {::UtilityHelper#field_html_options}
    # @return [HTML block element] the standard text field with hint and error texts.
    def text_field(attribute, options = {}, html_options = {})
      # @see base_form_builder's methods: form_options and append_table_fields_attribute
      append_table_fields_attribute(attribute)
      options = form_options(:options, options)
      html_options = UtilityHelper.field_html_options(options, form_options(:html_options, html_options))
      field_wrapper(attribute, options, html_options) do
        super(attribute, html_options)
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
    def date_field(attribute, options = {}, html_options = {})
      # Sets the value to it's current value, if it's not modified in the view level.
      # For some reason in the date_field it doesn't auto-populate it with the attribute's value so we need to do this.
      html_options[:value] = @object.send(attribute) if html_options[:value].blank?
      append_table_fields_attribute(attribute)
      options = form_options(:options, options)
      html_options = UtilityHelper.field_html_options(options, form_options(:html_options, html_options))

      # As the IE version of a date field is non-existent and Edge does something that we don't like, those two
      # browsers uses a text field instead, with the appropriates attributes so that it acts as a date field similar
      # to both Chrome and Firefox.
      is_incompatible_browser = ['INTERNET EXPLORER', 'EDGE', 'SAFARI'].include?(current_browser.upcase)
      return text_field(attribute, options, ie_date_field_html_options(html_options)) if is_incompatible_browser

      field_wrapper(attribute, options, html_options) do
        super(attribute, html_options)
      end
    end

    # Creates a standard text area with associated.
    #
    # It uses the standard way of creating fields by using the field_wrapper and passing the class
    # needed to give the method the correct the class.
    #
    # @param attribute [Object] symbol to be translated to a string, which is also used as the label of it
    # @param options [Hash] options containing information which is used to modify parts of the field, this can also
    #   include the default options of the text_area.
    # @param html_options [Hash] options (element attributes/properties) to be passed into the creation of the element.
    # @return [HTML block element] a text area wrapped with the standard class
    def text_area_field(attribute, options = {}, html_options = {})
      append_table_fields_attribute(attribute)
      options = form_options(:options, options)
      options[:width] = 'three-quarters' if options[:width].nil?
      input_class = 'govuk-textarea'
      html_options =
        UtilityHelper.field_html_options(options, form_options(:html_options, html_options), input_class)
      field_wrapper(attribute, options, html_options, input_class) do
        text_area(attribute, html_options)
      end
    end

    # Create a password field with the correct label hint and error structure
    # This creates a standard password field for the user to input data related
    # to the attribute passed on to the parameter. Within this element block, the
    # hint and error texts gets added.
    # @param attribute [Object] the symbol to be translated to a string relating to the content
    # @param options [Hash] options containing information which is used to modify parts of the field, this can also
    #   include the default options of the password_field.
    # @param html_options [Hash] options (element attributes/properties) to be passed into the creation of the element.
    # @return [HTML block element] the standard password field with hint and error texts.
    def password_field(attribute, options = {}, html_options = {})
      html_options = UtilityHelper.field_html_options(options, html_options)
      field_wrapper(attribute, options, html_options) do
        super(attribute, html_options)
      end
    end

    # Creates a hidden field which has the ability to display a value when the options :display_attribute is
    # passed.
    # @param attribute [Symbol] the attribute of an object that is using this field.
    # @param options [Hash] options containing information which is used to modify parts of the field, this can also
    #   include the default options of the hidden_field.
    # @param html_options [Hash] options (element attributes/properties) to be passed into the creation of the element.
    # @return [HTML block element] the standard hidden field (with a display if defined).
    def hidden_field(attribute, options = {}, html_options = {})
      append_table_fields_attribute(attribute) if options.key?(:display_attribute)
      options = form_options(:options, options)
      html_options = form_options(:html_options, html_options)
      # If we want the hidden field to display a value while we're storing data into it, we can do so by
      # adding the :display_attribute into the options hash of the param in view.
      display_value = @object.send(options[:display_attribute]) if options.key?(:display_attribute)
      # @note display and display_value has been split off so that the developer can change (or add) which element
      #   will they be using to display the value they need.
      display = display_value.nil? ? ''.html_safe : table_data_tag(display_value, class: 'remove_border_bottom_line')
      super(attribute, html_options) + display
    end

    # Create a select field with the correct class; the select field is a list of
    # items for the user to select a single item from.
    # collection send to the method has to be inherited from ReferenceValue class
    # @param attribute [Object] symbol to be passed to {::BaseFormBuilder#field_wrapper}
    # @param method [Object] a collection of data [value, code] where the code is to be displayed
    # @param options [Hash] options containing information which is used to modify parts of the field, this can also
    #   include the default options of the select.
    #   This can also allow the overriding of the code and value methods to call on each item in method
    #   @example - shows the result of to_s in the drop down rather than the default value method.
    #      <%= f.select :my_code, @my_codes, { :code => :code, :value => :to_s }, {} %>
    #   @example - leaves the 'Choose from list' as an option even when other option selected
    #      <%= f.select :my_code, @my_codes, { include_blank: true }, {} %>
    # @param html_options [Hash] options (element attributes/properties) to be passed into the creation of the element.
    # @return [HTML block element] the standard select field with the correct class
    def select(attribute, method, options = {}, html_options = {})
      append_table_fields_attribute(attribute)
      options = select_options(options)
      html_options = select_html_options(options, html_options)

      value_method = options.key?(:value) ? options[:value] : :value
      code_method = options.key?(:code) ? options[:code] : :code
      method = method.collect { |p| [p.send(value_method), p.send(code_method)] } if defined? method.collect

      field_wrapper(attribute, options, html_options, 'govuk-select') { super }
    end

    # Create a button field with the correct class
    # Default button will be  disabled when the button is click.it can be override with
    # 'not_disable' option
    # Example to override this:
    # <%= f.button 'signin', {not_disable:''}%>
    # @param id [Object] id of button, and used to get the value from the translations
    # @param html_options [Hash] options (element attributes/properties) to be passed into the creation of the element.
    # @return [HTML block element] the standard button field with the correct class
    def button(id = 'continue', html_options = {})
      html_options[:class] ||= 'scot-rev-button'
      # if not id provided assume this is a continue button and set if and name accordingly
      id ||= 'continue'
      html_options[:name] ||= 'continue' if id == 'continue'
      html_options = UtilityHelper.submit_html_options(id, options, html_options)
      if !id.nil?
        super @template.t(id, html_options), html_options
      else
        super
      end
    end

    # Create a submit field with the correct class
    # Default button will be disabled when the form is submitted. It can be overridden with
    # 'not_disable' option
    # Example to override this:
    # <%= f.submit 'submit', {not_disable:''}%>
    # @param id [Object] id of button, and used to get the value from the translations
    # @param html_options [Hash] options (element attributes/properties) to be passed into the creation of the element.
    # @return [HTML block element] the standard submit field with the correct class
    def submit(id = nil, html_options = {})
      span = @template.content_tag(:span, '', class: 'scot-rev-submit-image')
      html_options = UtilityHelper.submit_html_options(id, options, html_options)
      submit = if !id.nil?
                 super @template.translate(id, html_options), html_options
               else
                 super
               end
      @template.content_tag(:div, submit + span, class: 'scot-rev-submit')
    end

    # Create a check box field with the correct class
    # @param attribute [Object] used as the label and passed as value of the check_box
    # @param options [Hash] a hash of options used to further modify the check box field
    # @return [HTML block element] the standard checkbox field with the correct classes and label
    def check_box_field(attribute, options = {}, html_options = {})
      check_box_html_options = { class: 'govuk-checkboxes__input' }
      error = error_text(attribute, options, check_box_html_options)
      check_box_field = check_box(attribute, check_box_html_options, 'Y', 'N')
      html_options[:class] = 'govuk-checkboxes__label'
      label_field = field_label_wrapper(attribute, options, html_options)
      check_box_item = @template.content_tag(:div, check_box_field + label_field, class: 'govuk-checkboxes__item')
      @template.content_tag(:div,
                            error + check_box_item,
                            class: field_wrapper_class(field_wrapper_error_class(attribute)))
    end

    # Creates a collection of check boxes for each item in the collection with correct class and template,
    # associated with a clickable label.
    # Use value_method and text_method to convert items in the collection for use as text/value in check boxes.
    # @param method [Symbol] symbol to be translated to string for the label, hint and error texts.
    # @param collection [Object] a collection of data that is directly linked to the options values of the keys'
    #   :value_method and :text_method.
    # @param options [Hash] will contain all the functional options to modify the fields, and it will also have
    #   the default :value_method (with value of :code) and :text_method (with value of :value) to be used
    #   for creating the collection checkboxes.
    # @param html_options [Hash] options (element attributes/properties) to be passed into the creation of the wrapper.
    # @return [HTML block element] the standard field for collection of check boxes
    def collection_check_boxes_fields(method, collection, options = {}, html_options = {})
      html_options[:class] = 'govuk-checkboxes'
      options[:value_method] ||= :code
      options[:text_method] ||= :value
      check_box_div_inline_tag = collection_checkbox_wrapper(method, collection, options, html_options)
      collection_field_wrapper(method, options) { check_box_div_inline_tag }
    end

    # Create a collection of radio inputs with correct class and template
    # for the attribute.
    # Basically this helper will create a radio input associated with a label
    # for each text/value option in the collection,
    # using value_method and text_method to convert these text/value.
    # that will be evaluated for each item in the collection.
    # @example collection_radio_buttons_fields(:user_is_current, CurrentInactive.all)
    # @param method [Symbol] symbol to be translated to string for the label, hint and error texts.
    # @param collection [Object] a collection of data that is directly linked to the options values of the keys'
    #   :value_method and :text_method.
    # @param options [Hash] will contain all the functional options to modify the fields, and it will also have
    #   the default :value_method (with value of :code) and :text_method (with value of :value) to be used
    #   for creating the collection radio buttons.
    # @param html_options [Hash] options (element attributes/properties) to be passed into the creation of the wrapper.
    # @return [HTML block element] the standard field for collection of radio buttons
    def collection_radio_buttons_fields(method, collection, options = {}, html_options = {})
      wrapper_class = 'govuk-radios'
      wrapper_class += ' govuk-radios--inline' if options[:alignment] != 'vertical'

      # :alignment is the only options that is currently passed into the creation of the field.
      html_options = { class: wrapper_class }.merge(html_options)
      options[:value_method] ||= :code
      options[:text_method] ||= :value
      radio_div_inline_tag = collection_radio_buttons_wrapper(method, collection, options, html_options)
      collection_field_wrapper(method, options) { radio_div_inline_tag }
    end

    # This creates a currency field with pound sign before textbox with
    # the correct label hint and error structure
    # to the attribute passed on to the parameter. Within this element block, the
    # hint and error texts gets added.
    # @param attribute [Object] the symbol to be translated to a string relating to the content
    # @param options [Array] an array of options to be passed to the
    #   {::UtilityHelper#field_html_options}
    # @return [HTML block element] the standard password field with hint and error texts.
    def currency_field(attribute, options = {}, html_options = {})
      # The type is being used as a functional option, not html option.
      options = { type: 'CURRENCY' }.merge(options)
      text_field(attribute, options, html_options)
    end

    # Creates a standard file field with associated hint and error text fields.
    # Within this element block the hint and error texts gets added.
    # @param attribute [Object] the symbol to be translated to a string relating to the content
    # @param options [Array] an array of options to be passed to the {::UtilityHelper#field_html_options}
    # @return [HTML block element] the standard text field with hint and error texts.
    def file_field(attribute, options = {}, html_options = {})
      options = form_options(:options, options)
      input_class = 'govuk-file-upload'
      html_options =
        UtilityHelper.field_html_options(options, form_options(:html_options, html_options), input_class)
      field_wrapper(attribute, options, html_options, input_class) do
        super(attribute, html_options)
      end
    end

    # Creates multiple fields (passed as the yielded block given) in a single row with one title.
    #
    # The field that can be used by this requires to do one step (in the method where the field is being created):
    # 1. The options and html_options needs to be merged with the @table_options options and html_options, this
    #   can be done by calling the method form_options like this:
    #   options = form_options(:options, form_options(:html_options, options))
    #   or in some cases, the options needs be stored separately to the html_options.
    #
    # To use this, you must ensure that in your view:
    # 1. when you're passing the fields (like text_field, date_field, select etc.) you must use <% %> and not <%= %>
    # 2. at the end of each field (if it's not the last field to be added), you must put a + like this <% ... + %>
    # @example
    #   <%= form.fieldset_fields({ label: t('.created_date_title'), hint: t('.created_date_hint') }) do |fieldset| %>
    #     <% fieldset.date_field(:from_datetime) + %>
    #     <% fieldset.date_field(:to_datetime) %>
    #   <% end %>
    # @param heading [Hash] contains data that will be used to create the title, hint, etc. of the heading part
    #   of the fieldset.
    # @yield contains the fields to be displayed in a horizontal (by default) layout.
    def fieldset_fields(heading)
      # The main point of this method is that we yield in at least two form fields, which is to lay out the fields
      # horizontally (by default). So if none was passed, then this method should not be used.
      return unless block_given?

      field_labels = heading[:include_field_labels] ? {} : { label: '' }
      # The default direction will always be :horizontal, but we can set it to :vertical which will change
      # the structure of the fields are placed.
      direction = heading[:direction] || :horizontal
      # The width relies on the layout direction of the fields, the width will be full for :horizontal and for
      # :vertical it should be it's normal width (1/3)
      width = direction == :horizontal ? { width: 'full' } : {}
      # This global variable will be used in the yielded form fields to change a few of it's options so it also
      # knows that it's being used as part of a fieldset.
      @fieldset_options = { direction: direction, options: field_labels.merge(width), html_options: {} }
      output = fieldset_wrapper(heading, yield(self))
      # We need to set this back to nil since when we're using the fields normally we don't want them
      # to be looked as if they're part of the fieldset.
      @fieldset_options = nil
      output.html_safe
    end

    # Creates the standard table of fields, which has the label text of the fields as the table headings, that can
    # also have a delete row button and add row button .
    #
    # The field that can be used by this requires to do two steps (in the method where the field is being created):
    # 1. Append the attribute used into the @table_options[:attribute] by calling the method
    #   append_table_fields_attribute(attribute)
    #   before the creation of the field.
    # 2. The options and html_options needs to be merged with the @table_options options and html_options, this
    #   can be done by calling the method form_options like this:
    #   options = form_options(:options, form_options(:html_options, options))
    #   or in some cases, the options needs be stored separately to the html_options.
    #
    # To use this, you must ensure that in your view:
    # 1. when you're passing the fields (like text_field, date_field, select etc.) you must use <% %> and not <%= %>
    # 2. at the end of each field (if it's not the last field to be added), you must put a + like this <% ... + %>
    # @example
    #   <%= f.table_fields(@lbtt_return.link_transactions, :link_transactions) do |table_form| %>
    #     <% table_form.text_field(:return_reference) + %>
    #     <% if @lbtt_return.flbt_type == "#{$convey_type}" %>
    #       <% table_form.currency_field(:consideration_amount) %>
    #     <% else %>
    #       <% table_form.currency_field(:npv_inc) + %>
    #       <% table_form.currency_field(:premium_inc) %>
    #     <% end %>
    #   <% end %>
    # @param objects [Array] containing objects used to show the table of fields
    # @param attribute [Symbol] the attribute to be used on the fields_for which will be a part of the created field's
    #   input element ('name' and 'id' attribute) and label element ('for' attribute).
    # @param options [Hash] options that can be passed to all the options and html_options of each fields created.
    #   See table_fields_options_setup for more information about other options.
    def table_fields(objects, attribute, options = {})
      return if objects.blank? || !block_given?

      # attributes will be used to store an array of attributes which is of type Symbol and will be used for creating
      # the row of table headings.
      attributes = body = ''
      # This creates the body part of the table and extracts the attributes used (to be used for creating the head part)
      # The temporary variable index will be used as part of the field's identity. So with the standard code, this will
      # affect the input element ('name' and 'id' attribute) and label element ('for' attribute) of the field.
      objects.each_with_index do |object, index|
        fields_for(attribute, object) do |form|
          # Sets up the table options of the current object's form class
          table_fields_options_setup(form, index, options)
          # Wraps a <tr> around the <td>s of fields made from the yield data
          body += table_fields_row_wrapper(objects, yield(form), form, index, options)

          # form.table_options[:attributes] consists of a list of attributes that was yielded in.
          # We only need to get the first row of attributes as all the attributes per row should be the same throughout
          # the table.
          attributes = form.table_options[:attributes] if index.zero?
        end
      end

      # Creates the table element with the thead (containing a row of <th> which consists of translated attributes) and
      # tbody. Then depending on the options, it could add an add button for user to be able to add a new row of data.
      table_fields_wrapper(attributes, body, options)
    end
  end
end
