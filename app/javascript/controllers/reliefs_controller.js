import { Controller } from "@hotwired/stimulus"

// Handles setting the amount fields to calculated or n/a in the reliefs page
export default class extends Controller {
  static targets = ["adsAmount", "lbttAmount"]

  connect() {
    this.calculated_text = this.element.getAttribute('data-calculated-text')
    this.na_text = this.element.getAttribute('data-na-text')
  }

  setFields(event) {

    var value = event.currentTarget.value
    var auto_calculated = false
    var relief_type = 'STANDARD'
    if (value !== '') {
      auto_calculated = value.split(">$<")[1];
      relief_type = value.split(">$<")[2];
    }

    // Note we need to clear the fields and remove read only as the user can select a relief type and 
    // then change that selected relief type
    if (relief_type == "STANDARD" || relief_type == "LBTT") {
      if (auto_calculated == "true") {
        this.lbttAmountTarget.value = this.calculated_text;
        this.lbttAmountTarget.setAttribute('readonly', true);
      } else {
        this.lbttAmountTarget.value = "";
        this.lbttAmountTarget.removeAttribute('readonly');
      }
    } else {
      this.lbttAmountTarget.value = this.na_text;
      this.lbttAmountTarget.setAttribute('readonly', true);
    };

    if (relief_type == "STANDARD" || relief_type == "ADS") {
      if (auto_calculated == "true") {
        this.adsAmountTarget.value = this.calculated_text;
        this.adsAmountTarget.setAttribute('readonly', true);
      } else {
        this.adsAmountTarget.value = "";
        this.adsAmountTarget.removeAttribute('readonly');
      }
    } else {
      this.adsAmountTarget.value = this.na_text;
      this.adsAmountTarget.setAttribute('readonly', true);
    };
  }
}
