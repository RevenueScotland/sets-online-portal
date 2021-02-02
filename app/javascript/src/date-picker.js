// This file contains JS that applies to the datepicker feature of a date field, which are normally used on
// browsers that do not have their native datepicker.
//
// This datepicker has the ability to select a date, go to next or previous month and select a year.
//
// This was built using jquery-ui datepicker and also from https://dequeuniversity.com/library/aria/date-pickers/sf-date-picker
// so that the datepicker is accessible, but the other source's code was further modified to fit to the
// standards and functionalities that are needed.
$(function () {
  $('.datepicker').datepicker({
    showOn: 'button',
    buttonImageOnly: false,
    buttonText: '',
    dayNamesShort: ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"],
    onClose: closeThisDatepicker,
    onSelect: closeThisDatepicker,

    dateFormat: 'dd/mm/yy',
    changeYear: true,
    yearRange: 'c-40:c+40'
  });

  // No need to execute the methods if there's no date_field that needs a datepicker
  if ($('.datepicker').length > 0) {
    $('.ui-datepicker-trigger').attr('aria-label', 'Date picker');
    dayTripper();
  }
});

// Hides the date picker and re-focuses to the date field that is associated with the date picker.
function closeThisDatepicker() {
  // Make the rest of the page accessible again
  $("#dp-container").removeAttr('aria-hidden');
  $("#skipnav").removeAttr('aria-hidden');
  // and let's re-focus back on the field.
  $(this).datepicker('hide');
  $(this).focus();
}


function dayTripper() {
  $('.ui-datepicker-trigger').click(function () {
    setTimeout(function () {
      var today = $('.ui-datepicker-today a')[0];

      if (!today) {
        today = $('.ui-state-active')[0] ||
          $('.ui-state-default')[0];
      }

      // Hide the entire page (except the date picker)
      // from screen readers to prevent document navigation
      // (by headings, etc.) while the popup is open
      $("main").attr('id', 'dp-container');
      $("#dp-container").attr('aria-hidden', 'true');
      $("#skipnav").attr('aria-hidden', 'true');

      // Hide the "today" button because it doesn't do what
      // you think it supposed to do
      $(".ui-datepicker-current").hide();

      today.focus();
      datePickHandler();
      $(document).on('click', '#ui-datepicker-div .ui-datepicker-close', function () {
        closeCalendar();
      });
    }, 0);
  });
}

