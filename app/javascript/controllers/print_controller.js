import { Controller } from "@hotwired/stimulus"

// The print controller provides functionality to support printing a page
// it is linked to a print link, see PrintLinkComponent
export default class extends Controller {
  printPage(event) {
    window.print();
    event.preventDefault();
  }
}
