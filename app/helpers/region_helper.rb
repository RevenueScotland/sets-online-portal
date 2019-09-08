# frozen_string_literal: true

# Region helpers for this application
# @note data attributes decode are still to be completed, when suitable test data
#   is made available from the back office (i.e. services/taxes for accounts)
module RegionHelper
  # Creates a standard display region showing data from a series
  # of objects which is passed a list of attributes to be displayed.
  #
  # @example
  #  <%= display_regions( [ {
  #  header: { model: @account, attribute: :account_name, link: :update_account_details, path: edit_account_path },
  #  data: [
  #        { model: @account, attributes: [:email_address, :contact_number] },
  #        { model: @account.company, attributes:
  #          [ { attribute: :company_number, skip_blank: true, link: update_account_details, path: edit_account_path},
  #                         :company_name, :full_address ], skip_blank: true },
  #        { model: @account.address, attributes:  [ { attribute: :full_address, link: update_account_details,
  #                                                    path: edit_account_path } ] },
  #        { model: @account, attributes: [ { attribute: :services, combine_array: ', ', decode: decode_service } ] }
  #        ]
  #  } ] ) %>
  #
  # array is an array of hashes, which contains:
  #   header is displayed without a label; link and path are optional
  #   data is an array of hashes
  #     model is the object that owns the attribute to be displayed in that region
  #     attributes is an array of either simple attributes to display, or another hash containing:
  #       attribute the name of the attribute
  #       skip_blank a flag to indicate to omit the row if the value is blank (optional)
  #       link label text for a link (optional)
  #       path link path (optional)
  #       combine_array combine the elements of the array into one value, using the value to combine them
  #       decode name of a function on the controller to decode the element [TODO]
  #     skip_blank a flag to indicate to omit the rows if the object is blank
  def display_regions(array)
    return if array.nil? || array.empty?

    body = ''
    array.each do |item|
      # Each headers attribute should list the ids of all th elements associated with that cell.
      header_id = SecureRandom.uuid
      body += display_header_in_table(item[:header], header_id) if item.key?(:header)
      body += display_data_rows_in_table(item[:data], header_id) if item.key?(:data)
    end
    content_tag(:table, body.html_safe, class: 'govuk-table')
  end

  # Creates a standard display region showing data from an object
  # which passes in a list of attributes to be displayed. The list
  # of attributes is used to generate both the label and value.
  # The value is taken from the attribute of the object.
  #
  # There is also a title which is displayed on its own.
  # @example
  #   display_region(
  #                  @user,
  #                  [:email_address],
  #                  :username
  #                 )
  # @param object [Object] the object that owns the attribute to be displayed in the region
  # @param attributes [Array] list of the data that consists of label and the value of the object to be displayed.
  # @param title (optional) can pass in a title which is displayed on its own
  # @return [HTML block element] the current standard format of a region to be displayed,
  #   which is displayed as a table. If no object is found then nil.
  def display_region(object, attributes, title = nil)
    return if object.nil?

    body = ''
    body += content_tag(:tr, content_tag(:td, object.send(title)), class: 'govuk-table__row') unless title.nil?
    attributes.each do |attribute|
      body += display_field_in_table(object, attribute)
    end
    content_tag(:table, body.html_safe, class: 'govuk-table')
  end

  private

  # Creates a standard display field in a row of a table
  # using the attribute (as the label) and the attribute of the
  # object (as the value).
  #
  # This is used in {#display_region} method.
  #
  # @example
  #   display_field_in_table(
  #                          @account.user
  #                          :username
  #                         )
  #
  # A yield allows additional columns to be added to the row
  #
  # @param object [Object] the object that owns the attribute to be displayed in a table row.
  # @param attribute [Object] is used as the label and the value of the object to be displayed.
  # @param id [String] is assign to the corresponding
  # @param header_id [String] is assigned to the corresponding 'td'.Required as per Web Content Accessibility Guidelines
  # @param translation_options [String] use a different translation key from the same model translation path
  # @return [HTML block element] an object that uses the label and value in the standard format, which
  #   is a row of data. If no object is found then nil.
  def display_field_in_table(object, attribute, header_id, id, translation_options = nil)
    additional_cols = yield

    # TODO: CR RSTP-580 it'd be great if there was a way to use the default translations too, eg make it so if
    #       translation_options started with "." it used "object.model_name.i18n_key" (see below) and if it didn't
    #       then it wouldn't.  Then lbtt/en.yml's submit_return_reference_text could be moved to the generic one.
    # allow overriding the label text
    label = translation_options.present? ? translation_options : attribute
    content_tag(
      :tr, content_tag(:th,
                       t(label, default: '', scope: [object.i18n_scope, :attributes, object.model_name.i18n_key]),
                       class: 'govuk-table__header', id: id) +
                        content_tag(:td, object.send(attribute), class: 'govuk-table__cell',
                                                                 headers: "#{header_id} #{id}") + additional_cols,
      class: 'govuk-table__row'
    )
  end

  # Creates a standard header field in a row of a table using the header structure supplied. Typically this
  # is used in {#display_regions} method. This is different from a data item in that the label is not displayed
  # @example
  #   { model: @account, attribute: :account_name, link: :update_account_details, path: edit_account_path }
  #
  #   model is the object that owns the attribute to be displayed in that region
  #   attribute the name of the attribute
  #   link label text for a link (optional)
  #   path link path (optional)
  #   link_options link options (for example requires_action) (optional)
  #
  # @param header [Hash] a hash of details about the header
  # @param header_id [String] is assigned to the corresponding 'td'.Required as per Web Content Accessibility Guidelines
  # @return [HTML block element] an object that uses the details to display the header in the standard format, which
  #   is a row of data. If no object is found then nil.
  def display_header_in_table(header, header_id)
    return if header.nil?

    content_tag(
      :tr, content_tag(:th, header[:model].send(header[:attribute]),
                       class: 'govuk-table__header', colspan: 2, id: header_id) + display_link_cell(header, header_id),
      class: 'govuk-table__row'
    )
  end

  # Creates a standard data rows of a table using the header structure supplied. Typically this
  # is used in {#display_regions} method.
  # @example
  #  [
  #    { model: @account, attributes: [:email_address, :contact_number] },
  #    { model: @account.company, attributes:
  #      [ { attribute: :company_number, skip_blank: true, link: update_account_details, path: edit_account_path},
  #                     :company_name, :full_address ], skip_blank: true },
  #    { model: @account.address, attributes:  [ { attribute: :full_address, link: update_account_details,
  #                                                path: edit_account_path } ] },
  #    { model: @account, attributes: [ { attribute: :services, combine_array: ', ', decode: decode_service } ] }
  #  ]
  #
  #  model is the object that owns the attribute to be displayed in that region
  #  attributes is an array of either simple attributes to display, or another hash containing:
  #    attribute the name of the attribute
  #    skip_blank a flag to indicate to omit the row if the value is blank (optional)
  #    link label text for a link (optional)
  #    path link path (optional)
  #    link_options link options (for example requires_action) (optional)
  #    combine_array combine the elements of the array into one value, using the value to combine them
  #    decode name of a function on the controller to decode the element [TODO]
  #  skip_blank a flag to indicate to omit the rows if the object is blank
  #
  # @param rows [Array] an array of details about the data
  # @param header_id [String] is assigned to the corresponding 'td'.Required as per Web Content Accessibility Guidelines
  # @return [HTML block element] an object that uses the details to display the data rows in the standard format, which
  #   is a rows of data. If no object is found then nil.
  def display_data_rows_in_table(rows, header_id)
    return if rows.nil? || rows.empty?

    row_display = ''
    rows.each do |item|
      next if skip_blank?(item, :model)

      item[:attributes].each do |data|
        row_display += display_data_in_table(item[:model], data, header_id)
      end
    end
    row_display
  end

  # returns true if :skip_blank key is present in the hash and set to true, and if the
  # key in the hash is missing or the value is nil, or empty where supported
  # @param hash [Hash] the hash that contains the skip_blank key/value and the key with value
  # @param key [Key/String] the key to check for blankness in the hash
  # @return true if :skip_blank key is present in the hash and set to true, and if the
  # key in the hash is missing or the value is nil, or empty. Otherwise false
  def skip_blank?(hash, key)
    return false unless hash.key?(:skip_blank) || hash[:skip_blank]

    !hash.key?(key) || hash[key].nil? || (hash[key].respond_to?(:empty?) && hash[key].empty?)
  end

  # returns true if :skip_blank key is present in the hash and set to true, and if the
  # key in the hash is missing or the value on the model is nil, or empty where supported
  # @param model [Object] the object to check for nil-ness
  # @param hash [Hash] the hash that contains the skip_blank key/value and the key with value
  # @return true if :skip_blank key is present in the hash and set to true, and if the
  # key in the hash is missing or the value is nil, or empty. Otherwise false
  def skip_attribute_blank?(model, hash)
    return true if model.nil?

    return false unless hash.key?(:skip_blank) || hash[:skip_blank]

    value = model.send(hash[:attribute])

    value.nil? || (value.respond_to?(:empty?) && value.empty?)
  end

  # Creates a standard data row of a table using the model and attribute structure supplied. Typically this
  # is used in {#display_regions} method.
  # @example
  #  simple attributes:
  #     [:email_address, :contact_number]
  #
  #  complex attributes:
  #      [ { attribute: :company_number, skip_blank: true, link: update_account_details, path: edit_account_path},
  #                     :company_name, :full_address ] },
  #
  #  attribute the name of the attribute
  #  skip_blank a flag to indicate to omit the row if the value is blank (optional)
  #  link label text for a link (optional)
  #  path link path (optional)
  #  link_options link options (for example requires_action) (optional)
  #  combine_array combine the elements of the array into one value, using the value to combine them
  #  decode name of a function on the controller to decode the element [TODO]
  #
  # @param model [Object] the object that owns the attribute to be displayed in a table row.
  # @param attribute [Key/String] is used as the label and the value of the object to be displayed.
  # @param header_id [String] is assigned to the corresponding 'td'.Required as per Web Content Accessibility Guidelines
  # @return [HTML block element] an object that uses the details to display the data row in the standard format, which
  #   is a rows of data.
  def display_data_in_table(model, attribute, header_id)
    # generate unique id for each th column and assign it to corresponding td
    id = SecureRandom.uuid
    return display_field_in_table(model, attribute, header_id, id) { empty_cell(id) } unless attribute.is_a?(Hash)
    return '' if skip_attribute_blank?(model, attribute)

    value = attribute[:attribute]
    value = value.join(attribute[:combine_array]) if value.is_a?(Array) && attribute.key?(:combine_array)
    display_field_in_table(model, value, header_id, id, attribute[:translation_options]) do
      display_link_cell(attribute, id)
    end
  end

  # Creates a standard link block in a table cell, or blank cell if the attributes are missing
  # @param hash [Hash] the text to display
  # @param header_id [String] is assigned to the corresponding 'td'.Required as per Web Content Accessibility Guidelines
  # @return [HTML block element] an object that uses the text and path to construct a link within a table cell
  def display_link_cell(hash, header_id = '')
    return empty_cell(header_id) unless hash.key?(:link) && authorised?(current_user, hash[:link_options])

    content_tag(:td, link_to(t('.link.' + hash[:link].to_s), hash[:path], class: 'govuk-link'),
                class: 'govuk-table__cell', headers: header_id)
  end

  # Creates an empty cell
  # @param header_id [String] is assigned to the corresponding 'td'.Required as per Web Content Accessibility Guidelines
  # @return [HTML block element] an object that's an empty cell
  def empty_cell(header_id)
    content_tag(:td, '', class: 'govuk-table__cell', headers: header_id)
  end
end
