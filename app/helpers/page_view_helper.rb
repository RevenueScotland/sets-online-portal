# frozen_string_literal: true

# This is a helper to render the hidden field that contains the page view name
# Page view name is a unique name for this view, so that it can be tracked, for
# example, in Google Analytics
module PageViewHelper
  # Render the page view into HTML, typically used with: <%= render_page_view(__FILE__) %>
  # @param view_filepath [File path] the file path of the views file
  # @return [HTML block element] The HTML for page view name
  def render_page_view(view_filepath)
    hidden_field_tag 'page_view', view_filepath.split('/')[-2, 2].join('-').gsub(/.html.erb/, '')
  end
end
