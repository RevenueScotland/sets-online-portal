// This file contains JS that applies to the radio buttons and hideable group of fields
// of specific pages on the slft-return flow.
// Using the values of the radio button it can show or hide the specified group of fields.
$(function () {
  $.fn.hideRadioFields("returns_slft_slft_return[slcf_yes_no]");
  $.fn.hideRadioFields("returns_slft_slft_return[non_disposal_add_ind]");
  $.fn.hideRadioFields("returns_slft_slft_return[non_disposal_delete_ind]");
  $.fn.hideRadioFields("returns_slft_slft_return[bad_debt_yes_no]");
  $.fn.hideRadioFields("returns_slft_slft_return[removal_credit_yes_no]");

  $.fn.hideRadioFields("returns_slft_waste[nda_ex_yes_no]", "Y", "hide_nda");
  $.fn.hideRadioFields("returns_slft_waste[restoration_ex_yes_no]", "Y", "hide_restoration");
  $.fn.hideRadioFields("returns_slft_waste[other_ex_yes_no]", "Y", "hide_other");
  $.fn.hideRadioFields("returns_slft_slft_return[repayment_yes_no]");
});
