import { Controller } from "@hotwired/stimulus"

// This controller controls case on the input field
export default class extends Controller {
    connect() {
        if ((window.location.pathname.endsWith('/en/accounts/registration/account_details'))
            || (window.location.pathname.endsWith('/en/account/edit-basic'))
            || (window.location.pathname.endsWith('/en/returns/lbtt/party_details'))
            || (window.location.pathname.endsWith('/en/returns/lbtt/representative_contact_details'))
        ) {
            var l_id = document.querySelector('[id$=_nino]');

            if (l_id) {
                l_id = l_id.id
                document.getElementById(l_id).style.textTransform = "uppercase";
            }
        }
    }
}
