import { Controller } from "@hotwired/stimulus"

// The visibility controller provides functionality to support hiding a region when a radio group is selected
export default class extends Controller {
  static targets = ["region"]

  static values = {
    visible: String
  }

  connect() {
    // Find the checked triggering element with the correct value
    var triggerControl = this.element.querySelector(`[data-action='visibility#toggleRegion'][value=${this.visibleValue}]:checked`)

    this.toggleRegionForValue(((triggerControl === null) ? "" : triggerControl.value))
  }

  toggleRegion(event) {
    if (event.currentTarget.type == 'checkbox') {
      // For a checkbox ignore if not the target value
      if (event.currentTarget.value == this.visibleValue) {
        this.toggleRegionForValue((event.currentTarget.checked ? event.currentTarget.value : null))
      }
    } else {
      this.toggleRegionForValue(event.currentTarget.value)
    }
  }

  toggleRegionForValue(value) {
    if (value == this.visibleValue) {
      this.regionTarget.classList.remove('fully-hidden');
    } else {
      this.regionTarget.classList.add('fully-hidden');
    }
  }
}
