# frozen_string_literal: true

# Revenue Scotland Specific UI code
module RS
  # Renders a table of sites from {Returns::Slft::Site} in one of two formats
  class SiteTableComponent < ViewComponent::Base
    include DS::ComponentHelpers
    include Core::ListValidator

    # Format of the sites deleted_sites is used for description
    ALLOWED_FORMATS = %i[sites deleted_sites].freeze

    # Used as object to get the total of given columns
    class Total
      attr_reader :net_lower_tonnage, :net_standard_tonnage, :exempt_tonnage, :total_tonnage

      def initialize(sites)
        @net_lower_tonnage = @net_standard_tonnage = @exempt_tonnage = @total_tonnage = 0
        sites&.each_value do |site|
          @net_lower_tonnage = site.net_lower_tonnage + @net_lower_tonnage
          @net_standard_tonnage = site.net_standard_tonnage + @net_standard_tonnage
          @exempt_tonnage = site.exempt_tonnage + @exempt_tonnage
          @total_tonnage = site.total_tonnage + @total_tonnage
        end
      end
    end

    attr_reader :sites, :caption, :region_name, :id, :link, :small_screen, :totals, :format

    # @param sites [Array] The array of sites
    # @param caption [String] The caption to use on the table
    # @param id [String] The id of the table used for anchoring
    # @param link [HTML] A link to display below the tables, used for e.g. linking to all messages
    # @param small_screen [Symbol] How to display the table on a small screen
    # @param format [Symbol] Are we rendering the sites as a deleted_sites or normal
    def initialize(sites:, caption:, id:, link: nil, small_screen: nil, format: :sites)
      super()

      @sites = sites
      @totals = Total.new(sites)
      @region_name = caption
      @caption = tag.h2(caption, class: 'ds_!_margin-bottom--0')
      @id = id
      @link = link
      @small_screen = small_screen
      @format = self.class.fetch_or_fallback(ALLOWED_FORMATS, format, :sites)
    end
  end
end
