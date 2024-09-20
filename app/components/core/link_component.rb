# frozen_string_literal: true

# Core user interface components and helpers
# This holds all core logic, except that which is specific to how a particular user interface is rendered
module Core
  # Builds a page link
  class LinkComponent < ViewComponent::Base
    include Core::ListValidator

    attr_reader :url, :name, :options, :subtype

    # Subtypes that are supported by this component
    ALLOWED_SUBTYPES = %i[centered padded].freeze

    # @param url [Path] The url the link is for
    # @param name [String] the name to show on the link, defaults to url
    # @param target [String] The target window, if _blank then noopener and noreferrer get added
    # @param delete [Boolean] If this is a delete action, changes the method for turbo
    # @param confirm_message [String] Adds a confirmation message when pressed, normally used with delete
    # @param show_new_window [Boolean] Shows the open in new window text when the target is blank.
    #   if set to false the tag is visually hidden
    # @param subtype [Symbol] Subtype of the link
    def initialize(url:, name: nil, target: nil, delete: false, confirm_message: nil, show_new_window: true,
                   subtype: nil)
      super()
      @url = url
      @name = name || url.delete_prefix('https://')
      @options = {}
      handle_blank_target(target, show_new_window)
      @options[:id] = @name.parameterize.underscore
      @options[:target] = target if target
      data = data(delete, confirm_message)
      @options[:data] = data if data.present?
      @subtype = self.class.fetch_or_fallback(ALLOWED_SUBTYPES, subtype, nil) if subtype
    end

    # Utility function to add the subtype class
    # @param subtype_classes [Hash] The classes that apply for each subtype
    def options_with_subtype(subtype_classes)
      return @options if @subtype.nil? || subtype.nil?

      @options.merge({ class: subtype_classes[@subtype] })
    end

    private

    # Creates the data options
    # @param delete [Boolean] If this is a delete action, changes the method for turbo
    # @param confirm_message [String] Adds a confirmation message when pressed, normally used with delete
    def data(delete, confirm_message)
      data = {}
      data[:turbo_method] = :delete if delete
      data[:turbo_confirm] = confirm_message if confirm_message
      data
    end

    # Adds extra options onto the link when it is opening in a new window
    # as well as adding the opens in new window text
    # @param target [String] the target for the link
    # @param show_new_window [Boolean] If false then adds the new window text as visually hidden
    def handle_blank_target(target, show_new_window)
      return unless target == '_blank'

      @options = { rel: 'noopener noreferrer' }
      @name = html_escape(@name) + if show_new_window
                                     tag.span(" (#{I18n.t('opens_new_window')})")
                                   else
                                     tag.span(" (#{I18n.t('opens_new_window')})", class: 'visually-hidden')
                                   end
    end
  end
end