function datePickHandler() {
  var activeDate;
  var container = document.getElementById('ui-datepicker-div');
  // This used to be a get element by id, but we're adding the text 'datepicker' on the class.
  var input = $('.datepicker')[0];

  if (!container || !input) {
    return;
  }

  // $(container).find('table').first().attr('role', 'grid');

  container.setAttribute('role', 'application');
  container.setAttribute('aria-label', 'Calendar view date-picker');

  // the top controls:
  var prev = $('.ui-datepicker-prev', container)[0],
    next = $('.ui-datepicker-next', container)[0];


  // This is the line that needs to be fixed for use on pages with base URL set in head
  next.href = 'javascript:void(0)';
  prev.href = 'javascript:void(0)';

  next.setAttribute('role', 'button');
  next.removeAttribute('title');
  prev.setAttribute('role', 'button');
  prev.removeAttribute('title');

  appendOffscreenMonthText(next);
  appendOffscreenMonthText(prev);

  // delegation won't work here for whatever reason, so we are
  // forced to attach individual click listeners to the prev /
  // next month buttons each time they are added to the DOM
  $(next).on('click', handleNextClicks);
  $(prev).on('click', handlePrevClicks);

  monthDayYearText();

  $(container).on('keydown', function calendarKeyboardListener(keyVent) {
    var which = keyVent.which;
    var target = keyVent.target;
    var dateCurrent = getCurrentDate(container);

    if (!dateCurrent) {
      dateCurrent = $('a.ui-state-default')[0];
      setHighlightState(dateCurrent, container);
    }

    if (27 === which) { // ESC
      if (target instanceof HTMLSelectElement) {
        handleYearSelects();
        setTimeout(function () { focusDayPicker(); }, 0);
      } else {
        keyVent.stopPropagation();
        return closeCalendar();
      }
    } else if (which === 9 && keyVent.shiftKey) { // SHIFT + TAB
      keyVent.preventDefault();
      if (isTargetOnDayPicker(target)) { // a date link
        focusNextButton();
      } else if (isTargetOnPrev(target)) { // the prev link
        focusDayPicker();
      } else if (isTargetOnYear(target)) {
        focusPrevButton();
        if (!isTargetOnPrev(target)) { // If we changed an option from the year selection
          handleYearSelects();
          setTimeout(function () { focusPrevButton(); }, 0);
        }
      } else if (isTargetOnNext(target)) { // the next link
        focusYearSelect();
      } else {
        focusDayPicker();
      }
    } else if (which === 9) { // TAB
      keyVent.preventDefault();
      if (isTargetOnDayPicker(target)) {
        focusPrevButton();
      } else if (isTargetOnPrev(target)) {
        focusYearSelect();
      } else if (isTargetOnYear(target)) {
        focusNextButton();
        if (!isTargetOnNext(target)) { // If we changed an option from the year selection
          handleYearSelects();
          setTimeout(function () { focusNextButton(); }, 0);
        }
      } else if (isTargetOnNext(target)) {
        focusDayPicker();
      } else {
        focusDayPicker();
      }
    } else if (which === 37) { // LEFT arrow key
      // if we're on a date link...
      if (!isTargetOnClose(target) && isTargetOnDayPicker(target)) {
        keyVent.preventDefault();
        previousDay(target);
      } else if (isTargetOnNext(target)) {
        focusYearSelect();
      } else if (isTargetOnYear(target)) {
        focusPrevButton();
        if (!isTargetOnPrev(target)) {  // If we changed an option from the year selection
          handleYearSelects();
          setTimeout(function () { focusPrevButton(); }, 0);
        }
      }
    } else if (which === 39) { // RIGHT arrow key
      // if we're on a date link...
      if (!isTargetOnClose(target) && isTargetOnDayPicker(target)) {
        keyVent.preventDefault();
        nextDay(target);
      } else if (isTargetOnPrev(target)) {
        focusYearSelect();
      } else if (isTargetOnYear(target)) {
        focusNextButton();
        if (!isTargetOnNext(target)) { // If we changed an option from the year selection
          handleYearSelects();
          setTimeout(function () { focusNextButton(); }, 0);
        }
      }
    } else if (which === 38) { // UP arrow key
      if (!isTargetOnClose(target) && isTargetOnDayPicker(target)) {
        keyVent.preventDefault();
        upHandler(target, container, prev);
      } else if (isTargetOnYear(target)) {
        handleYearSelects();
        focusYearSelect();
      }
    } else if (which === 40) { // DOWN arrow key
      if (!isTargetOnClose(target) && isTargetOnDayPicker(target)) {
        keyVent.preventDefault();
        downHandler(target, container, next);
      } else if (isTargetOnYear(target)) {
        handleYearSelects();
        focusYearSelect();
      }
    } else if (which === 13) { // ENTER
      if (isTargetOnDayPicker(target)) {
        setTimeout(function () {
          closeCalendar();
        }, 100);
      } else if (isTargetOnPrev(target)) {
        handlePrevClicks();
      } else if (isTargetOnNext(target)) {
        handleNextClicks();
      } else if (isTargetOnYear(target)) {
        keyVent.preventDefault();
        handleYearSelects();
      }
    } else if (32 === which) { // SPACE bar
      if (isTargetOnPrev(target) || isTargetOnNext(target)) {
        target.click();
      }
    } else if (33 === which) { // PAGE UP
      moveOneMonth(target, 'prev');
    } else if (34 === which) { // PAGE DOWN
      moveOneMonth(target, 'next');
    } else if (36 === which) { // HOME
      var firstOfMonth = $(target).closest('tbody').find('.ui-state-default')[0];
      if (firstOfMonth) {
        firstOfMonth.focus();
        setHighlightState(firstOfMonth, $('#ui-datepicker-div')[0]);
      }
    } else if (35 === which) { // END
      var $daysOfMonth = $(target).closest('tbody').find('.ui-state-default');
      var lastDay = $daysOfMonth[$daysOfMonth.length - 1];
      if (lastDay) {
        lastDay.focus();
        setHighlightState(lastDay, $('#ui-datepicker-div')[0]);
      }
    }

    $(".ui-datepicker-current").hide();
  });
}

