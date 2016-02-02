# eggdrop sqlite calendar script
# (c)2013 cr0n

set vers "0.3"
set dbfile "scripts/cal.sqlite"
set sqlite3lib "/usr/lib/tcltk/sqlite3/libtclsqlite3.so"
#set sqlite3lib "/usr/lib/sqlite3/libtclsqlite3.so"

set perlbin "/usr/bin/perl"
set cal2ics "/path/to/cal2ics.pl"
set calurl "http://your.server.tld/calendar.ics"

load $sqlite3lib sqlite3

sqlite3 db $dbfile

setudef flag calendar

bind pub - !calurl pub:get_calurl
bind pub - !when pub:get_date
bind pub - !what pub:get_events
bind pub - !whatnext pub:get_next
bind pub - !whatweek pub:get_events_week

bind msg - !calurl msg:get_calurl
bind msg - !when msg:get_date
bind msg - !what msg:get_events
bind msg - !whatnext msg:get_next
bind msg - !whatweek msg:get_events_week

bind pub o|o !whatmonth pub:get_events_month

bind pub - !addevent pub:add_event
bind pub - !delevent pub:del_event

bind pub o|o !clearevents pub:clear_events

bind msg oE|E !addevent msg:add_event
bind msg oE|E !delevent msg:del_event

bind msg o|o !test msg:test

proc msg:test {n u h a} {
    putquick "PRIVMSG $n :[expr {4294967295+1}]"
    set str ""
    set fmt ""
    regexp {^"(.+)" "(.+)"$} [string trim $a] -> str fmt
    set msg [int:get_date $str $fmt]
    if {$msg != -1} {
        putquick "PRIVMSG $n :$msg"
    } else {
        putquick "PRIVMSG $n :specify a valid time"   
    }
}

proc int:db_init {db} {
    db_drop db
    db_create db
}

proc int:db_drop {db} {
    db eval {DROP TABLE events}
}

proc int:db_create {db} {
    db eval {
        CREATE TABLE events(
            id integer primary key,
            stime integer,
            etime integer,
            event text,
            recurr text,
            wholeday text
        )
    }
    db eval {CREATE UNIQUE INDEX event_unique on events(stime,event)}
}

proc int:get_day_start {str fmt} {
    return [int:get_date [int:get_date $str "%Y-%m-%d 00:00"] $fmt]
}

proc int:get_month_start {off fmt} {
    return [int:get_date [int:get_date "now $off months" "%Y-%m-01 00:00"] $fmt]
}

proc int:get_week_start {off fmt} {
    if {[int:get_date "now" "%a"] == "Mon"} {
        return [int:get_day_start "now $off weeks" $fmt]
    } else {
        return [int:get_day_start "last monday $off weeks" $fmt]
    }
}

proc int:get_date {str fmt} {
    if {[string length $str] == 0 || [string length $fmt] == 0 || [catch {clock scan $str} err]} {
        return -1
    } else {
        return [clock format [clock scan $str] -format $fmt]
    }
}

proc all:get_calurl {target} {
    global calurl
    putquick "PRIVMSG $target :$calurl"
}

proc all:out_events {out target emptymsg} {
    if {[llength $out] > 0} {
        foreach {start end event} $out {
            if {$start == $end} {
                putserv "PRIVMSG $target :$start | $event"
            } else {
                putserv "PRIVMSG $target :$start - $end | $event"
            }
        }
    } else {
        putquick "PRIVMSG $target :$emptymsg"
    }
}

proc all:clear_events {target} {
    global db perlbin cal2ics
    db eval {DELETE FROM events}
    exec $perlbin $cal2ics
    putquick "PRIVMSG $target :all events cleared"
}

