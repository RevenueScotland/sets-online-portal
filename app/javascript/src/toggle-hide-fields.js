// This file contains JS that applies to the toggle hiding and showing of specific fields,
// which can be done by clicking a button/link or simply by loading a page.

// This checks if the hidden fields has values, if it does then it will be used for
// keeping the hidden field open.
$.fn.checkHiddenFieldHasValues = (function (element) {
  var hiddenFieldWithValues = 0;
  var formGroup = element + ' .govuk-form-group ';
  var hiddenFields = ['.govuk-input', '.govuk-date', '.govuk-select', ' .govuk-checkboxes__item .govuk-checkboxes__input'];

  // checks if and of the text, date and select fields contains any value
  $.each(hiddenFields, function (n, content) {
    // Sets the selector content for the value of content (which would be value of text_date_select_checkbox)
    var selectorContent = $(formGroup + content);
    // Sets the selector content for the check box as it has some slight diferrences
    var iteratingCheckBox = n > 2;
    if (iteratingCheckBox) selectorContent = $(element + content);

    for (var i = 0; i < selectorContent.length; i++) {
      if (selectorContent[i].value.length > 0) {
        // Skip the check box if it's unticked
        if (iteratingCheckBox) if (!selectorContent[i].checked) continue;
        hiddenFieldWithValues++;
      }
    }
  });

  return hiddenFieldWithValues;
});

$.fn.extend({
  // toggleText: function (a, b) {
  //   return this.text(this.text() == b ? a : b);
  // },

  hideField: function (hideOrNot, element, className) {
    if (hideOrNot != null) {
      $(element).toggleClass(className, hideOrNot);
    }
    else {
      $(element).toggleClass(className)
    }
  },

  // This method allows you to toggle show/hide of fields depending on the values of the radio field
  // @example Show fields when the radio group name of reg_company_contact_address_yes_no has a value of 'A'
  //   $.fn.hideRadioFields("reg_company_contact_address_yes_no", 'A');
  // @example Show multiple fields but one at a time depending on it's radio group's value.
  //   If the radio button of name returns_lbtt_lbtt_return[contingent_events_ind] has a value of 'E' then show
  //   the fields with id deferral_agreed_details.
  //     $.fn.hideRadioFields("returns_lbtt_lbtt_return[contingent_events_ind]", 'E', 'deferral_agreed_details');
  //   If the radio button of name returns_lbtt_lbtt_return[deferral_agreed_ind] has a value of 'X' then show the
  //   fields with id deferral_reference_details.
  //     $.fn.hideRadioFields("returns_lbtt_lbtt_return[deferral_agreed_ind]", 'X', 'deferral_reference_details');
  hideRadioFields: function (radioGroupName, matchValue, id) {
    radioGroupName = "input[name = '" + radioGroupName + "']";
    // We're escaping the method when we can't find the element with this name, so that we don't go through
    // the whole method.
    if ($(radioGroupName).length == 0) return;

    // sets the default value for each variables - allows both id and matchValue to be null
    id = typeof id !== 'undefined' ? '#' + id : '#hideable';
    matchValue = typeof matchValue !== 'undefined' ? matchValue : 'Y';
    className = "govuk-radios__conditional--hidden";

    // update visibility on change
    $(radioGroupName).change(function () { $.fn.hideField($(radioGroupName + ":checked").val() != matchValue, id, className); });

    // update visibility on load (only if on right page)
    if ($(radioGroupName).length) {
      $.fn.hideField($(radioGroupName + ":checked").val() != matchValue, id, className);
    }
  },

  // Similarly to the hideRadioFields, this also hides the fields when the checkbox is ticked.
  // The contents of the matchValue is either a boolean value of true or false, but this will default
  // to true when there's no passed in value. This means that if the check box is ticked, we show the field, if it
  // is not ticked then hide it.
  hideCheckboxFields: function (checkboxID, matchValue, hideableSectionID) {
    checkboxID = "#" + checkboxID;
    // We're escaping the method when we can't find the element with this id, so that we don't go through
    // the whole method.
    if ($(checkboxID).length == 0) return;

    // sets the default value for each variables - allows both hideableSectionID and matchValue to be null
    hideableSectionID = typeof hideableSectionID !== 'undefined' ? '#' + hideableSectionID : '#hideable';
    matchValue = typeof matchValue !== 'undefined' ? matchValue : true;
    toggleableClassName = "govuk-checkboxes__conditional--hidden";

    // update visibility on checkbox tick
    $(checkboxID).click(function () { $(hideableSectionID).toggleClass(toggleableClassName); });

    // update visibility on load (only if on the right page)
    hideField = ($(checkboxID).is(":checked") == matchValue) ? false : true;
    if ($(checkboxID).length) {
      $.fn.hideField(hideField, hideableSectionID, toggleableClassName);
    }
  }

});

$(function () {
  // Toggle hide and shows the header's navigation bar on click on the menu link
  $("#menu").on("click", function () {
    $("#navigation").toggleClass('govuk-header__navigation--open');
    $("#menu").toggleClass('govuk-header__menu-button--open');
  });
})