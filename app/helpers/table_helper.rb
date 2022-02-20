# frozen_string_literal: true

# helper for creating application specific table
#
# This is a visual example of how the table structure may look like for display_table:
#
#              column 0        column 1        column 2        column n
#             +---------------+---------------+---------------+---------------+
# objects[0]  | <th>          | <th>          | <th>          | <th...>       | row 0
#             | attributes[0] | attributes[1] | attributes[2] | attributes[n] |
#             +---------------+---------------+---------------+---------------+
# objects[1]  | <td>          | <td>          | <td>          | <td...>       | row 1
#             +---------------+---------------+---------------+---------------+
#             | <action links >                                               | row 2
#             +---------------+---------------+---------------+---------------+
# objects[2]  | <td>          | <td>          | <td>          | <td...>       | row 3
#             +---------------+---------------+---------------+---------------+
#             | <action links >                                               | row 4
#             +---------------+---------------+---------------+---------------+
# objects[3]  | <td...>       | <td...>       | <td...>       | <td...>       | row (n - 1)
#             +---------------+---------------+---------------+---------------+
#             | <action links...>                                             | row n
#             +---------------+---------------+---------------+---------------+
#
module TableHelper # rubocop:disable Metrics/ModuleLength
  # This is a main method to creates a standard table using gds style and classes
  # @param objects [Object] a collection require to build table
  # @param attributes [Symbol] is the attribute of the object, which can be considered as a method of it too.
  #   These are used to display the value of the object's attributes.
  # @param actions [Hash] the link actions to be created for each rows. See include_action? and action_tag for
  #   the extra parameters and what to pass into this part of the params.
  # @param options [Hash] is a hash of extra information to be control the display of individual attributes
  # Recognised formats are :money and :date
  # @return [HTML block element] The HTML for table with GDS style attached
  # Example :
  # display_table(@collection,
  #                [:attribute1,:attribute2,...],
  #                [
  #                  { label: t('edit_row'), action: :edit },
  #                  { label: t('<action name>'),action: <action_path> },.......
  #                ],
  #                { attribute1 : { format: : money} })
  def display_table(objects, attributes, actions = nil, options = {})
    return if objects.blank?

    head = table_head_tag(table_heading_row(objects[0], attributes, options))
    body, table_summary = display_table_body(objects, attributes, actions, options)
    footer = display_table_footer(attributes, table_summary, options)
    table_tag(head + body + footer)
  end

  private

  # Creates the row for the table headings <th> which are the labels of each of the attributes.
  def table_heading_row(object, attributes, options)
    return if object.nil?

    cols = attributes.collect do |attribute|
      attr_options = options[attribute] || {}
      label = UtilityHelper.label_text(object, attribute, **attr_options)
      table_header_tag_cell(attribute, attr_options, label)
    end

    table_row_tag(safe_join(cols))
  end

  # Create table header cell applying the GDS standard.
  # @see the {#table_cell_class} for usage and description of both the params attribute and options.
  # @param label [String] text that is passed in for the table header contents
  # @return [HTML block element] the standard table header <th> element with the appropriate class
  def table_header_tag_cell(attribute, options, label = '')
    return ''.html_safe if skip_cell?(options)

    table_heading_class = table_cell_class(attribute, options, :th)
    option_class = table_heading_class.blank? ? {} : { class: table_heading_class }
    table_heading_tag(label, option_class)
  end

  # Create table data cell applying the GDS standard, used for displaying the contents of an attribute or
  # for creating a table data cell for action links.
  # @param text [String] text passed in for the contents of the table data element
  # @param attribute [Object] is the attribute of the object, normally it won't have an attribute if the
  #   method is used for action links.
  # @param options [Hash] is used to add extra information into this attribute
  # @return [HTML block element] the standard table data <td> element with the appropriate class
  def table_data_tag_cell(text = '', attribute = nil, options = {})
    return ''.html_safe if skip_cell?(options)

    options = {} if options.nil?
    table_data_class = table_cell_class(attribute, options)
    option_class = table_data_class.blank? ? {} : { class: table_data_class }
    # Normally options contains all other options that doesn't need to be included in the element's property,
    # so we'll make sure to get the defined html_options if it exists.
    html_options = options[:html_options] || {}
    table_data_tag(text, html_options.merge(option_class))
  end

  # Create table data cell for the footer applying the GDS standard, used for displaying the contents of a footer
  # normally totals, not that the tag is still <td>
  # @param text [String] text passed in for the contents of the table data element
  # @param options [Hash] is used to add extra information into this attribute
  # @return [HTML block element] the standard table data <td> element with the appropriate class
  def table_footer_tag_cell(text = '', options = {})
    return '' if skip_cell?(options)

    options = {} if options.nil?
    table_data_class = table_cell_class(nil, options)
    option_class = table_data_class.blank? ? {} : { class: table_data_class }
    # Normally options contains all other options that doesn't need to be included in the element's property,
    # so we'll make sure to get the defined html_options if it exists.
    html_options = options[:html_options] || {}
    table_data_tag(text, html_options.merge(option_class))
  end

  # The standard class for the attribute's table cell with the added extra class from options extracted and applied.
  # Currently it applies to both the <th> and <td>.
  # @param attribute [Symbol] the attribute of the object.
  # @param options [Hash] contains a hash of options which will be used to add on to the table cell's class.
  # @param cell [Symbol] determines which table cell this method is used for, the values should only be a :td or :th.
  # @return [String] a combined list of classes which could be an empty string.
  def table_cell_class(attribute, options, cell = :td)
    cell_classes = []
    # Class to remove border bottom line as for the attributes we don't want to put a line below it. This is because
    # their action links are below its row of data. If there's an attribute then it means that it's an action and
    # therefore the bottom line should not be remove so that it a divider between each objects can be seen.
    cell_classes << 'remove_border_bottom_line' if !attribute.nil? && cell == :td

    # Adds a format specific class onto the column
    unless options.nil?
      cell_classes << 'money_format' if options[:format] == :money
      cell_classes << options[:cell_class] unless options[:cell_class].nil?
    end

    cell_classes.join(' ')
  end

  # Used for skipping the showing of a cell, normally when an attribute is not to be shown then
  # that whole column shouldn't be shown too. So this is used to create that.
  def skip_cell?(options)
    return false if options.blank?

    return true if !options[:add].nil? && options[:add] == false

    options[:skip]
  end

  # create table body applying gds CSS class
  #
  # To show that the item in the table has been selected, make sure to add a symbol called :selected
  # with a boolean datatype in the model class.
  # @param objects [Array] a collection of data that will be used against the attributes
  # @param attributes [Array] a collection of attributes related to the objects, these attributes are
  #   to be shown on the table data.
  # @param actions [Array] a collection of hash that is used for actions, such as action for a link to edit page.
  # @param options [Hash] is used for adding extra option class to the specified column by its attribute.
  # @return [HTML block element, Hash] the standard table body element with the appropriate class and an
  #   associated summary if required
  def display_table_body(objects, attributes, actions, options)
    return if objects.nil?

    table_summary = setup_table_summary(options)

    # @note This collects the rows that builds the table with indexing. See {#actions_cell} method to learn more
    #   about what the index is used for.
    rows = objects.collect.with_index do |object, index|
      # Collects each of the attributes from the object which is then placed in a table data.
      cols = display_table_body_row_cells(object, attributes, table_summary, options)

      # Creating the two rows:
      # 1. first one is the row of the collected attributes data of the object,
      # 2. the second one is the row of actions related to that object of which it's attributes data are shown.
      table_row_tag(safe_join(cols), table_row_highlight_class(object)) +
        table_row_tag(actions_cell(object, attributes, actions, cols, index))
    end

    [table_body_tag(safe_join(rows)), table_summary]
  end

  # create table footer from the summary data applying gds CSS class
  # It loops through the attributes and checks if a summary total needs to be applied and if so
  # then creates it in the correct cell
  # Currently it only supports a total but can be expanded to add average, count etc
  # It also creates the label for the row row description in the cell given
  # Note that if both a label and summary are specified for the same cell then the summary will take precedence
  # @example summary: { total: { attributes: %i[net_lower_tonnage net_standard_tonnage exempt_tonnage total_tonnage],
  #                     label: { cell: :site_name, text: t('.total') } }
  #
  # @param attributes [Array] a collection of attributes related to the objects, these attributes are
  #   to be shown on the table data.
  # @param table_summary [Hash] a hash of options and values to be used to generate a summary footer if required.
  # @param options [Hash] is used for adding extra option class to the specified column by its attribute.
  # @return [HTML block element] the standard table body element with the appropriate class
  def display_table_footer(attributes, table_summary, options)
    return if table_summary.nil?

    rows = []
    table_summary.each do |type, type_hash|
      # We have other hash in the table summary e.g. with the data ignore these
      # note used include for when we add other totals
      next unless %i[total].include?(type)

      cols = display_table_footer_row_cells(type, type_hash, attributes, table_summary, options)
      rows << table_row_tag(safe_join(cols), class: 'table_footer')
    end
    table_footer_tag(safe_join(rows))
  end

  # This is used to determine whether an item is to be highlighted or not.
  #
  # It should skip the objects that doesn't have the :selected attribute.
  # @param object [Object] is the instance of the object to be looked at
  # @return [Hash] value of the class for highlighting the row.
  def table_row_highlight_class(object)
    return {} unless object.respond_to?(:selected)

    # Checks the object's selected attribute to see if it's been selected or not, to highlight the row.
    return { class: 'govuk-focus-colour' } if object.send(:selected)

    {}
  end

  # create table row for actions column
  #
  # Skips the item in the list that are selected, used for the messages. If the row is selected
  # which means that it is currently being viewed, then do not put the action links for it.
  # @param actions [Array] an array of actions which may be related to the object, and may or may not be shown.
  # @param cols [Array] contains all the table data <td> elements of that row, which is
  #   only used to find out how big the size of it for the colspan of the row of actions.
  # @param index [Integer] contains the index of the object from the list where it is stored.
  # @param object [Object] the object with attributes to which the action to be shown is connected to.
  # @return [HTML block element] a HTML table data <td> of the action anchor elements
  def actions_cell(object, attributes, actions, cols, index)
    # creating column for actions
    action_cols = ''.html_safe
    actions.nil? || actions.each do |action|
      # Main reason why we have the if-statement is to know which actions to show/add.
      # break-down of conditions:
      # 1. table_row_highlight_class(object) - If row is highlighted (in other words 'selected' in show messages)
      #   then the action link doesn't need to be shown for it.
      # 2. include_action?(action, object) - If the action is not (or should not be) included for that row of data,
      #   then don't show it.
      # 3. action[:path] == :display - If the simple text needs to be displayed instead of an action link, then do that
      # To display simple text among all action link content_tag(:span, action[:label]) has been added
      # @example "Ongoing Enquiry" with "continue", "download" links
      next unless include_action?(action, object)

      if action[:path] == :display
        action_cols += action_display_tag(action, object)
      elsif table_row_highlight_class(object).blank?
        # @note As the index is only used as part of one method in a lower level, this will be merged into the action
        # hash so that we won't have to add an extra parameter for each of the methods it goes into as that will be
        # wasting the parameter space, and it is quite irrelevant for that method too.
        action_cols += action_tag(object, attributes, action.merge(object_index: index))
      end
    end

    table_data_tag_cell(action_cols, nil, html_options: { colspan: cols.size })
  end

  # This method is used to check if the action link should be visible or not. Also
  # checks if there are link_options that specify any authorisation actions, and if so
  # this method checks those as well.
  #
  # Action options relevant to this method:
  #   1. action[:visible_for] contains a single method of the object that is passed as param,
  #   that method should return a boolean value of true for the action link to be considered
  #   to be shown. If this isn't defined, then it should default to including that action, when it
  #   passes the authentication of actions.
  #   2. action[:link_options] containing the :requires_action or :requires_action_path to check
  #   if authorized to have this action link. @see include_auth_actions
  #
  # Only used for {actions_cell}
  # @param action [Hash] is a hash which should contain :visible_for for this method to check the object's methods
  #   for visibility and :link_options to check if authorized.
  # @param object [Object] is the object holding the methods (that the contents of the :visible_for symbol will
  #   match with) to determine if action link is to be shown or not.
  # @return [Boolean] if the action link should be visible for the row and they are authorized
  #   then that action link will be shown; true.
  def include_action?(action, object)
    auth_action = include_auth_actions action[:link_options], object unless action[:link_options].nil?
    return false if defined?(current_user) && !authorised?(current_user, auth_action)
    return true if action[:visible_for].nil?
    return false if object.send(action[:visible_for]) == false

    true
  end

  # Get the authorisation actions based on the link_options hash supplied
  def include_auth_actions(link_options, object)
    return link_options if link_options.include?(:requires_action)
    return { requires_action: object.send(link_options[:requires_action_path]) } if
      link_options.include?(:requires_action_path)
  end

  # Creates the action tag for text display only
  # This also supports embedding a value into the text if the :value_method hash is passed in
  # The display text must then include a string replacement of key of value
  def action_display_tag(action, object)
    options = action[:options] || {}
    label = action[:label]
    if action[:value_method]
      value = object.send(action[:value_method])
      label = format(label, value: value)
    end
    options[:class] = add_action_class_option(options[:class], :text)
    tag.span(label, **options)
  end

  # Create action tag like edit, show more details available at url
  # https://guides.rubyonrails.org/routing.html#creating-paths-and-urls-from-objects
  # To add more actions to any related row of data, simply add or append a list of hash
  # to the 3rd param value of the {#display_table} method when used.
  #
  # Action options relevant to this method, to build the action tag:
  #   Label of link (mandatory):
  #     1. action[:label] [String] sets the label of the link.
  #   Path to link (mandatory- but only one is needed):
  #     1. action[:path] [Symbol || String] the rails path name, which may include a query string or the object's
  #       id (to_param output) when link is generated. See {#action_path_link} for how the different data type
  #       is handled.
  #     2. action[:action] [Symbol] rails standard routes path (e.g. :show, :new, etc.)
  #   Extra options (optional):
  #     1. action[:parameter] [Symbol] custom param values to create the link
  #     2. action[:query] [Hash] used to create the resourceful way of forming links with query strings. See
  #       below for more details about the contents of this hash:
  #       a. :attributes [Array] array of attributes that will be used to get values to construct the query string.
  #         This can include a symbol or hash. The [Symbol] will automatically be converted into the value and create
  #         it into a query string, for example we have a symbol :sent_by and the object's sent_by attribute consists
  #         of the value 'Me', so the query string will be '?sent_by=Me'.
  #         The [Hash] is used to be more specific with how we'll get the value. Below are the contents of this hash:
  #         - :attribute [Symbol] the same as above's symbol
  #         - :value [String] instead of getting the object's value, this will override that and use this.
  #         - :label [String] instead of using the attribute as the label for the value, this will override that.
  #       b. :filter_model [Symbol] the model of the filter, so that we can construct a query string in a specific
  #         way such as '?dashboard_message_filter[sent_by]=Me', without this then it should only create '?sent_by=Me'
  #     3. action[:options] contains a hash of options that will be directly passed into the link_to method.
  #     4. action[:object_index_attribute] [Symbol] using the terms from the :query, this is the :label so what we put
  #       here will be used to build the url. And it's :value will depend on the current index of the object it's from
  #       which is taken from the action[:object_index]
  #     5. action[:id_prefix] [String] contains the prefix of the id, which will be built up with the current index of
  #       the object it's from, we get the index from the action[:object_index].
  #       For example, { id_prefix: 'edit_message' } may build 'edit_message_1', 'edit_message_2', 'edit_message_3'
  #
  # @param action [Hash] is a hash containing the label to the action and the action itself
  # @param object [Object] is the object holding attributes that can be used for the specific action
  # @return [HTML block element] the standard action element which consists of an anchor element
  #   with the applied options if applicable.
  def action_tag(object, attributes, action)
    link_to(action[:label], action_link(action, object), action_options(object, attributes, action))
  end

  # Creates the action link to be used in the link_to.
  def action_link(action, object)
    # If action[:parameter] is defined then get that value from the object; this will be used to pass
    # custom param values in the path of the link.
    action_content = action[:action]
    path_content = action[:path]
    link = object if %i[show destroy].include? action_content
    # Simply gets the action link from the action hash of key :path if it exists.
    link = action_path_link(action, path_content, object, link) unless path_content.nil?
    # After looking for the link, if we still haven't created a link, then we do below.
    link ||= [action_content, object]
    link
  end

  # Creates the action link for the hash of action's key :path.
  # @return [String] the path generated from the hash of the key :path with param or query string values,
  #   OR the initial action link passed from the parameter, if no such key exists.
  def action_path_link(action, path, object, action_link)
    # Sets the link's path to the custom path which is the path passed from the view. This means that the path
    # will be a fixed path (which will be the same for each row in the list)
    return path if path.is_a?(String)

    # Creates the param or query value depending on the contents of the action. Normally when this is being generated
    # only one of the two is needed.
    param_or_query = action[:parameter].nil? ? object : object.send(action[:parameter]).to_s
    param_or_query = query_string_hash(action, object) unless action[:query].nil?
    param_or_query = param_or_query_index(param_or_query, action)

    # @note send(<method>, <param>) is equals to <method>(<param>)
    # @example send(:action_display_tag, { action: :display, label: 'Hello'})
    #   is equals to action_display_tag({ action: :display, label: 'Hello'})
    return send(path, param_or_query) if path

    action_link
  end

  # Adds the index of the object to the param or query using the object_index_attribute.
  # This should also work with the query hash.
  # @example if our action consists of { object_index_attribute: :sub_object_index } then it will
  #   build something like "/en/claim-payments/claimant-details?sub_object_index=1"
  # @return [Hash] the param or query contents including the object-index
  def param_or_query_index(param_or_query, action)
    return param_or_query if action[:object_index_attribute].nil?

    index_hash = { action[:object_index_attribute] => action[:object_index].to_i + 1 }
    param_or_query.is_a?(Hash) ? index_hash.merge(param_or_query) : index_hash
  end

  # Creates the query string that will currently be in hash format, to be passed into the path.
  # @return [Hash] the query string contents which is currently in a hash format.
  def query_string_hash(action, object)
    query = action[:query]
    return if query.nil?

    query_hash = {}

    # Builds the query hash contents
    query[:attributes].each { |attribute| query_hash = attribute_to_query_hash(query_hash, attribute, object) }
    query[:filter_model].nil? ? query_hash : { query[:filter_model] => query_hash }
  end

  # Adds the contents of the attribute to the query hash.
  # @return [Hash] the query hash with the new added query instruction
  def attribute_to_query_hash(query_hash, attribute, object)
    label, value = if attribute.is_a?(Symbol)
                     [attribute, object.send(attribute)]
                   else
                     [attribute[:label] || attribute[:attribute],
                      attribute[:value] || object.send(attribute[:attribute])]
                   end

    query_hash[label] = value
    query_hash
  end

  # Extracts the options that are to be passed as html_options to link_to (link tag)
  # @return [Hash] html options for each actions
  def action_options(object, attributes, action)
    options = action[:options] || {}
    options[:id] = "#{action[:id_prefix]}_#{action[:object_index].to_i + 1}" if action[:id_prefix]
    options[:method] = 'delete' if action[:action] == :destroy
    options[:class] = add_action_class_option(options[:class])
    set_action_aria_label_option(object, attributes, action, options)
    set_action_data_option(object, options)
    options
  end

  # Sets up the aria-label option, which will default to the first item of the attributes to be shown.
  # However, if there's no value in the attribute then it will not add an aria-label.
  # @return [String] the value for the aria-label.
  def set_action_aria_label_option(object, attributes, action, options)
    aria_label = action[:aria_label]
    value = object.send((aria_label.nil? ? attributes[0] : aria_label).to_sym)
    return if value.blank?

    options['aria-label'] = "#{action[:label]} for #{value}"
  end

  # Sets up the data option, which modifies it according to its contents.
  # A value of the object can be passed into the text displayed on the confirm box.
  def set_action_data_option(object, options)
    data = options[:data]
    return if data.nil?

    # :data is used for displaying a dialog box, mainly when deleting a row of data or leaving the page.
    # The contents of :confirm is normally a text, but if it's an array, the first item is the translatable text
    # and the second item is attribute of the object which it's value will be added on to the translation.
    # In short, this is a way to pass an object attribute's value to the translation.
    # @example
    # { label: t('.delete_row'), path: :returns_slft_waste_delete_path, parameter: :delete_action_param,
    #   options: { data: { confirm: ['.delete', :ewc_code_and_description] } } }
    return unless data[:confirm].is_a?(Array)

    translatable, attribute = data[:confirm]
    options[:data] = { confirm: t(translatable, value: object.send(attribute)) }
  end

  # Generates the class of the action link, which a custom class can be added from the view.
  # @param existing_class [String] The existing class for the option
  # @param type [Symbol] As this is used for the action, which can be a text or a link, then the two possible
  #   values of this are :link and :text.
  # @return [String] the action link's class option
  def add_action_class_option(existing_class, type = :link)
    classes = ['table_action_item', existing_class]
    classes << 'govuk-link' if type == :link
    classes.compact.join(' ')
  end

  # Builds an array of cells for a body row
  #
  # @param object [Object] The object being processed
  # @param attributes [Array] a collection of attributes related to the objects, these attributes are
  #   to be shown on the table data.
  # @param table_summary [Hash] The hash being used to build up data for the table summary.
  # @param options [Hash] is used for adding extra option class to the specified column by its attribute.
  # @return [Array] An array of HTML cells
  def display_table_body_row_cells(object, attributes, table_summary, options)
    attributes.collect do |attribute|
      attr_options = options[attribute] || {}
      table_data_tag_cell(table_display_value_text(object, attribute, table_summary, attr_options), attribute,
                          attr_options)
    end
  end

  # Sets up an internal hash used to store the values for generating a summary if one is needed
  # @param options [Hash] the hash passed in this will contain the summary tag if one is provided
  # @return [Hash] A hash that is used to drive and hold the summary footer
  def setup_table_summary(options)
    table_summary = options.delete(:summary)
    return if table_summary.nil?

    # Create a nested hash to hold totals for any attributes from any of the summary lines
    # This is then used to hold a list of values that are then totalled or summarised as needed when the footer is
    # produced
    # Need to create and then merge as cannot add into a hash during iteration
    data = {}
    table_summary.each_value do |value|
      array = value[:attributes]
      array.each { |sym| data[sym] = [] }
    end
    table_summary.merge!(data)
  end

  # Builds an array of cells for a  footer row for a given total type
  # @param type [Symbol] the type of total being derived
  # @param type_hash [Hash] the hash of options for this type
  # @param attributes [Array] the list of attributes (cells) in the table
  # @param table_summary [Hash] a hash of options and values to be used to generate a summary footer if required.
  # @param options [Hash] the array of general options
  # @return [array] the array of html for cells on this row
  def display_table_footer_row_cells(type, type_hash, attributes, table_summary, options)
    cols = []
    attributes.each do |attribute|
      attr_opts = options[attribute] || {}
      value = table_footer_label_value(attribute, type_hash[:label])

      # work out what the summary value is, currently only total is supported
      value = table_footer_summary_value(table_summary[attribute], type) if type_hash[:attributes].include?(attribute)
      cols << table_footer_tag_cell(CommonFormatting.format_text(
                                      value, format: attr_opts[:format], break_characters: attr_opts[:break_characters]
                                    ), attr_opts)
    end
    cols
  end

  # Get the label for a table footer row if one is required for this cell
  # @param attribute [Symbol] the name of the attribute cell being process
  # @param label_options [Hash] the options for the label for this row
  # @return String the label value for this cell if required
  def table_footer_label_value(attribute, label_options)
    return '' if label_options.nil?

    label_options[:text] if label_options[:cell] == attribute
  end

  # Get the summary for a table footer row if one is required for this cell
  # @param attribute_values [Array] the array of values for this attribute
  # @param type [Symbol] the type of summary being calculated, currently only total
  # @return [String] the summary value
  def table_footer_summary_value(attribute_values, type)
    return '' if attribute_values.nil?

    attribute_values.sum if type == :total
  end
end
