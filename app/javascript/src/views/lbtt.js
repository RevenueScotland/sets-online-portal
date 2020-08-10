$(function() {
  $.fn.hideRadioFields("returns_lbtt_ads[ads_sell_residence_ind]");
  $.fn.hideRadioFields("returns_lbtt_party[is_contact_address_different]");
  // about_the_calculation
  $.fn.hideRadioFields(
    "returns_lbtt_lbtt_return[contingents_event_ind]",
    "Y",
    "deferral_agreed_details"
  );
  $.fn.hideRadioFields(
    "returns_lbtt_lbtt_return[deferral_agreed_ind]",
    "Y",
    "deferral_reference_details"
  );
  // linked_transactions
  $.fn.hideRadioFields("returns_lbtt_lbtt_return[linked_ind]");
  // premium_paid
  $.fn.hideRadioFields("returns_lbtt_lbtt_return[premium_paid]");
  // relief_on_transaction
  $.fn.hideRadioFields(
    "returns_lbtt_lbtt_return[non_ads_reliefclaim_option_ind]"
  );
  $.fn.hideRadioFields("returns_lbtt_ads[ads_reliefclaim_option_ind]");
  // sale_of_business
  $.fn.hideRadioFields("returns_lbtt_lbtt_return[business_ind]");
  // rental_years
  $.fn.hideRadioFields("returns_lbtt_lbtt_return[rent_for_all_years]", "N");
  $.fn.hideRadioFields("returns_lbtt_party[org_type]", "OTHER");
});
