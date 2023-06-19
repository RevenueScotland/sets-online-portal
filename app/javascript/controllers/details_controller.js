import { Controller } from "@hotwired/stimulus"

// The details controller makes sure that a details component is open if it contains any 
// input fields that are set
export default class extends Controller {
  connect() {
    var inputs = this.element.querySelectorAll("input, select, checkbox, textarea");
    var data = false;
    for (const input of inputs) {
      if (input.type == 'hidden') continue
      if (input.type == 'checkbox') {
        // check boxes are tricky and selected is not set in DS version
        if (input.getAttribute('data-form').endsWith('-checked')) { data = true; break }
      } else {
        if (input.value) { data = true; break }
      }
    }
    if (data) { this.element.open = true }
  }
}
