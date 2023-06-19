# frozen_string_literal: true

# Main handling all of the DS functions to support an application
module DS
  # Inline Text Component
  #
  # Allows field to be in a fieldset group with an optional separate header and hint text
  # Alignment is be default horizontal, but can also be switched to vertical
  # NOTE: Vertical alignment does not work with select components as the select component width is incorrect
  # This is an issue within the DS styling
  #
  # Based on Digital Scotland Pattern {https://designsystem.gov.scot/components/text-input/}
  class FieldSetComponent < ViewComponent::Base
    include Core::ListValidator

    attr_reader :legend, :hint, :alignment

    # List of allowed alignments
    ALLOWED_ALIGNMENTS = %i[horizontal vertical].freeze

    # @param legend [Boolean] Legend for the in line field
    # @param hint [Boolean] Hint for the in line field
    # @param alignment [Boolean] Alignment
    def initialize(legend: nil, hint: nil, alignment: :horizontal)
      super()
      @legend = legend
      @hint = hint
      @alignment = self.class.fetch_or_fallback(ALLOWED_ALIGNMENTS, alignment, :horizontal)
    end
  end
end