// methods used for key press events on the datepicker.

function isTargetOnPrev(target) {
  return $(target).hasClass('ui-datepicker-prev');
}

function isTargetOnNext(target) {
  return $(target).hasClass('ui-datepicker-next');
}

function isTargetOnYear(target) {
  return $(target).hasClass('ui-datepicker-year');
}

function isTargetOnClose(target) {
  return $(target).hasClass('ui-datepicker-close');
}

function isTargetOnDayPicker(target) {
  return $(target).hasClass('ui-state-default');
}

function focusNextButton() {
  $('.ui-datepicker-next')[0].focus();
}

function focusPrevButton() {
  $('.ui-datepicker-prev')[0].focus();
}

function focusYearSelect() {
  $('.ui-datepicker-year')[0].focus();
}

function focusDayPicker() {
  activeDate = $('.ui-state-highlight') || $('.ui-state-active')[0];
  if (activeDate) {
    activeDate.focus();
  }
}

function focusCloseButton() {
  $('.ui-datepicker-close')[0].focus();
}

function closeCalendar() {
  var container = $('#ui-datepicker-div');
  $(container).off('keydown');
  $.each($('.datepicker'), function (index, object) {
    $(object).datepicker('hide');
  });
}

///////////////////////////////
//////////////////////////// //
///////////////////////// // //
// UTILITY-LIKE THINGS // // //
///////////////////////// // //
//////////////////////////// //
///////////////////////////////
function isOdd(num) {
  return num % 2;
}

function moveOneMonth(currentDate, dir) {
  var button = (dir === 'next')
    ? $('.ui-datepicker-next')[0]
    : $('.ui-datepicker-prev')[0];

  if (!button) {
    return;
  }

  var ENABLED_SELECTOR = '#ui-datepicker-div tbody td:not(.ui-state-disabled)';
  var $currentCells = $(ENABLED_SELECTOR);
  var currentIdx = $.inArray(currentDate.parentNode, $currentCells);

  button.click();
  setTimeout(function () {
    updateHeaderElements();

    var $newCells = $(ENABLED_SELECTOR);
    var newTd = $newCells[currentIdx];
    var newAnchor = newTd && $(newTd).find('a')[0];

    while (!newAnchor) {
      currentIdx--;
      newTd = $newCells[currentIdx];
      newAnchor = newTd && $(newTd).find('a')[0];
    }

    setHighlightState(newAnchor, $('#ui-datepicker-div')[0]);
    newAnchor.focus();

  }, 0);

}

function handleYearSelects() {
  setTimeout(function () {
    $('.ui-datepicker-year option').blur();
    updateHeaderElements();
    prepHighlightState();
    $('.ui-datepicker-year').focus();
    $(".ui-datepicker-current").hide();
  }, 0);
}

function handleNextClicks() {
  setTimeout(function () {
    updateHeaderElements();
    prepHighlightState();
    $('.ui-datepicker-next').focus();
    $(".ui-datepicker-current").hide();
  }, 0);
}

function handlePrevClicks() {
  setTimeout(function () {
    updateHeaderElements();
    prepHighlightState();
    $('.ui-datepicker-prev').focus();
    $(".ui-datepicker-current").hide();
  }, 0);
}

function previousDay(dateLink) {
  var container = document.getElementById('ui-datepicker-div');
  if (!dateLink) {
    return;
  }
  var td = $(dateLink).closest('td');
  if (!td) {
    return;
  }

  var prevTd = $(td).prev(),
    prevDateLink = $('a.ui-state-default', prevTd)[0];

  if (prevTd && prevDateLink) {
    setHighlightState(prevDateLink, container);
    prevDateLink.focus();
  } else {
    handlePrevious(dateLink);
  }
}


