# frozen_string_literal: true

# helper for creating application specific table
module TableHelper
  # This is a main method to creates a standard table using gds style and classes
  # @param objects [Object] a collection require to build table
  # @param attributes [Symbol] is the attribute of the object, which can be considered as a method of it too.
  # @param actions [Hash] the link actions to be created for that row. See include_action? and action_tag for
  #   the extra parameters.
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
    return if objects.nil? || objects.empty?

    table(table_head_tag(objects[0], attributes, options) + table_body_tag(objects, attributes, actions, options))
  end

  private

  # Create table tag
  # @param contents [HTML block element] the contents to be wrapped in a table element
  # @return [HTML block element] the standard table-wrapped contents with the appropriate class
  def table(contents)
    content_tag(:table, contents, class: 'govuk-table')
  end

  # create table header applying gds CSS classes
  # This is using {#header_column_tag} to create the table header and
  # @param attributes [Array] a collection of attributes related to the object, these are the attributes
  #   to be shown on the table header.
  # @return [HTML block element] the standard table head element with the appropriate classes
  def table_head_tag(object, attributes, options)
    return if object.nil?

    cols = attributes.collect do |attribute|
      label = t(attribute, default: '', scope: [object.i18n_scope, :attributes, object.model_name.i18n_key])
      header_column_tag(attribute, options[attribute], label)
    end

    tr_tag = content_tag(:tr, cols.join('').html_safe, class: 'govuk-table__head')

    content_tag(:thead, tr_tag, class: 'govuk-table__head')
  end

  # create table header column applying gds CSS class
  # @param label [String] is the text that is passed in for the table header contents
  # @return [HTML block element] the standard table header element with the appropriate class
  def header_column_tag(attribute, options, label = '')
    content_tag(:th, label, class: detail_column_class_list(attribute, options, ['govuk-table__header']))
  end

  # create table data column applying gds CSS class
  # @param text [String] is the text passed in for the contents of the table data element
  # @param attribute [Object] is the attribute of the object, normally it won't have an attribute if it's used for
  #   action links.
  # @param options [Hash] is used to add extra information into this attribute
  # @return [HTML block element] the standard table data element with the appropriate class
  def detail_column_tag(text = '', attribute = nil, options = {})
    options = {} if options.nil?
    td_class = detail_column_class_list(attribute, options).join(' ')
    text = detail_column_text(text, options)
    content_tag(:td, text, options.merge!(class: td_class))
  end

  # The standard class for the attribute's table cell with the added extra class from options extracted and applied.
  # @return [Array] a list of classes which are to be combined
  def detail_column_class_list(attribute, options, column_class = ['govuk-table__cell'])
    # Class to remove border bottom line as for the attributes we don't want to put a line below it. This is because
    # their action links are below its row of data. If there's an attribute then it means that it's an action and
    # therefore the bottom line should not be remove so that it a divider between each objects can be seen.
    column_class << 'remove_border_bottom_line' if !attribute.nil? && !column_class.include?('govuk-table__header')

    # Adds a format specific class onto the column
    column_class << 'money_format' if !options.nil? && options[:format] == :money
    column_class
  end

  # Modifies the text if it needs to be
  def detail_column_text(text, options)
    text = CommonFormatting.format_text(text, options)

    # Puts the text in new lines for each '\n' found in the text
    text = new_lines_detail(text)
    text
  end

  # For texts that should consist of new lines, this will put it on the next line down.
  # @return [String] a html safe string with the break line added
  def new_lines_detail(text)
    return text unless text.to_s.include?("\n") || text.to_s.include?("\302")

    # replaces all of \n with a break line
    text.gsub!("\n", '<br />')
    text.html_safe
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
  # @return [HTML block element] the standard table body element with the appropriate class
  # @note I cannot seem to find another way of making this method smaller without altering
  def table_body_tag(objects, attributes, actions, options)
    return if objects.nil?

    rows = objects.collect do |object|
      # Collects each of the attributes from the object which is placed in a table data.
      cols = attributes.collect do |attribute|
        detail_column_tag(object.send(attribute), attribute, options[attribute])
      end
      # Creating the two rows:
      # 1. first one is the row of the collected attributes data of the object,
      # 2. the second one is the row of actions related to that object of which it's attributes data are shown.
      table_row_tag(cols, highlight_row_class(object)) +
        table_row_tag(table_row_action_columns(actions, cols, object))
    end
    content_tag(:tbody, rows.join('').html_safe, class: 'govuk-table__body')
  end

  # Creates the table row tag with a specified row class options if defined.
  # @param row_data_list [Array] contains an array of table data which will be joined
  # @param row_class_options [String] class options for row only
  def table_row_tag(row_data_list, row_class_options = '')
    content_tag(:tr, row_data_list.join('').html_safe, class: "govuk-table__row#{row_class_options}")
  end

  # This is used to determine whether an item is to be highlighted or not.
  #
  # It should skip the objects that doesn't have the :selected attribute.
  # @param object [Object] is the instance of the object to be looked at
  # @return [String] returns the value of the class for highlighting the row
  def highlight_row_class(object)
    return '' unless object.respond_to?(:selected)

    # Checks the object's selected attribute to see if it's been selected or not, to highlight the row.
    return ' govuk-focus-colour' if object.send(:selected)

    ''
  end

  # create table row for actions column
  #
  # Skips the item in the list that are selected, used for the messages. If the row is selected
  # which means that it is currently being viewed, then do not put the action links for it.
  # @param actions [Array] an array of actions to be pushed into a column
  # @param cols [Array] is the array that contains all the table data <td> elements of that row, which is
  #   only used to find out how big the size of it for the colspan of the action row.
  # @param object [Object] the object with attributes to which the action to be shown is connected to.
  # @return [Array] an array consisting of HTML table data of the action anchor elements
  def table_row_action_columns(actions, cols, object)
    # creating column for actions
    action_cols = ''
    actions.nil? || actions.each do |action|
      # If row is highlighted (in other words 'selected' in show messages) then the action link doesn't need to be
      # shown for it.
      # And if the action is not included for that row of data, then don't show it.
      action_cols += action_tag(action, object) + '&emsp;&emsp;'.html_safe if highlight_row_class(object) == '' &&
                                                                              include_action?(action, object)
    end
    [detail_column_tag(action_cols.html_safe, nil, colspan: cols.size)]
  end

  # This method is used to check if the action link should be visible or not. Also
  # checks if there are link_options that specify any authorisation actions, and if so
  # this method checks those as well.
  #
  # Action options relevant to this method:
  #   1. action[:visible_for] contains a single method of the object that is passed as param,
  #   that method should return a boolean value of true for the action link to be considered
  #   to be shown.
  #   2. action[:link_options] containing the :requires_action or :requires_action_path to check
  #   if authorized to have this action link. @see include_auth_actions
  #
  # Only used for {table_row_action_columns}
  # @param action [Hash] is a hash which should contain :visible_for for this method to check the object's methods
  #   and :link_options to check if authorized.
  # @param object [Object] is the object holding the methods that the contents of the :visible_for symbol will
  #   match with, to determine if action link is to be shown or not.
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

  # Create action tag like edit, show more details available at url
  # https://guides.rubyonrails.org/routing.html#creating-paths-and-urls-from-objects
  #
  # Action options relevant to this method:
  #   1. action[:path] can be set to define an actual path (ie to another controller)
  #   2. action[:method_path] to call a method from the object to get the path.
  #   3. action[:parameter] passes any 1 attribute's value from the object that creates the table
  #   4. action[:label] sets the label of the link.
  #   5. action[:action] rails standard routes path (e.g. :show, :new, etc.)
  #   6. action[options] contains a hash of options that will be directly passed into the link_to method.
  #
  # @param action [Object] is a hash containing the label to the action and the action itself
  # @param object [Object] is the object holding attributes that can be used for the specific action
  # @return [HTML block element] the standard action element which consists of an anchor
  #   element with link related to the parameter value of object.
  def action_tag(action, object) # rubocop:disable Metrics/AbcSize
    options = action[:options]
    return link_to(action[:label], nil, options) if action[:action] == :nil

    # If action[:parameter] is defined then get that value from the object; this will be used to pass param values.
    param = action[:parameter].nil? ? object : object.send(action[:parameter]).to_s
    # Sets the link's path to the object method's path
    return link_to(action[:label], send(object.send(action[:method_path]), param), options) if action[:method_path]
    # Sets the link's path to the path name
    return link_to(action[:label], send(action[:path], param), options) if action[:path]

    if action[:action] == :show
      link_to(action[:label], object, options)
    else
      link_to(action[:label], [action[:action], object], options)
    end
  end
end
