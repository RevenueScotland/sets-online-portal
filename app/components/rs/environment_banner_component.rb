# frozen_string_literal: true

# RS specific parts of the UI
module RS
  # Based on the phase banner component but is used to show the environment information
  # see {https://designsystem.gov.scot/components/phase-banner}
  class EnvironmentBannerComponent < ViewComponent::Base
    attr_reader :banner_text, :env_colour

    # returns the text that should be shown in that banner for the environment
    # @param env_name [String] The name of the environment
    def get_reference_desc(env_name)
      env_desc ||= ReferenceData::SystemParameter.lookup('BANNER MESSAGE', 'SYS', 'RSTU',
                                                         safe_lookup: true)[env_name]&.value
      env_desc
    end

    # returns the colour of the banner for the environment
    # @param env_name [String] The name of the environment
    def get_reference_colour(env_name)
      env_colour ||= ReferenceData::SystemParameter.lookup('BANNER COLOUR', 'SYS', 'RSTU',
                                                           safe_lookup: true)[env_name]&.value&.to_s
      %w[005C00 700000 C4B454 000000 FF0000].include?(env_colour) ? "rs_environment_banner_#{env_colour}" : nil
    end

    # Initialize this class, by setting the environment banner details
    def initialize
      env_name ||= ReferenceData::SystemParameter.lookup('DB_NAME', 'SYS', 'RSTU', safe_lookup: true)['DB_NAME']&.value

      super
      @banner_text = get_reference_desc(env_name)
      @env_colour = get_reference_colour(env_name)
    end
  end
end
