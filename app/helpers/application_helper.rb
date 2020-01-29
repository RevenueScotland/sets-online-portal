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

  # Provides the text that consists of the title for Scotland's portal
  # @param title [String] this is the contents of the <h1> of the page, which is the title of the page.
  def page_title_text(title)
    # This is the default title of the page if there isn't any <h1> found
    page_title = t('default_title')
    page_title = title + ' | ' + page_title unless title.nil?
    # The title should now have the word 'Error:' when we find any errors in the form, see the {#form_errors_for}.
    page_title = t('error') + ': ' + page_title if @form_error_found

    page_title.html_safe
  end

  # Provides link to account-handling actions, which is shown at the header area.
  #
  # Link to account-handling actions include paths to login,
  # logout and account page. It checks for the current user
  # and will pass signed in users to the {#signed_in_user_links}.
  #
  # To pass in options, do <% content_for :nav_bar_options, { <options> } %> in the html page where <options> is a
  # hash of options.Options are applied on an hyperlink generated from this method.Currently it used to
  # add CSS class 'external-link' on link so that warning message will be shown on leaving a specific page
  # when user click on it.
  # @example - in html page
  #  <% content_for :nav_bar_options, { class: 'external-link' } %>
  # @param options [Hash] options for creating the account_links. Currently supported are: hide_nav_elements
  # @param html_options [Hash] html options passed into the creation of the links.
  # @return [HTML link element] the appropriate links.
  def account_links(options = {}, html_options = {})
    return if options[:hide_all]

    if current_user.nil?
      return if current_page?(controller: '/login', action: 'new')

      account_list_item_tag(link_to(t('signin'), login_path, html_options))
    else
      signed_in_user_links(options, html_options)
    end
  end

  # Creates a standard display field outside of a table of data.
  # option[div_css_class] is use to override the outer div css
  # It is using the attribute (as the label) and the attribute of the
  # object (as the value).
  # @example Creates postcode display field of the address_summary object, with modified div and text classes.
  #   display_field(@address_summary,
  #                 :postcode,
  #                 {},
  #                 { wrapper: { class: "display-inline-text" }, text: { class: "govuk-label" } })
  #
  # @param object [Object] the object that owns the attribute to be displayed.
  # @param attribute [Symbol] is used as the label and the value of the object to be displayed.
  # @param options [Hash] functional options applied to the display_field to modify how the output is displayed.
  # @param html_options [Hash] can consist of three keys with hash values. The three keys are :wrapper, :label and
  #   :text, these are split up so that we can apply specific html options to each elements separately.
  # @return [HTML block element] an object that uses the label and value in the standard format, which
  #   is a label and span containing the value. If no object is found then nil.
  def display_field(object, attribute, options = {}, html_options = {})
    return if object.nil?

    label = display_field_label(object, attribute, options, display_field_label_html_options(html_options[:label]))
    text = display_field_text(object, attribute, options, display_field_text_html_options(html_options[:text], label))
    content_tag(:div, label + text, display_field_wrapper_html_options(html_options[:wrapper]))
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
  #               { link: :attribute-name1, path: redirect_path1 },
  #               { link: :attribute-name2, path: redirect_path2 }
  #              ]
  # Additional options on the navigation link can be passed as a hash with options.
  # These options will be tagged onto the HTML as an HTML element attribute.
  # To override default html element attribute of li used list_html_options and
  # for hyperlink used link_html_options.
  #
  # e.g.
  #     link = [{ link: :attribute-name1,
  #               path: redirect_path1,
  #               list_html_options: { class: 'css class of li' },
  #             link_html_options: { class: 'css class of hyper link', target: '_blank' } }]
  # To add hint text for hyperlink arrange translation file as per an example given below
  #   en:
  #     views:
  #       view:
  #         link:
  #           attribute-name: 'link text'
  #           hint:
  #             attribute-name: 'link hint text'
  # Key information about the param links need an array of hashes, the hash may contain:
  #   :link [String] (REQUIRED) The text that will be displayed
  #   :path [String] (REQUIRED) The path of the link, which will take the user to that page.
  #   :link_html_options [Hash] (OPTIONAL) options that will be passed into the creation of the anchor tag of the link.
  #     This can also include the key :requires_action to check for authorised user but will not be included in
  #     the element.
  #   :list_html_options [Hash] (OPTIONAL) options that will be passed into the creation of the list item <li> element.
  #   :link_options [Hash] (OPTIONAL) functional options that is used to modify the link, and will not be passed into
  #     the element's creation.
  #     Below is the content of link_options:
  #     - :sentence_for_swap_text [String] (OPTIONAL) consists of the symbol for the sentence to be used for
  #       translation. If we want the list item <li> to include both a link and some extra text in the same sentence,
  #       then this can be used.
  # @param links [Array] contains an array of hashes of information to create the link(s)
  # If links array contain only one record then display link without unordered list
  def navigational_links(links, html_options = { class: 'govuk-list govuk-list--bullet' })
    li_contents = ''
    return navigational_link(links[0]) if links.size == 1

    links.each do |link|
      link_content = navigational_link(link)
      next if link_content.nil?

      li_contents += content_tag(:li, link_content, link[:list_html_options])
    end
    content_tag(:ul, li_contents.html_safe, html_options)
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
  # @param options extra options that can be passed to the lower routines
  # @return [HTML element block] standard error region. If no error is passed.
  def form_errors_for(object = nil, options = nil)
    error_hashes = extract_all_errors(object)
    # This variable is currently being used to determine what the page title will include. It's used
    # to check if there's any errors found. This gets refreshed on page load.
    @form_error_found = error_hashes.any?
    render('layouts/form_errors', error_hashes: error_hashes, options: options) if @form_error_found || flash.any?
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

  # Builds the header menu for an authenticated user.
  # This is used in the {#account_links} method.
  #
  # If the password has almost expired and optional link is shown to reset the password
  #
  # The logout link is aways shown.
  # @return [HTML link element] with links to the dashboard, account details and logout.
  def signed_in_user_links(options, html_options)
    # NB '/accounts' rather than 'accounts' so that this method works from different namespaces
    # empty content_tag:div just so the addition works with possible nil entries
    content_tag(:div) +
      dashboard_link(options, html_options) + account_details_link(options, html_options) + change_password_link +
      account_list_item_tag(link_to(t('signout'), logout_path, html_options))
  end

  # Builds dashboard link for user, which is used in {#signed_in_user_links} method.
  # @return [HTML block element] the account details link if the user is authorised to view them
  def dashboard_link(options, html_options)
    return unless show_nav_link(options, :dashboard)

    account_list_item_tag(link_to('Dashboard', dashboard_path, html_options))
  end

  # Builds change password links for an user, which is used in {#signed_in_user_links} method.
  #
  # To provide information to a registered user when his/her password is going to expire
  # so that user can change it if required.
  # @return [HTML block element] password days before expiring, and a link
  #   to changing the password if it has expired or overdue.
  def change_password_link
    return if current_user.days_to_password_expiry.nil? || current_user.days_to_password_expiry.negative?

    account_list_item_tag(link_to(t('notification', count: current_user.days_to_password_expiry),
                                  user_change_password_path))
  end

  # Builds account details link for user, which is used in {#signed_in_user_links} method.
  # @return [HTML block element] the account details link if the user is authorised to view them
  def account_details_link(options, html_options)
    return unless can?(AuthorisationHelper::VIEW_ACCOUNTS) && show_nav_link(options, :account_details)

    account_list_item_tag(link_to(t('account-details'), { controller: '/accounts', action: 'show' }, html_options))
  end

  # The standard list item <li> tag used for any list item of account links.
  def account_list_item_tag(contents)
    content_tag(:li, contents.html_safe, class: 'govuk-header__navigation-item')
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

  # Extracts all the errors associated with the passed object or array of objects including any sub-objects
  # @see object_and_index_array
  # It creates an array of hashes containing the href and message that can be used to build the error region
  # @param obj [Object] The object or an array of objects which must respond to the rails errors method
  # @return [Array] an array of hashes containing the href and message
  def extract_all_errors(obj)
    errs = []
    object_and_index_array(obj).each do |this_hash|
      this_obj = this_hash[:object]
      extract_object_errors(errs, this_obj, this_hash[:index], error_href_first_part(this_obj))
      next unless this_obj.respond_to?(:error_objects)

      this_obj.error_objects(true)&.each do |eh|
        extract_object_errors(errs, eh[:object], eh[:index], error_href_first_part(this_obj, eh[:attribute]))
      end
    end
    errs
  end

  # Depending on the page we may get a single object OR
  #   an array on disparate objects to to display the errors for OR
  #   we may get an array of the same objects (if we are displaying a table)
  # This routine returns a array of hashes that can be processed with the object and a potential index if it is an
  # array of the same object
  # @param obj [Object] The object containing the errors
  # @return [Array] an array of hashed with an object: and optionally an index:
  def object_and_index_array(obj)
    return [object_and_index_hash(obj)] unless obj.is_a?(Array) # deal with the simple case that this isn't an array

    # make sure that if the object is an array all the same we push it down a level in the array
    object_class = obj[0].class
    obj = [obj] if obj.all? { |o| o.class == object_class }

    # Now we can iterate to create the hash
    iterate_object(obj)
  end

  # Iterates around the object to produce a hash of the objects and the index in the array if needed
  # assumes the object has already been tidied up @see object_and_index_array
  # @param obj [Object] The object array
  # @return [Array] an array of hashes @see object_and_index_hash
  def iterate_object(obj)
    error_array = []
    obj.each do |this_object|
      if this_object.is_a?(Array)
        # Need to iterate around this object, we now assume this is an array of the same object type
        this_object.each_with_index { |that_object, i| error_array << object_and_index_hash(that_object, i) }
      else
        # handle an array on objects
        error_array << object_and_index_hash(this_object)
      end
    end
    error_array
  end

  # Returns the hash representing and error object and if needed its index
  # @param obj [Object] The object
  # @param ind [Integer] The index of the object in an array
  # @return [Hash] The  hash with the object: and optionally an index:
  def object_and_index_hash(obj, ind = nil)
    { object: obj, index: ind }
  end

  # Extracts the errors from an object and creates an array of hashes contained the href and message
  # that can be used to build the error region
  # @param obj [Object] The object which has the errors the object must respond to the rails errors method
  # @param ind [Integer] The index of the object where it is a multi record block
  # @param href_first_part [String] The first part of the href link based on the object and optional attribute
  # @return [Array] an array of hashes containing the href and message
  def extract_object_errors(errs, obj, ind, href_first_part)
    Rails.logger.debug { "  Extracting errors for #{obj.class} ind #{ind} [link #{href_first_part}]" }

    # We're getting the href of each links and the error message separately because there are two ways
    # of getting them and both have different functionalities. It is possible to match the href value
    # with the error message because the two arrays are returning each of the errors in the same order
    # as each other.
    href_list = extract_error_href_ids(obj, ind, href_first_part)
    message_list = extract_error_messages(obj)

    return if message_list.size.zero?

    # Adds all the errors found to the errs array
    (0..href_list.size).each do |n|
      errs << { href: href_list[n], message: message_list[n] }
    end
  end

  # Extracts the href to be used for the error summary links' ids.
  def extract_error_href_ids(obj, ind, href_first_part)
    href_list = []
    # The obj.errors.details includes both the attribute and error in the symbol format, and it also includes
    # any options passed.
    # So we need to get the correct attribute according to the options passed.
    obj.errors.details.each do |attr, details|
      details.each do |detail|
        href_value = detail[:link_id] if attr == :base
        href_value ||= error_href(href_first_part, attr, ind)
        href_list << href_value
      end
    end
    href_list
  end

  # Extracts the messages from the errors
  def extract_error_messages(obj)
    message_list = []
    # The obj.errors.messages seems to include only the attribute and the error message in text, so we need
    # to do this to get the error message in text.
    obj.errors.messages.each do |_, messages|
      messages.each do |msg|
        message_list << msg
      end
    end
    message_list
  end

  # Generates a href for use in the error link based on the object name, the attribute name, and an optional prefix
  # if the attribute is :base then returns nil
  # @param href_first_part [String] The first part of the error link based on the object and attribute
  # @param attr [String] the attribute name
  # @param ind [Integer] The index of the object
  # @return [String] The href link to use
  def error_href(href_first_part, attr, ind = nil)
    return nil if attr == :base

    if ind.nil?
      href_first_part + '_' + attr.to_s
    else
      href_first_part + '_' + ind.to_s + '_' + attr.to_s
    end
  end

  # Generates the first part (the object name) href for use in the error link based on the object name
  # and the attribute name if we are dealing with a child object
  # @param obj [Object] The object of the attribute
  # @param attribute_name [Object] The name of the attribute that is the child object
  # @return [String] The href link to use
  def error_href_first_part(obj, attribute_name = nil)
    if attribute_name.nil?
      model_name_from_record_or_class(obj).param_key
    else
      model_name_from_record_or_class(obj).param_key + '_' + attribute_name.to_s.delete_prefix('@')
    end
  end

  # Creates the standard label of the display field.
  # @see display_field for more details about the parameter values and how this is used.
  # @return [HTML block element] the standard label used for a normal display field.
  def display_field_label(object, attribute, options, html_options)
    label(@object_name, attribute, html_options) do
      UtilityHelper.label_text(object, attribute, options)
    end
  end

  # Gets the text for the display field using the attribute of the object with the options applied.
  # @param object [Object] the object that owns the attribute to be displayed.
  # @param options [Hash] consists of the extra options used to modify the text.
  # @see display_field for more details about the parameter values and how this is used.
  # @return [HTML block element] the standard text used for a normal display field.
  def display_field_text(object, attribute, options, html_options)
    text = CommonFormatting.format_text(object.send(attribute), options)
    content_tag(:span, text, html_options)
  end

  # Generates the display_field <div> wrapper's html_options.
  # @return [Hash] html options to be created with the <div> wrapper element.
  def display_field_wrapper_html_options(html_options)
    html_options = html_options.dup || {}
    # Allows the field to be traversed through by tabbing, which makes it visible to screen readers (hearable).
    html_options[:tabindex] = 0
    wrapper_class = 'govuk-form-group display-field'
    wrapper_class += " #{html_options[:class]}" unless html_options[:class].nil?
    html_options[:class] = wrapper_class
    html_options
  end

  # Generates the display_field label's html_options.
  # @return [Hash] html options to be created with the <label> element.
  def display_field_label_html_options(html_options)
    html_options = html_options.dup || {}
    html_options[:class] = html_options[:class].nil? ? 'govuk-label' : "govuk-label #{html_options[:class]}"
    html_options
  end

  # Generates the display_field <span> text's html_options.
  # This needs the generated label to construct the id for the span.
  # @return [Hash] html options to be created with the <span> text element.
  def display_field_text_html_options(html_options, label)
    html_options = html_options.dup || {}
    html_options[:id] = label.to_s.scan(/for="([^"]*)"/).last.first
    html_options
  end

  # Create a standard navigational link with hint text as assign in translation file.
  # The method is using {#navigational_link_output} to create the standard navigational
  # link and on top of that, this method is building it with hint text.
  # @param link [Hash] hash of options for the link
  # @return [HTML link element] standard navigational link.
  def navigational_link(link)
    return if link[:link].nil?

    options = link[:link_options] || {}
    html_options = link[:link_html_options] || {}
    output = navigational_link_output(link[:link], link[:path], html_options)
    return output if options[:sentence_for_swap_text].nil?

    # Creates the navigational link with extra texts, by swapping the normal text of parts of the sentence
    # with the same text but with the navigational link.
    UtilityHelper.swap_texts(options[:sentence_for_swap_text], text_link: { t(".link.#{link[:link]}") => output })
  end

  # Create a standard navigational link with the correct css class and template.
  # This method is being used by {#navigational_link}.
  # @return [HTML link element] standard navigational link to a field. Or nil, if there is no link or path.
  def navigational_link_output(link, path, html_options)
    return if link.nil? || path.nil?

    # html_options[:class] = UtilityHelper.link_class(html_options) unless html_options[:class] == ''
    link_to(t('.link.' + link.to_s).html_safe, path, html_options)
  end

  # Override of standard link_to method, to check for access to link.
  # @return [HTML link element] standard navigational link to a field. Or nil, if there is no link or path.
  def link_to(link, path, html_options = {})
    return unless authorised?(current_user, html_options)

    # Removes the requires_action before the creation of the link
    html_options = strip_non_html_options(html_options)
    # This prevents the 'Reverse Tabnabbing' attack, which is where the attacker modifies the previous tab's
    # web page using javascript on the new page that is loaded on a new tab.
    html_options[:rel] = 'noopener noreferrer' if html_options[:target] == '_blank'
    html_options[:class] ||= 'govuk-link'
    super
  end

  # Strips the non html options out, used as part of the creation of an anchor tag.
  # Strips the requires_action options.
  def strip_non_html_options(html_options)
    html_options = html_options.reject { |option| option == :requires_action } || {}
    html_options
  end

  # Create a select field without attribute with the correct class;
  # @param options [Hash] contains functional options which are information used for how the field is displayed.
  # @param html_options [Hash] includes the html options and the default options that can be used to build a select_tag
  def select_tag(name, option_tags = nil, options = {}, html_options = {})
    html_options = UtilityHelper.field_html_options(options, html_options, 'govuk-select')
    super(name, option_tags, html_options)
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
