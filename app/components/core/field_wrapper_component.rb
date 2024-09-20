# frozen_string_literal: true

# Core user interface components and helpers
# This holds all core logic, except that which is specific to how a particular user interface is rendered
module Core
  # This is the standard field wrapper that adds labels, hints and errors to a rendered field
  # It also records any errors for the field in the error_summary_list content_for (see {ErrorSummaryComponent})
  # See {WrapperDelegate} which holds most of the logic
  class FieldWrapperComponent < ViewComponent::Base
    include ListValidator

    attr_reader :builder, :method, :one_question, :type, :show_label, :readonly

    delegate :id, :label_text, :label_visually_hidden, :hint_text, :hint_id, :error_list, :error_id,
             :add_html_options, to: :wrapper

    # List of allowed button types
    ALLOWED_TYPES = %i[field date field_group field_group_inline].freeze

    # @param builder [Object] The current form builder
    # @param method [Symbol] The attribute/field being rendered
    # @param one_question [Boolean] Is this the only field on the page (changes the way the label/header is
    #   rendered)
    # @param optional [Boolean] Is the field optional, adds the optional tag on the label
    # @param show_label [Boolean] Show the label, set to false for e.g. tables
    # @param interpolations [Hash] Hash of options that are passed down to @see LabellerDelegate
    # @param type [Symbol] Used to record the type of field being wrapped, can be used to change rendered html
    def initialize(builder:, method:, one_question: false, optional: false, show_label: true, interpolations: {},
                   type: :field, readonly: false)
      super()
      @builder = builder
      @one_question = one_question
      @method = method
      @optional = optional
      @show_label = show_label
      @interpolations = interpolations
      @type = self.class.fetch_or_fallback(ALLOWED_TYPES, type, :field)
      @readonly = readonly
    end

    # Is the type one of the field group types
    def field_group_type?
      type == :field_group || type == :field_group_inline
    end

    # Set up the wrapper using the view context
    def before_render
      # The wrapper needs the view context
      @wrapper = WrapperDelegate.new(builder: @builder, method: @method,
                                     optional: @optional, interpolations: @interpolations, view_context: view_context,
                                     readonly: @readonly)
    end

    private

    attr_reader :wrapper
  end
end