function handlePrevious(target) {
  var container = document.getElementById('ui-datepicker-div');
  if (!target) {
    return;
  }
  var currentRow = $(target).closest('tr');
  if (!currentRow) {
    return;
  }
  var previousRow = $(currentRow).prev();

  if (!previousRow || previousRow.length === 0) {
    // there is not previous row, so we go to previous month...
    previousMonth();
  } else {
    var prevRowDates = $('td a.ui-state-default', previousRow);
    var prevRowDate = prevRowDates[prevRowDates.length - 1];

    if (prevRowDate) {
      setTimeout(function () {
        setHighlightState(prevRowDate, container);
        prevRowDate.focus();
      }, 0);
    }
  }
}

function previousMonth() {
  var prevLink = $('.ui-datepicker-prev')[0];
  var container = document.getElementById('ui-datepicker-div');
  prevLink.click();
  // focus last day of new month
  setTimeout(function () {
    var trs = $('tr', container),
      lastRowTdLinks = $('td a.ui-state-default', trs[trs.length - 1]),
      lastDate = lastRowTdLinks[lastRowTdLinks.length - 1];

    // updating the cached header elements
    updateHeaderElements();

    setHighlightState(lastDate, container);
    lastDate.focus();

  }, 0);
}

///////////////// NEXT /////////////////
/**
 * Handles right arrow key navigation
 * @param  {HTMLElement} dateLink The target of the keyboard event
 */
function nextDay(dateLink) {
  var container = document.getElementById('ui-datepicker-div');
  if (!dateLink) {
    return;
  }
  var td = $(dateLink).closest('td');
  if (!td) {
    return;
  }
  var nextTd = $(td).next(),
    nextDateLink = $('a.ui-state-default', nextTd)[0];

  if (nextTd && nextDateLink) {
    setHighlightState(nextDateLink, container);
    nextDateLink.focus(); // the next day (same row)
  } else {
    handleNext(dateLink);
  }
}

function handleNext(target) {
  var container = document.getElementById('ui-datepicker-div');
  if (!target) {
    return;
  }
  var currentRow = $(target).closest('tr'),
    nextRow = $(currentRow).next();

  if (!nextRow || nextRow.length === 0) {
    nextMonth();
  } else {
    var nextRowFirstDate = $('a.ui-state-default', nextRow)[0];
    if (nextRowFirstDate) {
      setHighlightState(nextRowFirstDate, container);
      nextRowFirstDate.focus();
    }
  }
}

function nextMonth() {
  nextMon = $('.ui-datepicker-next')[0];
  var container = document.getElementById('ui-datepicker-div');
  nextMon.click();
  // focus the first day of the new month
  setTimeout(function () {
    // updating the cached header elements
    updateHeaderElements();

    var firstDate = $('a.ui-state-default', container)[0];
    setHighlightState(firstDate, container);
    firstDate.focus();
  }, 0);
}

/////////// UP ///////////
/**
 * Handle the up arrow navigation through dates
 * @param  {HTMLElement} target   The target of the keyboard event (day)
 * @param  {HTMLElement} cont     The calendar container
 * @param  {HTMLElement} prevLink Link to navigate to previous month
 */
