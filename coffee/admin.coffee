###
habitat: admin
http://habitat.habhub.org/admin
(C) Copyright 2012; GNU GPL 3
Daniel Saul
###

db = $.couch.db "habitat"

logged_in = ->
    $.couch.session {
        include_docs: true,
        success: (data) ->
            console.log data
    }

logged_in()
