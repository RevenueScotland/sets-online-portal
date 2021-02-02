// This file contains JS that applies to the text field of the relief amount column on
// relief pages of the lbtt return.
//
// This sets the value of those text-fields to 'calculated' and applies the readonly property
// to the field when certain conditions are met.
$(function () {
    var is_value_select_using_keypress = false;
    $('.relief_claim').on('blur', function () {
        selected_relief_type = $(this).val();
        calculated_text = $(this).data("calculated-text")

        if (selected_relief_type.length == 0)
            return
        is_relief_amount_auto_calculated = selected_relief_type.split(">$<")[1];
        var relief_amount_id = $(this).attr('id').replace("relief_type_auto", "relief_amount");
        if (is_relief_amount_auto_calculated == "true") {
            $('#' + relief_amount_id).val(calculated_text);
            $('#' + relief_amount_id).attr('readonly', true);
        }
        // clear only when previously value is calculated
        else if ($('#' + relief_amount_id).val() == calculated_text) {
            $('#' + relief_amount_id).val("");
            $('#' + relief_amount_id).removeAttr("readonly");
        }
        else {
            $('#' + relief_amount_id).removeAttr("readonly");
        }

    });
});