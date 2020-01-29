// This is mainly used for displaying a combobox text field with autocomplete functionality and a button to
// show all in a drop - down format.
//
// Used example in url https://jqueryui.com/autocomplete/#combobox to develop this.
// CSS used for it is in /vendor/assets/stylesheets/jquery-ui.min.css which is applied to application.scss
// and source is http://jqueryui.com/download/. Version 1.12.1.
//
// Related icons used are in /assets/images/ui-icons_<hex>_256x240.png
// @example How to use this on a page - simply add { text_auto_complete: true } in the options (3rd parameter) section of the select field
//   <%= form.select : country, ReferenceData:: ReferenceValue.list('COUNTRIES', 'SYS', 'RSTU'), { text_auto_complete: true }, {} %>
//   @see party_details.html.erb for an example of where it's being used.
$(function () {
    $.widget("custom.combobox", {
        _create: function () {
            // As we're using a select field to create the combobox, this is being hidden.
            this.element.hide();

            // Pass the name attribute in to the autocomplete-combobox text field.
            // The id is passed so that cucumber testing could identify the field by its label.
            // See the error parameter in the _createAutocomplete to see where this is being used.
            this._createAutocomplete(this.element.attr("name"), this.element.attr("id"),
                this.element.attr("aria-describedby"), this.element.hasClass("govuk-select--error"));
            this._createShowAllButton();
            this.element.removeAttr("id");
        },

        _createAutocomplete: function (name, id, describedby, error) {
            var selected = this.element.children(":selected"),
                value = selected.val() ? selected.text() : "";

            this.input = $("<input>")
                // inserts the input text field before the select element that this replaces.
                .insertBefore(this.element)
                .val(value)
                // Passes in the element's name attribute from the now-hidden select field.
                .attr("name", name)
                .attr("id", id)
                .attr("title", "")
                .attr("type", "text")
                .attr("placeholder", "Enter text or choose from list")
                .addClass("govuk-!-width-one-third govuk-input ") //  custom-combobox-input ui-widget ui-widget-content ui-state-default ui-corner-left ")
                .autocomplete({
                    delay: 0,
                    minLength: 0,
                    // source is where we're getting the data to do the autocompletion
                    source: $.proxy(this, "_source")
                })
                .tooltip({
                    classes: {
                        "ui-tooltip": "ui-state-highlight"
                    }
                })
                .attr("autocomplete", "off");

            if (describedby != null) {
                this.input.attr("aria-describedby", describedby);
            }

            // The error class is added if the field itself is throwing an error. 
            // See base_form_builder's method gds_html_error_class.
            // This is needed as it is adding the error class to the select-field which is being hidden so that
            // the input text field will replace it.
            if (error) {
                this.input.addClass("govuk-input--error");
            }

            this._on(this.input, {
                autocompleteselect: function (event, ui) {
                    ui.item.option.selected = true;
                    this._trigger("select", event, {
                        item: ui.item.option
                    });
                },

                autocompletechange: "_removeIfInvalid"
            });
        },

        // The show all button which is on the right side of the field
        _createShowAllButton: function () {
            var input = this.input,
                wasOpen = false;

            $("<a>")
                .attr("tabIndex", -1)
                .attr("title", "Show all items")
                .tooltip()
                .insertBefore(this.element)
                .button({
                    icons: {
                        primary: "ui-icon-triangle-1-s"
                    },
                    text: false
                })
                .removeClass("ui-corner-all")
                // To format it so that the button is in the text field, see custom-combobox-customized-button of aplication.scss
                .addClass("custom-combobox-toggle ui-corner-right") // custom-combobox-customized-button")
                .on("mousedown", function () {
                    wasOpen = input.autocomplete("widget").is(":visible");
                })
                .on("click", function () {
                    input.trigger("focus");

                    // Close if already visible
                    if (wasOpen) {
                        return;
                    }

                    // Pass empty string as value to search for, displaying all results
                    input.autocomplete("search", "");
                });
        },

        _source: function (request, response) {
            // Contains the text input's value, which will be used to match with the texts on the list of options.
            var field_text = $.ui.autocomplete.escapeRegex(request.term);
            // Matches with a word's first character(s) that's anywhere in the sentence using regex, the word can be
            // separated by spaces or dashes.
            // Straight out of regex: It should match with any character with a space or dash first and then the user's
            //                        input OR it just needs to match with the user's input. The characters that the
            //                        user input should be the first characters of the word it matches to.
            var matcher = new RegExp("^((.*\\s?\-?)?)" + field_text, "i");
            response(this.element.children("option").map(function () {
                // Options's text
                var text = $(this).text();
                if (this.value && (!request.term || matcher.test(text)))
                    return {
                        label: text,
                        value: text,
                        option: this
                    };
            }));
        },

        _removeIfInvalid: function (event, ui) {

            // Selected an item, nothing to do
            if (ui.item) {
                return;
            }

            // Search for a match (case-insensitive)
            var value = this.input.val(),
                valueLowerCase = value.toLowerCase(),
                valid = false;
            this.element.children("option").each(function () {
                if ($(this).text().toLowerCase() === valueLowerCase) {
                    this.selected = valid = true;
                    return false;
                }
            });

            // Found a match, nothing to do
            if (valid) {
                return;
            }

            // Remove invalid value
            this.input
                .val("")
                .attr("title", value + " didn't match any item")
                .tooltip("open");
            this.element.val("");
            this._delay(function () {
                this.input.tooltip("close").attr("title", "");
            }, 2500);
            this.input.autocomplete("instance").term = "";
        },

        _destroy: function () {
            this.wrapper.remove();
            this.element.show();
        }
    });

    $(".combobox").combobox();
});