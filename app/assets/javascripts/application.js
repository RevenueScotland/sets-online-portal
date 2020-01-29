// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, or any plugin's
// vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery3
//= require jquery-ui
//= require rails-ujs
//= require turbolinks
//= require govuk-frontend-3.0.0.min
//= require application-ui
//= require address_search
//= require ga
//= require spin
//= require session_expiry
//= require_tree ./views
//= require file-upload-shared
//= require auto-complete
//= require date-picker
//= require details.polyfill
//= require relief-claim-amount-ui-handler
$(function () {
    document.body.className = ((document.body.className) ? document.body.className + ' js-enabled' : 'js-enabled');

    // This method prints the contents of the current window.
    $('.print').on("click", function () {
        window.print();
    })

    // This method will close current window
    $('.close').on("click", function () {
        window.close();
    })

})

