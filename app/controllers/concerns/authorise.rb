# frozen_string_literal: true

# Provide the authorise annotation to a controller class
module Authorise
  extend ActiveSupport::Concern

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
    # @example protect all routes with action1 if there is a current user, otherwise allow if the user defined function
    #          my_function returns true
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
      if routes.nil? || routes.empty?
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

  private

  # Check if the call is authorised. It tries to call the various flavours of authorise in the following order:
  #   authorise_<action_name>_<http_request_type>
  #   authorise_<action_name>
  #   authorise_<http_request_type>
  #   authorise
  # Once an authorise method is found, it's result is returned.
  # @return [Boolean] return true if the call is authorised, otherwise false
  def action_authorised? # rubocop:disable Metrics/AbcSize
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
