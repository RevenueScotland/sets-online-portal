// This file contains JS that applies to a "dirty" form.
$(function () {
  // To make the code simpler, if the property "data-form-dirty-warning-message" is found on a form,
  // then that means it is using the incomplete-form functionality.
  var warning_message = $('form').attr('data-form-dirty-warning-message');

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
  if (warning_message != null) {
    $('.external-link').on('click', function () {
      if (!confirm(warning_message)) {
        event.preventDefault();
      }
    });
  }
})