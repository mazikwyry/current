// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require turbolinks
//= require bootstrap-sass
//= require bootstrap-material-design
//= require bootstrap-datepicker
//= require bootstrap-select
//= require toastr
//= require_tree .

$(function() {
	$('#start_date, #end_date').datepicker({
    startView: 1,
    format: "yyyy-mm-dd",
    orientation: "top left",
    autoclose:true,
    language: "pl"
	});

  $('#start_month, #end_month').datepicker({
      format: "yyyy-mm",
      startView: 1,
      minViewMode: 1,
      orientation: "top left",
      autoclose:true,
      language: "pl"
  });

	$('.selectpicker').selectpicker();
	$('[data-toggle="tooltip"]').tooltip();
});
