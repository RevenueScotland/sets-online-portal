# frozen_string_literal: true

# Region helpers for this application, this is best used for displaying values of attributes
# from different objects, with a header and description about what the region is about. In addition,
# action links can also be added to each part of the regions.
#
# The display_region for the data creates a HTML table with 2 or 3 columns (a
# label, a value and optionally a link). So the options are therefore giving classes to add to these
# potentially three columns (label, value, link)
#
# @note data attributes decode are still to be completed, when suitable test data
#   is made available from the back office (i.e. services/taxes for accounts)
#
# This is a visual example of how the table structure looks like for display_region:
#
#               +----------------------+-------------------+-------------------+
# header:       | <table heading>                          | <link> (OPTIONAL) |
#               | (heading_cell_class)                     | (link_cell_class) | row 0
#               +----------------------+-------------------+-------------------+
# description:  | <description>                            | <link> (OPTIONAL) |
#               | (data_cell_class)                        | (link_cell_class) | row 1
#               +----------------------+-------------------+-------------------+
# data:         | <label>              | <value>           | <link> (OPTIONAL) |
#               | (heading_cell_class) | (data_cell_class) | (link_cell_class) | row 2
#               +----------------------+-------------------+-------------------+
#               | <label...>           | ...               | ...               | row ...
#               +----------------------+-------------------+-------------------+
#                 column 0                column 1           column 2
#
#
# This is a visual example of how the table structure may look like when using a display_table_region:
#
#               +------------+------------+------------+------------+-------------------+
# header:       | <table heading>                                   | <link> (OPTIONAL) |
#               | (heading_cell_class)                              | (link_cell_class) | row 0
#               +----------------------+-------------------+-------------------+
# description:  | <description>                            | <link> (OPTIONAL) |
#               | (data_cell_class)                        | (link_cell_class) | row 1
#               +------------+------------+------------+------------+-------------------+
# table:        | <label #1> | <label #2> | <label #3> | <label #4> | <label #N...>     | row 1
#               +------------+------------+------------+------------+-------------------+
#               | <value #1> | <value #2> | <value #3> | <value #4> | <value #N...>     | row 2
#               +------------+------------+------------+------------+-------------------+
#               | <action link(s)>                                                      | row 3
#               +------------+------------+------------+------------+-------------------+
#               | <value #1> | <value #2> | <value #3> | <value #4> | <value #N...>     | row 4
#               +------------+------------+------------+------------+-------------------+
#               | <action link(s)>                                                      | row 5
#               +------------+------------+------------+------------+-------------------+
#                 column 0     column 1     column 2     column 3     column 4

