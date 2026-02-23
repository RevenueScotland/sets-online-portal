import { Controller } from "@hotwired/stimulus"

// This controller is used for restricting special characters in a text field
export default class extends Controller {
	connect() {
		this.restrictedRegex = /[\[\]\{\}\*¬|~"=_]/g;

		this.restrictedInputs = this.element.querySelectorAll("[data-skip_special_chars='true']");
		this.restrictedInputs.forEach(input => {
			input.addEventListener("input", this.filter.bind(this));
		});
	}

	filter(event) {
		event.target.value = event.target.value.replace(this.restrictedRegex, "");
	}
}
