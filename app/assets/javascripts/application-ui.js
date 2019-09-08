// This is js file used to keep common ui jquery functions 

// overwrites document ready with turbolinkload
// Commented out the arrow function way of doing things
// jQuery.fn.ready = (fn) =>
//     $(this).on('turbolinks:load', fn);
jQuery.fn.ready = function (fn) {
    $(this).on('turbolinks:load', fn)
};

// This checks if the hidden fields has values, if it does then it will be used for
// keeping the hidden field open.
$.fn.checkHiddenFieldHasValues = (function (element) {
    var hiddenFieldWithValues = 0;
    var formGroup = element + ' .govuk-form-group ';
    var hiddenFields = ['.govuk-input', '.govuk-date', '.govuk-select', ' .govuk-checkboxes__item .govuk-checkboxes__input'];

    // checks if and of the text, date and select fields contains any value
    $.each(hiddenFields, function (n, content) {
        // Sets the selector content for the value of content (which would be value of text_date_select_checkbox)
        var selectorContent = $(formGroup + content);
        // Sets the selector content for the check box as it has some slight diferrences
        var iteratingCheckBox = n > 2;
        if (iteratingCheckBox) selectorContent = $(element + content);

        for (var i = 0; i < selectorContent.length; i++) {
            if (selectorContent[i].value.length > 0) {
                // Skip the check box if it's unticked
                if (iteratingCheckBox) if (!selectorContent[i].checked) continue;
                hiddenFieldWithValues++;
            }
        }
    });

    return hiddenFieldWithValues;
});

$.fn.extend({
    toggleText: function (a, b) {
        return this.text(this.text() == b ? a : b);
    },

    hideField: function (hideOrNot, element, className) {
        if (hideOrNot != null) {
            $(element).toggleClass(className, hideOrNot);
        }
        else {
            $(element).toggleClass(className)
        }
    },

    // This method allows you to toggle show/hide of fields depending on the values of the radio field
    // @example Show fields when the radio group name of reg_company_contact_address_yes_no has a value of 'A'
    //   $.fn.hideRadioFields("reg_company_contact_address_yes_no", 'A');
    // @example Show multiple fields but one at a time depending on it's radio group's value.
    //   If the radio button of name returns_lbtt_lbtt_return[contingent_events_ind] has a value of 'E' then show
    //   the fields with id deferral_agreed_details.
    //     $.fn.hideRadioFields("returns_lbtt_lbtt_return[contingent_events_ind]", 'E', 'deferral_agreed_details');
    //   If the radio button of name returns_lbtt_lbtt_return[deferral_agreed_ind] has a value of 'X' then show the
    //   fields with id deferral_reference_details.
    //     $.fn.hideRadioFields("returns_lbtt_lbtt_return[deferral_agreed_ind]", 'X', 'deferral_reference_details');
    hideRadioFields: function (radioGroupName, matchValue, id) {
        // sets the default value for each variables - allows both id and matchValue to be null
        id = typeof id !== 'undefined' ? '#' + id : '#hideable';
        matchValue = typeof matchValue !== 'undefined' ? matchValue : 'Y';
        radioGroupName = "input[name = '" + radioGroupName + "']";
        className = "govuk-radios__conditional--hidden";

        // update visibility on change
        $(radioGroupName).change(function () { $.fn.hideField($(radioGroupName + ":checked").val() != matchValue, id, className); });

        // update visibility on load (only if on right page)
        if ($(radioGroupName).length) {
            $.fn.hideField($(radioGroupName + ":checked").val() != matchValue, id, className);
        }
    }
});

