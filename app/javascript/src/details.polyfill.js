
// Copy the code from URL
// https://github.com/alphagov/govuk_frontend_toolkit/blob/master/javascripts/govuk/details.polyfill.js
// To fix summary details tag specifically for IE Browser.
// <details> polyfill
// http://caniuse.com/#feat=details

// FF Support for HTML5's <details> and <summary>
// https://bugzilla.mozilla.org/show_bug.cgi?id=591737

// http://www.sitepoint.com/fixing-the-details-element/

$(function (GOVUKFrontend) {
  GOVUKFrontend.details = {
    NATIVE_DETAILS: typeof document.createElement('details').open === 'boolean',
    KEY_ENTER: 13,
    KEY_SPACE: 32,

    // Create a started flag so we can prevent the initialisation
    // function firing from both DOMContentLoaded and window.onload
    started: false,

    // Cross-browser character code / key pressed
    charCode: function (e) {
      return (typeof e.which === 'number') ? e.which : e.keyCode
    },

    // Initialisation function
    addDetailsPolyfill: function (list, container) {
      container = container || document.body
      // If this has already happened, just return
      // else set the flag so it doesn't happen again
      if (GOVUKFrontend.details.started) {
        return
      }
      GOVUKFrontend.details.started = true
      // Get the collection of details elements, but if that's empty
      // then we don't need to bother with the rest of the scripting
      if ((list = container.getElementsByTagName('details')).length === 0) {
        return
      }
      // else iterate through them to apply their initial state
      var n = list.length
      var i = 0
      for (i; i < n; i++) {
        var details = list[i]

        // Save shortcuts to the inner summary and content elements
        details.__summary = details.getElementsByTagName('summary').item(0)
        details.__content = details.getElementsByTagName('div').item(0)

        if (!details.__summary || !details.__content) {
          return
        }
        // If the content doesn't have an ID, assign it one now
        // which we'll need for the summary's aria-controls assignment
        if (!details.__content.id) {
          details.__content.id = 'details-content-' + i
        }

        // Add ARIA role="group" to details
        details.setAttribute('role', 'group')

        // Add role=button to summary
        details.__summary.setAttribute('role', 'button')

        // Add aria-controls
        details.__summary.setAttribute('aria-controls', details.__content.id)

        // Set tabIndex so the summary is keyboard accessible for non-native elements
        // http://www.saliences.com/browserBugs/tabIndex.html
        if (!GOVUKFrontend.details.NATIVE_DETAILS) {
          details.__summary.tabIndex = 0
        }

        // Detect initial open state
        var openAttr = details.getAttribute('open') !== null

        //As the page loads, determines whether to keep the hideable group fields open or closed.
        //This code is specific to our project requirement
        if ($.fn.checkHiddenFieldHasValues('.govuk-details__text') > 0) {
          details.setAttribute('open', 'open')
          openAttr = true
        }

        if (openAttr === true) {
          details.__summary.setAttribute('aria-expanded', 'true')
          details.__content.setAttribute('aria-hidden', 'false')
        } else {
          details.__summary.setAttribute('aria-expanded', 'false')
          details.__content.setAttribute('aria-hidden', 'true')
          if (!GOVUKFrontend.details.NATIVE_DETAILS) {
            details.__content.style.display = 'none'
          }
        }

        // Create a circular reference from the summary back to its
        // parent details element, for convenience in the click handler
        details.__summary.__details = details
      }

    },

    // Define a statechange function that updates aria-expanded and style.display
    // Also update the arrow position
    statechange: function (summary) {
      var filterTextClass = '.filter_text';
      var expanded = summary.__details.__summary.getAttribute('aria-expanded') === 'true'
      var hidden = summary.__details.__content.getAttribute('aria-hidden') === 'true'

      summary.__details.__summary.setAttribute('aria-expanded', (expanded ? 'false' : 'true'))
      summary.__details.__content.setAttribute('aria-hidden', (hidden ? 'false' : 'true'))

      // Show/hide fields when text is clicked. It also works for all browsers.
      // This code is specific to our project requirement
      $.fn.hideField(null, filterTextClass, 'js-hidden');

      summary.__details.__content.style.display = (expanded ? 'none' : '')
      var hasOpenAttr = summary.__details.getAttribute('open') !== null
      if (!hasOpenAttr) {
        summary.__details.setAttribute('open', 'open')
      } else {
        summary.__details.removeAttribute('open')
      }

      if (summary.__twisty) {
        summary.__twisty.firstChild.nodeValue = (expanded ? '\u25ba' : '\u25bc')
        summary.__twisty.setAttribute('class', (expanded ? 'arrow arrow-closed' : 'arrow arrow-open'))
      }

      return true
    },
    // Bind two load events for modern and older browsers
    // If the first one fires it will set a flag to block the second one
    // but if it's not supported then the second one will fire
    init: function ($container) {
      GOVUKFrontend.details.addDetailsPolyfill()
    }
  }
  GOVUKFrontend.details.init();

  // Show/hide fields when text is clicked. It also works for all browsers.
  $('.govuk-details__summary').click(function (e) {
    GOVUKFrontend.details.statechange(this)
    e.preventDefault();
    return
  });

  // handle keypress event
  $('.govuk-details__summary').keypress(function (e) {
    if (GOVUKFrontend.details.charCode(e) === GOVUKFrontend.details.KEY_ENTER || GOVUKFrontend.details.charCode(e) === GOVUKFrontend.details.KEY_SPACE) {
      e.preventDefault();
      this.click();
    }
  });

})
