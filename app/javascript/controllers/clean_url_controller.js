import { Controller } from "@hotwired/stimulus"

// The print controller provides functionality to support printing a page
// it is linked to a print link, see PrintLinkComponent
export default class extends Controller {
	connect() {
		if (window.location.search) {
			const cleanUrl = window.location.origin + window.location.pathname
			window.history.replaceState({}, document.title, cleanUrl)
		}
	}
}
