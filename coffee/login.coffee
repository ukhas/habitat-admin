###
habitat: admin
http://habitat.habhub.org/admin
(C) Copyright 2012; GNU GPL 3
Daniel Saul
###

# Setup Stuff
#
$.ajaxSetup
    timeout: 10000

db = $.couch.db("habitat")
#loggedinUser = ""

####

# General Stuff
#

btn_disable = (element) ->
    $(element).prop "disabled", true
    $(element).addClass "disabled"

btn_enable = (element) ->
    $(element).prop "disabled", false
    $(element).removeClass "disabled"

####

#Login Stuff
#


logged_in = (role) ->
    $.couch.session
        success: (data) ->
            return showLoginPage() if not data["userCtx"]["name"]?
            return display_login_error("You must login as a #{role}.") if (jQuery.inArray role, data["userCtx"]["roles"]) == -1
            hideLoginPage(data["userCtx"]["name"])

showLoginPage = ->
    $('#adminpage').hide()
    $('#loginpage').show()
    $('body').addClass "login"
    $('#login_password').val ""

hideLoginPage = (loggedinUser) ->
    $('#loginpage').hide()
    $('body').removeClass "login"

    loadAdminPage(loggedinUser)
    $('#adminpage').show()

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
            showLoginPage()


display_login_error = (error) ->
    $('#login_error').html error
    $('div.error').css "display", "block"
   
#Login Form
$('#login_submit').click -> login $('#login_user').val(), $('#login_password').val()
$('#logout_link').click -> logout()
$('#loginpage input').keypress (e) ->
   $('#login_submit').click() if (e.keyCode or e.which) == 13

####

# Admin page
#

loadAdminPage = (user) ->
    $('#header_username').html user
    openSection "#approval_list"
    load_approval_list()

section_titles =
    "#approval_list": ["flight approval", "", "Search all unapproved docs..."]
    

openSection = (open) ->
    $("#sections > section").not(open).hide()
    $(open).show()

    $("#page_title").text section_titles[open][0]
    $("#page_subtitle").text section_titles[open][1]

    if not section_titles[open][2]
        $("#search").hide()
    else
        $("#search").attr "placeholder", section_titles[open][2]


####

# Approval list<
#

doc_types =
    unapproved_flights:
        view: "flight/unapproved_name_including_payloads"
        include_docs: true
        term_key: (term) -> term
        display: (row) ->
            doc = row.doc
            d = browse_row doc.name, doc._id, doc.launch.time
            d.data "browse_return", doc
            return d

load_approval_list = () ->
    options =
        include_docs: true
        success: (resp) ->
            display_approval_list resp
            expand_row window.location.hash
            return
        error: (status, error, reason) ->
            $("#approval_list_status").text "Error loading rows: #{status}, #{error}, #{reason}"
            return
            
    db.view "flight/unapproved_name_including_payloads", options
    
expanded_rows = [
    [["flight name", "string", "name"],             ["project name", "string", "metadata", "project"]],
    [["window start", "date", "start"],             ["group name", "string", "metadata", "group"]],
    [["window end", "date", "end"],                 ["location", "string", "metadata", "location"]],
    [["launch time", "date", "launch", "time"],     ["latitude", "number", "launch", "location", "latitude"]],
    [["timezone", "string", "launch", "timezone"],  ["longitude", "number", "launch", "location", "longitude"]]
    ]

expand_row = (id) ->
    console.log id
    if id isnt ""
        $(id + " .expanded-view").toggle()
        console.log $(id + "-click").html()
        if $(id + "-click").html() == "+"
            $(id + "-click").html "-"
        else
            $(id + "-click").html "+"

display_approval_list = (resp) ->
    i = 0
    $("#approval_list_table").html ""
    for row in resp.rows
        if not row.key[2]
            i++
            r = "
                <div class='row approval_list_item' id='#{row.id}'>
                    <div class='one column alpha expand_item'><a id='#{row.id}-click' href='##{row.id}'>+</a></div>
                    <div class='seven columns'>
                        <div><strong>#{row.doc.name}</strong></div>
                        <div><small>#{row.id}</small></div>
                    </div>
                    <div class='six columns hidden-overflow' style='text-align: right;'>
                        <div>#{row.doc.launch.time}</div>
                        <div>#{row.doc.metadata?.group or ""} - #{row.doc.metadata?.project or ""}</div>
                    </div>
                    <button class='two columns omega approve_btn' value='#{row.id}'>Approve</button>
                
                    <div class='fifteen columns offset-by-one expanded-view alpha omega'>
                "

            for expanded_row in expanded_rows
                r += "
                    <div class='two columns alpha key'>#{expanded_row[0][0]}</div>
                    <div class='five columns value'><span class='inner #{expanded_row[0][1]}'>
                    #{bla = row.doc; bla = bla[thing] for thing in expanded_row[0].slice(2); bla}
                    </span></div>
                    <div class='two columns offset-by-one key'>#{expanded_row[1][0]}</div>
                    <div class='five columns omega value'><span class='inner #{expanded_row[1][1]}'>
                    #{bla = row.doc; bla = bla[thing] for thing in expanded_row[1].slice(2); bla}
                    </span></div>
                    "
            r += "
                <div class='fourteen columns alpha omega'><br/></div>
                <div class='two columns alpha key'>payloads</div>
                "
            for payload, x in row.doc.payloads
                r += " 
                    <div class='twelve columns omega #{"offset-by-two alpha" if x isnt 0}'>
                    <a href='../habitat/#{payload}' class='inner string'>#{payload}</a>
                    </div>
                    "
            r += "</div></div>"
            
            $("#approval_list_table").append r
            $("#" + row.id + " .expanded-view").hide()
            setup_click_events row.id
    $("#approval_list_status").text "#{i} unapproved flight"
    $("#approval_list_status").append "s" if i > 1
    $("#approval_list_status").html "<h5 style='text-align: center;'>Whoopeee! No unapproved flights! </h5>" if i < 0 

setup_click_events = (id) ->
        $("#" + id + "-click").bind 'click', -> expand_row "#"+id
        $("#" + id + " .approve_btn").click -> approve_flight id


approve_flight = (id) ->
    saveDoc_options =
        success: (resp) ->
            alert "#" + id + " approved."
            load_approval_list()
            $("#shadow").hide()
        error: (resp) ->
            alert "There was a problem approving doc #" + id
            $("#shadow").hide()
            logged_in "manager"

    openDoc_options =
        success: (doc) ->
            doc.approved = true
            console.log doc
            db.saveDoc doc, saveDoc_options
        error: (resp) ->
            alert "There was a problem approving doc #" + id
            $("#shadow").hide()

    $("#shadow").show()
    db.openDoc id, openDoc_options


####



$ ->

    showLoginPage()
    logged_in "manager"
    return
