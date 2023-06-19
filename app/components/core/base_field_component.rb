# frozen_string_literal: true

# Core user interface components and helpers
# This holds all core logic, except that which is specific to how a particular user interface is rendered
module Core
  # Defines a base Core field component with standard attributes, this is kept in synch with {FieldWrapperComponent}
  # as most of the options are passed through to that component for rendering
  class BaseFieldComponent < ViewComponent::Base
    attr_reader :builder, :method, :one_question, :optional, :show_label, :interpolations

    delegate :formatted_value, to: :formatter

    # @param builder [Object] The current form builder
    # @param method [Symbol] The method on the object being rendered
    # @param readonly [Boolean] Is the field read only
    # @param disabled [Boolean] Is the field disabled, note that a disabled field is not submitted
    # @param one_question [Boolean] Is this the only field on the page, this changes the way the label is rendered
    # @param optional [Boolean] Is the field optional, adds the optional tag on the label
    # @param show_label [Boolean] Show the label, set to false for if you don't want the label to be visible on a
    #   specific instance (e.g. in tables). If you never want a method to have a visible label then use a visually
    #   hidden label
    # @param autocomplete [String] An autocomplete tag {https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/autocomplete}
    # @param interpolations [Hash] Hash of options that are passed down to @see LabellerDelegate
    # @param data_options [Hash] A hash of one or more data options to add to the field, used for stimulus
    def initialize(builder:, method:, readonly: false, disabled: false, one_question: false, optional: false, # rubocop:disable Metrics/MethodLength
                   show_label: true, autocomplete: nil, interpolations: {}, data_options: {})
      super()
      @builder = builder
      @method = method
      @readonly = readonly
      @disabled = disabled
      @one_question = one_question
      @optional = optional
      @show_label = show_label
      @autocomplete = autocomplete
      @interpolations = interpolations
      @data_options = data_options.transform_keys { |k| "data-#{k}" }
    end

    # Utility function to create a hash of the extra option
    def add_html_options(existing_options)
      { readonly: @readonly, disabled: @disabled, autocomplete: @autocomplete }.merge(@data_options)
                                                                               .merge(existing_options)
    end

    private

    # Returns the formatter or creates it
    def formatter
      return @formatter if @formatter

      # The below allows for arbitrary fields that aren't on the object
      value = @builder.object.send(@method) if @builder.object.respond_to?(@method)
      @formatter = Core::FormatterDelegate.new(value: value, type: :automatic)
    end
  end
end