function upHandler(target, cont, prevLink) {
  prevLink = $('.ui-datepicker-prev')[0];
  var rowContext = $(target).closest('tr');
  if (!rowContext) {
    return;
  }
  var rowTds = $('td', rowContext),
    rowLinks = $('a.ui-state-default', rowContext),
    targetIndex = $.inArray(target, rowLinks),
    prevRow = $(rowContext).prev(),
    prevRowTds = $('td', prevRow),
    parallel = prevRowTds[targetIndex],
    linkCheck = $('a.ui-state-default', parallel)[0];

  if (prevRow && parallel && linkCheck) {
    // there is a previous row, a td at the same index
    // of the target AND theres a link in that td
    setHighlightState(linkCheck, cont);
    linkCheck.focus();
  } else {
    // we're either on the first row of a month, or we're on the
    // second and there is not a date link directly above the target
    prevLink.click();
    setTimeout(function () {
      // updating the cached header elements
      updateHeaderElements();
      var newRows = $('tr', cont),
        lastRow = newRows[newRows.length - 1],
        lastRowTds = $('td', lastRow),
        tdParallelIndex = $.inArray(target.parentNode, rowTds),
        newParallel = lastRowTds[tdParallelIndex],
        newCheck = $('a.ui-state-default', newParallel)[0];

      if (lastRow && newParallel && newCheck) {
        setHighlightState(newCheck, cont);
        newCheck.focus();
      } else {
        // theres no date link on the last week (row) of the new month
        // meaning its an empty cell, so we'll try the 2nd to last week
        var secondLastRow = newRows[newRows.length - 2],
          secondTds = $('td', secondLastRow),
          targetTd = secondTds[tdParallelIndex],
          linkCheck = $('a.ui-state-default', targetTd)[0];

        if (linkCheck) {
          setHighlightState(linkCheck, cont);
          linkCheck.focus();
        }

      }
    }, 0);
  }
}

//////////////// DOWN ////////////////
/**
 * Handles down arrow navigation through dates in calendar
 * @param  {HTMLElement} target   The target of the keyboard event (day)
 * @param  {HTMLElement} cont     The calendar container
 * @param  {HTMLElement} nextLink Link to navigate to next month
 */
function downHandler(target, cont, nextLink) {
  nextLink = $('.ui-datepicker-next')[0];
  var targetRow = $(target).closest('tr');
  if (!targetRow) {
    return;
  }
  var targetCells = $('td', targetRow),
    cellIndex = $.inArray(target.parentNode, targetCells), // the td (parent of target) index
    nextRow = $(targetRow).next(),
    nextRowCells = $('td', nextRow),
    nextWeekTd = nextRowCells[cellIndex],
    nextWeekCheck = $('a.ui-state-default', nextWeekTd)[0];

  if (nextRow && nextWeekTd && nextWeekCheck) {
    // theres a next row, a TD at the same index of `target`,
    // and theres an anchor within that td
    setHighlightState(nextWeekCheck, cont);
    nextWeekCheck.focus();
  } else {
    nextLink.click();

    setTimeout(function () {
      // updating the cached header elements
      updateHeaderElements();

      var nextMonthTrs = $('tbody tr', cont),
        firstTds = $('td', nextMonthTrs[0]),
        firstParallel = firstTds[cellIndex],
        firstCheck = $('a.ui-state-default', firstParallel)[0];

      if (firstParallel && firstCheck) {
        setHighlightState(firstCheck, cont);
        firstCheck.focus();
      } else {
        // lets try the second row b/c we didnt find a
        // date link in the first row at the target's index
        var secondRow = nextMonthTrs[1],
          secondTds = $('td', secondRow),
          secondRowTd = secondTds[cellIndex],
          secondCheck = $('a.ui-state-default', secondRowTd)[0];

        if (secondRow && secondCheck) {
          setHighlightState(secondCheck, cont);
          secondCheck.focus();
        }
      }
    }, 0);
  }
}

