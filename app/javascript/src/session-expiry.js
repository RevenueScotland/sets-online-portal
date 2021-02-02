// This file contains JS that handles the session expiry
// It includes functionality to issue a warning prior to session expiry 
// and functionality to clear the turbolinks cache on logout and expiry

// Add the timeout function when the page is refreshed
var warning_timer // set as a global so we can make sure we clear existing timers before creating a new one
$(document).on('turbolinks:load', function () {
  clearTimeout(warning_timer)
  var sessionTtlWarn = $("meta[name='session_ttl_warning']").attr("content");
  if (sessionTtlWarn && !isNaN(sessionTtlWarn)) {
    var sessionTtlWarnMessage = $("meta[name='session_ttl_warning_message']").attr("content");
    warning_timer = setTimeout(function () { alert(sessionTtlWarnMessage); }, sessionTtlWarn * 60000);
  }
})

$(function () {
  // If the page is the session expired page then clear the turbolinks cache on load
  const expiredURL = '/logout-session-expired';
  if (window.location.pathname.endsWith(expiredURL)) {
    Turbolinks.clearCache();
    // The above leaves the current page in the cache so kick of a timer really clear the cache
    setTimeout(function () { Turbolinks.clearCache() }, 500);
  }
})

document.addEventListener('turbolinks:click', function (event) {
  // Add event listener to clear the turbolinks cache on logout
  const logoutURL = '/logout';
  if (event.data.url.endsWith(logoutURL)) {
    Turbolinks.clearCache();
    // Prevent turbolinks firing on this link 
    // otherwise it still caches the current page
    event.preventDefault();
  }
});