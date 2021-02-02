// This file contains JS that applies to the radio buttons and hideable group of fields
// of specific pages on the claim flow.
// Using the values of the radio button it can show or hide the specified group of fields.
$(function () {
  $.fn.hideRadioFields("claim_claim_payment[reason]", "OTHER");
  $.fn.hideRadioFields("claim_claim_payment[full_repayment_of_ads]", "N");
  $.fn.hideRadioFields("returns_lbtt_party[same_address]", "N");
});
