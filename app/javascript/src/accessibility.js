// This file contains JS that applies mainly to the accessibility of the application.
$(function () {
  // The heading can now be focused as it has a property of tabindex. This is added so that we don't see the
  // heading 1 with an outline when it's focused.
  $('h1').css('outline', 'none');

  // Focuses on the error summary if it exists. Normally the error summary isn't shown unless the form has been
  // submitted and the page reloads.
  $('.govuk-error-summary').focus();
})

document.addEventListener('turbolinks:click', function () {
  // This allows the screen reader to read at least the heading parts of the page when we click on 
  // a (turbo)link.
  // It focuses on the header first as some page load already focuses on the h1, which would not
  // notify the screen reader that the focus has changed.
  // In most (turbo)link click, the screen reader should read out the contents of the header and then
  // it always read the heading 1 <h1>.
  // This is also defined here as we don't want the focus to change on any button clicks which the
  // screen reader should read the full page normally.
  document.addEventListener('turbolinks:load', function () {
    $('.govuk-header').attr("tabindex", "-1").css('outline', 'none');
    $('.govuk-header').focus();
    setTimeout(function () { $('h1').focus() }, 0);
  });
});