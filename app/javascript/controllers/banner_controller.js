import { Controller } from "@hotwired/stimulus"
// This uses the standard revenue scotland storage logic for cookies
import _storage from '../../../node_modules/@scottish-government/pattern-library/src/base/tools/storage/storage';

// The banner controller handles closing a banner message, and recording the fact
export default class extends Controller {

  storage = _storage;

  connect() {
    var button = this.element.querySelector(".ds_notification__close");
    this.cookie_name = `banner-${this.element.id}`;
    var cookie_value = this.storage.getCookie(this.cookie_name)
    if (cookie_value == 'Y') {
      this.element.parentNode.removeChild(this.element);
    } else {
      button.style.display = "block";
    }
  }

  persistClose() {
    this.element.parentNode.removeChild(this.element);
    this.storage.setCookie(
      this.storage.categories.preferences,
      this.cookie_name,
      'Y',
      1
    );
  }
}
