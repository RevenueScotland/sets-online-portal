# frozen_string_literal: true

# Errors module - a place to put error handling related files
module Error
  # Exception we can throw when Wizard model data does not exist (ie when they type in a URL rather than starting from
  # the start of a wizard).
  # Cannot extend StandardError since the general error handler catches all StandardErrors.
  class WizardRedirectError < Exception # rubocop:disable Lint/InheritException
    attr_reader :url

    def initialize(url)
      super()
      @url = url
    end

    # Text representation of this exception
    def to_s
      @url
    end
  end
end
