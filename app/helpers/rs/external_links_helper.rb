# frozen_string_literal: true

# RS specific UI items
module RS
  # Returns the specific link required from the back office cross reference data
  module ExternalLinksHelper
    # @return [String] a link associated with particular link code
    # @param link_code [String] is a PRM_CODE mapped to the link.
    def external_link_url(link_code)
      ReferenceData::SystemParameter.lookup('PWS_LINKS', 'SYS', 'RSTU')[link_code].value
    end
  end
end
