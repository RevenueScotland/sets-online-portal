# frozen_string_literal: true

# Generic helpers for this application
module ApplicationHelper # rubocop:disable Metrics/ModuleLength
  include RegionHelper
  include AuthorisationHelper

  # Provides the appropriate language links replacing the locale on the current path.
  #
  # @todo
  #   Needs improving to render a list of languages and also to provide the list
  #   based on the configured list of locales. Also not hardcode the language text.
  def language_links
    case I18n.locale
    when :cy
      link_to 'English', request.path.sub(%r{\A/cy(/|\z)}, '/cy/' => '/en/', '/cy' => '/en'),
              class: 'site-items__link', target: '_self'
    when :en
      link_to 'Cymru', request.path.sub(%r{\A/en(/|\z)}, '/en/' => '/cy/', '/en' => '/cy'),
              class: 'site-items__link', target: '_self'
    end
  end

  # Provides link to account-handling actions, which is shown at the header area.
  #
  # Link to account-handling actions include paths to login,
  # logout and account page. It checks for the current user
  # and will pass signed in users to the {#signed_in_user_links}.
  #
  # To pass in options, do <% content_for :nav_bar_options, { <options> } %> in the html page where <options> is a
  # hash of options.
  #
  # @param options [Hash] options for creating the account_links. Currently supported are: hide_nav_elements
  # @return [HTML link element] the appropriate links.
  def account_links(options = nil)
    return if !options.nil? && options[:hide_all]

    if current_user.nil?
      unless current_page?(controller: '/login', action: 'new')
        content_tag(:li, link_to(t('signin'), login_path), class: 'govuk-header__navigation-item')
      end
    else
      signed_in_user_links nav_options(options)
    end
  end

  # Creates a standard display field outside of a table of data.
  # It is using the attribute (as the label) and the attribute of the
  # object (as the value).
  # @example
  #   display_field(
  #                 @account.user,
  #                 :username
  #                )
  # @param object [Object] the object that owns the attribute to be displayed.
  # @param attribute [Object] is used as the label and the value of the object to be displayed.
  # @return [HTML block element] an object that uses the label and value in the standard format, which
  #   is a label and span containing the value. If no object is found then nil.
  def display_field(object, attribute, options = {})
    return if object.nil?

    content_tag(:div, label(@object_name, t(attribute, default: '', scope: [object.i18n_scope, :attributes,
                                                                            object.model_name.i18n_key]),
                            class: ' govuk-label') + display_field_text(object, attribute, options),
                class: 'govuk-form-group')
  end

  # Gets the text for the display field using the attribute of the object with the options applied.
  # @param object [Object] the object that owns the attribute to be displayed.
  # @param options [Hash] consists of the extra options used to modify the text.
  # @return [HTML block element] the standard text used for a normal display field.
  def display_field_text(object, attribute, options)
    text = CommonFormatting.format_text(object.send(attribute), options)
    content_tag(:span, text, class: options[:class])
  end

  # Create a list of navigational links.
  #
  # Input parameter includes a collection of link data and options to
  # override an HTML attribute of ul element. This is using the
  # {#navigational_link} method to create the standard navigational
  # link for each item.
  #
  # e.g.
  #      links = [
  #               {link: :attribute-name1, path: redirect_path1 },
  #               {link: :attribute-name2, path: redirect_path2}
  #              ]
  # Additional options on the navigation link can be passed as a hash with options.
  # These options will be tagged onto the HTML as an HTML element attribute.
  # To override default html element attribute of li used list_options and
  # for hyperlink used link_options.
  #
  # e.g.
  #     link = [{link: :attribute-name1,
  #              path: redirect_path1,
  #              list_options:{class:'css class of li'},
  #              link_options:{class:'css class of hyper link',target:'_blank'}}]
  # To add hint text for hyperlink arrange translation file as per an example given below
  #   en:
  #     views:
  #       view:
  #         link:
  #           attribute-name: 'link text'
  #           hint:
  #             attribute-name: 'link hint text'
  # If links array contain only one record then display link without unordered list
  def navigational_links(links, options = { class: 'govuk-list govuk-list--bullet' })
    li_contents = ''
    return navigational_link(links[0]) if links.size == 1

    links.each do |link|
      link_content = navigational_link(link)
      next if link_content.nil?

      link[:additional_text_options] = { class: 'span-padding-left-5' } if link[:additional_text_options].nil?
      li_contents += content_tag(:li, link_content, link[:list_options])
    end
    content_tag(:ul, li_contents.html_safe, options)
  end

  # This determines the web browser currently being used, by retrieving the user agent and parsing it through.
  # @return [String] Here are some of the output of it:
  #   'Internet Explorer'
  #   'Firefox'
  #   'Edge'
  #   'Chrome'
  def application_browser
    UserAgent.parse(request.user_agent).browser.to_s
  end

  # Display the standard error region.
  #
  # If there are no errors on the passed object the error region is not rendered.
  # @param object active record or active model object with linked errors
  # @return [HTML element block] standard error region. If no error is passed.
  def form_errors_for(object = nil, options = nil)
    render('layouts/form_errors', object: object, do_not_show_attributes: false, options: options) unless object.blank?
  end

  # Same as #form_errors_for but does not show the attribute name in validation messages
  def form_errors_without_attributes(object = nil, options = nil)
    render('layouts/form_errors', object: object, do_not_show_attributes: true, options: options) unless object.blank?
  end

  # Returns the attribute name in the error region taking into account and translation overrides on the model
  # @param object [Object] active record or active model object for which errors are being displayed
  # @param attr [Symbol] the attribute for which the errors are being displayed
  # @param options [Hash] a hash of extra information to pass to the translation_attribute method
  # @return the translated human attribute name
  def error_attribute_name(object, attr, options)
    return object.class.human_attribute_name(attr).tr('?', '') unless object.respond_to?(:translation_attribute)

    extra_info = error_attribute_name_extra(attr, options)
    object.class.human_attribute_name(object.translation_attribute(attr, extra_info, true)).tr('?', '')
  end

  # Builds the header menu for an authenticated user.
  # This is used in the {#account_links} method.
  #
  # If the password has almost expired and optional link is shown to reset the password
  #
  # The logout link is aways shown.
  # @return [HTML link element] with links to the dashboard, account details and logout.
  def signed_in_user_links(options)
    # NB '/accounts' rather than 'accounts' so that this method works from different namespaces
    # empty content_tag:div just so the addition works with possible nil entries
    content_tag(:div) + dashboard_link(options) + account_details_link(options) + change_password_link +
      content_tag(:li, link_to(t('signout'), logout_path, options), class: 'govuk-header__navigation-item')
  end

  # Builds dashboard link for user, which is used in {#signed_in_user_links} method.
  # @return [HTML block element] the account details link if the user is authorised to view them
  def dashboard_link(options)
    return unless show_nav_link(options, :dashboard)

    content_tag(:li, link_to('Dashboard', dashboard_path, options), class: 'govuk-header__navigation-item')
  end

  # Builds change password links for an user, which is used in {#signed_in_user_links} method.
  #
  # To provide information to a registered user when his/her password is going to expire
  # so that user can change it if required.
  # @return [HTML block element] password days before expiring, and a link
  #   to changing the password if it has expired or overdue.
  def change_password_link
    return if current_user.days_to_password_expiry.nil? || current_user.days_to_password_expiry.negative?

    content_tag(:li,
                link_to(t('notification', count: current_user.days_to_password_expiry),
                        user_change_password_path),
                class: 'govuk-header__navigation-item')
  end

  # Builds account details link for user, which is used in {#signed_in_user_links} method.
  # @return [HTML block element] the account details link if the user is authorised to view them
  def account_details_link(options)
    return unless can?(AuthorisationHelper::VIEW_ACCOUNTS) && show_nav_link(options, :account_details)

    content_tag(:li, link_to(t('account-details'), { controller: '/accounts', action: 'show' }, options),
                class: 'govuk-header__navigation-item')
  end

  # Check to show a navigational link
  # @param options [Hash] nav_bar_options hash
  # @param element [Symbol] the part of the nav bar to show
  # @return [Boolean] true to show the link, otherwise false
  def show_nav_link(options, element)
    return true if options.nil? || !options.key?(:hide_nav_elements)

    hidden = options[:hide_nav_elements].is_a?(Array) ? options[:hide_nav_elements] : [options[:hide_nav_elements]]
    !hidden.include?(element)
  end

  # take the ActiveSupport::SafeBuffer options and convert to a hash
  def nav_options(options)
    return {} if options.to_s.empty?

    options
  end

  # Renders the standard gov uk warning with the text specified
  def govuk_warning(text)
    content_tag(:div,
                content_tag(:span, '!', class: 'govuk-warning-text__icon', aria: { hidden: true }) +
                content_tag(:strong, content_tag(:span, 'Warning', class: 'govuk-warning-text__assistive') + text,
                            class: 'govuk-warning-text__text'),
                class: 'govuk-warning-text')
  end

  private

  # Create a standard navigational link with hint text as assign in translation file.
  # The method is using {#link_to_field} to create the standard navigational
  # link and on top of that, this method is building it with hint text.
  # @param link [Hash] hash of options for the link
  # @return [HTML link element] standard navigational link.
  def navigational_link(link)
    return if link[:link].nil?

    link_field = link_to_field(link[:link], link[:path], link[:link_options])
    return if link_field.nil?

    additional_text_options = navigational_link_text_options(link)
    additional_text = navigational_link_text(link)
    link_field + (content_tag(:span, additional_text, additional_text_options) unless additional_text == '')
  end

  # Create text options for navigational_link. @see #navigational_link for more information
  # @param link [Hash] hash of options for the link
  # @return [String] text options based on the #link param
  def navigational_link_text_options(link)
    return { class: 'display-inline-text' } if link[:additional_text_options].nil?

    link[:additional_text_options]
  end

  # Create additional text for navigational_link. @see #navigational_link for more information
  # @param link [Hash] hash of options for the link
  # @return [String] additional text based on the #link param
  def navigational_link_text(link)
    t '.link.hint.' + link[:link].to_s, default: ''
  end

  # Create a standard navigational link with the correct css class and template.
  # This method is being used by {#navigational_link}.
  # @return [HTML link element] standard navigational link to a field. Or nil, if there is no link or path.
  def link_to_field(link, path, options)
    return if link.nil? || path.nil?

    options =  if options.nil?
                 { class: 'govuk-link' }
               else
                 { class: 'govuk-link' }.merge(options)
               end
    link_to(t('.link.' + link.to_s), path, options)
  end

  # Override of standard link_to method, to check for access to link.
  # @return [HTML link element] standard navigational link to a field. Or nil, if there is no link or path.
  def link_to(link, path, options = {})
    return unless authorised?(current_user, options)

    super
  end

  # Create a select field without attribute with the correct class;
  def select_tag(name, option_tags = nil, options = {})
    options = UtilityHelper.add_css_classes(options, 'govuk-select')
    super
  end

  # Returns any extra translation information required which is keyed by attr
  # @param attr [Symbol] the attribute for which the errors are being displayed
  # @param options [Hash] a hash of extra information to pass to the translation_attribute method
  # @return the extra information, or nil if not extra information supplied, or the attr is not found
  # @note only use :translation_options if there's no other way of avoiding it.
  def error_attribute_name_extra(attr, options)
    return nil if options.nil? || options[:translation_options].nil?

    options[:translation_options][attr]
  end

  # override the existing form_for method to add default autocomplete off
  # it can override by passing value html: { autocomplete: "on" }
  def form_for(name, *args, &block)
    options = args.extract_options!
    options[:html] = {} if options[:html].nil?
    options[:html][:autocomplete] = 'off' if options[:html][:autocomplete].nil?
    args << options
    super(name, *args, &block)
  end

  # override the existing form_with method to add default autocomplete off
  # it can override by passing value html: { autocomplete: "on" }
  def form_with(model: nil, scope: nil, url: nil, format: nil, **options)
    options[:html] = {} if options[:html].nil?
    options[:html][:autocomplete] = 'off' if options[:html][:autocomplete].nil?
    super
  end
end
