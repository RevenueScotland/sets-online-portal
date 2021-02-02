# frozen_string_literal: true

# The print data module allows you to define a layout in the supporting object that generates JSON with a given format
# that is passed to the back office to allow them to format a PDF with the questions and answers and visibility rules
# as we hold them
#
# To do this you define a print layout method in the object which returns an array made up of the sections that you
# want printed.
#
# There are three types of sections:
#   list, which has a list of items that you want included
#   table, which also includes a list of items that you want included but lists them in a table when printed
#   object, which create a section by calling the sections method on the underlying object
#
# Each section support the follow hash codes
#   code: A code for the section, for object type section this is the method to call to get the array of objects
#   name: The method to call on the option to get the name of the section e.g. when the section is based on an object
#         and you want the name of that particular object
#   key: The key to use to get the name of the section if name not provide, e.g. the name of a page
#   key scope: The scope used to get the key
#   type: see above
#   divider: true or false, passed through to the docmosis template to say if you want a line above the section
#   display_title: true or false, passed through to the docmosis template to say if the name should be displayed
#
# For a list type section then you provide an array of list_items, each item supports the following hash codes
#   code: The code for the item, the attribute name, this method is called to get the value shown in the template
#   format: passed through to the docmosis template, may also have an impact in the generated attribute value
#           :money - Passed to docmosis to use a money format with a pound sign
#           :date - The value is a date to be formatted as dd Month YYYY
#           :list - When the value is an array, and there is a lookup list,  format as Yes/No against each lookup value
#   key_scope: If passed overrides the standard scope for getting the item label, otherwise the standard
#              object scope is used, note the translation obeys the translation attributes overrides
#   placeholder: If passed overrides the standard value from the attribute. This is of the form <%STRING%>
#                this is replace by the back office before the format is save. The list is agreed with the back
#                office and is used to insert values that we don't have e.g. reference
#   lookup: true or false, This tells the code to lookup the description of the value, this uses the
#           reference lookup concern
#   lookup_boolean: true or false, this tells the code to translate a boolean value to Yes and No
#   when: and is: and is_not: tells the code to check the value of the when method and only show the item if
#                             the value is/is not in the array provided
#
# For an object type section then the code iterates over the array of objects provided by the method
# calling the print_layout on those objects to create a section (or sections) for each object
#
# For a table type section then the hash supports the following
#   row_cells: This contains an array of one or more list_items (each list_item generates a
#              rowcell in the template. Each list_items can contain one or more items
#              as for the list items above for a normal list section.
#              If there is one item in the list_items then the rowcell is generated with the value
#              If there are multiple items then the label : value is generated in the cell
#              If there is one item then the header of the table is generated with the label for
#              the attribute, otherwise it is left blank
#
# NOTE: some of the names and pluralisation is controlled by the template in use on the back office
#
# @example
#        [{ code: :about_transaction, # section code
#           key: :transaction_subtitle, # key for the title translation
#           key_scope: %i[returns slft summary], # scope for the title translation
#           type: :list, # type list = the list of attributes to follow
#           list_items: [{ code: :year, lookup: true },
#                        { code: :fape_period, lookup: true },
#                        { code: :non_disposal_delete_ind, lookup: true },
#                        { code: :non_disposal_delete_text, when: :non_disposal_delete_ind, is: ['Y'] }] },
#         { code: :sites,
#           type: :object }]
#
module PrintData # rubocop:disable Metrics/ModuleLength
  extend ActiveSupport::Concern

  # Defines the print format
  class PrintData
    attr_accessor :section

    # creates the print data
    # @param sections [Array] the sections being rendered
    # @return [PrintData] an instance of print data
    def initialize(sections)
      @section = sections
    end
  end

  # Defines the format for a section of the print; this can either be a list or a table
  # object type sections are rendered into either a list or a table
  class SectionData
    attr_accessor :sectioncode, :sectiontitle, :sectiontype, :pagebreak, :listitem, :tableheadings, :tablerow,
                  :sectiondivider, :displaytitle, :itemcount, :tablerowcount, :tablecolumncount

    # Creates a section
    # The parent section options are used for the first section when a section is based on an array
    # of objects. This allows headers to be provided for the start of the list of objects rather than for
    # each individual object
    # @param object [Object] the object being rendered
    # @param section_options [Hash] the hash being used to render this section
    # @param objects [Array] an array of objects when rendering a table
    # @param parent_section_options [Hash] the hash for the parent section when processing objects
    # @param extra_data [Hash] a hash of extra data keyed on an arbitrary value
    # @return [SectionData] an instance of section data
    def initialize(object, section_options, objects = nil, parent_section_options = nil, extra_data = nil)
      use_parent_title = (parent_section_options || {})[:use_parent_title]
      # Pass the parent options down for initialisation if needed
      initialize_section_options(section_options, (use_parent_title ? parent_section_options : {}))

      @sectiontitle = object.section_name(section_options, parent_section_options, extra_data)

      if sectiontype == :list
        list_specific_items(object, section_options, extra_data)
      else
        table_specific_items(objects, extra_data)
      end
    end

    private

    # Initialises the basic section options
    # The parent details are only used if the option is not provided for this section
    # The rules are
    #   Use the current section option if the value is provided
    #   else use the parent section value
    # @param section_options [Hash] the hash being used to render this section
    # @param parent_section_options [Hash] The parent section details
    def initialize_section_options(section_options, parent_section_options)
      @sectioncode = set_value(section_options, parent_section_options, :code)
      @sectiontype = set_value(section_options, parent_section_options, :type)
      @sectiondivider = set_value(section_options, parent_section_options, :divider)
      @pagebreak = set_value(section_options, parent_section_options, :page_break)
      @displaytitle = set_value(section_options, parent_section_options, :display_title)
    end

    # Set the individual option value based on the rule
    #   Use the current section option if the value is provided
    #   else use the parent section value
    # @param section_options [Hash] the hash being used to render this section
    # @param parent_section_options [Hash] The parent section details
    # @param key [Symbol] The key being processed
    def set_value(section_options, parent_section_options, key)
      return section_options[key] if section_options.key?(key)

      parent_section_options[key]
    end

    # Override the section options
    # This overrides previously set values based on those passed in if they are specified
    # @param section_options [Hash] the hash being used to render this section
    def override_section_options(section_options)
      # Note we can't use || as the values may be false
      @sectioncode = section_options[:code] if section_options.key?(:code)
      @sectiontype = section_options[:type] if section_options.key?(:type)
      @sectiondivider = section_options[:divider] if section_options.key?(:divider)
      @pagebreak = section_options[:page_break] if section_options.key?(:page_break)
      @displaytitle = section_options[:display_title] if section_options.key?(:display_title)
    end

    # For tables, loops around the array of objects and gets a row of data for each object
    # The data is split into row cells
    # @param objects [Array] an array of objects when rendering a table
    # @param extra_data [Hash] a hash of extra data keyed on an arbitrary value
    # @return [Array] an array of strings with one entry per object
    def tablerow_array(objects, extra_data)
      tablerow = []
      objects.each do |object|
        tablerow << RowData.new(object.row_cells(extra_data))
      end
      tablerow
    end

    # sets the list specific items
    # @param section_options [Hash] the hash being used to render this section
    # @param extra_data [Hash] a hash of extra data keyed on an arbitrary value
    def list_specific_items(object, section_options, extra_data)
      @listitem = object.list_items(section_options[:list_items], extra_data)
      @itemcount = @listitem.count
    end

    # Creates the table specific items
    # @param objects [Array] an array of objects when rendering a table
    # @param extra_data [Hash] a hash of extra data keyed on an arbitrary value
    def table_specific_items(objects, extra_data)
      @tableheadings, @tablecolumncount = objects[0].table_headings(extra_data)
      @tablerow = tablerow_array(objects, extra_data)
      @tablerowcount = @tablerow.count
    end
  end

  # Defines the format for an item being printed
  # An item is normally the value which we have recorded but for some items e.g. the return reference
  # at the time of submission to the back office we don't know what they are so we pass a placeholder value
  # that the back office can replace
  class ItemData
    attr_accessor :itemcode, :itemlabel, :itemformat, :itemdata

    # creates an item
    # @param object [Object] the object being rendered
    # @param item_options [Hash] the hash being used to render this item
    # @param extra_data [Hash] a hash of extra data keyed on an arbitrary value
    # @return [ItemData] an instance of item data
    def initialize(object, item_options, extra_data)
      @itemcode = item_options[:code]
      @itemformat = item_options[:format]
      unless item_options[:nolabel]
        @itemlabel = object.this_label(item_options[:code], item_options[:key_scope], item_options,
                                       extra_data)
      end

      @itemdata = object.this_value(item_options[:code], item_options[:lookup],
                                    item_options[:format], item_options[:placeholder])
    end
  end

  # Defines the format for a row of data being printed
  # this is an array of cells
  class RowData
    attr_accessor :rowdata

    # initialises a row data item
    # blank items must still have a place holder
    # @param rowdata [Array] a an array of cells
    # @return [RowData] an instance of item data
    def initialize(rowdata)
      @rowdata = rowdata
    end
  end

  # Defines the format for a cell in a row of data being printed
  # a cell is either one item in which case it just contains the value
  # or an array of items in which case the format is label:value
  class RowCell
    attr_accessor :rowcell

    # initialises a row cell item
    # blank items must still have a place holder
    # @param object [Object] the object being rendered
    # @param list_items [Array] the one or more items in this cell
    # @param extra_data [Hash] a hash of extra data keyed on an arbitrary value
    # @return [RowCell] an instance of the cell which is an array of strings
    def initialize(object, list_items, extra_data)
      list_items_count = list_items.count
      @rowcell = []
      list_items.each do |item|
        next unless object.include_item_or_section?(item[:when], item[:is], item[:is_not], extra_data)

        @rowcell << rowcell_value(object, item, list_items_count, extra_data)
      end
    end

    private

    # Gets the individual item value
    # @param object [Object] the object being rendered
    # @param item [Hash] the hash containing an individual item
    # @param item_count [Integer] the number of items in this cell
    # @param extra_data [Hash] a hash of extra data keyed on an arbitrary value
    # @return [String] the formatted string for this item
    def rowcell_value(object, item, item_count, extra_data)
      this_value = object.this_value(item[:code], item[:lookup], item[:format],
                                     item[:placeholder])
      if item_count == 1 || item[:nolabel]
        this_value
      else
        "#{object.this_label(item[:code], item[:key_scope], item, extra_data)} : #{this_value}"
      end
    end
  end

  # This is the routine to call to get the actual data formatted correctly
  # basically it just adds the out wrapping section tag for the JSON
  # The translation options enables extra values to be passed in to assist in
  # looking up the translation keys
  # @param extra_data [Hash] a hash of extra data keyed on an arbitrary value
  # @param layout [Symbol] The method to call on the model for the layout, the default is :print_layout
  # @return [Json] The json format of the wrapped sections for the printing
  def print_data(layout = :print_layout, extra_data = nil)
    PrintData.new(sections(layout, extra_data)).to_json
  end

  # This is the main routine is loops through the sections defined on the underlying object from
  # the #print_layout method and then builds the sections and the items/tables that make it up.
  # @param layout [Symbol] The method to call on the model for the layout, the default is :print_layout
  # @param extra_data [Hash] a hash of extra data keyed on an arbitrary value
  # @param parent_section [Hash] The options for the parent section used when processing objects
  # @param first_object [Boolean] Set if processing objects and this is the first object, used to control headings
  # @return [hash] the sections to be printed; may be merged into a parent object
  def sections(layout, extra_data, parent_section = nil, first_object: false)
    layout_print = send(layout)

    section_list = []

    # loop around each section rendering it in turn
    layout_print.each_with_index do |section, i|
      next if section.nil?

      Rails.logger.debug("Section #{section[:code]} Type #{section[:type]} Extra Data #{extra_data.inspect}")
      next if skip_section(section, parent_section, extra_data)

      section_list += process_section(layout, section, extra_data, parent_section,
                                      (first_object && i.zero? ? true : false))
    end
    section_list # return the section list
  end

  # Creates the row headings for a table for this object by looping round the items and extracting the labels
  # @param extra_data [Hash] a hash of extra data keyed on an arbitrary value
  def table_headings(extra_data)
    tableheadings = []
    print_layout.each do |section|
      row_cells = section[:row_cells]
      raise Error::AppError.new('table_headings', 'No Row Cells defined') if row_cells.nil?

      tableheadings += table_cell_headers(row_cells, extra_data)
    end
    [tableheadings, tableheadings.count]
  end

  # Creates the data row for a table for this object by looping round the items and extracting the values
  # @param extra_data [Hash] a hash of extra data keyed on an arbitrary value
  def row_cells(extra_data)
    rowdata = []
    print_layout.each do |section|
      rowdata += row_cell_items(section[:row_cells], extra_data)
    end
    rowdata
  end

  # Derives the section name for this object and section
  # if the section options includes a :name item then this method is called on this object
  # otherwise the passed :key and :scope are used
  # @param section_options [Hash] the hash being used to render this section
  # @param parent_section_options [Hash] the hash for the parent section if an object
  # @return [string] the section name to use
  def section_name(section_options, parent_section_options, extra_data)
    section_name = extract_name(parent_section_options)
    section_name = extract_name(replace_section_name(section_options, extra_data)) if section_name.nil?
    section_name
  end

  # Returns the array of attributes and values (the list items) for this object based on the items list passed in
  # The item can contain a visibility check @see include_item_or_section?
  # @param list_items [Array] The array of item hashes being used to render this section
  # @param extra_data [Hash] a hash of extra data keyed on an arbitrary value
  # @return [Array] the array of items to render
  def list_items(list_items, extra_data)
    list = []
    list_items.each do |item|
      next unless include_item_or_section?(item[:when], item[:is], item[:is_not], extra_data)

      list << ItemData.new(self, item, extra_data)
    end
    list
  end

  # Derives the label for this item, takes account of any overrides
  # defined in the #translation_attribute method on the object
  # @param code [string] The name of the attribute
  # @param key_scope [string] The scope for the translation
  # @param options [Hash] The hash of options
  # @param extra_data [Hash] a hash of extra translation options keyed on a value
  # @return [string] the label for this item
  def this_label(code, key_scope, options, extra_data)
    options ||= {}
    # Set the value of the translations options if a key was passed in to the item that is present in the extra data
    unless options[:translation_extra].nil? || extra_data.nil?
      options[:translation_options] = extra_data[options[:translation_extra]]
    end
    options[:key_scope] = i18n_item_scope(key_scope)

    label = UtilityHelper.label_text(self, code, options)
    # Make sure breaks turn into returns for printing
    label = label.gsub('<br>', "\n")
    # strip any other HTML out of the labels
    sanitizer = Rails::Html::FullSanitizer.new
    sanitizer.sanitize(label)
  end

  # Derives the value for this item either the value or the lookup value where lookup is specified.
  # It is possible that the value can be an array (where the user has checked multiple boxes) if so then this is
  # returned as a comma separated list (the default) or as a list of descriptions and yes or no (if the format is list)
  # @param code [string] The name of the attribute
  # @param lookup [boolean] if a lookup value should be used
  # @param format [Symbol] The format of the value drives any formatting, this is normally passed to the template
  # @param placeholder [String] placeholder string, if present then this is returned and is replaced at the back office
  # @return [string] the value for this item
  def this_value(code, lookup, format, placeholder)
    return placeholder unless placeholder.nil?

    values = send(code)
    values = [values] unless values.respond_to? :each

    if lookup && format == :list
      this_value_list_format(code, values)
    else
      this_value_standard_format(code, values, lookup, format)
    end
  end

  # Derives if this item should be included some items are only included when a
  # linked field has a certain value, or does not have a certain value
  # @param when_method [Symbol] The method to be called, or the extra data key
  # @param is_array [Array] The array of values to check the result against positively, or the symbol nil
  # @param is_not_array [Array] The array of values to check the result against negatively, or the symbol nil
  # @param extra_data [Hash] a hash of extra translation options keyed on a value
  # @return [Boolean] should this value be included
  def include_item_or_section?(when_method, is_array, is_not_array, extra_data)
    return true if when_method.nil?

    value = include_item_or_section_value(when_method, extra_data)
    response = value_is_in_check(value, is_array, true) && !value_is_in_check(value, is_not_array, false)
    Rails.logger.debug(
      "Include Check #{when_method} Value #{value} is in #{is_array} is not in #{is_not_array} response: is #{response}"
    )
    response
  end

  private

  # Derives the value for an item where the format is list
  # This only applies where the values has an associated lookup list.
  # For each item in the list it says if it was selected or not e.g.
  #   Lookup description 1 : Yes
  #   Lookup description 2 : No
  # Used where the original field was a list of check boxes based on a list
  # @param code [string] The name of the attribute
  # @param values [Array] The list of values
  # @return [string] The list of lookup values and if they were selected or not separated by a return
  def this_value_list_format(code, values)
    return_values = []
    list_ref_data(code).each do |r|
      flag = (values.include?(r.code) ? 'Yes' : 'No')
      return_values << "#{r.value} : #{flag}"
    end
    return_values.join("\n")
  end

  # Derives the value for this item for a standard (non list) layout
  # This is the value or the lookup value where there is a linked code value.
  # If the value is an array (e.g. where the user has checked multiple boxes) this is returned as a comma separated list
  # @param code [string] The name of the attribute
  # @param values [Array] The list of values
  # @param lookup [boolean] if a lookup value should be used
  # @param format [Symbol] The format of the value drives any formatting, this is normally passed to the template
  # @return [string] the value for this item
  def this_value_standard_format(code, values, lookup, format)
    return_values = []
    values.each do |v|
      expand_value = expand_value(code, v, lookup, format)
      return_values << expand_value unless expand_value.nil?
    end
    return_values.join(', ')
  end

  # Returns the array of values for a row for this object based on the items list passed in
  # The item can contain a visibility check @see include_item_or_section? but if not visible an empty string is returned
  # @param cell_items [Array] The array of cell hashes being used to render this section
  # @param extra_data [Hash] a hash of extra translation options keyed on a value
  # @return [Array] the array of values
  def row_cell_items(cell_items, extra_data)
    list = []
    cell_items.each do |cell|
      list << RowCell.new(self, cell[:list_items], extra_data)
    end
    list
  end

  # Returns the array of headers for a row for this object based on the items list passed in
  # @param row_cells [Array] The array of row_cells being used to render this section
  # @param extra_data [Hash] a hash of extra data keyed on an arbitrary value
  # @return [Array] the array of header labels
  def table_cell_headers(row_cells, extra_data)
    list = []

    row_cells.each do |cell|
      list << if cell[:list_items].count == 1
                item = cell[:list_items][0]
                this_label(item[:code], item[:key_scope], item, extra_data) unless item[:nolabel]
              else
                ''
              end
    end
    list
  end

  # Derives the scope for label translations either using teh key_scope passed in or based on the underlying model
  # @param key_scope [Array] The key scope passed in from the config
  # @return [string] the key scope that will be used
  def i18n_item_scope(key_scope)
    key_scope || [i18n_scope, :attributes, model_name.i18n_key]
  end

  # Processes an individual section based on the options passed in
  # note that it returns an array as the section may be based on a list of objects
  # in which case each object is a section
  # @param section_options [Hash] The options to be used for this section
  # @param extra_data [Hash] a hash of extra data keyed on an arbitrary value
  # @param parent_section_options [Hash] The options for the parent section when this is an object
  # @param use_parent_title [Boolean] Should you use the parent section to generate the section headers
  # @return [Array] the sections rendered
  def process_section(layout, section_options, extra_data, parent_section_options, use_parent_title)
    # for table and object types get the list of objects
    # skip if there are none
    if %i[object table].include?(section_options[:type])
      objects = make_sure_array(send(section_options[:code]))

      return [] if objects.nil? || objects.count < 1 # we need to return an empty array not nil
    end

    if %i[list table].include?(section_options[:type])
      # always return an array so wrap this in an array
      parent_section_options[:use_parent_title] = use_parent_title unless parent_section_options.nil?
      [SectionData.new(self, section_options, objects, parent_section_options, extra_data)]
    else # object
      process_objects_section(replace_section_name(section_options, extra_data), layout, objects, extra_data)
    end
  end

  # need to make sure that response is an array
  # we may get a hash, an array or a single object from the call
  # so need to convert, not it needs to go through both checks
  # @param objects the response from an object method
  # @return [Array] an array of what was passed in
  def make_sure_array(objects)
    return if objects.nil?

    objects = objects.values if objects.respond_to?(:values)
    objects = [objects] unless objects.respond_to?(:each)
    objects
  end

  # Processes an object section by looping around the objects
  # @param parent_section [Hash] The parent section being processed
  # @param objects [Array] the array of objects to be iterated around
  # @param extra_data [Hash] a hash of extra data keyed on an arbitrary value
  # @return [Array] the sections rendered
  def process_objects_section(parent_section, layout, objects, extra_data)
    return if objects.nil?

    section_list = []
    objects.each_with_index do |object, i|
      extra_data ||= {}
      # We're passing in the index of the object so that we can use it with things like showing or hiding a row of data
      # depending on the index of the object.
      extra_data[:object_index] = i
      section_list += object.sections(layout, extra_data, parent_section, first_object: (i.zero? ? true : false))
    end
    section_list
  end

  # Derives the value for this item either the value or the lookup value where there is a linked code value.
  # @param code [string] The name of the attribute, needed for lookups
  # @param value [String] the value of the attribute
  # @param lookup [boolean] if a lookup value should be used
  # @param format [Symbol] The format of the value drives any formatting, this is normally passed to the template
  # @return [string] the expanded value for this item
  def expand_value(code, value, lookup, format)
    return nil if value.blank?
    return lookup_ref_data_value(code, value) if lookup
    return value.to_date.strftime('%d %B %Y') if format == :date

    value
  end

  # Gets the value for the include item processing
  # @param when_method [Symbol] The method to be called, or the extra data key
  # @param extra_data [Hash] a hash of extra translation options keyed on a value
  # @return [Object] The value to be checked
  def include_item_or_section_value(when_method, extra_data)
    Rails.logger.debug("When Method #{when_method} (#{respond_to?(when_method)}) Extra Data #{extra_data.inspect}")

    if !extra_data.nil? && extra_data.key?(when_method)
      extra_data[when_method]
    else
      unless respond_to?(when_method)
        raise Error::AppError.new('include_item_or_section_value', "#{when_method} is not defined")
      end

      send(when_method)
    end
  end

  # Derives if this item should be included some items are only included when a
  # linked field has a certain value, or does not have a certain value
  # @param value [Object] The value to be checked
  # @param check [Array or Symbol] The array to be compared against or the symbol :nil if this is a nil check
  # @param default [Boolean] The value to be returned if there is no check
  # @return [Boolean] Does the value match the check
  def value_is_in_check(value, check, default)
    return default if check.nil? # if nothing to check then return default
    return check.include?(value) unless check == :nil?

    value.nil? || value.blank? if check == :nil?
  end

  # Derives the section name
  # The original section name contains a name (which is a method to be called) and/or
  # a translation key and scope.
  # The name method will have already been called if present (see #replace_section_name)
  # This routine generates the title as
  #   Translated Key
  #   Result of method
  #   Translated Key (result of method)
  # @param section_options [Hash] the hash being used to render this section
  # @return [string] the section name to use
  def extract_name(section_options)
    return if section_options.nil?

    name = section_options[:name]
    unless section_options[:key].nil?
      name = I18n.t(section_options[:key], scope: section_options[:key_scope]) +
             (name.nil? ? '' : "(#{name})")
    end
    name
  end

  # Processes the section details to handle the title
  # This may be being done on the parent section for an object in the context of a parent
  # or for the child object
  # It turns a key with a replace #key_value# into a string and a name method into the value
  # @param section_options [Hash] the hash being used to render this section
  # @return [Hash] the revised hash
  def replace_section_name(section_options, extra_data)
    section_options = replace_section_name_key(section_options, extra_data)
    replace_section_name_name(section_options)
  end

  # This turns a key with a replace #key_value# into a string
  # @param section_options [Hash] the hash being used to render this section
  # @return [Hash] the revised hash
  def replace_section_name_key(section_options, extra_data)
    # If the key is a string replace value and turn it into a symbol
    unless section_options[:key].nil?
      # The :key_value can be used as the method to be called from the model OR
      # it can be called from the print_data's extra_data parameter.
      key_value = section_options.delete(:key_value)
      unless key_value.nil?
        value = extra_data.blank? || extra_data[key_value].nil? ? send(key_value) : extra_data[key_value]
      end
      key = section_options[:key]
      section_options[:key] = key.sub('#key_value#', value).to_sym if key.is_a? String
    end

    section_options
  end

  # It turns a a name method into the value
  # @param section_options [Hash] the hash being used to render this section
  # @return [Hash] the revised hash
  def replace_section_name_name(section_options)
    # Get the value associated with the method in the name key
    unless section_options[:name].nil?
      name_options = section_options[:name]
      unless name_options.is_a? String
        section_options[:name] = this_value(name_options[:code], name_options[:lookup],
                                            name_options[:format], name_options[:placeholder])
      end
    end
    section_options
  end

  # Decides if a section should be skipped
  # if it is
  #    nil?
  #    An object being processed for a parent that doesn't have this section
  #    The visibility rules exclude it
  # @param section [Hash] the section being processed
  # @param parent_section [Hash] The options for the parent section used when processing objects
  # @param extra_data [Hash] a hash of extra data keyed on an arbitrary value
  # @return [true] Should the section be skipped
  def skip_section(section, parent_section, extra_data)
    return true if section.nil? # allows for suppressed sections
    # Skip sections which are restricted to certain parent codes for objects
    return true unless section[:parent_codes].nil? || parent_section.nil? ||
                       section[:parent_codes].include?(parent_section[:code])
    # Skip sections which have visibility rules
    return true unless include_item_or_section?(section[:when], section[:is], section[:is_not], extra_data)

    Rails.logger.debug("Section #{section[:code]} Not Skipped")
    false
  end
end
