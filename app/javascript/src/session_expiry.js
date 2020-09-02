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