proc all:add_event {target args} {
    global db perlbin cal2ics
    set txt ""
    set wholeday ""
    if {[regexp {^([\w\-\+ ]+?) (\d\d?:\d\d|wholeday)(?: ([1-9]\d* (?:minute|hour|day)s?))? \|* ?(.+)$} [regsub -all {\s+} [string trim [join $args " "]] { }] -> day stime dur txt]} {
        if {$stime == "wholeday"} {
            set wholeday "true"
            set dstart [int:get_day_start $day "%s"]
            if {$dur == ""} {
                # double call to allow queries like "next sunday +3 days"
                set dend [int:get_date "$day" "%Y-%m-%d 00:00"]
                set dend [int:get_date "$dend +1 days" "%s"]
            } else {
                if {[regexp {^(\d+) days?$} $dur -> numdays]} {
                    # see above comment
                    set dend [int:get_date "$day" "%Y-%m-%d 00:00"]
                    set dend [int:get_date "$dend +$numdays days" "%s"]
                } else {
                    putquick "PRIVMSG $target :that does not make sense"
                    return
                }
            }
        } else {
            set wholeday "false"
            set dstart [int:get_date "$day $stime" "%s"]
            if {$dur == ""} {
                set dend $dstart
            } else {
                # again, see above
                set dend [int:get_date "$day $stime" "%Y-%m-%d %H:%M"]
                set dend [int:get_date "$dend +$dur" "%s"]
            }
        }
        if {$dstart != -1 && $dend != -1 && [string length $txt] > 0} {
            set recurr ""
            regexp {^.+?(\(daily|weekly|monthly)\)$} $txt -> recurr
            if {[string length $recurr] == 0} {
                set recurr "false"
            }
            db eval {INSERT OR IGNORE INTO events VALUES(NULL, :dstart, :dend, :txt, :recurr, :wholeday)}
            if {[db changes] > 0} {
                exec $perlbin $cal2ics
                set out "event added"
            } else {
                set out "event not added - dupe"
            }
        } else {
            set out "syntax: !addevent <start date descriptor> (HH?:MM|wholeday) \[duration (hours|minutes|days)\] event description ..."
        }
    } else {
        set out "syntax: !addevent <start date descriptor> (HH?:MM|wholeday) \[duration (hours|minutes|days)\] event description ..."
    }
    putquick "PRIVMSG $target :$out"
}

proc all:del_event {target args} {
    global db perlbin cal2ics
    set txt ""
    set wholeday ""
    if {[regexp {^([\w\-\+ ]+?) (\d\d?:\d\d|wholeday)(?: (\d+ (?:minute|hour|day)s?))? \|* ?(.+)$} [regsub -all {\s+} [string trim [join $args " "]] { }] -> day stime dur txt]} {
        if {$stime == "wholeday"} {
           set wholeday "true"
           set dstart [int:get_day_start $day "%s"]
        } else {
           set wholeday "false"
           set dstart [int:get_date "$day $stime" "%s"]
        }
        if {$dstart != -1 && [string length $txt] > 0} {
            db eval {
                DELETE FROM events
                WHERE event LIKE :txt AND stime = :dstart AND wholeday = :wholeday
            }
            set dels [db changes]
            if {$dels > 0} {
                if {$dels > 1} {
                    set out "$dels events deleted"
                } else {
                    set out "$dels event deleted"
                }
                exec $perlbin $cal2ics
            } else {
                set out "no such event exists"
            }
        } else {
            set out "syntax: !delevent <start date descriptor> (HH?:MM|wholeday) <exact event string>"
        }
    } else {
        set out "syntax: !delevent <start date descriptor> (HH?:MM|wholeday) <exact event string>"
    }
    putquick "PRIVMSG $target :$out"
}

proc all:get_next {target} {
    global db
    set dt [int:get_date "now" "%s"]
    set out [db eval {
        SELECT strftime('%Y-%m-%d %H:%M', stime, 'unixepoch', 'localtime') AS start, strftime('%Y-%m-%d %H:%M', etime, 'unixepoch', 'localtime') AS end, event FROM events
        WHERE stime >= :dt
        ORDER BY stime
        LIMIT 1
    }]
    all:out_events $out $target "no future events exist"
}

proc all:get_date {target args} {
    global db
    set txt [encoding convertto utf-8 [string trim [join $args " "]]]
    set dt [int:get_day_start "now" "%s"]
    if {[string length $txt] > 0} {
        set out [db eval {
            SELECT strftime('%Y-%m-%d %H:%M', stime, 'unixepoch', 'localtime') AS start, strftime('%Y-%m-%d %H:%M', etime, 'unixepoch', 'localtime') AS end, event FROM events
            WHERE (stime >= :dt OR etime >= :dt) AND event LIKE '%' || :txt || '%'
            ORDER BY stime
            LIMIT 5
        }]
        all:out_events $out $target "no such event exists"
    } else {
        putquick "PRIVMSG $target :syntax: !when <event pattern>"
    }
}


