$(function () {
    var is_value_select_using_keypress = false;
    $('#search_results').on('blur', function () {
        // reset value as we don't need this flag this event
        is_value_select_using_keypress = false;
        this.click();
    });

    $('#search_results').on('click', function () {
        // to avoid click event for firing when user select value using
        // keypress or no value select from dropdown list
        if (this.selectedIndex > 0 && !is_value_select_using_keypress) {
            $('[name="select"]').click();
        }
        else {
            // reset the value
            is_value_select_using_keypress = false;
        }
    });

    $('#search_results').on('keydown', function () {
        is_value_select_using_keypress = true;
    });
}); 