import { Controller } from "@hotwired/stimulus"

// This controller moves the conditional warning from under the radio group to under the selected radio button
export default class extends Controller {
    connect() {
        if (window.location.pathname.endsWith('/en/accounts/registration/taxes')
            || (window.location.pathname.endsWith('/en/returns/lbtt/declaration'))
            || (window.location.pathname.endsWith('/en/returns/slft/declaration'))
            || (window.location.pathname.endsWith('/en/returns/sat/declaration_calculation'))) {
            const selectedElement = document.querySelector("#main-content > div.ds_layout__content > form > div > div.ds_inset-text");
            const radioButtons = Array.from(document.querySelectorAll('input[type="radio"]'));

            const values = ['Land and Building Transaction Tax', 'BACS']

            let LookupRadio = null;

            for (const radio of radioButtons) {
                const label = radio.labels && radio.labels[0];
                if (label) {
                    const labelText = label.textContent.trim();
                    if (values.some(i => labelText.includes(i))) {
                        LookupRadio = radio;
                    }
                }
            }

            let success = false;
            if (LookupRadio) {
                const targetParent = LookupRadio.parentElement;
                if (targetParent) {
                    targetParent.insertAdjacentElement('afterend', selectedElement);
                    success = true;
                }
            }

            const data = {
                success: success,
                foundLookupRadio: !!LookupRadio,
                selectedElementMoved: selectedElement.parentElement !== null // Check if the element is still in the DOM
            };
        }
    }
}
