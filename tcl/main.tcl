# Tcl on Windows has unfortunate defaults:
#   - cp1252 encoding, which will mangle utf-8 source code
#   - crlf linebreaks instead of unix-style lf
# Let's be consistent cross-platform to avoid surprises:
encoding system "utf-8"
foreach p {stdin stdout stderr} {
    fconfigure $p -encoding "utf-8"
    fconfigure $p -translation lf
}

package require Tk

wm title . "Overly Repetitive Tedious Software (in Go)"
tk appname gorts

# Proper Windows theme doesn't allow setting fieldbackground on text inputs,
# so let's settle with `clam` instead.
ttk::style theme use clam

wm protocol . WM_DELETE_WINDOW {
    exit 0
}

# Data that we send to the actual web-based overlay:
array set scoreboard {
    description ""
    subtitle ""
    p1name ""
    p1character ""
    p1score 0
    p1team ""
    p2name ""
    p2character ""
    p2score 0
    p2team ""
}

# $applied_scoreboard represents data that has actually been applied
# to the overlay. This is used to display diff in the UI, and to restore data
# when user clicks "Discard".
foreach key [array names scoreboard] {
    set applied_scoreboard($key) scoreboard($key)
}

array set var_to_widget {
    description .n.m.description.entry
    subtitle .n.m.subtitle.entry
    p1name .n.m.players.p1name
    p1character .n.m.players.p1character
    p1score .n.m.players.p1score
    p1team .n.m.players.p1team
    p2name .n.m.players.p2name
    p2character .n.m.players.p2character
    p2score .n.m.players.p2score
    p2team .n.m.players.p2team
}

# GUI has 1 tab: Main (.n.m)

ttk::notebook .n
ttk::frame .n.m -padding 5
.n add .n.m -text Main
grid .n -column 0 -row 0 -sticky NESW

# Main tab:

