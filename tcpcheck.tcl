# simple tcp client
# (c)2014 cr0n

set vers "0.1"
set host "your_ip"
set port "your_port"

bind pub - !trollenv pub:get_data

proc pub:get_data {n u h c a} {
    set data [int:get_data]
    if {[llength $data] == 1} {
        switch [lindex $data 0] {
            e_socks {putserv "PRIVMSG $c :error: timeout"}
            e_parse {putserv "PRIVMSG $c :error: crappy data"}
            default {putserv "PRIVMSG $c :error: wtf.."}
        }
    } else {
        putserv "PRIVMSG $c :geiger counter: [lindex $data 0] cpm"
        putserv "PRIVMSG $c :temperature: [format "%.1f" [lindex $data 1]]°C"
    }
}

proc int:get_data {} {
    global host port
    set ret {}
    set sock [socket -async $host $port]
    if {[catch {gets $sock line1}] || [catch {gets $sock line2}]} {
        lappend ret "e_socks"
    } else {
        if {[regexp {^(\d+)$} [string trim $line1] -> count] && [regexp {^(\d+(?:[.,]\d+)?)$} [string trim $line2] -> temp]} {
            lappend ret $count $temp
        } else {
            lappend ret "e_parse"
        }
    }
    return $ret
}

putlog "TCP Check v$vers successfully loaded."
