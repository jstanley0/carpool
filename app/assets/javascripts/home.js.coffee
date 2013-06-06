# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$(document).ready ->
  onChangeDriver = (select) ->
    val = $(select).val()
    if val == '0'
      $(".driver_check").hide()
      $(".driver_check input").prop('checked', false)
    else
      $(".driver_check").show()
      $(".driver_check_#{val}").hide()
      $(".driver_check_#{val} input").prop('checked', true)

  tehbox = $('#ride_driver_id')
  if tehbox.length > 0
    onChangeDriver tehbox
    tehbox.change (event) ->
      onChangeDriver event.target