// add an aria-label to the date link indicating the currently focused date
// (formatted identically to the required format: mm/dd/yyyy)
function monthDayYearText() {
  var cleanUps = $('.amaze-date');

  $(cleanUps).each(function (clean) {
    // each(cleanUps, function (clean) {
    clean.parentNode.removeChild(clean);
  });

  var datePickDiv = document.getElementById('ui-datepicker-div');
  // in case we find no datepick div
  if (!datePickDiv) {
    return;
  }

  var dates = $('a.ui-state-default', datePickDiv);
  $(dates).attr('role', 'button').on('keydown', function (e) {
    if (e.which === 32) {
      e.preventDefault();
      e.target.click();
      setTimeout(function () {
        closeCalendar();
      }, 100);
    }
  });
  $(dates).each(function (index, date) {
    var currentRow = $(date).closest('tr'),
      currentTds = $('td', currentRow),
      currentIndex = $.inArray(date.parentNode, currentTds),
      headThs = $('thead tr th', datePickDiv),
      dayIndex = headThs[currentIndex],
      daySpan = $('span', dayIndex)[0],
      monthName = $('.ui-datepicker-month', datePickDiv)[0].innerHTML,
      year = $('.ui-datepicker-year', datePickDiv).find(":selected").text(),
      number = date.innerHTML;

    if (!daySpan || !monthName || !number || !year) {
      return;
    }

    // AT Reads: {date} {month} {year} {day}
    // "18 December 2014 Thursday"
    var dateText = date.innerHTML + ' ' + monthName + ' ' + year + ' ' + daySpan.title;
    // AT Reads: {date(number)} {name of day} {name of month} {year(number)}
    // var dateText = date.innerHTML + ' ' + daySpan.title + ' ' + monthName + ' ' + year;
    // add an aria-label to the date link reading out the currently focused date
    date.setAttribute('aria-label', dateText);
  });
}

// update the cached header elements because we're in a new month or year
function updateHeaderElements() {
  var context = document.getElementById('ui-datepicker-div');
  if (!context) {
    return;
  }

  //  $(context).find('table').first().attr('role', 'grid');

  prev = $('.ui-datepicker-prev', context)[0];
  next = $('.ui-datepicker-next', context)[0];

  //make them click/focus - able
  next.href = 'javascript:void(0)';
  prev.href = 'javascript:void(0)';

  next.setAttribute('role', 'button');
  prev.setAttribute('role', 'button');
  appendOffscreenMonthText(next);
  appendOffscreenMonthText(prev);

  $(next).on('click', handleNextClicks);
  $(prev).on('click', handlePrevClicks);

  // add month day year text
  monthDayYearText();
}

function prepHighlightState() {
  var highlight;
  var cage = document.getElementById('ui-datepicker-div');
  highlight = $('.ui-state-highlight', cage)[0] ||
    $('.ui-state-default', cage)[0];
  if (highlight && cage) {
    setHighlightState(highlight, cage);
  }
}

// Set the highlighted class to date elements, when focus is received
function setHighlightState(newHighlight, container) {
  var prevHighlight = getCurrentDate(container);
  // remove the highlight state from previously
  // highlighted date and add it to our newly active date
  $(prevHighlight).removeClass('ui-state-highlight');
  $(newHighlight).addClass('ui-state-highlight');
}


// grabs the current date based on the highlight class
function getCurrentDate(container) {
  var currentDate = $('.ui-state-highlight', container)[0];
  return currentDate;
}

/**
 * Appends logical next/prev month text to the buttons
 * - ex: Next Month, January 2015
 *       Previous Month, November 2014
 */
function appendOffscreenMonthText(button) {
  var buttonText;
  var isNext = $(button).hasClass('ui-datepicker-next');
  var months = ['january', 'february', 'march', 'april', 'may', 'june', 'july',
    'august', 'september', 'october', 'november', 'december'];

  var currentMonth = $('.ui-datepicker-title .ui-datepicker-month').text().toLowerCase();
  var monthIndex = $.inArray(currentMonth.toLowerCase(), months);
  var currentYear = $('.ui-datepicker-title .ui-datepicker-year').find(":selected").text().toLowerCase();
  var adjacentIndex = (isNext) ? monthIndex + 1 : monthIndex - 1;

  if (isNext && currentMonth === 'december') {
    currentYear = parseInt(currentYear, 10) + 1;
    adjacentIndex = 0;
  } else if (!isNext && currentMonth === 'january') {
    currentYear = parseInt(currentYear, 10) - 1;
    adjacentIndex = months.length - 1;
  }

  buttonText = (isNext)
    ? 'Next Month, ' + firstToCap(months[adjacentIndex]) + ' ' + currentYear
    : 'Previous Month, ' + firstToCap(months[adjacentIndex]) + ' ' + currentYear;

  $(button).find('.ui-icon').html(buttonText);
}

// Returns the string with the first letter capitalized
function firstToCap(s) {
  return s.charAt(0).toUpperCase() + s.slice(1);
}