#
# Call the display_region method to use this.
#
# Here are a few key points about what to know in order to be able to use this:
# 1. There are three sections when using the region_helper's display_region to display things, and these are
#   :header, :description and :data.
#     a. :header is placed at the top when displayed, this consists of a heading and a link (which is optional).
#         When being used in the display_region, the :header symbol requires a hash.
#     b. :description is right below the :header, this can consist of a description and a link.
#         When being used in the display_region, the :description symbol requires a hash, similarly to the :header.
#     c. :data is the part where we can show a bunch of information about different objects and it's attributes,
#         this will mainly consist of a list of the attribute's translated texts (label) and value. When being used in
#         the display_region, the :data symbol requires an array of hash. In addition, the data creates a HTML table
#         with 2 or 3 columns (a label, a value and optionally a link). So the options are therefore giving classes to
#         add to these potentially three columns (label, value, link).
# 2. For each of the three sections (:header, :description and :data), here is a full list of symbols/hash that can
#   be passed into them, to fully and easily utilise the region_helper's display_region:
#     a. :header [Hash]
#       - :model [Object] is the instance of an object that contains attribute, to get a value.
#       - :attribute [Symbol] it's value is used as the text displayed as the heading. This is needed when :model is
#         present.
#       - :label [String] this is the text displayed as the heading, only use this when there is no
#         :model and :attribute. In other words, use this when a custom text is needed.
#       - :link [Symbol] to be translated and visually displayed as the text of the link. This is OPTIONAL.
#       - :path [Path] the path of the link. This MUST be used when using :link.
#       - :link_options [Hash] contains options that will be passed as html options for the link e.g. an id.
#         It can also be used to pass down a required action to show the link (using requires_action)
#         @example link_options: { requires_action: AuthorisationHelper::VIEW_MESSAGE_DETAIL, id: 'view_message' }
#         This is OPTIONAL, but best used with the presence of :link and :path.
#     b. :description [Hash]
#       - :model [Object] see the header's :model as they have the same concept
#       - :attribute [Symbol] see the header's :attribute as they have the same concept
#       - :region_description [String] this is the text displayed as the heading, only 3use this when there is no
#         :model and :attribute. In other words, use this when a custom text is needed.
#       - :link [Symbol] see the header's :link as they have the same concept
#       - :path [Path] see the header's :path as they have the same concept
#       - :link_options [Hash] see the header's :link_options as they have the same concept
#     c. :data [Array]
#       - :model [Object] is the instance of an object that contains attribute, to get both the translated text
#         and value of the object's attribute.
#       - :attributes [Array] an array of hashes or symbols which gives instructions about what data to show and how
#         to display that specific row of data.
#         The symbols that are passed will immediately be used as the attribute of the object to display the translated
#         text and value of the attribute.
#         For passing a hash of details, see below for information about what symbols/hash we can use:
#         + :attribute [Symbol] see the header's :attribute as they have the same concept
#         + :format [Symbol] OPTIONAL, used for converting the data to the specified defined data conversions.
#           See format method for a list of symbols that can be assigned to this symbol.
#         + :skip [Symbol|Boolean] OPTIONAL, used for skipping that row of data if the value is blank, so that it won't
#           have to be shown. The two symbols that we can pass are :if_blank and :if_model_blank. A condition on the
#           view can also be passed and it's boolean value will be used to determine whether we do the skip or not.
#         + :link [Symbol] see the header's :link as they have the same concept
#         + :path [Path] see the header's :path as they have the same concept
#         + :link_options [Hash] see the header's :link_options as they have the same concept
#       - :format [Symbol] OPTIONAL, when used here, it adds a :format value to each of the attributes.
#       - :skip [Symbol] OPTIONAL, similar to skip but looks at the model level to determine if it needs
#         to skip displaying all the defined attributes under that model.
# 3. There is also the parameter options [Hash] which takes in a hash of data, this is where we mainly want to put in
#   some custom html_options or any type of options which would affect the parts of the regions depending on where
#   the options are pointing to.
#   To use the options you'll need to pass in at least one of the three hashes with symbols :header, :description, or
#   :data. Each symbol is used to access each of the region's options. See {#options_setup} to learn more about how
#   the options are initially setup.
#   @example This should access the header region's section and look at the table data <td> element and add the class
#     'text_align_center' to it, and it should also look at the description region's section and add the class
#     'background_colour_green' to the table data <td> element.
#     { header: { link_cell_class: 'text_align_center' }, description: { data_cell_class: 'background_colour_green' } }
# 4. Here are some examples of how to use the region_helper's display_region:
#   @example 1
#     <%= display_region( {
#       header: { model: @account, attribute: :account_name, link: :update, path: edit_basic_account_path,
#                 link_options: { requires_action: AuthorisationHelper::UPDATE_PARTY } },
#       description: { region_description: t('hello') },
#       data: [ { model: @account,
#                 attributes: [:email_address, :contact_number] },
#               { model: @account.company,
#                 attributes: [ { attribute: :company_number, skip: :if_blank },
#                               { attribute: :full_address, skip: :if_blank } ],
#                 skip: @account.company.nil? },
#               { model: @account.address,
#                 attributes: [ { attribute: :full_address,
#                                 link: :update, path: edit_address_account_path,
#                                 link_options: { requires_action: AuthorisationHelper::UPDATE_PARTY } } ]
#               } ]
#                             } )
#     %>
#
#   @example 2
#     <%= display_region( {
#       header: { label: t('.edit_calculation') }.merge(calculation_nav_link),
#       description: { region_description: t('.calculation_description') },
#       data: [ { model: @lbtt_return.tax,
#                 attributes: [ { attribute: :calculated },
#                                 { attribute: :ads_due, skip: !@lbtt_return.show_ads? },
#                                 { attribute: :due_before_reliefs, skip: !@lbtt_return.show_ads? },
#                                 { attribute: :total_reliefs },
#                                 { attribute: :total_ads_reliefs, skip: !@lbtt_return.show_ads? },
#                                 { attribute: :tax_due } ],
#                 skip: @lbtt_return.flbt_type != 'CONVEY',
#                 format: :money },
#               { model: @lbtt_return.tax,
#                 attributes: [ { attribute: :npv_tax_due },
#                               { attribute: :premium_tax_due },
#                               { attribute: :total_reliefs,
#                                 skip: %w[LEASEREV ASSIGN TERMINATE].include?(@lbtt_return.flbt_type) },
#                               { attribute: :tax_due },
#                               { attribute: :amount_already_paid,
#                                 skip: !%w[LEASEREV ASSIGN TERMINATE].include?(@lbtt_return.flbt_type) },
#                               { attribute: :tax_due_for_return,
#                                 skip: !%w[LEASEREV ASSIGN TERMINATE].include?(@lbtt_return.flbt_type) } ],
#                 skip: @lbtt_return.flbt_type == 'CONVEY',
#                 format: :money } ]
#       },
#       { header: { link_cell_class: 'text_align_right' },
#         data: { heading_cell_class: 'region_data_heading', data_cell_class: 'text_align_right' } } )
#     %>
module RegionHelper # rubocop:disable Metrics/ModuleLength
  # Creates a standard display region showing data from a series
  # of objects which is passed a list of attributes to be displayed.
  #
  # @param region [Hash] contains a hash of information to display various data in certain
  #   regions. See above for what we can pass in this param, to be able to use it properly.
  # @param options [Hash] contains optional information about how we can display certain parts of the region.
  def display_region(region, options = {})
    return if region.blank?

    header_options, description_options, data_options = options_setup(region, options)
    head = display_header_section(region, header_options)
    body = display_description_section(region, description_options)
    body += display_data_rows_section(region, data_options)
    table_tag(table_head_tag(head) + table_body_tag(body))
  end

  # Creates a standard display region using a table and showing an array of object's data.
  # One row is equivalent to one object's data.
  def display_table_region(region, options = {})
    return if region.blank?

    header_options, description_options, _data_options = options_setup(region, options)

    table = display_table_section(region)
    table[0] = table_head_tag(display_header_section(region, header_options) +
                                display_description_section(region, description_options) + table[0])
    table_tag(table.join)
  end

  private

  # Initializes the options for each part of the region sections.
  # Both options and the html_options are set here.
  #
  # Here are some descriptions about what some of the symbols in the options mean:
  #   - :html_options [Hash] is used to store element's properties, which will be passed into the creation
  #     of the element.
  #   - :header_id [ID] see the comments below on the header_id variable.
  #   - :is_data [Boolean] is actually used to add to the class so that the line below that cell is removed.
  #                        or is used to determine that we're looking at a data, when calling methods.
  #
  # @param item [Hash] consists items regarding the header, description and data regions.
  # @param options [Hash] consists of details about options that will be passed down and used for manipulating
  #   each of the region sections.
  # @return [Array] the options for each of the regions.
  def options_setup(item, options)
    # This is the id of the header's <th> which will be associated with each of the other regions
    # (description and data) when their <th> and <td> elements are created. In addition, this will
    # also be associated with the links created in <td> elements.
    header_id = SecureRandom.uuid
    options[:header] = header_options_setup(options, header_id, colspan_count(item, true))
    options[:description] = description_options_setup(options, header_id, colspan_count(item, false))
    options[:data] = data_options_setup(options, header_id, data_colspan_count(item))

    [options[:header], options[:description], options[:data]]
  end

  # Setting up the options for the header region section
  def header_options_setup(options, header_id, colspan)
    header_options = { html_options: { colspan: colspan }, header_id: header_id }
    return header_options.merge(options[:header]) unless options[:header].nil?

    header_options
  end

  # Setting up the options for the description region section
  def description_options_setup(options, header_id, colspan)
    description_options = { html_options: { colspan: colspan }, header_id: header_id, is_data: true }
    return description_options.merge(options[:description]) unless options[:description].nil?

    description_options
  end

  # Setting up the options for the data region section
  def data_options_setup(options, header_id, colspan)
    data_options = { html_options: { colspan: colspan }, header_id: header_id, is_data: true }
    return data_options.merge(options[:data]) unless options[:data].nil?

    data_options
  end

  # Checks to see if there is a link in the hash passed.
  # @param item [Hash] the hash of items to be checked to see if there exists a link.
  # @return [Boolean] true if link is found.
  def item_has_link?(item)
    return false if item.blank?

    !item[:link].nil?
  end

  # Checks a single :data attribute to see if it has a link.
  # @return [Boolean] does this specific attribute have a link
  def data_has_link?(attribute)
    # The attribute can consist of a hash or a symbol, normally when it's a symbol this also
    # means that it automatically doesn't include any link for that row.
    return false unless attribute.is_a?(Hash)

    item_has_link?(attribute)
  end

  # Checks the array contents of :data to see whether if there is a link found in any of it's attributes.
  # @return [Boolean] true if there is a link found for any attribute.
  def any_data_has_link?(item_data)
    data_has_link = false
    return data_has_link if item_data.blank?

    # Checks each of the attributes of the array found in item[:data] to see if there's a link
    item_data.each do |row_of_data|
      row_of_data[:attributes].each { |attribute| data_has_link = true if data_has_link?(attribute) }
    end
    data_has_link
  end

  # Counts all the table attributes that will be shown. This is also used for determining the colspan required.
  def count_table_attributes(item)
    table = item[:table]
    return 2 if table.blank?

    table_size = table[:attributes].size
    # Checks the :options hash and for each option hash value of the attribute's symbol, check if it is to be skipped.
    # This is what the contents of :options is normally
    #   options: { <attribute>: { skip: <boolean> }, <attribute2>: { class: <class> } }
    table[:options]&.values&.each do |attribute_opt|
      table_size -= 1 if attribute_opt[:skip]
    end

    table_size
  end

  # Calculates the header and description <th> required colspan.
  # @param header [Boolean] is this the header (default) or description
  # @return [Integer] colspan count for header's <th>
  def colspan_count(item, header)
    header_has_link = item_has_link?(item[:header])
    # If we're using a table, then the count will initially depend on the number of attributes that are to be displayed
    # otherwise it will be two
    colspan = count_table_attributes(item)
    # if any of the data has a link (will only be true for non table regions) then add one to the count
    colspan += 1 if any_data_has_link?(item[:data])
    # if the header has a link then take one off to allow for this
    colspan -= 1 if header_has_link && header
    colspan
  end

  # Calculates the colspan required for the :data part of the region, which will be used on the <td> where it
  # contains the value, and not on any of it's link.
  # @return [Integer] colspan count for data's <td> where it contains the value of an attribute.
  def data_colspan_count(item)
    # Base colspan of data region section.
    data_colspan = 1
    # Base colspan increases when we find a link on the data region
    data_colspan += 1 if any_data_has_link?(item[:data])
    data_colspan
  end

  # Creates a standard header field in a row of a table using the header structure supplied. Typically this
  # is used in {#display_region} method. This is different from a data item in that the label is not displayed
  # # @example
  # #   { model: @account, attribute: :account_name, link: :update_account_details, path: edit_account_path }
  # @param item [Hash] a hash of details about the header is to be extracted, see above (2. a.) :header to learn about
  #   the details that can be passed into this hash param.
  # @param options [Hash] consists of options for the header region section.
  # @return [HTML block element] The standard header region section.
  def display_header_section(item, options)
    header = item[:header]
    return '' if header.blank?

    # The region header's heading text, it is stored in a variable for readability purposes.
    header_text = header[:label] || header[:model].send(header[:attribute])

    table_row_tag(
      table_heading_tag(header_text, header_html_options(options)) +
        display_link_cell(header, options)
    )
  end

  # Creates a standard description field in a row of the table. This is always below the header region.
  # Typically this is used in {#display_region} method.
  # @param item [Hash] a hash of details about the description is to be extracted. See (2. b.) :description to learn
  #   about details that can be passed into this hash param.
  # @param options [Hash] consists of options for the description region section
  # @return [HTML block element] The standard description region section. [ <td> | <td link OPTIONAL>]
  def display_description_section(item, options)
    description = item[:description]
    return '' if description.blank?

    # The region description's text, it is stored in a variable for readability purposes.
    description_text = description[:region_description] || description[:model].send(description[:attribute])

    table_row_tag(
      table_data_tag(description_text, description_html_options(options)) +
        display_link_cell(description, options)
    )
  end

  # Creates a standard data rows of a table using the header structure supplied. Typically this
  # is used in {#display_region} method.
  # @example
  #  [
  #    { model: @account, attributes: [:email_address, :contact_number] },
  #    { model: @account.company, attributes:
  #      [ { attribute: :company_number, skip: :if_blank, link: update_account_details, path: edit_account_path},
  #                     :company_name, :full_address ], skip: :if_blank },
  #    { model: @account.address, attributes:  [ { attribute: :full_address, link: update_account_details,
  #                                                path: edit_account_path } ] },

  #  ]
  #
  # @param item [Hash] the array of details about the data is extracted. See (2. c.) :data to learn about details that
  #   can be passed into this hash param.
  # @param options [Hash] consists of options for the data region section
  # @return [HTML block element] an object that uses the details to display the data rows in the standard format, which
  #   is rows of data.
  def display_data_rows_section(item, options)
    # rows = items[:data]
    # If in the display_region([<hash>]) -> if <hash> doesn't have :data then escape.
    return '' if item[:data].blank?

    row_display = ''
    # Look at each rows of hash contents of the array :data
    item[:data].each do |data|
      next if skip?(nil, data)

      # Applies the data conversion options by default on each of the attributes, only if it exists.
      options = add_data_conversion_options(data, options)
      # Look at the hash contents of the array :attributes
      data[:attributes].each do |row|
        row_display += display_data_in_table(data[:model], row, options)
      end
    end
    row_display.html_safe
  end

  # Creates a standard data row of a table using the model and attribute structure supplied. Typically this
  # is used in {#display_region} method.
  # @example
  #  simple attributes:
  #     [:email_address, :contact_number]
  #
  #  complex attributes:
  #      [ { attribute: :company_number, skip: :if_blank, link: update_account_details, path: edit_account_path },
  #                     :company_name, :full_address ] },
  #
  # @param object [Object] the object that owns the attribute to be displayed in a table row, which is normally the
  #   :model part of the hash in an item of the array :data.
  # @param attribute [Symbol/Hash] if it's a symbol, this is used as the label and the value of the object to be
  #   displayed. If it's a hash, see the possible contents of it from the top of this file (2. c.) :data
  #   under the hash :attributes.
  # @param options [Hash] consists of options for the data region section
  # @return [HTML block element] an object that uses the details to display the data row in the standard format, which
  #   is row of data [ <th> | <td> | <td link OPTIONAL> ].
  def display_data_in_table(object, attribute, options)
    # generate unique id for each <th> column and assign it to corresponding <td>
    id = SecureRandom.uuid
    options = data_html_options(options, id)

    # If the contents of the array :attributes is a symbol instead of a hash.
    return display_data_row(object, attribute, options) { nil } unless attribute.is_a?(Hash)
    return '' if skip?(object, attribute)

    # If hash is found, then we need to get the actual attribute from it and apply the options found
    # from the hash.
    attribute_content = attribute[:attribute]
    options = add_data_conversion_options(attribute, options)
    link = display_link_cell(attribute, options.merge(id: id))
    # For the data that has a link, we need to revert the colspan back to 1. The reason lies in {#options_setup}
    # where the base colspan for any data is set to 2 whenever we have a link on any data.
    options[:data_html_options][:colspan] = 1 unless link.nil?
    display_data_row(object, attribute_content, options) { link }
  end

  # Creates a standard display field in a row of a table using the attribute (as the label)
  # and the attribute of the object (as the value). This is used in {#display_region} method.
  #
  # @example
  #   display_data_row(@account.user, :username, {})
  #
  # @yield A yield allows additional columns to be added to the row
  # @param object [Object] see display_data_in_table's object param description.
  # @param attribute [Object] is used as the label and the value of the object to be displayed.
  # @return [HTML block element] see display_data_in_table's object return description.
  def display_data_row(object, attribute, options)
    return '' if object.nil?

    data_text_value = table_display_value_text(object, attribute, options)
    data_text_heading = UtilityHelper.label_text(object, attribute, options)

    table_row_tag(
      table_heading_tag(data_text_heading, options[:heading_html_options]) +
        table_data_tag(data_text_value, options[:data_html_options]) +
        yield
    )
  end

  # Creates the region's section for displaying the table, it uses parts of table_helper when creating this.
  # @see table_helper for more information about this.
  # @param item [Hash] extracts the contents of :table which is used for creating the region's section.
  # @return [Array] with three items, the first item contains the part of the table that should go into
  #   the table head <thead> and the second item is to go into the table body <tbody> and the third the <tfoot>.
  def display_table_section(item)
    # If we're not using the table, or our table's array of models object is empty.
    return Array.new(3, '') if split_table(item[:table]).nil?

    # Partly because of rubocop, all the contents of the :table hash has been split into four variables
    models, attributes, actions, options = split_table(item[:table])

    # To complete the table, it needs to have parts of the head first.
    # @see table_helper#table_heading_row as it's being used to create the row of headings.
    head = table_heading_row(models[0], attributes, options)
    return Array.new(3, '') if head.blank?

    # @see table_helper#display_table_body as this is using that method to create the body of the table.
    body = display_table_body(models, attributes, actions, options)

    footer = display_table_footer(attributes, options)

    [head, body, footer]
  end

  # Splits all the contents of the hash :table and then outputs each of them, which is to be stored into
  # separate variables.
  # @see display_table_section for usage.
  def split_table(table)
    return if table.blank?
    return if table[:models].blank?

    options = table[:options].blank? ? {} : table[:options]
    [table[:models], table[:attributes], table[:actions], options]
  end

  # Skips the model if the model is nil, but if model contains a data then we'll show the attributes that we can show.
  # @return [Boolean] true if contents of the model (object) in the hash is nil or empty or
  #   if the hash doesn't have the key :model.
  def skip_model_blank?(hash)
    !hash.key?(:model) || hash[:model].nil? || (hash[:model].respond_to?(:empty?) && hash[:model].empty?)
  end

  # Normally used for skipping a single row of attribute, if the :skip is present on the hash where
  # the :attribute is defined and if :skip is set to :if_blank and that attribute doesn't contain any value (or nil)
  # then that row should be skipped.
  # @param model [Object] the object to check for nil-ness
  # @param hash [Hash] the hash that contains the skip: :if_blank and :attribute, to be checked for the attribute's
  #   value.
  # @return [Boolean] true if the value of the attribute is nil or empty, or the model is nil.
  def skip_attribute_blank?(model, hash)
    return true if model.nil?

    value = model.send(hash[:attribute])
    value.nil? || (value.respond_to?(:empty?) && value.empty?)
  end

  # Used for skipping a row of attribute(s) depending on where the :skip was defined in the view.
  #
  # This works with the :skip symbol, and it needs to be defined in either the hash with :attribute or :model.
  # @param skip [Boolean] true means that the displaying of that attribute should be skipped.
  # @return [Boolean] true, should skip that row(s).
  def skip_on_boolean(skip)
    return false if skip.is_a?(Symbol) || ![true, false].include?(skip)

    skip
  end

  # Looks at all the possible ways of skipping either a single row of attribute or a model's collection of attributes
  # when being considered to display.
  # @return [Boolean] true then that row(s) of data is to be skipped. If false then don't skip it.
  def skip?(model, hash)
    return false if !hash.is_a?(Hash) || !hash.key?(:skip)

    skip = hash[:skip]
    return skip_model_blank?(hash) if skip == :if_model_blank
    return skip_attribute_blank?(model, hash) if skip == :if_blank

    skip_on_boolean(skip)
  end

  # Creates a standard link block in a table cell.
  # @param hash [Hash] should contain the link to be displayed. This should at least consist of the :link, :path
  #   and it could have the optional :link_options. See above (2. a.) :header for more details of it's contents.
  # @return [HTML block element] the standarad link within a standard table data <td> element for links.
  def display_link_cell(hash, options)
    return unless hash.key?(:link) && authorised?(current_user, hash[:link_options])

    link = hash[:link]
    return if link.nil? # && !authorised?(current_user, hash[:link_options])

    table_data_tag(link_to(t(".link.#{link}"), hash[:path], link_html_options(hash)),
                   link_cell_html_options(options))
  end

  # The data conversion is in the hash where either the :attribute or :model is defined, so this needs to be merged
  # into the options.
  # @param hash [Hash] is where we look for the option :format, to know what the value needs to be converted to.
  # @return [Hash] the options with the merged data conversion options (if it exists).
  def add_data_conversion_options(hash, options)
    # If the data conversion option doesn't exist then we don't have to merge it with the options.
    options = { format: hash[:format] }.merge(options) unless hash[:format].nil?
    # options = { translate_options: hash[:translate_options] }.merge(options) unless hash[:translate_options].nil?
    options = { label: hash[:label] }.merge(options) unless hash[:label].nil?

    options
  end

  # Constructs the html options of the :header section of the region.
  # This is normally passed into the <th> element and used as the element's properties.
  # @return [Hash] html options
  def header_html_options(options)
    # Adding the id is required as per Web Content Accessibility Guidelines
    region_cell_class(options, :heading_cell_class).merge(id: options[:header_id]).merge(options[:html_options])
  end

  # Constructs the html options of the :description section of the region.
  # This is normally passed into the <td> element and used as the element's properties.
  # @return [Hash] html options
  def description_html_options(options)
    # Adding the headers is required as per Web Content Accessibility Guidelines
    region_cell_class(options, :data_cell_class).merge(
      headers: "#{options[:header_id]} #{SecureRandom.uuid}"
    ).merge(options[:html_options])
  end

  # Constructs the html options of the :data section of the region.
  # This is normally passed into the <th> (:heading_html_options) and <td> (:data_html_options)
  # element and used as the element's properties.
  # @return [Hash] html options
  def data_html_options(options, id)
    # Adding the id and headers are required as per Web Content Accessibility Guidelines
    options[:heading_html_options] = region_cell_class(options, :heading_cell_class).merge(id: id)
    options[:data_html_options] = region_cell_class(options, :data_cell_class).merge(
      headers: "#{options[:header_id]} #{id}"
    ).merge(options[:html_options])
    options
  end

  # Constructs the html options of the link anchor tag
  # @return [Hash] html options
  def link_html_options(hash)
    html_options = hash[:link_options]&.reject { |key| key == :requires_action } || {}
    html_options.merge(class: 'govuk-link')
  end

  # Constructs the html options of the table data cell where it consists of the link.
  # @return [Hash] html options
  def link_cell_html_options(options)
    # link_options = hash[:link_options].reject { |key| key == :requires_action }
    # Adding the headers or id is required as per Web Content Accessibility Guidelines
    html_options = options[:is_data] ? { id: options[:id] } : { headers: options[:header_id] }
    html_options.merge(region_cell_class(options, :link_cell_class))
  end

  # The standard class for a region's table cell (either a <td> or <th>)
  # To add into the <th> class, add a heading_cell_class: <class_text_value>
  # To add into the <td> class that consists of a link, add a link_cell_class: <class_text_value>
  # To add into the <td> class consisting of a normal text, add a data_cell_class: <class_text_value>
  # @example when display_region is used
  #   display_region({header: ..., data: ...},
  #     { header: { link_cell_class: 'text_align_right' },
  #       data: { heading_cell_class: 'region_data_heading', data_cell_class: 'text_align_right' } })
  # @param cell_type [Symbol] this is used to point to the correct class options
  # @return [Hash] class key and it's value
  def region_cell_class(options, cell_type)
    option_class = ''
    option_class += ' remove_border_bottom_line' if options[:is_data]
    option_class += " #{options[cell_type]}" unless options[cell_type].nil?
    return {} if option_class.blank?

    { class: option_class }
  end
end
