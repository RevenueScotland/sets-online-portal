// This file contains JS that applies to the radio buttons and hideable group of fields
// of the account's registration flow.
// Using the values of the radio button it can show or hide the specified group of fields.
$(function () {
    $.fn.hideRadioFields("account[reg_company_contact_address_yes_no]", 'N');
});