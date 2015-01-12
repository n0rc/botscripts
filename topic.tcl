# topic toggler
# (c)2012 cr0n

package require http

set vers "0.3"
set pinghost "your.ping.host"
set pingbin "/bin/ping6"
set sre {(?i)\y(h(?:oe|ö)hle:?\s+)(up|down|unknown|broken)\y}
set pre {(?i)\y(pinghost:?\s+)(up|down)\y}
set statusurl "http://your-server.tld/api"
set statuschan "#your-channel"

set timer 1

bind pub - !hup pub:set:hup
bind pub - !hdown pub:set:hdown
bind pub - !htoggle pub:set:htoggle
bind pub - !hinit pub:hinit
bind pub - !hauto pub:hinit
bind pub - !hstop pub:hstop
bind time - "*" auto:check:status
bind time - "*" auto:check:ping

proc int:disable:timer {c} {
    global timer
    if {$timer == 1} {
        set timer 0
        putserv "PRIVMSG $c :auto topic disabled"
    }
}

proc pub:hstop {n u h c a} {
    global timer
    if {$timer == 0} {
        putserv "PRIVMSG $c :auto topic already disabled"
    } else {
        int:disable:timer $c
    }
}

proc pub:hinit {n u h c a} {
    global timer
    if {$timer != 1} {
        set timer 1
        putserv "PRIVMSG $c :auto topic enabled"
    } else {
        putserv "PRIVMSG $c :auto topic already enabled"
    }
}

proc auto:check:status {m h d w y} {
    global statusurl statuschan timer
    if {$timer == 1} {
        set token [::http::geturl $statusurl -timeout 10000]
        set code [::http::ncode $token]
        set status [::http::status $token]
        if {$code == 200 && $status == "ok"} {
            set data [::http::data [::http::geturl $statusurl]]
            if {$data == "1"} {
                int:set:status "up" $statuschan quiet
            } elseif {$data == "0"} {
                int:set:status "down" $statuschan quiet
            } elseif {$data == "?"} {
                int:set:status "unknown" $statuschan quiet
            }
        } else {
            int:set:status "broken" $statuschan quiet
        }
    }
}

proc int:toggle:status {status} {
    if {$status == "up"} {
        return "down"
    } else {
        return "up"
    }
}

proc pub:set:htoggle {n u h c a} {
    global sre
    set status ""
    set topic [topic $c]
    if {[regexp $sre $topic -> -> status]} {
        set topic [regsub $sre $topic "\\1[int:toggle:status [string tolower $status]]"]
        putserv "TOPIC $c :$topic"
        int:disable:timer $c
    } else {
        putserv "PRIVMSG $c :no hoehle status section found in topic"
    }
}

proc int:ping:host {pinghost} {
    global pingbin
    if {[catch {exec $pingbin -c 3 $pinghost >/dev/null 2>@1} result]} {
        return "down"
    } else {
        return "up"
    }
}

proc auto:check:ping {m h d w y} {
    global pre pinghost statuschan timer
    if {$timer == 1} {
        set status ""
        set newstatus [int:ping:host $pinghost]
        set topic [topic $statuschan]
        set ret 1
        if {[regexp $pre $topic -> -> status]} {
            if {[string tolower $status] != $newstatus} {
                set topic [regsub $pre $topic "\\1$newstatus"]
                putserv "TOPIC $statuschan :$topic"
            }
        }
    }
}

proc int:set:status {newstatus c mode} {
    global sre
    set status ""
    set topic [topic $c]
    set ret 1
    if {[regexp $sre $topic -> -> status]} {
        if {[string tolower $status] == $newstatus} {
            if {$mode != "quiet"} {
                putserv "PRIVMSG $c :see topic :P"
            }
        } else {
            set topic [regsub $sre $topic "\\1$newstatus"]
            putserv "TOPIC $c :$topic"
            set ret 0
        }
    } elseif {$mode != "quiet"} {
        putserv "PRIVMSG $c :no hoehle status section found in topic"
    }
    return $ret
}

proc pub:set:hdown {n u h c a} {
    if {[int:set:status down $c noisy] == 0} {
        int:disable:timer $c
    }
}

proc pub:set:hup {n u h c a} {
    if {[int:set:status up $c noisy] == 0} {
       int:disable:timer $c
    }
}

putlog "Status Topic v$vers successfully loaded."
