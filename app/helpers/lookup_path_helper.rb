# frozen_string_literal: true

# Use the @virtual_path to get the lookup path
module LookupPathHelper
  # Utility helper to give the full path for the given translation key.
  # Effectively this returns the full path that would be used by the normal t(.<key>) Rails operation
  # Used when passing view keys into a partial
  # @see https://github.com/rails/rails/blob/56832e791f3ec3e586cf049c6408c7a183fdd3a1/actionview/lib/action_view/helpers/translation_helper.rb#L123
  # @param key [String] the key to be used
  def full_lazy_lookup_path(key)
    if key.to_s.first == '.'
      raise "Cannot use t(#{key.inspect}) short cut because path is not available" unless @virtual_path

      @virtual_path.gsub(%r{/_?}, '.') + key.to_s
    else
      key
    end
  end
end
