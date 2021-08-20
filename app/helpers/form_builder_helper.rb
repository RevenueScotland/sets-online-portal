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
  class LabellingFormBuilder < ActionView::Helpers::FormBuilder # rubocop:disable Metrics/ClassLength
    include DateFormatting

    # This attribute is used for storing options for when we're creating a table fields
    # It is needed because we use a fields_for that yields in a new form object and we need
    # to set the options on the builder externally
    attr_accessor :table_options

    attr_writer :current_browser

    # Used as the global variable to set the browser that is currently being used.
    # Currently if your page has dates then this is one of the must have in your form.
    # @example Simply put this one line in your form, assuming that you name it as 'form'
    #   <% form.current_browser = application_browser %>
    # @see ApplicationHelper::application_browser
    def current_browser
      if @current_browser.nil?
        raise Error::AppError.new('Base Form Builder',
                                  'Browser has not been set for this page.')
      end

      @current_browser
    end

    # Creates a standard text field with associated hint and error text fields.
    # This creates a standard text field for the user to input data related to
    # the attribute that is passed on to the parameter. Within this element block,
    # the hint and error texts gets added.
    # @param attribute [Object] the symbol to be translated to a string relating to the content
    # @param options [Array] an array of options to be passed to the {::UtilityHelper#field_html_options}
    # @return [HTML block element] the standard text field with hint and error texts.
    def text_field(attribute, options = {}, html_options = {})
      # @see base_form_builder's methods: form_options and append_table_fields_attribute
      options, html_options = setup_standard_field_options(attribute, options, html_options)
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

      options, html_options = setup_standard_field_options(attribute, options, html_options)
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
      options[:width] = 'three-quarters' if options[:width].nil? && !using_table_fields?
      html_options[:class] = 'table_field_textarea' if using_table_fields?
      input_class = 'govuk-textarea'
      options, html_options = setup_standard_field_options(attribute, options, html_options, input_class)
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
      move_field_options_to_table(attribute, options, html_options) if options.key?(:display_attribute)
      options = form_options(:options, options)
      html_options = form_options(:html_options, html_options)
      # If we want the hidden field to display a value while we're storing data into it, we can do so by
      # adding the :display_attribute into the options hash of the param in view.
      display_value = @object.send(options[:display_attribute]) if options.key?(:display_attribute)
      # @note display and display_value has been split off so that the developer can change (or add) which element
      #   will they be using to display the value they need.
      display = if display_value.nil?
                  ''.html_safe
                else
                  @template.table_data_tag(display_value, class: 'remove_border_bottom_line')
                end
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
      move_field_options_to_table(attribute, options, html_options) if using_table_fields?
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
      if id.nil?
        super
      else
        super @template.t(id, **html_options), html_options
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
      span = @template.tag.span('', class: 'scot-rev-submit-image')
      html_options = UtilityHelper.submit_html_options(id, options, html_options)
      submit = if id.nil?
                 super
               else
                 super @template.translate(id, **html_options), html_options
               end
      @template.tag.div(submit + span, class: 'scot-rev-submit')
    end

    # Create a check box field with the correct class
    # @param attribute [Object] used as the label and passed as value of the check_box
    # @param options [Hash] a hash of options used to further modify the check box field
    # @return [HTML block element] the standard checkbox field with the correct classes and label
    def check_box_field(attribute, options = {}, html_options = {})
      check_box_html_options = { class: 'govuk-checkboxes__input' }
      error = error_text(attribute, options, check_box_html_options)
      check_box_field = check_box(attribute, check_box_html_options, 'Y', 'N')
      options[:label_class] = 'govuk-checkboxes__label'
      label_field = field_label_wrapper(attribute, options, html_options)
      check_box_item = @template.tag.div(check_box_field + label_field, class: 'govuk-checkboxes__item')
      @template.tag.div(error + check_box_item, class: field_wrapper_class(field_wrapper_error_class(attribute)))
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

    # This creates a percentage field with % sign before text-box with
    # the correct label hint and error structure
    # to the attribute passed on to the parameter. Within this element block, the
    # hint and error texts gets added.
    # @param attribute [Object] the symbol to be translated to a string relating to the content
    # @param options [Array] an array of options to be passed to the
    #   {::UtilityHelper#field_html_options}
    # @return [HTML block element] the standard password field with hint and error texts.
    def percentage_field(attribute, options = {}, html_options = {})
      options[:width] = 'width-3' if options[:width].nil?
      # The type is being used as a functional option, not html option.
      options = { type: 'PERCENTAGE' }.merge(options)
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

    # Creates multiple fields (passed as the captured block given) in a single row with one title.
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
    #     <%= fieldset.date_field(:from_datetime) %>
    #     <%= fieldset.date_field(:to_datetime) %>
    #   <% end %>
    # @param heading [Hash] contains data that will be used to create the title, hint, etc. of the heading part
    #   of the fieldset.
    # @yieldparam [FormBuilder] form Gives this form builder to the block to be captured
    # @yieldreturn [SafeBuffer] The html block with at least two form fields
    def fieldset_fields(heading, &block)
      # The main point of this method is that we capture in at least two form fields, which is to lay out the fields
      # horizontally (by default). So if none was passed, then this method should not be used.
      return unless block_given?

      field_labels = heading[:include_field_labels] ? {} : { label: '' }
      # The default direction will always be :horizontal, but we can set it to :vertical which will change
      # the structure of the fields are placed.
      direction = heading[:direction] || :horizontal
      # The width relies on the layout direction of the fields, the width will be full for :horizontal and for
      # :vertical it should be it's normal width (1/3)
      width = direction == :horizontal ? { width: 'full' } : {}
      # This global variable will be used in the captured form fields to change a few of it's options so it also
      # knows that it's being used as part of a fieldset.
      @fieldset_options = { direction: direction, options: field_labels.merge(width), html_options: {} }
      output = fieldset_wrapper(heading, @template.capture(self, &block))
      # We need to set this back to nil since when we're using the fields normally we don't want them
      # to be looked as if they're part of the fieldset.
      @fieldset_options = nil
      output
    end

    # Creates the standard table of fields, which has the label text of the fields as the table headings, that can
    # also have a delete row button and add row button .
    #
    # The field that can be used by this requires to do two steps (in the method where the field is being created):
    # 1. Append the attribute used into the @table_options[:attribute] by calling the method
    #   move_field_options_to_table(attribute, options, html_options)
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
    #     <%= table_form.text_field(:return_reference) %>
    #     <% if @lbtt_return.flbt_type == "#{$convey_type}" %>
    #       <%= table_form.currency_field(:consideration_amount) %>
    #     <% else %>
    #       <%= table_form.currency_field(:npv_inc) %>
    #       <%= table_form.currency_field(:premium_inc) %>
    #     <% end %>
    #   <% end %>
    #
    # To add a caption, you must ensure that in you en.yml you have defined the text according to the object
    # and attribute that was passed in.
    # By default this doesn't add any caption to the table unless you define it.
    # @example We are using the object <Applications::Slft::Sites...> and attribute :waste
    #   en:
    #     activemodel:
    #       captions:
    #         applications/slft/sites:
    #           wastes: 'Here is my caption text'
    # @param object [Object] the main object which has the attribute that contains the sub-objects to show.
    # @param attribute [Symbol] the attribute to be used on the fields_for which will be a part of the created field's
    #   input element ('name' and 'id' attribute) and label element ('for' attribute).
    # @param options [Hash] options that can be passed to all the options and html_options of each fields created.
    #   See add_options_to_table_fields for more information about other options.
    # @yieldparam [FormBuilder] form Gives this form builder to the block to be captured
    # @yieldreturn [SafeBuffer] The html block with at least two form fields
    def table_fields(object, attribute, options = {}, &block)
      # objects contain the sub-objects used to show the table of fields
      # attributes will be used to store a hash of attributes (with options) and will be used for creating
      # the row of table headings.
      objects, attributes, body = initial_table_fields_values(object, attribute)
      return if objects.blank? || !block_given?

      # This creates the body part of the table and extracts the attributes used (to be used for creating the head part)
      # The temporary variable index will be used as part of the field's identity. So with the standard code, this will
      # affect the input element ('name' and 'id' attribute) and label element ('for' attribute) of the field.
      objects.each_with_index do |sub_object, index|
        fields_for(attribute, sub_object) do |form|
          # Sets up the table options of the current object
          add_options_to_table_fields(objects, form, index, options)
          # Wraps a <tr> around the <td>s of fields made from the captured data
          body += table_fields_row_wrapper(objects, @template.capture(form, &block), form, index, options)

          # form.table_options[:attributes] consists of a list of attributes that was yielded in.
          # We only need to get the first row of attributes as all the attributes per row should be the same throughout
          # the table.
          attributes = extract_attributes_from_table_fields(form) if index.zero?
        end
      end

      # Creates the table element with the thead (containing a row of <th> which consists of translated attributes) and
      # tbody. Then depending on the options, it could add an add button for user to be able to add a new row of data.
      table_fields_wrapper(object, attribute, attributes, body, options)
    end

    private

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
      @template.tag.span(hint, hint_html_options)
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
      field_label_wrapper(attribute, options.merge(label: 'ignore'),
                          html_options).to_s.scan(/for="([^"]*)"/).last.first
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

      @template.tag.span(hidden_label, class: 'govuk-visually-hidden')
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

      @template.tag.span(error_content(attribute), error_html_options)
    end

    # Wrapper for generic label, hint text, error text structure for collection field.
    # @param attribute [Object] the symbol to be translated to a string related to the contents of the collection field
    # @param options [Array] an array of options that is passed to the {#field_label_wrapper}
    # @return [HTML block element] returns the generic label, hint text and error text for a field
    def collection_field_wrapper(attribute, options)
      legend_tag = collection_legend_wrapper(attribute, options)
      hint_text = hint_text(attribute, options)
      error_text = error_text(attribute, options)
      fieldset_tag = @template.tag.fieldset(legend_tag + hint_text + error_text + yield, class: 'govuk-fieldset')

      @template.tag.div(fieldset_tag, class: field_wrapper_class(field_wrapper_error_class(attribute)))
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
      output = @template.tag.div(header_texts + input_field, class: field_wrapper_class(error_class))

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
      set_input_class_to_error(html_options, input_class) if error_class.present?

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
      # If we are adding a visually hidden label then mark the label as html safe
      label = hidden_label + label.html_safe unless hidden_label.nil? # rubocop:disable Rails/OutputSafety
      # If we're creating an empty label then we don't create it.
      return ''.html_safe if label.blank?

      @template.label(@object_name, attribute, label_options) do
        label
      end
    end

    # Depending on the contents of the global options @table_options and @fieldset_options that comes from
    # the form_builder_helper, this will wrap another layer on the output if the field is being used as part of a
    # fieldset or a table of fields.
    def multiple_fields_wrapper(output)
      unless @fieldset_options.nil? || @fieldset_options[:direction] == :vertical
        return @template.tag.div(output, class: 'fieldset-input__item')
      end
      return @template.table_data_tag(output, class: 'remove_border_bottom_line') if using_table_fields?

      output
    end

    # Wrapper for the group of fields, which is creating a single label, hint and the fields without their separate
    # label
    # @param heading [Hash] should contain the title of the fieldset, may contain other data related to the heading.
    # @param fields [HTML block element] Contains the html block of each of the fields, which is to be placed into a div
    #   container.
    def fieldset_wrapper(heading, fields)
      output = field_label_wrapper(heading[:attribute], label: heading[:label])
      output += hint_text(heading[:attribute], hint: heading[:hint])
      output += @template.tag.div(fields, class: 'fieldset-input')

      @template.tag.div(@template.tag.fieldset(output, class: 'govuk-fieldset'), class: 'govuk-form-group')
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
      radio_buttons = collection_radio_buttons(method, collection, options[:value_method],
                                               options[:text_method]) do |b|
        @template.tag.div(b.radio_button(class: 'govuk-radios__input') +
                              b.label(class: 'govuk-label govuk-radios__label'), class: 'govuk-radios__item')
      end
      @template.tag.div(radio_buttons, html_options)
    end

    # Creates the standard wrapper for a collection of checkboxes.
    # See {FormBuilderHelper.LabellingFormBuilder#collection_check_boxes_fields} for information about the parameters.
    # @return [HTML block element] the standard checkbox wrapper collection with the appropriate classes
    def collection_checkbox_wrapper(method, collection, options, html_options)
      checkbox = collection_check_boxes(method, collection, options[:value_method], options[:text_method]) do |b|
        @template.tag.div(b.check_box(class: 'govuk-checkboxes__input') +
                              b.label(class: 'govuk-label govuk-checkboxes__label'), class: 'govuk-checkboxes__item')
      end
      @template.tag.div(checkbox, html_options)
    end

    # set default class and div to legend used in {FormBuilderHelper.LabellingFormBuilder#collection_check_boxes_fields}
    # and {FormBuilderHelper.LabellingFormBuilder#collection_radio_buttons_fields}
    # @param attribute [Object] the symbol to be translated to a string
    # @return [HTML block element] the standard legend wrapper; consists of the headings of the content.
    def collection_legend_wrapper(attribute, options)
      legend = UtilityHelper.label_text(@object, attribute, options)
      legend += visually_hidden_label(attribute, options, {}) || ''
      h1_tag = @template.tag.h1(legend, class: 'govuk-fieldset__heading')
      @template.tag.legend(h1_tag, class: 'govuk-fieldset__legend govuk-fieldset__legend',
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
        @template.tag.span('&#163;'.html_safe, class: 'govuk-label currency')
      when 'PERCENTAGE'
        @template.tag.span('&#37;'.html_safe, class: 'govuk-label percentage')
      else
        ''.html_safe
      end
    end

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
      options[:width] = 'three-quarters' if %w[CURRENCY
                                               PERCENTAGE].include?(options[:type]) && options[:width] == 'full'

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
      error_start = "<span class=\"govuk-visually-hidden\">#{I18n.t('.error')}:</span>".html_safe # rubocop:disable Rails/OutputSafety

      (error_start + @template.safe_join(@object.errors[attribute], "<br>#{error_start}".html_safe)) # rubocop:disable Rails/OutputSafety
    end

    # Determines if our field being built is being created as part of table_fields
    # @return [Boolean] true means yes we are building it as part of table_fields, false is no.
    def using_table_fields?
      !@table_options.nil?
    end

    # Appends to the @table_options the attributes associated with options and html_options passed from the fields.
    # There are only some options and html_options that we pass in to the @table_options, these are defined within
    # the method: options_list and html_options_list.
    # @note this is needed on each fields that we want to include in the table_fields method of form_builder_helper.
    def move_field_options_to_table(attribute, options, html_options)
      # This is where we'll store all the options to build the <th> of the fields.
      attributes = @table_options[:attributes]

      # The list of options and html_options that we will extract from the field so that it can be built later with the
      # table heading <th>.
      options_list = %i[width]
      html_options_list = []

      attributes[attribute] = { options: options.select { |key, _| options_list.include?(key) },
                                html_options: html_options.select { |key, _| html_options_list.include?(key) } }

      # Removing the options and html_options that were associated with the attribute in the table_options, these
      # options are specific to the table_fields.
      options.reject! { |key, _| options_list.include?(key) }
      html_options.reject! { |key, _| options_list.include?(key) }
    end

    # Copies the generated standard label of the field to be used as the table-heading text of each column.
    # @return [String] the label now for the field, which should be an empty string.
    def add_label_to_table_fields_options(attribute, label, html_options)
      # The 'ignore' means this is currently being used to get the id of the hint/error
      return label if label == 'ignore'

      # Copies the label to the table-options so that it can be used later to build the <th> for each column.
      # We only need to extract the label once for each field, so that we don't re-overwrite this, then that's why we've
      # put the condition.
      @table_options[:attributes][attribute][:options][:label] = label if html_options[:index].zero?

      # The field itself doesn't need a label any more as it will be used as part of the <th>, but the field still
      # needs the hidden label.
      ''
    end

    # The initial values of the three fields: objects, attributes and body
    # @note This has been split out so that it can cope with rubocop
    # @return [Array] first item is the array of sub-objects, second is the hash of attributes with options,
    #   and third is the html body.
    def initial_table_fields_values(object, attribute)
      [object.send(attribute), {}, ''.html_safe]
    end

    # Used for initially setting up the table_options of the table_fields form.
    # @note only used in table_fields method of form_builder_helper.
    # Here is a list of possible options that can be added to the options when the table_fields method is called:
    #   1. :exclude_delete_button [Boolean] partly used for determining if the delete row button should be added.
    #   2. :exclude_add_button [Boolean] used for determining if the add row button should be added.
    #   3. :autofocus_record [Symbol] should either be nil, :first or :last, this will determine where to set the
    #   autofocus on page load. For example :first will set the focus to the first object in the list of objects.
    def add_options_to_table_fields(objects, form, index, options)
      # The key :attributes [Hash] will be used to store a hash of attributes (with options) used when the fields
      # are created so that it can be used to display the table headings for each columns.
      form.table_options = { attributes: {}, options: { width: 'full' }, html_options: { index: index } }
      return if options.nil?

      # Depending on the contents of the :autofocus_record, we'll set it to focus to either the first, last or not.
      if options[:autofocus_record].present? && objects.send(options[:autofocus_record]) == objects[index]
        form.table_options[:html_options].merge!(autofocus: true)
      end

      # The autofocus option is only used to set the html options to have an autofocus, it is needed on the set up of
      # each objects but it's not needed anywhere further down the code. So we exclude it from here.
      form.table_options.merge!(options.reject { |o| %i[autofocus_record].include?(o) })
    end

    # Wraps the fields in a table_row <tr> element, which may also include the delete row button.
    # @note only used in table_fields method of form_builder_helper.
    # @param fields [HTML block element] By the time this method is called, the row of fields have already been created,
    #   and this is what it consists.
    def table_fields_row_wrapper(objects, fields, form, index, options)
      delete_button = ''.html_safe
      # Normally where we have more than one row of object, we want to default the 'delete row' button to be shown.
      if objects.size > 1 && !options[:exclude_delete_button]
        delete_text = @template.t('delete_row')
        button_html_options = { name: 'delete_row', class: 'scot-rev-button_link govuk-link', id: "delete_row_#{index}",
                                value: index, 'aria-label' => table_field_hidden_label(delete_text, { index: index }) }
        delete_button = @template.table_data_tag(@template.button_tag(delete_text, button_html_options),
                                                 class: 'remove_border_bottom_line')
        # Adds the table_heading for the 'delete row' button
        form.table_options[:attributes][:action] = { options: { label: @template.t('action') } }
      end
      @template.table_row_tag(fields + delete_button)
    end

    # Extracts the attributes hash from the form.
    # This contains a hash of options to build the heading for each column.
    def extract_attributes_from_table_fields(form)
      form.table_options[:attributes]
    end

    # Creates the standard table of fields output which may also have a caption area and an add row button.
    # For the description of the param attributes and body see the local variable attributes and body of
    # {FormBuilderHelper.LabellingFormBuilder#table_fields}.
    # @param object [Object] the main object
    # @param attribute [Symbol] the attribute which contains all the sub-objects
    # @param attributes [Hash] contains all the attributes used and will be used to create the <th> of each column
    # @param body [HTML block element] all the generated fields that are all wrapped up in <tr>s for each object,
    #   and for each field to be shown for that object they're wrapped in <td>.
    # @param options [Hash] see add_options_to_table_fields for some of the contents
    # @return [HTML block element] the table with a caption, all the fields, delete buttons (which looks like a link)
    #   and an add row button (which looks like a link).
    def table_fields_wrapper(object, attribute, attributes, body, options)
      @template.table_tag(@template.table_caption_tag(UtilityHelper.attribute_text(object, attribute, :caption)) +
                table_fields_head_wrapper(attributes) +
                @template.table_body_tag(body)) +
        table_fields_add_row_button(options)
    end

    # Generates the text to be used for the visually-hidden labels of a field of table_fields
    # @return [String] the text with the row index
    def table_field_hidden_label(text, html_options)
      index = html_options[:index]
      return text if index.nil? || !index.is_a?(Integer)

      @template.t('row', title: text, row: (index + 1))
    end

    # Creates the add row button of the table_fields if we don't exclude it.
    # @return [HTML block element] Button disguised as a link that will execute the add row feature,
    #   which should be defined in your controller.
    def table_fields_add_row_button(options)
      # Normally we want to have an 'add row' button, so we will look for the :exclude_add_button.
      return '' if options[:exclude_add_button]

      add_row = button('add_row', class: 'scot-rev-button_link govuk-link', name: 'add_row')
      @template.tag.div(add_row, class: 'govuk-form-group')
    end

    # Creates the table_fields's row of table headings.
    # @param attributes [Hash] the attributes associated with their options to build the table-heading
    # @return [HTML block element] The table-head part of the table_fields,
    #   which builds html code:
    #   <thead>
    #   ..<tr>
    #   ....<th>"<label-text from options or translation>"</th>
    #   ..</tr>
    #   </thead>
    def table_fields_head_wrapper(attributes)
      head = ''.html_safe
      return head if attributes.blank?

      attributes.each do |attribute, all_options|
        heading_text = options[:label] || @template.t(".#{attribute}")
        head += @template.table_heading_tag(heading_text, th_html_options(all_options))
      end

      @template.table_head_tag(@template.table_row_tag(head))
    end

    # Generate the table_heading options according to the options which we get from the associated attribute
    # @return [Hash] html options to build the table_heading.
    def th_html_options(all_options)
      options = all_options[:options] || {}
      html_options = all_options[:html_options] || {}

      # The gds_css_class_for_width defaults to using the 'one-third' width if the :width passed is nil,
      # so in order to build the classes of the <th> normally when :width isn't passed
      html_options[:class] = UtilityHelper.gds_css_class_for_width(options[:width]) unless options[:width].nil?
      html_options
    end
  end
end