$(function () {
    // Detects the browser currently in use.
    // See https://stackoverflow.com/questions/9847580/how-to-detect-safari-chrome-ie-firefox-and-opera-browser to
    // learn more about the other browsers.
    var isIE = /*@cc_on!@*/false || !!document.documentMode;
    var isEdge = !isIE && !!window.StyleMedia;
    // See the if statement below where it's being used to learn more about it.
    var form_dirty_warning_message = $('form').attr('data-form-dirty-warning-message');


    // As the .endsWith is only introduced in ECMAScript6 (ES6), this polyfill is done to deal with it.
    // Most things in ES6 aren't supported in IE11 and this is one of it. See https://kangax.github.io/compat-table/es6/
    // This is used below.
    if (!String.prototype.endsWith) {
        String.prototype.endsWith = function (search, this_len) {
            if (this_len === undefined || this_len > this.length) {
                this_len = this.length;
            }
            return this.substring(this_len - search.length, this_len) === search;
        };
    }

    // This if statement handles all the logic when the user tries to leave a page that consists
    // of form dirty. It alerts with a confirm warning message with the option to accept leaving the page, alternatively,
    // cancel this to stay on their current page.
    //
    // It's current main usage is on the summary pages of both slft and lbtt, when the user tries to leave the
    // page without saving or submitting the form, by clicking on the back or any of the navigational links at the header.
    //
    // Note: This won't display a warning message when browser close, refresh or click the back button
    //
    // To use this:
    // 1. You need to set data property key: 'form-dirty-warning-message' of the page form tag.
    //   i. 'form-dirty-warning-message' is the confirm warning message shown in the alert, which will also be used
    //      to indicate this is a page that can trigger the confirm warning message.
    //
    // 2. You need to apply the CSS class 'external-link' for those HTML
    //    link where a user needs to prompt warning before leaving the current page.
    //
    // There is no need to check for 'external-link' clicks on pages that doesn't have data-form-dirty-warning-message
    if (form_dirty_warning_message != null) {
        $('.external-link').on('click', function () {
            if (!confirm(form_dirty_warning_message)) {
                event.preventDefault();
            }
        });
    }

    // Contains the class for the hideable group fields
    // var hideableGroupClass = '.govuk-details__text';

    // // Don't do the check for hidden fields for each pages that doesn't have any show/hide details
    // // @example This applies to the layout hideable_details,
    // //   <%= render '/layouts/hideable_details/', { clickable_text: [t('filter_show'), t('filter_hide')] } do % > %>
    // // @see _hideable_details.html.erb for more information
    // if ($(hideableGroupClass).length > 0) {
    //     // This is used to determine if the text is toggle-able - mainly used on the clickable filter text.
    //     var filterTextClass = '.filter_text';
    //     // Base class of the clickable text
    //     var clickableTextClass = '.govuk-details__summary-text';
    //     // The details class that can normally be opened/closed (hideable) on the browsers Chrome and Firefox
    //     var openableGroupClass = '.govuk-details';

    //     KEY_ENTER: 13;
    //     KEY_SPACE: 32;
    //     // Show/hide fields when text is clicked. It also works for all browsers.
    //     $(filterTextClass).click(function () {
    //         $.fn.hideField(null, filterTextClass, 'js-hidden');
    //     });

    //     // As the normal GDS standard of the details is not working for either IE11 or Edge,
    //     // this is done so that the clickable texts can be toggled to show/hide the 
    //     // hideable group fields.
    //     if (isIE || isEdge) {
    //         $(clickableTextClass).click(function () {
    //             $(hideableGroupClass).toggle();
    //         });

    //         $('.govuk - details__summary').keypress(function (e) {
    //             if ($.fn.charCode(e) == KEY_ENTER || $.fn.charCode(e) === KEY_SPACE) {
    //                 $(hideableGroupClass).toggle();
    //             }
    //         });

    //     }

    //     // As the page loads, determines whether to keep the hideable group fields open or closed.
    //     if ($.fn.checkHiddenFieldHasValues(hideableGroupClass) > 0) {
    //         // Opens the hideable group
    //         $(openableGroupClass).prop({ open: true });
    //         // This handles the toggle text change
    //         $.fn.hideField(null, filterTextClass, 'js-hidden');
    //     } else {
    //         // Closes the hideable group
    //         $(openableGroupClass).removeAttr("open");
    //         // As the normal toggle of hide and show of the hideable group fields doesn't work
    //         // on both IE11 and Edge, this is done to make sure that it works for them too.
    //         if (isIE || isEdge) {
    //             $(hideableGroupClass).hide();
    //         }
    //     }
    // }



    $("#menu").on("click", function () {
        $("#navigation").toggleClass('govuk-header__navigation--open');
        $("#menu").toggleClass('govuk-header__menu-button--open');
    });
})

// Add event listener to clear the turbolinks cache on logout
document.addEventListener('turbolinks:click', function (event) {
    // console.log("event.data.url: " + event.data.url);
    if (event.data.url.endsWith('/logout')) {
        // console.log("clearing cache");
        Turbolinks.clearCache();
        // Prevent turbolinks firing on this link 
        // otherwise it still caches the current page
        event.preventDefault();
    }
});


