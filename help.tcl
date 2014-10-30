# eggdrop help functions
# (c)2014 cr0n

set vers "0.1"
set botvers "0.4"
set cmdurl "http://url.with.further.info"

bind pub - !help pub:help
bind msg - !help msg:help

proc int:print:header {n} {
    global botvers
    puthelp "PRIVMSG $n :factbot v$botvers"
    puthelp "PRIVMSG $n :━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┯━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    puthelp "PRIVMSG $n :channel command                    │ description"
    puthelp "PRIVMSG $n :───────────────────────────────────┼─────────────────────────────────────────────"
}

proc int:print:footer {n} {
    global cmdurl
    puthelp "PRIVMSG $n :━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┷━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    puthelp "PRIVMSG $n :complete list of commands: $cmdurl"
}


proc int:print:help:general {n} {
    puthelp "PRIVMSG $n :!help calendar                     │ get help for calendar functions"
    puthelp "PRIVMSG $n :!help facts                        │ get help for fact functions"
    puthelp "PRIVMSG $n :!help status                       │ get help for status functions"
}

proc int:print:help:status {n} {
    puthelp "PRIVMSG $n :!hup                               │ sets status to 'up' (disables auto topic)"
    puthelp "PRIVMSG $n :!hdown                             │ sets status to 'down' (disables auto topic)"
    puthelp "PRIVMSG $n :!htoggle                           │ toggles status (disables auto topic)"
    puthelp "PRIVMSG $n :!hinit                             │ (re)enables auto topic"
    puthelp "PRIVMSG $n :!hauto                             │ idem"
    puthelp "PRIVMSG $n :!hstop                             │ disables auto topic"
    puthelp "PRIVMSG $n :!trollenv                          │ get temperature and radioactivity in hoehle"
}

proc int:print:help:facts {n} {
    puthelp "PRIVMSG $n :!fact <#>                          │ get fact num <#>"
    puthelp "PRIVMSG $n :!add <fact>                        │ add <fact>"
    puthelp "PRIVMSG $n :factbot: <fact>                    │ idem"
    puthelp "PRIVMSG $n :!del <#>                           │ delete fact num <#>"
    puthelp "PRIVMSG $n :!grep <regex>                      │ search facts for <regex>"
    puthelp "PRIVMSG $n :!randfact                          │ get a random fact"
}

proc int:print:help:calendar {n} {
    puthelp "PRIVMSG $n :!addevent <date> HH?:MM foo bar    │ add event 'foo bar' at <date> HH?:MM"
    puthelp "PRIVMSG $n :!delevent <date> HH?:MM foo bar    │ delete event 'foo bar' at <date> HH?:MM"
    puthelp "PRIVMSG $n :!what <date>                       │ get all events at <date>"
    puthelp "PRIVMSG $n :!when foo bar                      │ get the scheduled date for 'foo bar'"
    puthelp "PRIVMSG $n :!whatnext                          │ get next event"
    puthelp "PRIVMSG $n :!whatweek                          │ get all events in the current week"
    puthelp "PRIVMSG $n :!calurl                            │ get the url for the calendar (.ics format)"
}

proc msg:help {n u h a} {
    int:print:header $n
    if {[llength $a] == 1} {
        set what [lindex $a 0]
        if {$what == "calendar"} {
            int:print:help:calendar $n
        } elseif {$what == "facts"} {
            int:print:help:facts $n
        } elseif {$what == "status"} {
            int:print:help:status $n
        } else {
            int:print:help:general $n
        }
    } else {
        int:print:help:general $n
    }
    int:print:footer $n
}

proc pub:help {n u h c a} {
    msg:help $n $u $h $a
}

putlog "Help functions v$vers successfully loaded."
