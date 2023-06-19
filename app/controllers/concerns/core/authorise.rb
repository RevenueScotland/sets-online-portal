# frozen_string_literal: true

# Provide the authorise annotation to a controller class
module Core
  # Authorisation concern that adds authorisation to controller
  module Authorise
    extend ActiveSupport::Concern

    included do
      helper_method :authorised?, :can?, :cannot?
      before_action :authorise_action
    end

    # Classes that the ActiveSupport::Concern automatically adds as class level methods
    module ClassMethods
      # Check if a route is authorised for the current user or not.
      # @example protect route protected1 with action action1 when the method is a HTTP get
      #   authorise route: :protected1, requires: %i[action1], on: %i[get]
      # @example protect route protected2 with action action1 or action2 for all HTTP methods
      #   authorise route: :protected2, requires: %i[action1 action2]
      # @example protect route protected3 with action action1 and action2 for all HTTP methods
      #   authorise route :protected2, requires_all: %i[action1 action2]
      # @example protect routes route1 and route2 with action1
      #   authorise route: %i[route1 route2], requires: action1
      # @example protect all routes with action1 for HTTP delete
      #   authorise requires: action1, on: :delete
      # @example protect all routes with action1 if there is a current user, otherwise allow access
      #   authorise requires: action1, allow_if: :public
      # @example protect all routes with action1 if there is a current user, otherwise allow if the user defined
      #   function my_function returns true
      #   authorise requires: action1, allow_if: :my_function
      # @param options [Hash] set of options to protect the route with; must include :requires, :on and :route are
      # optional
      def authorise(options)
        return if %i[requires requires_all].none? { |k| options.key? k }

        override = options[:allow_if]
        route = options[:route]
        requires = options[:requires] || options[:requires_all]
        or_operation = options.key?(:requires)
        return write_authorise_method_for_routes(route, requires, or_operation, override) unless options.key?(:on)

        authorise_for_methods route, requires, or_operation, override, options
      end

      private

      # Iterate the methods for writing the authorise methods
      # @param route        [String/Symbol/Array] name(s) of the route to protect
      # @param requires     [String/Symbol] name of the action required
      # @param or_operation [Boolean] true if requires, false if requires_all
      # @param override     [String/Symbol] name of a function to override any authorisation checks
      # @param options      [Hash] set of options to protect the route with; must include :requires, :on and :route are
      def authorise_for_methods(route, requires, override, or_operation, options)
        methods = options[:on].is_a?(Array) ? options[:on] : [options[:on]]
        methods.each do |method|
          write_authorise_method_for_routes route, requires, or_operation, override, method
        end
      end

      # Iterate the routes for writing the authorise methods
      # @param routes       [String/Symbol/Array] name(s) of the route to protect
      # @param requires     [String/Symbol] name of the action required
      # @param or_operation [Boolean] true if requires, false if requires_all
      # @param override     [String/Symbol] name of a function to override any authorisation checks
      # @param method       [String/Symbol] HTTP action this authorise method responds to
      def write_authorise_method_for_routes(routes, requires, or_operation, override, method = '')
        if routes.blank?
          write_authorise_method('', requires, or_operation, override, method)
        else
          routes_for = routes.is_a?(Array) ? routes : [routes]
          routes_for.each do |route|
            write_authorise_method route, requires, or_operation, override, method
          end
        end
      end

      # Write the authorise method based on the route, and optionally the http method
      # @note @see https://apidock.com/ruby/Module/define_method for more information on define_method
      # @note any override provided only overrides if the supplied function returns true. If the supplied function
      #       returns false, the normal authorisation checks are applied
      # @param route        [String/Symbol] name of the route to protect
      # @param requires     [String/Symbol] name of the action required
      # @param or_operation [Boolean] true if requires, false if requires_all
      # @param override     [String/Symbol] name of a function to override any authorisation checks
      # @param method       [String/Symbol] HTTP action this authorise method responds to
      def write_authorise_method(route, requires, or_operation, override, method = '')
        route_name = route.empty? ? '' : "_#{route}"
        method_name = method.empty? ? '' : "_#{method}"
        def_name = "authorise#{route_name}#{method_name}"

        define_method(def_name) do
          return true if !override.to_s.empty? && send(override, requires, route, method)

          or_operation ? can?(requires) : authorised?(current_user, requires_all_action: requires)
        end
      end
    end

    # Check if the current user is authorised to perform this action
    # @return [Boolean] true if there's no authorise annotation for this action, or if the user is authorised to perform
    # this action, otherwise false
    def authorise_action
      return true if action_authorised?

      raise_forbidden
      false
    end

    # Common function that checks if there's a current_user and returns true if there isn't
    # @param _requires [String/Symbol] the action that's being checked
    # @param _route    [String/Symbol] name of the route that's being checked
    # @param _method   [String/Symbol] HTTP action
    # @return [Boolean] returns true if there's no current_user otherwise false
    def public(_requires = '', _route = '', _method = '')
      return true unless defined? current_user
      return true if current_user.nil?

      false
    end

    # Determine if the supplied user is authorised to perform the action. If authorisation is disabled, via the
    # Rails.configuration.x.authorisation.disabled flag then this method returns true. Options is a hash, which
    # can contain the following authorisation options:
    #   requires_action: "action_code" or requires_action: ["action_code_1", "action_code_2"]
    #     This checks that the user has access to the action, in the case of an array, has access to at least one action
    #   requires_all_action: "action_code" or requires_all_action: ["action_code_1", "action_code_2"]
    #     This checks that the user has access to the action, in the case of an array, has access to all the actions
    # if both are present, then requires_all_action is checked first
    # @param user [User] user to check if they have the action_code
    # @param options [Hash] options to check for authorisation options
    # @return [Boolean] true if the user is authorised (or authorisation is disabled), otherwise false
    def authorised?(user, options)
      return true if Rails.configuration.x.authorisation.disabled || options.nil? || options.empty?
      return true if options.nil? || %i[requires_action requires_all_action].none? { |k| options.key? k }

      check_requires user, options
    end

    # returns true if the current user has access to one of the action codes. Returns false if the user doesn't
    # have access to the action code, or there is no current user, or if the current user has no roles
    # @param action_codes [String/Symbol/Array] Either a single action code, or an array of action codes. In the
    #        array case, at least one action must be present
    # @return [Boolean] true if the user is authorised (or authorisation is disabled), otherwise false
    def can?(action_codes)
      return true if Rails.configuration.x.authorisation.disabled || action_codes.empty?
      return false unless user_roles? current_user

      check_requires_action current_user.user_roles['user_role'], action_codes
    end

    # returns true if the current user hasn't access to one of the action codes
    # @param action_codes [String/Symbol/Array] Either a single action code, or an array of action codes.  In the
    #        array case, at least one action must be present
    # @return [Boolean] true if the user is not authorised (or authorisation is not disabled), otherwise false
    def cannot?(action_codes)
      !can? action_codes
    end

    private

    # Determine if the supplied user is authorised to perform the action. @see #authorised for more information.
    # @param user [User] user to check if they have the action_code
    # @param options [Hash] options to check for authorisation options
    # @return [Boolean] true if the user is authorised (or authorisation is disabled), otherwise false
    def check_requires(user, options)
      return false unless user_roles?(user)

      roles = user.user_roles['user_role']
      return check_requires_all_action(roles, options[:requires_all_action]) if options.key? :requires_all_action

      check_requires_action(roles, options[:requires_action]) if options.key? :requires_action
    end

    # Determine if supplied user roles has access to all of the supplied action_codes.
    # @param roles [Array] Array of roles
    # @param action_codes [String/Array] the action code(s) to check
    # @return [Boolean] true if the user has access to all the action codes, otherwise false
    def check_requires_all_action(roles, action_codes)
      return false if roles.empty?
      return true if action_codes.empty?

      action_codes = Array(action_codes)
      action_codes.each do |action|
        return false unless ActionRoles.role_has(roles, action)
      end
      true
    end

    # Determine if supplied user roles has access to at least one of the supplied action_codes.
    # @param roles [Array] Array of roles
    # @param action_codes [String/Array] the action code(s) to check
    # @return [Boolean] true if the user has access to all the action codes, otherwise false
    def check_requires_action(roles, action_codes)
      return false if roles.empty?
      return true if action_codes.empty?

      action_codes = Array(action_codes)
      action_codes.each do |action|
        return true if ActionRoles.role_has(roles, action)
      end
      false
    end

    # Determine if the supplied user has any roles
    # @param user [User] user to check
    # @return [Boolean] true if the user is non-nil, and has at least some roles
    def user_roles?(user)
      !user.nil? && !user.user_roles.nil? && !user.user_roles['user_role'].nil? && !user.user_roles['user_role'].empty?
    end

    # return 403/Forbidden status back to the browser
    def raise_forbidden
      render('ds/exceptions/403', status: :forbidden, layout: 'application')
    end

    # Check if the call is authorised. It tries to call the various flavours of authorise in the following order:
    #   authorise_<action_name>_<http_request_type>
    #   authorise_<action_name>
    #   authorise_<http_request_type>
    #   authorise
    # Once an authorise method is found, it's result is returned.
    # @return [Boolean] return true if the call is authorised, otherwise false
    def action_authorised?
      authorised = authorise_action_for?("authorise_#{action_name}_#{request.method_symbol}")
      return authorised unless authorised.nil?

      authorised = authorise_action_for?("authorise_#{action_name}")
      return authorised unless authorised.nil?

      authorised = authorise_action_for?("authorise_#{request.method_symbol}")
      return authorised unless authorised.nil?

      authorised = authorise_action_for?('authorise')
      return authorised unless authorised.nil?

      true
    end

    # If the method_name exists, then call it and return the result. If the method name
    # doesn't exist then return nil
    # @param method_name [String] the name of the method to check if exists and call
    # @return [Boolean] nil if the method doesn't exist, otherwise the result of the method
    def authorise_action_for?(method_name)
      return nil unless respond_to?(method_name)

      send(method_name)
    end
  end
end
