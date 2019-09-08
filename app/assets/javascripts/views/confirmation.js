$(function () {
    $("#multiple-file-upload").toggleClass("govuk-radios__conditional--hidden", $("input[name='dashboard_message[additional_file]']:checked").val() != 'Y');
    $("input[name='dashboard_message[additional_file]']").change(function () {
        $("#multiple-file-upload").toggleClass("govuk-radios__conditional--hidden", this.value != 'Y');
    })
})