ttk::frame .n.m.description
ttk::label .n.m.description.lbl -text "Title"
ttk::entry .n.m.description.entry -textvariable scoreboard(description)
ttk::frame .n.m.subtitle
ttk::label .n.m.subtitle.lbl -text "Subtitle"
ttk::entry .n.m.subtitle.entry -textvariable scoreboard(subtitle)
ttk::frame .n.m.players
ttk::label .n.m.players.p1lbl -text "Player 1"
ttk::combobox .n.m.players.p1name -textvariable scoreboard(p1name) -width 35
ttk::combobox .n.m.players.p1character -textvariable scoreboard(p1character) -width 15
ttk::spinbox .n.m.players.p1score -textvariable scoreboard(p1score) -from 0 -to 999 -width 4
ttk::button .n.m.players.p1win -text "▲ Win" -width 6 -command {incr scoreboard(p1score)}
ttk::label .n.m.players.p1teamlbl -text "Team 1"
ttk::combobox .n.m.players.p1team -textvariable scoreboard(p1team)
ttk::separator .n.m.players.separator -orient horizontal
ttk::label .n.m.players.p2lbl -text "Player 2"
ttk::combobox .n.m.players.p2name -textvariable scoreboard(p2name) -width 35
ttk::combobox .n.m.players.p2character -textvariable scoreboard(p2character) -width 15
ttk::spinbox .n.m.players.p2score -textvariable scoreboard(p2score) -from 0 -to 999 -width 4
ttk::button .n.m.players.p2win -text "▲ Win" -width 6 -command {incr scoreboard(p2score)}
ttk::label .n.m.players.p2teamlbl -text "Team 2"
ttk::combobox .n.m.players.p2team -textvariable scoreboard(p2team)
ttk::frame .n.m.buttons
ttk::button .n.m.buttons.apply -text "▶ Apply" -command applyscoreboard
ttk::button .n.m.buttons.discard -text "✖ Discard" -command discardscoreboard
ttk::button .n.m.buttons.reset -text "↶ Reset scores" -command {
    set scoreboard(p1score) 0
    set scoreboard(p2score) 0
}
ttk::button .n.m.buttons.swap -text "⇄ Swap players" -command {
    # Since character is updated whenever name is updated, we'll need to write
    # characters last.
    set p1character $scoreboard(p1character)
    set p2character $scoreboard(p2character)
    foreach key {name score team} {
        set tmp $scoreboard(p1$key)
        set scoreboard(p1$key) $scoreboard(p2$key)
        set scoreboard(p2$key) $tmp
    }
    set scoreboard(p1character) $p2character
    set scoreboard(p2character) $p1character
}
ttk::label .n.m.status -textvariable mainstatus
grid .n.m.description -row 0 -column 0 -sticky NESW -pady {0 5}
grid .n.m.description.lbl -row 0 -column 0 -padx {0 5}
grid .n.m.description.entry -row 0 -column 1 -sticky EW
grid columnconfigure .n.m.description 1 -weight 1
grid .n.m.subtitle -row 1 -column 0 -sticky NESW -pady {0 5}
grid .n.m.subtitle.lbl -row 0 -column 0 -padx {0 5}
grid .n.m.subtitle.entry -row 0 -column 1 -sticky EW
grid columnconfigure .n.m.subtitle 1 -weight 1
grid .n.m.players -row 2 -column 0
grid .n.m.players.p1lbl -row 0 -column 0
grid .n.m.players.p1name -row 0 -column 1
grid .n.m.players.p1character -row 0 -column 2
grid .n.m.players.p1score -row 0 -column 3
grid .n.m.players.p1win -row 0 -column 4 -padx {5 0} -rowspan 2 -sticky NS
grid .n.m.players.p1teamlbl -row 1 -column 0
grid .n.m.players.p1team -row 1 -column 1 -columnspan 3 -sticky EW
grid .n.m.players.separator -row 2 -column 0 -columnspan 5 -pady 10 -sticky EW
grid .n.m.players.p2lbl -row 3 -column 0
grid .n.m.players.p2name -row 3 -column 1
grid .n.m.players.p2character -row 3 -column 2
grid .n.m.players.p2score -row 3 -column 3
grid .n.m.players.p2win -row 3 -column 4 -padx {5 0} -rowspan 2 -sticky NS
grid .n.m.players.p2teamlbl -row 4 -column 0
grid .n.m.players.p2team -row 4 -column 1 -columnspan 3 -sticky EW
grid .n.m.buttons -row 3 -column 0 -sticky W -pady {10 0}
grid .n.m.buttons.apply -row 0 -column 0
grid .n.m.buttons.discard -row 0 -column 1
grid .n.m.buttons.reset -row 0 -column 2
grid .n.m.buttons.swap -row 0 -column 3
grid .n.m.status -row 4 -column 0 -columnspan 5 -pady {10 0} -sticky EW
grid columnconfigure .n.m.players 2 -pad 5
grid columnconfigure .n.m.buttons 1 -pad 15
grid columnconfigure .n.m.buttons 3 -pad 15
grid rowconfigure .n.m.players 1 -pad 5
grid rowconfigure .n.m.players 3 -pad 5

# Character data
proc loadcharacters {} {
    set chars {Gran Charlotta Lancelot Vaseraga Beelzebub Lowain Soriz Katalina Narmaya Metera "Avatar Belial" Belial Seox Sandalphon Eustace Zeta Ferry 2B Djeeta Percival Ferry Ladiva Zooey Cagliostro Yuel Anre Vira Anlia Siegfried Grimnir Nier Lucilius Vane Beatrix Versusia Vikala}
    .n.m.players.p1character configure -values $chars
    .n.m.players.p2character configure -values $chars
}

# Run the function to load characters into the combo boxes
loadcharacters

