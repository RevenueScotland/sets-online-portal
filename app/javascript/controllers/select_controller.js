import { Controller } from "@hotwired/stimulus"

// The select controller provides functionality to support submitting a form when an 
// item is selected from a select list. It assumes there is a select list and an associated button
// The controller hides the button when connected and then when the select list value is changed
// clicks on the button
export default class extends Controller {
  static targets = ["button"]
  connect() {
    const element = this.buttonTarget;
    // This handles the revscot style buttons where there is an outer div that contains
    // the button and the triangle. The outer div is added in the css
    element.parentElement.classList.add('fully-hidden');
  }

  clickTarget() {
    this.buttonTarget.click();
  }
}
