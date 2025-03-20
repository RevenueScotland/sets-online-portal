import { Controller } from "@hotwired/stimulus"

// This controller controls focus when the body is replaced so that the title is read out
// this works round the turbo issues where the page is silently replaced
export default class extends Controller {
    connect() {
        if (document.getElementById("error-summary")) {
            var header = this.element.querySelector('h2');
        } else {
            var header = document.getElementsByClassName('ds_skip-links');
        }
        header.style = "outline:none";
        header.focus();
    }
}
