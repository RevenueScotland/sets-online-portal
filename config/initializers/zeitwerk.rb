# frozen_string_literal: true

# As stated on this link https://edgeguides.rubyonrails.org/upgrading_ruby_on_rails.html#project-structure
# zeitwerk mode infers constant names from file names (camelize).
# So "FLApplicationRecord".underscore is "fl_application_record",
# but "fl_application_record".camelize is "FlApplicationRecord" and not "FLApplicationRecord".
#
# Read up on https://edgeguides.rubyonrails.org/autoloading_and_reloading_constants.html#customizing-inflections
# to learn more about how to customize zeitwerk inflections.
Rails.autoloaders.each do |autoloader|
  autoloader.inflector.inflect(
    'fl_application_record' => 'FLApplicationRecord'
  )
end
