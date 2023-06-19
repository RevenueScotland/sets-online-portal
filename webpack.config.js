const path = require("path")
const webpack = require("webpack")
const CopyPlugin = require("copy-webpack-plugin")
// Extracts CSS into .css file
const MiniCssExtractPlugin = require('mini-css-extract-plugin')

module.exports = {
  mode: "production",
  devtool: "source-map",
  entry: {
    application: ["./app/javascript/application.js",
      "./app/assets/stylesheets/application.scss"]
  },
  module: {
    rules: [
      // Add CSS/SASS/SCSS rule with loaders
      {
        test: /\.(?:sa|sc|c)ss$/i,
        use: [MiniCssExtractPlugin.loader, 'css-loader', 'sass-loader'],
      }
    ],
  },
  output: {
    filename: "[name].js",
    sourceMapFilename: "[file].map",
    path: path.resolve(__dirname, "app/assets/builds")
  },
  resolve: {
    modules: ["app/javascript", "vendor/assets/javascript", "node_modules"],
    extensions: ['.js', '.jsx', '.scss', '.css']
  },
  plugins: [
    new webpack.optimize.LimitChunkCountPlugin({
      maxChunks: 1
    }),
    // Copy the assets out of the govuk frontend. Easier to do a straight
    // copy here
    new CopyPlugin({
      patterns: [
        { from: "node_modules/@scottish-government/pattern-library/dist/images", to: "assets/images" }
      ]
    }),
    new MiniCssExtractPlugin()
  ]
}
