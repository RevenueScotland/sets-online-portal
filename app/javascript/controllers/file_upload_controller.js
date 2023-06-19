import { Controller } from "@hotwired/stimulus"

// This provided functionality to make sure that files are uploaded
// when the user presses to go to the next page
export default class extends Controller {
  static targets = ["upload"]

  connect() {
    this.warning_text = this.element.getAttribute('data-warning-text')
  }

  checkUpload(event) {
    var inputs = this.element.querySelectorAll("input[type='file']");
    var files = false
    for (const input of inputs) {
      if (input.value) { files = true; break }
    }
    if (files && confirm(this.warning_text)) {
      this.uploadTarget.click()
      event.preventDefault()
    }
  }
}
