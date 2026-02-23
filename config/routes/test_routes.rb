# frozen_string_literal: true

# routes return only for test purpose
Rails.application.routes.draw do
  get 'raise_error', to: 'application_controller_test/stub#raise_error'
end
