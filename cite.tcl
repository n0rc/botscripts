# eggdrop citation script
# (c)2012 cr0n

set vers "0.2"

set citedb "scripts/cite.db"
set dumpfile "scripts/cite.db.txt"

array set cites {}
set citecount 0
set citeschanged 0

bind pub o|F !list pub:cdblist
bind pub - !fact pub:cdbfact
bind msg - !fact msg:cdbfact
bind pub - !randfact pub:cdbrand
bind pub - !del pub:cdbdel
bind pub o|F !set pub:cdbset
bind pub o|F !save pub:cdbsave
bind pub o|R !reset pub:cdbreset
bind pub o|F !flush pub:cdbflush
bind pub - !grep pub:cdbsearch
bind msg - !grep msg:cdbsearch
bind pub - !add pub:cdbadd
bind pub - factbot: pub:cdbadd
bind time - "?0 *" auto:cdbsave

proc pub:cdbrand {n u h c a} {
    global cites
    set keys [lsort -integer [array names cites]]
    if {[llength $keys] > 0} {
        set id [lindex $keys [expr {int(rand()*[llength $keys])}]]
        putquick "PRIVMSG $c :\[$id\] $cites($id)"
    } else {
        putquick "PRIVMSG $c :currently no facts exist"
    }
}

proc pub:cdblist {n u h c a} {
    global cites
    set citequery [lsort -integer [array names cites]]
    if {[llength $citequery] == 0} {
        putquick "PRIVMSG $c :currently no facts exist"
    } else {
        foreach i $citequery {
            putserv "PRIVMSG $c :\[$i\] $cites($i)"
        }
    }
}

proc msg:cdbfact {n u h a} {
    global cites
    set id [lindex $a 0]
    if {[info exists cites($id)]} {
        puthelp "PRIVMSG $n :\[$id\] $cites($id)"
    } else {
        puthelp "PRIVMSG $n :fact $id does not exist"
    }
}

proc pub:cdbfact {n u h c a} {
    global cites
    set id [lindex $a 0]
    if {[info exists cites($id)]} {
        putquick "PRIVMSG $c :\[$id\] $cites($id)"
    } else {
        putquick "PRIVMSG $c :fact $id does not exist"
    }
}

proc msg:cdbsearch {n u h a} {
    global cites
    set re [string trim $a]
    if {[string length $re] < 1} {
        puthelp "PRIVMSG $n ::P"
    } else {
        set re [regsub -all {\s+} $re {.*}]
        set found 0
        set out [list]
        foreach i [lsort -integer [array names cites]] {
            if {[regexp -nocase $re $cites($i)] == 1} {
                incr found
                if {$found > 10} break
                lappend out "\[$i\] $cites($i)"
            }
        }
        if {$found > 0} {
            if {$found > 10} {
                puthelp "PRIVMSG $n :found >10 results, please be more specific"
            }
            foreach line $out {
                puthelp "PRIVMSG $n :$line"
            }
        } else {
            puthelp "PRIVMSG $n :nothing found"
        }
    }
}

proc pub:cdbsearch {n u h c a} {
    global cites
    set re [string trim $a]
    if {[string length $re] < 1} {
        putquick "PRIVMSG $c ::P"
    } else {
        set re [regsub -all {\s+} $re {.*}]
        set found 0
        set out [list]
        foreach i [lsort -integer [array names cites]] {
            if {[regexp -nocase $re $cites($i)] == 1} {
                incr found
                if {$found > 5} break
                lappend out "\[$i\] $cites($i)"
            }
        }
        if {$found > 0} {
            if {$found > 5} {
                putserv "PRIVMSG $c :found >5 results, please be more specific"
            }
            foreach line $out {
                putserv "PRIVMSG $c :$line"
            }
        } else {
            putquick "PRIVMSG $c :nothing found"
        }
    }
}

proc pub:cdbdel {n u h c a} {
    global cites citeschanged
    set what [string trim $a]
    set j 0
    foreach i $what {
        if {[info exists cites($i)]} {
            unset cites($i)
            incr j
            set citeschanged 1
        }
    }
    putquick "PRIVMSG $c :$j facts removed"
}

proc pub:cdbset {n u h c a} {
    global cites citecount citeschanged
    set id [lindex "$a" 0]
    set txt [regsub {^\s*\d+\s+} [string trim $a] {}]
    if {[string length $txt] > 0 && $id >= 0 && $id <= $citecount} {
        putquick "PRIVMSG $c :\[$id\] $txt"
        set cites($id) $txt
        set citeschanged 1
    } else {
        putquick "PRIVMSG $c :new fact is empty or id is out of range"
    }
}

proc pub:cdbadd {n u h c a} {
    global cites citecount citeschanged
    set txt [string trim $a]
    if {[string length $txt] > 0 && $txt != "{}"} {
        set keys [lsort -integer [array names cites]]
        foreach i $keys {
            if {$cites($i) == $txt} {
                putquick "PRIVMSG $c :dupe, see fact $i"
                return
            }
        }
        incr citecount
        putquick "PRIVMSG $c :\[$citecount\] $txt"
        set cites($citecount) $txt
        set citeschanged 1
    } else {
        putquick "PRIVMSG $c :no fact given"
    }
}

proc int:cdbsave {} {
    global citedb cites citecount citeschanged dumpfile
    if {$citeschanged} {
        set citeschanged 0
        set fp [open $citedb w]
        puts $fp [list array set cites [array get cites]]
        puts $fp [list set citecount [set citecount]]
        close $fp
        set citequery [lsort -integer [array names cites]]
        set fp [open $dumpfile w]
        if {[llength $citequery] == 0} {
            puts $fp "currently no facts exist"
        } else {
            foreach id $citequery {
                puts $fp "\[$id\] $cites($id)"
            }
        }
        close $fp
        putlog "FactsDB saved"
    } else {
        putlog "FactsDB not saved (no change)"
    }
}

proc auto:cdbsave {m h d w y} {
    int:cdbsave
}

proc pub:cdbsave {n u h c a} {
    int:cdbsave
}

proc pub:cdbreset {n u h c a} {
    global cites citecount
    set citecount 0
    unset cites
    array set cites {}
    putquick "PRIVMSG $c :facts cleared"
}

proc int:cdbread {} {
    global citedb cites citecount
    uplevel {
        if {[file exist $citedb]} {
            unset cites
            source $citedb
        }
    }
}

proc pub:cdbflush {n u h c a} {
    global citedb cites citecount
    uplevel {
        if {[file exist $citedb]} {
            unset cites
            source $citedb
        }
    }    
    putquick "PRIVMSG $c :facts flushed"
}

int:cdbread

putlog "FactsDB v$vers successfully loaded."
