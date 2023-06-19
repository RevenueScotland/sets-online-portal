import { Controller } from "@hotwired/stimulus"

// This controller controls focus when the body is replaced so that the title is read out
// this works round the turbo issues where the page is silently replaced
export default class extends Controller {
    connect() {
        var header = this.element.querySelector('h1');
        header.style = "outline:none";
        header.focus();
    }
}