proc all:get_events {target args} {
    global db
    set dt [int:get_date [int:get_date [string trim [join $args " "]] "%Y-%m-%d 00:00"] "%s"]
    if {$dt != -1} {
        set out [db eval {
            SELECT strftime('%Y-%m-%d %H:%M', stime, 'unixepoch', 'localtime') AS start, strftime('%Y-%m-%d %H:%M', etime, 'unixepoch', 'localtime') AS end, event FROM events
            WHERE (stime >= :dt AND stime < :dt + 86400) OR (etime > :dt AND etime < :dt + 86400) OR (stime < :dt AND etime >= :dt + 86400)
            ORDER BY stime
            LIMIT 5
        }]
        all:out_events $out $target "no events exist for that date"
    } else {
        putquick "PRIVMSG $target :syntax: !what <date descriptor>"
    }
}

proc all:get_events_week {target args} {
    global db
    set off "+0"
    regexp {^[\+\-]?\d+$} [string trim [join $args " "]] off
    set dt [int:get_week_start $off "%s"]
    if {$dt != -1} {
        set out [db eval {
            SELECT strftime('%Y-%m-%d %H:%M', stime, 'unixepoch', 'localtime') AS start, strftime('%Y-%m-%d %H:%M', etime, 'unixepoch', 'localtime') AS end, event FROM events
            WHERE (stime >= :dt AND stime < :dt + 604800) OR (etime > :dt AND etime < :dt + 604800) OR (stime < :dt AND etime >= :dt + 604800)
            ORDER BY stime
            LIMIT 10
        }]
        all:out_events $out $target "no events exist for this week"
    } else {
        putquick "PRIVMSG $target :syntax: !whatweek <week offset>"
    }
}

proc all:get_events_month {target args} {
    global db
    set off "+0"
    regexp {^[\+\-]?\d+$} [string trim [join $args " "]] off
    set tmp [int:get_month_start $off "%Y-%m-%d %H:%M"]
    set dts [int:get_date $tmp "%s"]
    set dte [int:get_date "$tmp +1 month" "%s"]
    if {$dts != -1 && $dte != -1} {
        set out [db eval {
            SELECT strftime('%Y-%m-%d %H:%M', stime, 'unixepoch', 'localtime') AS dt, event FROM events
            WHERE stime >= :dt AND stime < :dt
            ORDER BY stime
            LIMIT 10
        }]
        all:out_events $out $target "no events exist for this month"
    } else {
        putquick "PRIVMSG $target :syntax: !whatmonth <month offset>"
    }
}

proc msg:get_calurl {n u h a} {
    all:get_calurl $n
}

proc pub:get_calurl {n u h c a} {
    if {![channel get $c calendar]} { return }
    all:get_calurl $c
}

proc msg:clear_events {n u h a} {
    all:clear_events $n
}

proc pub:clear_events {n u h c a} {
    if {![channel get $c calendar]} { return }
    all:clear_events $c
}

proc msg:add_event {n u h a} {
    all:add_event $n $a
}

proc pub:add_event {n u h c a} {
    if {![channel get $c calendar]} { return }
    all:add_event $c $a
}

proc msg:del_event {n u h a} {
    all:del_event $n $a
}

proc pub:del_event {n u h c a} {
    if {![channel get $c calendar]} { return }
    all:del_event $c $a
}

proc msg:get_next {n u h a} {
    all:get_next $n
}

proc pub:get_next {n u h c a} {
    if {![channel get $c calendar]} { return }
    all:get_next $c
}

proc msg:get_date {n u h a} {
    all:get_date $n $a
}

proc pub:get_date {n u h c a} {
    if {![channel get $c calendar]} { return }
    all:get_date $c $a
}

proc msg:get_events {n u h a} {
    all:get_events $n $a
}

proc pub:get_events {n u h c a} {
    if {![channel get $c calendar]} { return }
    all:get_events $c $a
}

proc msg:get_events_week {n u h a} {
    all:get_events_week $n $a
}

proc pub:get_events_week {n u h c a} {
    if {![channel get $c calendar]} { return }
    all:get_events_week $c $a
}

proc msg:get_events_month {n u h a} {
    all:get_events_month $n $a
}

proc pub:get_events_month {n u h c a} {
    if {![channel get $c calendar]} { return }
    all:get_events_month $c $a
}

putlog "Calendar v$vers successfully loaded."
