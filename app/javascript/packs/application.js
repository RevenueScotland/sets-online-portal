/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
//
// To reference this file, add <%= javascript_pack_tag 'application' %> to the appropriate
// layout file, like app/views/layouts/application.html.erb

require("@rails/ujs").start()
require("turbolinks").start()

// All vendor/assets/stylesheet javascript files
import 'govuk-frontend-3.0.0.min.js';
import 'spin.js';

// All the jquery-ui widgets javascript files we need
import autocomplete from 'jquery-ui/ui/widgets/autocomplete';
import tooltip from 'jquery-ui/ui/widgets/tooltip';
import button from 'jquery-ui/ui/widgets/button';
import datepicker from 'jquery-ui/ui/widgets/datepicker';

// All javascript/src javascript files
import 'application-ui';
import 'address_search';
import 'ga';
import 'session_expiry';
import 'file-upload-shared';
import 'auto-complete';
import 'date-picker';
import 'details.polyfill';
import 'relief-claim-amount-ui-handler';
import 'views/claim';
import 'views/confirmation';
import 'views/lbtt';
import 'views/registration';
import 'views/slft';

// Uncomment to copy all static images under ../images to the output folder and reference
// them with the image_pack_tag helper in views (e.g <%= image_pack_tag 'rails.png' %>)
// or the `imagePath` JavaScript helper below.
//
// const images = require.context('../images', true)
// const imagePath = (name) => images(name, true)

$(function () {
    document.body.className = ((document.body.className) ? document.body.className + ' js-enabled' : 'js-enabled');
})