proc initialize {} {
    loadicon
    loadstartgg
    loadwebmsg
    loadcountrycodes
    loadscoreboard
    loadplayernames

    setupdiffcheck
    setupplayersuggestion


    # By default this window is not focused and not even brought to
    # foreground on Windows. I suspect it's because tcl is exec'ed from Go.
    # The old "iconify, deiconify" trick no longer seems to work, so this time
    # I'm passing it to Go to call the winapi's SetForegroundWindow directly.
    if {$::tcl_platform(platform) == "windows"} {
        windows_forcefocus
    }
}

proc loadwebmsg {} {
    set resp [ipc "getwebport"]
    set webport [lindex $resp 0]
    set ::mainstatus "Point your OBS browser source to http://localhost:${webport}"
}

proc loadscoreboard {} {
    set sb [ipc "getscoreboard"]
    set ::scoreboard(description) [lindex $sb 0]
    set ::scoreboard(subtitle) [lindex $sb 1]
    set ::scoreboard(p1name) [lindex $sb 2]
    set ::scoreboard(p1country) [lindex $sb 3]
    set ::scoreboard(p1score) [lindex $sb 4]
    set ::scoreboard(p1team) [lindex $sb 5]
    set ::scoreboard(p2name) [lindex $sb 6]
    set ::scoreboard(p2country) [lindex $sb 7]
    set ::scoreboard(p2score) [lindex $sb 8]
    set ::scoreboard(p2team) [lindex $sb 9]
    update_applied_scoreboard
}

# Functions to apply and discard scoreboard changes
proc applyscoreboard {} {
    set sb [ \
        ipc "applyscoreboard" \
        $::scoreboard(description) \
        $::scoreboard(subtitle) \
        $::scoreboard(p1name) \
        $::scoreboard(p1character) \
        $::scoreboard(p1score) \
        $::scoreboard(p1team) \
        $::scoreboard(p2name) \
        $::scoreboard(p2character) \
        $::scoreboard(p2score) \
        $::scoreboard(p2team) \
    ]
    set mainstatus "Applying scoreboard..."
}

# Very simple line-based IPC system where Tcl client talks to Go server
# via stdin/stdout
proc ipc_write {method args} {
    puts "$method [llength $args]"
    foreach a $args {
        puts "$a"
    }
}
proc ipc_read {} {
    set results {}
    set numlines [gets stdin]
    for {set i 0} {$i < $numlines} {incr i} {
        lappend results [gets stdin]
    }
    return $results
}
proc ipc {method args} {
    ipc_write $method {*}$args
    return [ipc_read]
}

proc loadplayernames {} {
    set playernames [ipc "searchplayers" ""]
    .n.m.players.p1name configure -values $playernames
    .n.m.players.p2name configure -values $playernames
}

proc discardscoreboard {} {
    set mainstatus "Discarding changes..."
    # reset to applied scoreboard
    foreach key [array names scoreboard] {
        set scoreboard($key) $::applied_scoreboard($key)
    }
}

# Handle player swapping logic
proc swapplayers {} {
    set p1character $scoreboard(p1character)
    set p2character $scoreboard(p2character)
    foreach key {name score team} {
        set tmp $scoreboard(p1$key)
        set scoreboard(p1$key) $scoreboard(p2$key)
        set scoreboard(p2$key) $tmp
    }
    set scoreboard(p1character) $p2character
    set scoreboard(p2character) $p1character
}

proc setupdiffcheck {} {
    # Define styling for "dirty"
    foreach x {TEntry TCombobox TSpinbox} {
        ttk::style configure "Dirty.$x" -fieldbackground #dffcde
    }

    trace add variable ::scoreboard write ::checkdiff
    trace add variable ::applied_scoreboard write ::checkdiff
}

proc checkdiff {_ key _} {
    set widget $::var_to_widget($key)
    if {$::scoreboard($key) == $::applied_scoreboard($key)} {
        $widget configure -style [winfo class $widget]
    } else {
        $widget configure -style "Dirty.[winfo class $widget]"
    }
}