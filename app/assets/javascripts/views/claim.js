$(function () {
  $.fn.hideRadioFields("claim_claim_payment[reason]", "OTHER");

  $("#multiple-claim-file-upload").toggleClass(
    "govuk-radios__conditional--hidden",
    $("input[name='claim_claim_payment[more_uploads]']:checked").val() != "Y"
  );
  $("input[name='claim_claim_payment[more_uploads]']").change(function () {
    $("#multiple-claim-file-upload").toggleClass(
      "govuk-radios__conditional--hidden",
      this.value != "Y"
    );
  });
});
