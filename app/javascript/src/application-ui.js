// This file contains JS that applies to the whole site but is not related to any one
// functional feature, or which may be used in any other JS files

// Overwrites document ready with turbolinkload,
// this needs to be done so that the document ready is compatible with turbolinks.
jQuery.fn.ready = function (fn) {
    $(this).on('turbolinks:load', fn)
};

$(function () {
    document.body.className = ((document.body.className) ? document.body.className + ' js-enabled' : 'js-enabled');

    // As the .endsWith is only introduced in ECMAScript6 (ES6), this polyfill is done to deal with it.
    // Most things in ES6 aren't supported in IE11 and this is one of it. See https://kangax.github.io/compat-table/es6/
    if (!String.prototype.endsWith) {
        String.prototype.endsWith = function (search, this_len) {
            if (this_len === undefined || this_len > this.length) {
                this_len = this.length;
            }
            return this.substring(this_len - search.length, this_len) === search;
        };
    }
})