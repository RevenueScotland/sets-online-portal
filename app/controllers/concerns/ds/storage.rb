# frozen_string_literal: true

# Related to Digital Scotland Code
module DS
  # Provides server level access to the DS cookies.
  # See node_modules\@scottish-government\pattern-library\src\base\tools\storage
  module Storage
    extend ActiveSupport::Concern

    private

    # Internal PORO to wrap the permissions cookie
    class CookiePermissions
      # Initialise the model with the permissions cookie
      # @param cookie [String] The content of the cookie
      def initialize(cookie)
        storage_permissions_string = (cookie ? Base64.decode64(cookie) : '{}')
        @storage_permissions = ActiveSupport::JSON.decode(storage_permissions_string)
      end

      # Has this the user allowed storage of this level of permission
      # @param category [String] The particular storage category
      # @param default [Boolean] the default if not set, allows us to default to try on the cookie page
      # @return [Boolean] The permission for the category, always true for necessary
      #   default is false for others unless set
      def permission?(category, default: false)
        return true if category == 'necessary'

        (@storage_permissions.key?(category) ? @storage_permissions[category] : default)
      end

      # @param category [String] The category to set permissions for
      # @param value [String|Boolean] The permission for the category
      def permission(category, value)
        return @storage_permissions[category] = true if category == 'necessary'

        @storage_permissions[category] = ActiveModel::Type::Boolean.new.cast(value)
      end

      # Writes back to the cookie, we do this separately as more than one permission may be set
      def write
        storage_permissions_string = ActiveSupport::JSON.encode(@storage_permissions)
        Base64.strict_encode64(storage_permissions_string)
      end
    end

    # Gets the value for a particular storage permissions
    # @param category [String] The particular storage category
    # @param  default [Boolean] the default if not set, allows us to default to try on the cookie page
    # @return [Boolean] The permission for the category, always true for necessary
    #   default is false for others unless set
    def storage_permission?(category, default: false)
      cookie_permissions.permission?(category, default: default)
    end

    # Sets the storage permissions for revenue scotland
    def set_storage_permissions(preferences: false, statistics: false)
      cookie_permissions.permission('necessary', true)
      cookie_permissions.permission('preferences', preferences)
      cookie_permissions.permission('statistics', statistics)
      manually_set_cookie(cookie_permissions.write, 1.year)

      # Also write to say they have seen the message, if not already set
      return if cookies[:'cookie-notification-acknowledged']

      cookies[:'cookie-notification-acknowledged'] = { value: Base64.strict_encode64('yes'), expires: 1.year }
    end

    # Returns the current CookiePermissions object
    def cookie_permissions
      @cookie_permissions ||= CookiePermissions.new(cookies[:cookiePermissions])
    end

    # Because Rails URL encodes the content we need to avoid this so it works with DS code
    # Therefore create the cookie manually via rack, for date format see
    #  https://github.com/rails/rails/actionpack/test/dispatch/session/cookie_store_test.rb
    def manually_set_cookie(value, expire_in)
      expire_date = expire_in.from_now.gmtime.strftime('%a, %d %b %Y %H:%M:%S GMT')
      response['Set-Cookie'] =
        "cookiePermissions=#{value}; Expires=#{expire_date}; Path=/; SameSite=Lax"
    end
  end
end
