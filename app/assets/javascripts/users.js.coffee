# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$(document).ready ->
  updatePasswordVisibility = (checkbox) ->
    if $(checkbox).is(':checked')
      $(".password_entry").removeClass('hidden')
      $('[name="user[name]"]').prop('disabled', false)
    else
      $(".password_entry").addClass('hidden')
      $('[name="user[name]"]').prop('disabled', true)
  tehbox = $('#change_password_checkbox')
  if tehbox.length > 0
    updatePasswordVisibility tehbox
    tehbox.change (event) ->
      updatePasswordVisibility event.target
  else
    $(".password_entry").removeClass('hidden')
