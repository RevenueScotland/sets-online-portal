# frozen_string_literal: true

# DS specific parts of the UI (normally referencing classes)
module DS
  # A table component that handles forms this consists of one header and many rows
  # The rows can support form elements
  # see {https://designsystem.gov.scot/components/table}
  # see {TableComponent::HeaderComponent}
  # see {TableComponent::FormRowComponent}
  class TableFormComponent < ViewComponent::Base
    include Core::ListValidator

    renders_one :header, lambda { |**args|
      DS::TableComponent::HeaderComponent.new(action_header: @action_header, **args)
    }
    renders_many :form_rows, lambda { |**args|
                               TableComponent::FormRowComponent.new(
                                 builder: @builder, delete_link: @delete_links, **args
                               )
                             }

    attr_reader :caption, :id, :small_screen

    # The list of allowed options for handling a small screen
    ALLOWED_SMALL_SCREEN = %w[scrolling boxes].freeze

    # @param builder [Object] The current form builder
    # @param caption [String] The caption for the table
    # @param id [String] The id for the table, should identify it on the screen, used for anchoring for example
    # @param small_screen [Symbol] How to handle small screens
    # @param add_link [Boolean] Show an add row link
    # @param delete_links [Boolean] Show delete row links (defaults onto the individual rows)
    # see {https://designsystem.gov.scot/components/table}
    def initialize(builder:, caption: nil, id: nil, small_screen: nil, add_link: false, delete_links: false)
      super()

      @id = id
      @small_screen = self.class.fetch_or_fallback(ALLOWED_SMALL_SCREEN, small_screen, 'scrolling') if small_screen
      @caption = caption
      @builder = builder
      @add_link = add_link
      @delete_links = delete_links
      @action_header = delete_links # If delete links have been requested then create an action header
    end

    private

    # Should the add link be shown
    def add_link?
      @add_link
    end

    # Returns the add link
    def add_link
      button_tag(t('.add_row'), name: 'add_row', class: 'ds_link')
    end
  end
end
