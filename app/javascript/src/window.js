// This file contains JS that applies to the window on specific button/link click.
$(function () {
  // This method prints the contents of the current window.
  $('.print').on("click", function () {
    window.print();
  });

  // This method will close current window
  $('.close').on("click", function () {
    window.close();
  });
})