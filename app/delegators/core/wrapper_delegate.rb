# frozen_string_literal: true

# Core user interface components and helpers
# This holds all core logic, except that which is specific to how a particular user interface is rendered
module Core
  # Provides support to "wrap" a field e.g. hint text, label and errors.
  # Use this on those form components that are not in the standard (see {DS::FieldWrapperComponent})
  # It also records any errors for the field in the error_summary_list content_for (see {DS::ErrorSummaryComponent})
  class WrapperDelegate
    include ActionView::Helpers::FormTagHelper # Include FormTag helpers in this PORO

    delegate :label_text, :label_visually_hidden, :hint_text, to: :labeller
    delegate :formatted_value, to: :formatter

    # @param builder [Object] The current form builder
    # @param method [Symbol] The name of the method being rendered
    # @param type [Symbol] The type of the value if it cannot be auto-detected
    # @param view_context [Object] The view context (template) being used, needed for the page hints
    # @param optional [Boolean] Is the field optional, adds the optional tag on the label
    # @param interpolations [Hash] Hash of options that are passed down to @see LabellerDelegate
    def initialize(builder:, method:, type: :string, view_context: nil, optional: false, interpolations: {},
                   readonly: :readonly)
      @builder = builder
      @method = method
      @view_context = view_context
      @model = @builder.object
      @labeller = LabellerDelegate.new(klass_or_model: @model, method: @method,
                                       action_name: view_context&.action_name&.to_sym,
                                       optional: optional, interpolations: interpolations,
                                       readonly: readonly)
      # The below allows for arbitrary fields that aren't on the model
      value = @model.send(@method) if @model.respond_to?(@method)
      @formatter = FormatterDelegate.new(value: value, type: type)
    end

    # @return [String] the id to use for the hint, also used for aria-describedby
    def hint_id
      @hint_id ||= "#{id}-hint"
    end

    # @return [String] the id to use for the error(s), also used for aria-describedby
    def error_id
      @error_id ||= "#{id}-error"
    end

    # Extract the errors for a given attribute, this routine also stores them for use in an error summary at the top
    # of the page using content_for as list, there are no classes so this is not specific to a UI
    # @return [HTML] The error list
    def error_list
      return @error_list if @error_list

      @error_list = @model.errors.delete(@method)
      @error_list ||= {} # Ensure some value
      return nil if @error_list.blank?

      save_summary_error_list(@error_list)
      @error_list
    end

    # Utility function that adds extra html options to a field for the aria described by and autocomplete if they are
    # needed
    # Classes may be added by a calling routine
    # @param existing_hash The existing hash of html options
    # @return [Hash] the revised hash with the extra options for rendering the field
    def add_html_options(existing_hash, extra_options: {})
      extra_options[:aria] = { describedby: aria_described_by } if aria_described_by.present?
      merge_html_options(existing_hash, extra_options)
    end

    # Normally we don't need to use this as rails generates it for us, but it is needed
    # on field sets
    # @return [String] The base id being used for this field
    def id
      # Note that below method is from FormTagHelper
      @id ||= field_id(@builder.object_name, @method, index: @builder.index)
    end

    private

    attr_reader :labeller, :formatter

    # Adds the hint_id and or error_id to a string for use in the aria-describedby
    # @return [String] The aria described by text
    def aria_described_by
      @aria_described_by ||= "#{hint_id if hint_text.present?} #{error_id if error_list.present?}".strip
    end

    # Save the errors ready for display in the error_summary region
    # called for each attribute and then for any remaining errors
    # @param errors [String] The list of error messages
    def save_summary_error_list(errors)
      href = "##{id}"
      errors.each do |e|
        @view_context.content_for(:summary_error_list, error_list_entry(e, href))
      end
    end

    # Builds an error list entry for the summary region
    # @param error [String] The error message
    # @param href [String] The link url
    def error_list_entry(error, href = nil)
      tag.li(tag.a(error, href: href))
    end

    # Performs a merge of html type hash values returning the values space separated if there are duplicate keys
    # @example
    #   merge_html_options({key1: "value1", class: "class a"}, {key2: "value2", class: "class b"})
    #   => {key1: "value1", key2: "value2", class: "class a class b"}
    # @param this_hash [Hash] One of the hashes to merge
    # @param other_hash [Hash] The other hash to merge
    # @return [Hash] the merged hash
    def merge_html_options(this_hash, other_hash)
      this_hash.merge(other_hash) do |_key, this_val, other_val|
        [this_val, other_val].join(' ')
      end
    end
  end
end
