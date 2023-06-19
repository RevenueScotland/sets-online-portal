import { Controller } from "@hotwired/stimulus"

// Initialise a window level object to hold the timer so we can clear it
window.TimeoutWarning = {};

// Handles the timeout warning message
export default class extends Controller {
    static values = {
        minutes: Number,
        message: String
    }

    connect() {
        clearTimeout(window.TimeoutWarning.warningTimer);
        var localMessage = this.messageValue;
        window.TimeoutWarning.warningTimer = setTimeout(function () { alert(localMessage); }, this.minutesValue * 60000);
    }

    disconnect() {
        clearTimeout(window.TimeoutWarning.warningTimer);
    }
}
