Cookies = require("js.cookie");

'use strict';

var manageCookies = {
    init: function () {
        var cookiesOKButton = document.querySelector('.revscot_cookies-ok');
        var cookiesNoButton = document.querySelector('.revscot_cookies-no');

        if (cookiesOKButton) {
            this.addListener(cookiesOKButton, 'yes');
        }
        if (cookiesNoButton) {
            this.addListener(cookiesNoButton, 'no');
        }
    },

    addListener: function (target, accept_cookies) {
        target.addEventListener('click', function () { manageCookies.setCookie(accept_cookies) });
    },

    setCookie: function (accept_cookies) {
        // Set the appropriate secure if https is on
        var isSecure = location.protocol === 'https:';
        Cookies.set('revscot_cookies', accept_cookies, { path: '/', expires: 90, secure: isSecure, samesite: 'strict' });

        if (accept_cookies == 'no') {
            // If they check no then remove all but the whitelisted cookies
            var cookie_list = Cookies.get()
            for (var cookie_name in cookie_list) {
                if (['_revscot_session', 'revscot_cookies'].indexOf(cookie_name) > -1)
                    continue;

                Cookies.remove(cookie_name)
            }
        }
        // Remove the cookies message when they click
        var container = document.querySelector('.revscot_cookies');
        container.parentNode.removeChild(container);
    }
};

$(document).on('turbolinks:load', function () {
    manageCookies.init()
})