# frozen_string_literal: true

module ReferenceData
  # Represents Notification banner text details which are downloaded from the back office and cached.
  class SystemNotice < ReferenceDataCaching
    attr_accessor :link, :code, :page, :show_from, :show_till, :complete_ind
    attr_writer :title

    # Create a new instance of this class using the back office data given.
    # @param data [Hash] data from the back office response
    # @note return [Object] a new instance
    private_class_method def self.make_object(data)
      show_from = data[:show_from_date_time].to_time
      show_till = data[:show_until_date_time] if data[:show_until_date_time].present?

      SystemNotice.new(domain_code: data[:target_system], service_code: 'SYS',
                       workplace_code: data[:workplace_code], title: data[:notice_title],
                       link: data[:more_info_url], code: data[:refno], page: data[:unavailability_type],
                       show_from: show_from, show_till: show_till,
                       complete_ind: data[:completed_indicator])
    end

    # Checks the details needs to be displayed under notification banner is valid
    # based on the page and the current time
    # @param display_page [String] The page being displayed
    # @return [Boolean] Is this valid based on the page and the current time
    def valid_notice?(display_page)
      return true if Time.zone.now.between?(show_from, (show_till || Time.zone.now)) &&
                     complete_ind != true && (page == display_page || page == 'ALL')

      false
    end

    # If there is a link make sure the title ends with a '. '
    # @return The title with a '. ' if there is a link
    def title
      return @title unless link

      # handle the most common cases next
      return "#{@title}. " unless @title.ends_with?('. ', '.')
      return "#{@title} " if @title.ends_with?('.')

      @title
    end

    # Calls the correct service and specifies where the results are in the response body
    private_class_method def self.back_office_data
      lookup_back_office_data(:list_system_notices, { WorkplaceCode: 'RSTU', TargetSystem: 'PWS', CurrentOnly: true },
                              :system_notices)
    end
  end
end
