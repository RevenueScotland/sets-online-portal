// This file contains JS that applies to the file upload feature
$(function () {
	$(".file").each(function () {
		var file = $(this);
		// to adjust spinner position
		var opts = {
			'top': '20px',
			'left': '22px',
			'scale': 0.5
		}

		file.find(".uploadspinner").css('position', 'relative');

		var button = file.find("button[id^='AddResource']");

		button.click(function () {
			var fileinput = file.find("input[type='file']")[0];
			if (fileinput.files && fileinput.files.length > 0) {
				$(".next").hide();
				new Spinner(opts).spin(file.find(".uploadspinner")[0]);
			}
		});
	});
	$(".removefile").each(function () {
		var file = $(this);
		// to adjust spinner position
		var opts = {
			'top': '11px',
			'left': '12px',
			'scale': 0.4
		}
		file.find(".uploadspinner").css('position', 'relative');
		file.find("button[id^='DeleteResource']")
			.click(function () {
				new Spinner(opts).spin(file.find(".uploadspinner")[0]);
			});
	});

	$(".file-upload-check").on("click", function () {
		var fileinput = $("input[type='file']");
		if (fileinput.length) {
			if (fileinput[0].value) {
				warning_message = fileinput[0].attributes['data-warning-message'].value
				if (!confirm(warning_message)) {
					event.preventDefault();
				}
			}
		}
	})
});
