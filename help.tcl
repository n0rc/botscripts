# eggdrop help functions
# (c)2014 cr0n

set botvers "0.4"
set cmdurl "http://url.with.further.info"

bind pub - !help pub:cdbhelp
bind msg - !help msg:cdbhelp
bind pub - !hhelp pub:hhelp
bind msg - !hhelp msg:hhelp
bind pub - !chelp pub:calhelp
bind msg - !chelp msg:calhelp

proc int:print_header {n} {
    global botvers
    puthelp "PRIVMSG $n :factbot v$botvers"
    puthelp "PRIVMSG $n :==============================================================================================="
    puthelp "PRIVMSG $n :channel cmd      | desc"
    puthelp "PRIVMSG $n :-----------------+-----------------------------------------------------------------------------"
}

proc int:print_footer {n} {
    global cmdurl
    puthelp "PRIVMSG $n :==============================================================================================="
    puthelp "PRIVMSG $n :for a complete list of commands visit: $cmdurl"
}

proc msg:hhelp {n u h a} {
    int:print_header $n
    puthelp "PRIVMSG $n :!hup             | sets status to 'up' (disables auto topic)"
    puthelp "PRIVMSG $n :!hdown           | sets status to 'down' (disables auto topic)"
    puthelp "PRIVMSG $n :!htoggle         | toggles status (disables auto topic)"
    puthelp "PRIVMSG $n :!hinit           | (re)enables auto topic"
    puthelp "PRIVMSG $n :!hauto           | idem"
    puthelp "PRIVMSG $n :!hstop           | disables auto topic"
    puthelp "PRIVMSG $n :!hhelp           | guess what?"
    int:print_footer $n
}

proc msg:cdbhelp {n u h a} {
    int:print_header $n
    puthelp "PRIVMSG $n :!fact <#>        | get fact num <#>"
    puthelp "PRIVMSG $n :!add <fact>      | add <fact>"
    puthelp "PRIVMSG $n :factbot: <fact>  | idem"
    puthelp "PRIVMSG $n :!del <#>         | delete fact num <#>"
    puthelp "PRIVMSG $n :!grep <regex>    | search facts for <regex>"
    puthelp "PRIVMSG $n :!help            | guess what?"
    puthelp "PRIVMSG $n :!randfact        | get a random fact"
    int:print_footer $n
}

proc msg:calhelp {n u h a} {
    int:print_header $n
    puthelp "PRIVMSG $n :!addevent <date> HH?:MM foo bar ...   | add event 'foo bar ...' at <date> HH?:MM"
    puthelp "PRIVMSG $n :!delevent <date> HH?:MM foo bar       | delete event 'foo bar' (must be exact) at <date> HH?:MM"
    puthelp "PRIVMSG $n :!what <date>                          | get all events at <date>"
    puthelp "PRIVMSG $n :!when foo ...                         | get the scheduled date for 'foo ...'"
    puthelp "PRIVMSG $n :!whatnext                             | get next event"
    puthelp "PRIVMSG $n :!whatweek                             | get all events in the current week"
    puthelp "PRIVMSG $n :!calurl                               | get the url for the calendar (.ics format)"
    puthelp "PRIVMSG $n :!chelp                                | guess what?"
    int:print_footer $n
}

proc pub:calhelp {n u h c a} {
    msg:calhelp $n $u $h $a
}

proc pub:cdbhelp {n u h c a} {
    msg:cdbhelp $n $u $h $a
}

proc pub:hhelp {n u h c a} {
    msg:hhelp $n $u $h $a
}

putlog "Help functions successfully loaded."
