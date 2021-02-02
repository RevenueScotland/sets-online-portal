// This file contains JS that applies to the google analytics feature
// From https://gist.github.com/DimaSamodurov/127c39244d0b411bfb474a8102a83497
window.dataLayer = window.dataLayer || [];
function gtag() {
    dataLayer.push(arguments);
}

function gtag_event(event) {
    if (typeof gtag === 'function') {
        gtag('event', event);
    }
}

// note: in both calcEventName and addEventsToButtons button also refers to
//  input submit
function calcEventName(page_view_name, button) {
    return page_view_name.concat('-', button.id.replace('.', ''));
}

function addEventsToButtons(page_view_name, class_name) {
    var buttons = document.getElementsByClassName(class_name);
    for (var i = 0, len = buttons.length; i < len; i++) {
        var event_name = calcEventName(page_view_name, buttons[i]);
        buttons[i].addEventListener('click', function () { gtag_event(event_name) });
    }
}

document.addEventListener('turbolinks:load', function (event) {
    // Do not add the event if tracking id is not set
    if ($("meta[name='analytic_tracking_id']").attr("content") == undefined)
        return

    if (typeof gtag === 'function') {
        var page_view = document.getElementById("page_view");
        gtag('js', new Date());
        gtag('config', $("meta[name='analytic_tracking_id']").attr("content"), {
            'page_location': event.data.url,
            'page_path': '/' + page_view.value
        });
        addEventsToButtons(page_view.value, " scot-rev-button");
    }
});

// Global site tag (gtag.js) - Google Analytics if we have the tracking id
if ($("meta[name='analytic_tracking_id']").attr("content") != undefined)
    $.getScript("https://www.googletagmanager.com/gtag/js?id=" + $("meta[name='analytic_tracking_id']").attr("content"))
