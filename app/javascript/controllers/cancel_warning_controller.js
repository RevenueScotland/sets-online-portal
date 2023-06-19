import { Controller } from "@hotwired/stimulus"

// Handles the timeout warning message
export default class extends Controller {
    static values = {
        message: String
    }

    displayWarning(event) {
        if (!confirm(this.messageValue)) {
            event.preventDefault();
        }
    }
}
