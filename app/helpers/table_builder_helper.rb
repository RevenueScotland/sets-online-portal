# frozen_string_literal: true

# Base table builder is the utility helper required for any helper that requires the standard table components.
module TableBuilderHelper
  # @return [HTML block element] standard <table> element
  def table_tag(contents, html_options = {})
    return '' if contents.blank?

    template = @template || self
    template.content_tag(:table, contents.html_safe, handle_html_options('govuk-table', html_options))
  end

  # Creates the standard caption tag <caption> of the table.
  def table_caption_tag(caption, html_options = {})
    return '' if caption.blank?

    template = @template || self
    template.content_tag(:caption, caption.html_safe, handle_html_options('govuk-table__caption', html_options))
  end

  # Creates the standard table head tag <thead>, should return an empty string if there's no head.
  def table_head_tag(head, html_options = {})
    return '' if head.blank?

    template = @template || self
    template.content_tag(:thead, head.html_safe, handle_html_options('govuk-table__head', html_options))
  end

  # Creates the standard table body tag <tbody>, should return an empty string if there's no body.
  def table_body_tag(body, html_options = {})
    return '' if body.blank?

    template = @template || self
    template.content_tag(:tbody, body.html_safe, handle_html_options('govuk-table__body', html_options))
  end

  # Creates the standard table footer tag <tfoot>, should return an empty string if there's no footer.
  def table_footer_tag(body, html_options = {})
    return '' if body.blank?

    template = @template || self
    template.content_tag(:tfoot, body.html_safe, html_options)
  end

  # Creates the standard table row <tr> element
  # @return [HTML block element] standard <tr> element
  def table_row_tag(row, html_options = {})
    template = @template || self
    template.content_tag(:tr, row.html_safe, handle_html_options('govuk-table__row', html_options))
  end

  # Creates the standard table heading <th> element
  # @return [HTML block element] standard <th> element
  def table_heading_tag(heading, html_options = {})
    template = @template || self
    template.content_tag(:th, heading, handle_html_options('govuk-table__header', html_options))
  end

  # Creates the standard table data <td> element
  # @return [HTML block element] standard <td> element
  def table_data_tag(data, html_options = {})
    template = @template || self
    template.content_tag(:td, data, handle_html_options('govuk-table__cell', html_options))
  end

  # This is used to get the (formatted) text value from the table object's attribute.
  # If a table summary is being used it also updates the hash to maintain an array of values that need to be
  # summarised
  # @param object [Object] contains the instance of the object where the attribute's value is to be extracted from.
  # @param attribute [Symbol] used to get the value from the object.
  # @param options [Hash] contains the information about how the data should be formatted, if possible.
  # @return [String] the attribute's text value, which is formatted depending on the options[:format] contents.
  def table_display_value_text(object, attribute, options)
    text = object.send(attribute)

    # if we have a table summary and it includes this attribute then add it to the array
    @table_summary[attribute] << text unless @table_summary.nil? || !@table_summary.include?(attribute)

    text = CommonFormatting.format_text(text, options)
    text = object.lookup_ref_data_value(attribute) if options && options[:format] == :lookup_ref

    text
  end

  private

  # This handles the contents of the html options that are to be passed to the element when it's being created.
  def handle_html_options(default_class, html_options)
    return { class: default_class }.merge(html_options) if html_options.blank? || html_options[:class].nil?

    html_options[:class] = "#{default_class} #{html_options[:class]}"
    html_options
  end
end
