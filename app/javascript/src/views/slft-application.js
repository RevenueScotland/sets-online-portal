// This file contains JS that applies to the radio buttons, checkbox and hideable group of fields
// of specific pages on the slft-application flow.
// Using the values of the radio button or a checkbox it can show or hide the specified group of fields.
$(function () {
  $.fn.hideRadioFields("applications_slft_applications[existing_agreement]", "Y");
  $.fn.hideCheckboxFields("applications_slft_applications_supporting_document_list_other");
  $.fn.hideRadioFields("applications_slft_applications[naturally_occurring]", "Y");
  $.fn.hideRadioFields("applications_slft_sites[operator_separate_mailing_address]", "Y");
});
