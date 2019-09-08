# frozen_string_literal: true

# Represents role and actions
class ActionRoles < FLApplicationRecord
  # The domain code to use when loading all roles/actions in the back office
  DOMAIN_CODE = 'PORTALROLES'

  # Check if role(s) has the supplied action. If an array of roles is supplied, only one of the roles needs to be valid
  # of the supplied action_code
  # Parameters validated so that the developer catches errors early, given this is part of the site security
  # @param user_roles [Array/String] The user role(s) to check
  # @param role_action [String] The action to search for in that role
  # @return [Boolean] true if the role has the supplied action, otherwise false
  def self.role_has(user_roles, role_action)
    raise Error::AppError.new('NONE', 'user_roles must be supplied to this method') if user_roles.to_s.empty?
    raise Error::AppError.new('NONE', 'role_action must be supplied to this method') if role_action.to_s.empty?

    user_roles = [user_roles] unless user_roles.is_a?(Array)
    # The & causes any roles in both arrays to be returned
    !(find_for(role_action) & user_roles).empty?
  end

  # Load all actions from the back office and populate the cache with them
  def self.cache_all_actions
    success = false
    begin
      success = call_ok?(:get_role_actions, make_request(DOMAIN_CODE, '')) do |body|
        cache_all(body)
      end
    rescue StandardError => error
      Rails.logger.warn("Unable to cache action/roles: #{error.message}")
    end
    success
  end

  # @!method self.make_request(domain_code, role_action)
  # Convert the search parameters into a hash suitable for making the back office request
  # @param domain_code [String] search based on domain code
  # @param role_action [String] search based on role action
  # @return [Hash] a hash of search parameters
  private_class_method def self.make_request(domain_code, role_action)
    request = {}
    request['ins1:DomainCode'] = domain_code unless domain_code.to_s.empty?
    request['ins1:RoleActionCode'] = role_action unless role_action.to_s.empty?
    request
  end

  # @!method self.find_for(action_code)
  # Find the action_code and any associated roles in the cache. If missing from the cache load from the back office
  # @param [String] action_code is the action code
  # @return List of roles associated with the supplied action_code
  private_class_method def self.find_for(action_code)
    key = cache_key(action_code)
    Rails.logger.debug("Getting cache data for #{key}")
    Rails.cache.fetch(key, expires_in: cache_expiry_time) do
      Rails.logger.debug("Cache miss for #{key}, fetching back office data")
      success, roles = back_office_data(action_code)
      # if the back office call fails, then return nil, but don't store that in the cache
      return nil unless success

      roles
    end
  end

  # @!method self.back_office_data(action_code)
  # Obtain a list of roles applicable to the supplied action_code
  # @param action_code [String] search based on role action
  # @return [Array] an array of Roles that match the search criteria. The roles are stored as strings.
  private_class_method def self.back_office_data(action_code)
    code = action_code.to_s.upcase
    roles = []
    success = call_ok?(:get_role_actions, make_request('', code)) do |body|
      roles = roles_from_back_office(body)
    end
    Rails.logger.warn("action_code #{code} is not found, or has no roles associated with it") if roles.empty?
    [success, roles]
  end

  # @!method self.roles_from_back_office(body)
  # Create an array of role code strings from the web service call result.
  # @param body [Hash] the response of the web service call represented in a hash
  # @return [Array] array of role code strings
  private_class_method def self.roles_from_back_office(body)
    return [] if body[:role_actions].nil? || body[:role_actions][:role_action].nil?

    extract_roles_from_back_office(body[:role_actions][:role_action][:user_roles])
  end

  # @!method self.extract_roles_from_back_office(user_roles)
  # Create an array of role code strings from the web service call result.
  # @param user_roles [Array] the user roles from response of the web service call
  # @return [Array] array of role code strings
  private_class_method def self.extract_roles_from_back_office(user_roles)
    roles = []
    ServiceClient.iterate_element(user_roles) do |user_role|
      roles.push(user_role[:user_role_code])
    end
    roles
  end

  # @!method self.cache_all(body)
  # Cache all the actions and their roles as supplied by the body parameter
  # @param body [Hash] the response of the web service call represented in a hash
  private_class_method def self.cache_all(body)
    return if body.nil? || body[:role_actions].nil? || body[:role_actions][:role_action].nil?

    body[:role_actions][:role_action].each do |role_action|
      cache_action_code role_action[:role_action_code], role_action[:user_roles]
    end
  end

  # @!method self.cache_action_code(action, user_roles)
  # Cache all the actions and their roles as supplied by the body parameter
  # @param action [action] the action code
  # @param user_roles [Array/Hash] the user roles related to the action code
  private_class_method def self.cache_action_code(action, user_roles)
    roles = extract_roles_from_back_office user_roles
    Rails.logger.info("Caching action=#{action} roles=#{roles}")
    Rails.cache.write(cache_key(action), roles, expires_in: cache_expiry_time)
  end

  # @!method self.cache_key(action_code)
  # Where this data is stored in the cache.
  # Must be unique to the action code and the implementing class and always return the same value for the input.
  # @param [String] action_code is the action code
  # @return <class_name>_<action_code>
  private_class_method def self.cache_key(action_code)
    "#{name}##{action_code.to_s.upcase}"
  end

  # When the cache data for this class should expire.
  # @return Rails.configuration.x.authorisation.cache_expiry or 10 minutes if that's not set.
  private_class_method def self.cache_expiry_time
    Rails.configuration.x.authorisation.cache_expiry || 10.minutes
  end
end
