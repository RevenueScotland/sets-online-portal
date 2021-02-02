// This file contains JS that applies to the radio buttons and hideable group of fields
// of the message's confirmation page.
// Using the values of the radio button it can show or hide the specified group of fields,
// which in this case is the multiple file upload hideable fields
$(function () {
    $("#multiple-file-upload").toggleClass("govuk-radios__conditional--hidden", $("input[name='dashboard_message[additional_file]']:checked").val() != 'Y');
    $("input[name='dashboard_message[additional_file]']").change(function () {
        $("#multiple-file-upload").toggleClass("govuk-radios__conditional--hidden", this.value != 'Y');
    })
})