# frozen_string_literal: true

# Core user interface components and helpers
# This holds all core logic, except that which is specific to how a particular user interface is rendered
module Core
  # Builds a page link
  class LinkComponent < ViewComponent::Base
    include Core::ListValidator

    attr_reader :url, :name, :options, :subtype

    # Subtypes that are supported by this component
    ALLOWED_SUBTYPES = %i[centered padded previous next button
                          secondary_button banner_link].freeze

    # @param url [Path] The url the link is for
    # @param name [String] the name to show on the link, defaults to url
    # @param target [String] The target tab, if _blank then noopener and noreferrer get added
    # @param delete [Boolean] If this is a delete action, changes the method for turbo
    # @param confirm_message [String] Adds a confirmation message when pressed, normally used with delete
    # @param show_new_tab [Boolean] Shows the open in new tab text when the target is blank.
    #   if set to false the tag is visually hidden
    # @param subtype [Symbol] Subtype of the link
    # @param visually_hidden_text [String] Adds visually hidden descriptive text for the record
    def initialize(url:, name: nil, target: nil, delete: false, confirm_message: nil, show_new_tab: true, # rubocop:disable Metrics/MethodLength
                   subtype: nil, visually_hidden_text: nil)
      super()
      @url = url
      @name = name || url.delete_prefix('https://')
      @options = {}
      visually_hidden_text = append_visually_hidden_text(visually_hidden_text, target, show_new_tab)
      append_span_tag(visually_hidden_text) if visually_hidden_text
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

    # Adds extra options onto the link when it is opening in a new tab
    # as well as adding the opens in new tab text
    # @param target [String] the target for the link
    # @param show_new_tab [Boolean] If false then adds the new tab text as visually hidden
    def handle_blank_target(target, show_new_tab)
      return unless target == '_blank'

      @options = { rel: 'noopener noreferrer' }
      @name = html_escape(@name) + tag.span(" (#{I18n.t('opens_new_tab')})") if show_new_tab

      " (#{I18n.t('opens_new_tab')})" unless show_new_tab
    end

    # Adds appends visually hidden text onto the link
    # @param visually_hidden_text [String] the visually hidden text that to add in span tag
    # @param target [String] the target for the link
    # @param show_new_tab [Boolean] If false then adds the new tab text as visually hidden
    def append_visually_hidden_text(visually_hidden_text, target, show_new_tab)
      return handle_blank_target(target, show_new_tab) if visually_hidden_text.nil?

      return visually_hidden_text + handle_blank_target(target, show_new_tab) if target == '_blank'

      visually_hidden_text
    end

    # Adds visually hidden text onto the span tag
    # @param visually_hidden_text [String] the visually hidden text that to add in span tag
    def append_span_tag(visually_hidden_text)
      @name = html_escape(@name) + tag.span(visually_hidden_text, class: 'visually-hidden')
    end
  end
end
