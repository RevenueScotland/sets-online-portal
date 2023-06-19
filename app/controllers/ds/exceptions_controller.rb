# frozen_string_literal: true

module DS
  # Provides the controller functionality for displaying system exceptions
  # This is configured as the middleware exception app
  # see Core::ExceptionsHandler
  class ExceptionsController < ::ApplicationController
    include Core::ExceptionsHandler
  end
end
