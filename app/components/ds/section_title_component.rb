# frozen_string_literal: true

# DS specific parts of the UI (normally referencing classes)
module DS
  # Section title component
  class SectionTitleComponent < ViewComponent::Base
    attr_reader :section_title

    # @param section_title [String] The title of the section
    def initialize(section_title:)
      super()
      @section_title = section_title
    end
  end
end
