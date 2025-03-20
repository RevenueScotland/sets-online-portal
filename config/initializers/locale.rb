# config/initializers/locale.rb
# frozen_string_literal: true

# Set the default load path to allow sub directories
I18n.load_path += Dir[Rails.root.join('config/locales/**/*.{rb,yml}')] # rubocop:disable Rails/RootPathnameMethods

# Permitted locales available for the application
I18n.available_locales = %i[en cy]

# Set default locale to english
I18n.default_locale = :en
