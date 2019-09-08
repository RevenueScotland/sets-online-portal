# frozen_string_literal: true

module Error
  # Exception we can throw for problems in the app
  class AppError < StandardError
    attr_reader :code, :message

    def initialize(code = nil, message = nil)
      @code = code || 500
      @message = message || 'Error'
    end

    # Return the error message (may be printed on screen)
    def to_s
      @message
    end
  end
end
