import { Controller } from "@hotwired/stimulus"

// The DS controller initialises the digital scotland javascript
export default class extends Controller {
    connect() {
        window.DS.initAll()
        // Make sure we have scrolled to any autofocus elements
        var autofocus = this.element.querySelectorAll('[autofocus]')
        if ((autofocus[0]) && (location.hash == '')) {
            autofocus[0].scrollIntoView();
        }
    }
}
