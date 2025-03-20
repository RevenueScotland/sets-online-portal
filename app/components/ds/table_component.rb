# frozen_string_literal: true

# DS specific parts of the UI (normally referencing classes)
module DS
  # A table component this consists of one header and many rows
  # see {https://designsystem.gov.scot/components/table}
  # see {TableComponent::HeaderComponent}
  # see {TableComponent::RowComponent}
  class TableComponent < ViewComponent::Base
    include Core::ListValidator

    renders_one :header, DS::TableComponent::HeaderComponent
    renders_many :rows, DS::TableComponent::RowComponent
    renders_many :links, DS::LinkComponent
    renders_one :footer, DS::TableComponent::FooterComponent

    attr_reader :caption, :id, :small_screen

    # List of options for handling the small screen
    ALLOWED_SMALL_SCREEN = %w[scrolling boxes].freeze

    # @param caption [String] The caption for the table
    # @param id [String] The id for the table, should identify it on the screen, used for anchoring for example
    # @param small_screen [String] How to handle small screens
    # see {https://designsystem.gov.scot/components/table}
    def initialize(caption:, id: nil, small_screen: nil)
      super()

      @caption = caption
      @id = id
      @small_screen = self.class.fetch_or_fallback(ALLOWED_SMALL_SCREEN, small_screen, 'scrolling') if small_screen
    end
  end
end
