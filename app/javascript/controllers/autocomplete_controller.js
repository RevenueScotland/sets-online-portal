import { Controller } from "@hotwired/stimulus"

// The autocomplete controller provides functionality to support using a search through a select
// rather than use popping the list
// It is based on https://designsystem.gov.scot/components/autocomplete/ with the following differences
// a) We add the ability to show all the entries
// b) The entries are shown in a scrolling region
// c) We work round an issue where the highlight causes the page to hang if the existing value is blank
export default class extends Controller {
  static targets = ["select", "search"]
  static values = {
    extraHint: String
  }

  connect() {

    // Hide Select element
    this.selectTarget.classList.add('fully-hidden');
    // Make Search visible
    this.searchTarget.classList.remove('fully-hidden');
    // Get list of options
    this.selectOptions = this.selectTarget.querySelector("select").querySelectorAll("option");

    // Copy currently selected option (if there is one) to the select field
    var selectedText = ''
    var selectedOption = this.selectTarget.querySelector("select").querySelector("option[selected='selected']")
    if (selectedOption != null) {
      var selectedText = selectedOption.text
    };
    this.searchTarget.querySelector("input").value = selectedText;

    this.add_hint_text();

    class RSAutocomplete extends window.DS.components.Autocomplete {
      constructor(element, selectOptions, options = {}) {
        super(element, 'dummy', options);
        this.selectOptions = selectOptions;
        // Create a reference to the show all button
        this.showAllElement = element.querySelector('#show_all');
      }

      init() {
        super.init()

        // Add listener on the show all button
        this.showAllElement.addEventListener("click", (event) => {
          event.preventDefault();
          this.fetchSuggestions('').then(suggestions => {
            this.suggestions = suggestions;
            this.showSuggestions(this.suggestions);
            this.updateStatus(`There ${suggestions.length === 1 ? 'is' : 'are'} ${suggestions.length} ${suggestions.length === 1 ? 'option' : 'options'}`, 1500);
          })
          this.inputElement.focus();
        });
      }

      fetchSuggestions(searchTerm) {
        var upperSearchTerm = searchTerm.toUpperCase()
        var results = Array.from(this.selectOptions).map(function (option) {
          var match = option.text.toUpperCase().indexOf(upperSearchTerm)
          if (match >= 0 && option.value != '') {
            return {
              key: option.value,
              displayText: option.text,
              weight: match,
              type: "",
              category: ""
            }
          }
        }).filter(item => item !== undefined);

        return (Promise.resolve(results))
      }

      showSuggestions(suggestions) {
        // the below is a hack as the highlight code hangs if the matching value is an empty string
        // \\S matches all of the text
        if (this.inputElement.value == '') {
          this.inputElement.value = '\\S'
        }
        super.showSuggestions(suggestions)

        if (this.inputElement.value == '\\S') {
          this.inputElement.value = ''
        }

        // Scroll active suggestion into view
        var activeElement = this.listBoxElement.querySelector('.active')
        if (activeElement != null) {
          activeElement.scrollIntoView()
        }
      }
    }

    var autocomplete = new RSAutocomplete(
      this.element,
      this.selectOptions,
      {
        minLength: 1
      });

    autocomplete.init();
  }

  copySelected() {

    // Get the value as they may have typed and not selected from the list so always go back to the value
    var selectedText = this.searchTarget.querySelector("input").value
    // If we now have text try and get the index into the options
    var selectIndex = -1
    if (selectedText != '') {
      selectIndex = Array.from(this.selectOptions).findIndex(option => option.text.toUpperCase() == selectedText.toUpperCase())
    }
    this.selectTarget.querySelector("select").selectedIndex = selectIndex;
    // Clear the value if the entered value does not match
    if (selectIndex == -1) {
      this.searchTarget.querySelector("input").value = ''
    }
  }

  add_hint_text() {
    var hintElement = this.element.querySelector(".ds_hint-text");
    if (hintElement != null) {
      hintElement.innerHTML = hintElement.textContent + "<br/>" + this.extraHintValue;
    } else {
      var LabelElement = this.element.querySelector(".ds_label");
      var id = LabelElement.getAttribute('for') + "-hint";
      var hintElementHTML = `<p id="${id}" class="ds_hint-text">${this.extraHintValue}</p>`;
      LabelElement.insertAdjacentHTML("afterend", hintElementHTML);
    }
  }
}
