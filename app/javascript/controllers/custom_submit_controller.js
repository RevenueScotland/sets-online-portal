import { Controller } from "@hotwired/stimulus"

// This controller enables to submit on a button(which is not of type submit)
// To submit the form it is a part of AND
// it uses data params name and value to build any custom data that we need 
// for successful form submission or may need as part of the form to be submitted
export default class extends Controller {
	submit(event) {
		const form = this.element.closest('form');
		const paramName = this.element.dataset.paramName;
		const paramValue = this.element.dataset.paramValue;
		if (paramName) {
			const hiddenInp = document.createElement('input');
			hiddenInp.type = 'hidden';
			hiddenInp.name = paramName;
			hiddenInp.value = paramValue;
			form.appendChild(hiddenInp);
		}
		form.submit();
	}
}
