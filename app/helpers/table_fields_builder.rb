# frozen_string_literal: true

# This is where all the table_fields related codes are defined
module TableFieldsBuilder
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

    # Removing the options and html_options that were associated with the attribute in the table_options, these options
    # are specific to the table_fields.
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
    @table_options[:attributes][attribute][:options][:label] = label.html_safe if html_options[:index].zero?

    # The field itself doesn't need a label anymore as it will be used as part of the <th>, but the field still
    # needs the hidden label.
    ''
  end

  # The initial values of the three fields: objects, attributes and body
  # @note This has been split out so that it can cope with rubocop
  # @return [Array] first item is the array of sub-objects, second is the hash of attributes with options,
  #   and third is the body.
  def initial_table_fields_values(object, attribute)
    [object.send(attribute), {}, '']
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
    delete_button = ''
    # Normally where we have more than one row of object, we want to default the 'delete row' button to be shown.
    if objects.size > 1 && !options[:exclude_delete_button]
      delete_text = @template.t('delete_row')
      button_html_options = { name: 'delete_row', class: 'scot-rev-button_link govuk-link', id: "delete_row_#{index}",
                              value: index, 'aria-label' => table_field_hidden_label(delete_text, { index: index }) }
      delete_button = table_data_tag(@template.button_tag(delete_text, button_html_options),
                                     class: 'remove_border_bottom_line')
      # Adds the table_heading for the 'delete row' button
      form.table_options[:attributes][:action] = { options: { label: @template.t('action') } }
    end
    table_row_tag(fields + delete_button)
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
  # @return [HTML block element] the table with a caption, all the fields, delete buttons (which looks like a link) and
  #   an add row button (which looks like a link).
  def table_fields_wrapper(object, attribute, attributes, body, options)
    table_tag(table_caption_tag(UtilityHelper.attribute_text(object, attribute, :caption)) +
              table_fields_head_wrapper(attributes) +
              table_body_tag(body)) +
      table_fields_add_row_button(options)
  end

  # Generates the text to be used for the visually-hidden labels of a field of table_fields
  # @return [String] the text with the row index
  def table_field_hidden_label(text, html_options)
    index = html_options[:index]
    return text if index.nil? || !index.is_a?(Integer)

    @template.t('row', title: text, row: (index + 1))
  end

  private

  # Creates the add row button of the table_fields if we don't exclude it.
  # @return [HTML block element] Button disguised as a link that will execute the add row feature,
  #   which should be defined in your controller.
  def table_fields_add_row_button(options)
    # Normally we want to have an 'add row' button, so we will look for the :exclude_add_button.
    return ''.html_safe if options[:exclude_add_button]

    add_row = button('add_row', class: 'scot-rev-button_link govuk-link', name: 'add_row')
    @template.content_tag(:div, add_row, class: 'govuk-form-group')
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
    head = ''
    return head if attributes.blank?

    attributes.each do |attribute, all_options|
      heading_text = options[:label] || @template.t(".#{attribute}")
      head += table_heading_tag(heading_text, th_html_options(all_options))
    end

    table_head_tag(table_row_tag(head))
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
