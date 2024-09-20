# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Specific compiler for propshaft for digital scotland JS
# This replaces the links to icons.stack.svg with a full digested path
# ${this.imagePath}icons.stack.svg becomes <asset page>${this.image_path}icons.stack-<digest>.svg
class DigitalScotlandAssets < Propshaft::Compiler
  # The svg is controlled by this.imagePath, so look for this
  ASSET_URL_PATTERN = /(\${this.imagePath})(icons.stack.svg)/

  def compile(_logical_path, input)
    input.gsub(ASSET_URL_PATTERN) do
      svg_url(Regexp.last_match(2), Regexp.last_match(1))
    end
  end

  private

  def svg_url(svg, image_path)
    # Look for where we know the svg will be
    full_path = "assets/images/icons/#{svg}"
    if (asset = assembly.load_path.find(full_path))
      new_svg = asset.digested_path.basename
      "#{url_prefix}#{image_path}#{new_svg}"
    else
      Propshaft.logger.warn { "Unable to resolve '#{svg}'" }
      svg
    end
  end
end

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
# Rails.application.config.assets.precompile += %w( admin.js admin.css )

# Exclude javascript and stylesheets that are already bundled
Rails.application.config.assets.excluded_paths << Rails.root.join('app/assets/stylesheets')
Rails.application.config.assets.excluded_paths << Rails.root.join('app/assets/javascript')
Rails.application.config.assets.excluded_paths << Rails.root.join('vendor/assets/stylesheets')
Rails.application.config.assets.excluded_paths << Rails.root.join('vendor/assets/javascript')

Rails.application.config.assets.compilers << ['text/javascript', DigitalScotlandAssets]
