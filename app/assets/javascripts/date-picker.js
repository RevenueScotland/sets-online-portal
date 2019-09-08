$(document).on('turbolinks:load', function () {
  $(".datepicker").datepicker({
    dateFormat: 'dd/mm/yy',
    changeYear: true,
    yearRange: 'c-40:c+40'
  });
});