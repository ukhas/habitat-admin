###
habitat: admin
http://habitat.habhub.org/admin
(C) Copyright 2012; GNU GPL 3
Daniel Saul
###

$.ajaxSetup
    cache: false

db = $.couch.db "habitat"

logged_in = (role) ->
    $.couch.session
        success: (data) ->
            return if not data["userCtx"]["name"]?
            return display_login_error("You must login as a #{role}.") if (jQuery.inArray role, data["userCtx"]["roles"])
            $('#loginpage').css "display", "none"
            $('body').removeClass "login"
               
login = (username, password) ->
    $.couch.login
        name: username
        password: password
        error: (jqXHR, data, error) ->
            display_login_error error
        success: (data) ->
            logged_in "manager"

logout = ->
    $.couch.logout
        success: (data) ->
            console.log "Logged out"

display_login_error = (error) ->
    $('#login_error').html error
    $('div.error').css "display", "block"
    
#Login Form
$('#login_submit').click -> login $('#login_user').val(), $('#login_password').val()
$('#loginpage input').keypress (e) ->
   $('#login_submit').click() if (e.keyCode or e.which) == 13

$ ->
    #Check if we're already logged in
    logged_in "manager"
