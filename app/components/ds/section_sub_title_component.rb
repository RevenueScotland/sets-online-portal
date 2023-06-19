# frozen_string_literal: true

# DS specific parts of the UI (normally referencing classes)
module DS
  # Section title component
  class SectionSubTitleComponent < ViewComponent::Base
    attr_reader :section_sub_title

    # @param section_sub_title [String] The sub title of the section
    def initialize(section_sub_title:)
      super()
      @section_sub_title = section_sub_title
    end
  end
end
