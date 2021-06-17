#keymap.tcl
#!/bin/sh
# the next line restarts using wish \
exec wish "$0" "$@"

set title "Keymap 1.00 June 16 2021 20:40"
wm title . $title
tk_setPalette seashell1

set midi(outfileName) "/home/seymour/clean_midi/Eagles/Peaceful Easy Feeling.mid"
set midi(path_midi2abc) midi2abc
set midi(path_midicopy) midicopy
set midi(midiplayer) timidity
set midi(midiplayer_options) "-ik"
set midi(debug) 0
set midi(pitchcoef) ss
set midi(spacing) 2
set midi(weighted) 0
set midi(stripwindow) 1000
set midi(msdelay) 900
set midi(.pitchclass) ""
set midi(.notice) ""
set midi(fontsize) 11

#set df [font create -family FreeSans]
set df [font create -size $midi(fontsize)] 

proc help_info {} {
set hlp_msg "The program shows how the key signature evolves\
across a midi file. Histograms of the pitch classes are computed\
for blocks of n beats where n is specified in the spacing\
entry box. If the weighted entry box is checked, the histogram\
is weighted by the duration of the notes. The key is determined\
by matching the histogram with either the Krumhansl-Kessler\
or Craig Sapp's simple coefficients, for the different major and\
minor keys. The key with the highest correlation is plotted in\
color coded form. If the mouse pointer enters into one of the\
color coded boxes, the key will be shown below. If you left click\
the mouse pointer in one of the boxes, the corresponding normalized\
histogram will appear in a separate window. The correlation values\
for the four best keys will be listed on the right column. 

Right clicking in one of the boxes will animate a Tonnetz diagram\
for the notes in that time interval. (See Bergstrom and Hart, Isochords:\
visualizing structure in music.) Each beat is broken in 4 equal units \
(corresponding to 1/16 th note) and all the notes for each of the units are\
displayed in an animation. Purple notes are the notes that have turned\
on during that unit. If the note is still on in the following units,\
it is shown in red. The millisecond spinbox determines\
how long the program dwells in each of the 1/16 th note units.

If you have a midi player and wish to play a section of the midi\
file, adjust the width of the window and scroll to the section of\
interest, then click the play button.

The program creates a text file findpitch.ini containing the user\
options. A tmp.mid file is created and overwritten each time the user\
plays a selected segment.
"
show_message_page $hlp_msg w
return
}

proc show_message_page {text wrapmode} {
    global active_sheet df
    #remove_old_sheet
    set p .notice
    if [winfo exist .notice] {
        $p.t configure -state normal -font $df
        $p.t delete 1.0 end
        $p.t insert end $text
    } else {
        toplevel $p
        position_window ".notice"
        text $p.t -height 15 -width 60 -wrap $wrapmode -font $df -yscrollcommand {.notice.ysbar set}
        scrollbar $p.ysbar -orient vertical -command {.notice.t yview}
        pack $p.ysbar -side right -fill y -in $p
        pack $p.t -in $p -fill both -expand true
        $p.t insert end $text
    }
    raise $p .
}

# Krumhansl-Kessler coefficients - mean 3.709 removed
# major C scale
array set kkMj {
0	2.87
1	-1.25
2	-0.00
3	-1.15
4	0.90
5	0.61
6	-0.96
7	1.71
8	-1.09
9	0.18
10	-1.19
11	-0.60
}

# Krumhansl-Kessler coefficients - mean 3.4825 removed
# minor C scale (3 flats)
array set kkMn {
0	2.62
1	-1.03
2	-0.19
3	1.67
4	-1.11
5	-0.18
6	-1.17
7	1.04
8	0.27
9	-1.02
10	-0.37
11	-0.54
}

# Craig Sapp's simple coefficients (mkeyscape)
# mean 9/12 removed
# Major C scale
array set ssMj {
0	1.25
1	-0.75
2	0.25
3	-0.75
4	0.25
5	0.25
6	-0.75
7	1.25
8	-0.75
9	0.25
10	-0.75
11	0.25
}
# Minor C scale (3 flats)
array set ssMn {
0	1.25
1	-0.75
2	0.25
3	0.25
4	-0.75
5	0.25
6	-0.75
7	1.25
8	0.25
9	-0.75
10	0.25
11	-0.75
}


array set majorColors {
 0	 #00FF00
 1	 #26FF8C
 2	 #3F5FFF
 3	 #E41353
 4	 #FF0000
 5	 #FFFF00
 6	 #C0FF00
 7	 #5DD3FF
 8	 #8132FF
 9	 #CD29FF
 10	 #FFA000
 11	 #FF6E0A
}


proc write_ini {} {
global midi
set outhandle [open "keymap.ini" w]
puts $outhandle "outfileName\t$midi(outfileName)"
puts $outhandle "pitchcoef\t$midi(pitchcoef)"
puts $outhandle "spacing\t$midi(spacing)"
puts $outhandle "weighted\t$midi(weighted)"
puts $outhandle "path_midi2abc\t$midi(path_midi2abc)"
puts $outhandle "path_midicopy\t$midi(path_midicopy)"
puts $outhandle "midiplayer\t$midi(midiplayer)"
puts $outhandle "midiplayer_options\t$midi(midiplayer_options)"
puts $outhandle ".pitchclass\t$midi(.pitchclass)"
close $outhandle
}

proc read_ini {} {
global midi
if {![file exist keymap.ini]} return
set inhandle [open "keymap.ini" r]
while {[gets $inhandle line] > 0} {
  set linelist [split $line \t]
  set midi([lindex $linelist 0]) [lindex $linelist 1]
  }
close $inhandle
}

read_ini

wm protocol . WM_DELETE_WINDOW {
  get_geometry_of_all_toplevels 
  write_ini
  exit
  }


set types {{{midi files} {*.mid}}}

proc file_browser {} {
    global midi types
    global df

    set filedir [file dirname $midi(outfileName)]
    set openfile [tk_getOpenFile -initialdir $filedir \
            -filetypes $types]
    set midi(outfileName) $openfile
    .header.file configure -text $midi(outfileName) -font $df
}

proc search_executable {executable} {
global midi
set openfile [tk_getOpenFile] 
if {[string length $openfile] > 1} {set midi($executable) $openfile}
}


proc keystrip_window {} {
global midi
global df
 if {![winfo exist .keystrip.c]} {

    frame .header
    button .header.play -text play -font $df -command play_exposed
    button .header.open -text open -font $df -command {file_browser
                                                find_key}
    label .header.file -text $midi(outfileName)
    pack .header.play -side left -anchor w
    pack .header.open -side left -anchor w
    pack .header.file -side left -anchor w
    pack .header -anchor w

    frame .keystrip
    canvas .keystrip.c -width $midi(stripwindow) -height 50\
         -scrollregion { 0 0 1000.0 50}\
         -xscrollcommand ".keystrip.xsc set"
    scrollbar .keystrip.xsc -orient horiz -command {.keystrip.c xview}
    pack .keystrip.c
    pack .keystrip.xsc -fill x
    pack .keystrip
    frame .status
    label .status.txt -text "" -font $df
    pack .status.txt
    pack .status

    frame .cfg
    frame .cfg.spc
    label .cfg.spc.spclab -text spacing -font $df
    entry .cfg.spc.spcent -textvariable midi(spacing) -width 3 -font $df
    pack  .cfg.spc -side top -anchor w
    pack .cfg.spc.spclab -side left -anchor w
    pack .cfg.spc.spcent -side left -anchor w
    radiobutton .cfg.spc.kk -text kk -font $df -value kk -variable midi(pitchcoef) -command find_key
    radiobutton .cfg.spc.ss -text ss -font $df -value ss -variable midi(pitchcoef) -command find_key
    checkbutton .cfg.spc.w -text weighted -font $df -variable midi(weighted) -command find_key
    button .cfg.spc.h -text help -font $df -command help_info
    button .cfg.spc.c -text colors -font $df -command keyscape_keyboard
    pack .cfg.spc.kk .cfg.spc.ss .cfg.spc.w .cfg.spc.c .cfg.spc.h -side left -anchor w

    frame .cfg.exp
    button .cfg.exp.playerbut -text player -font $df -command {search_executable midiplayer}
    entry  .cfg.exp.playerent -textvariable midi(midiplayer) -font $df -width 40 
    entry  .cfg.exp.playeropt -textvariable midi(midiplayer_options) -font $df
    pack .cfg.exp -side top -anchor w
    pack .cfg.exp.playerbut .cfg.exp.playerent .cfg.exp.playeropt -side left -anchor w -padx 5

    frame .cfg.exa
    button .cfg.exa.midi2abcbut -text midi2abc -font $df -command {search_executable path_midi2abc}
    entry  .cfg.exa.midi2abcent -textvariable midi(path_midi2abc) -font $df -width 40 
    pack .cfg.exa -side top -anchor w
    pack .cfg.exa.midi2abcbut .cfg.exa.midi2abcent -side left -anchor w -padx 5
    
    frame .cfg.exc
    button .cfg.exc.midicopybut -text midicopy -font $df -command {search_executable path_midicopy}
    entry  .cfg.exc.midicopyent -textvariable midi(path_midicopy) -font $df -width 40 
    pack .cfg.exc -side top -anchor w
    pack .cfg.exc.midicopybut .cfg.exc.midicopyent -side left -anchor w -padx 5
    
    pack .cfg -anchor w

    bind .cfg.spc.spcent <Return> {focus .keystrip
                                   find_key}
    }
}


proc segment_histogram {beatfrom} {
# computes the histogram for a particular segment beginning
# at beat beatfrom and spacing beats wide.
    global pianoresult midi
    global histogram
    global ppqn
    global midi
    set spacing $midi(spacing)
    for {set i 0} {$i < 12} {incr i} {set histogram($i) 0}
    set beatstart [expr $beatfrom * $ppqn]
    set beatend [expr ($beatfrom + $spacing) * $ppqn]
    foreach line $pianoresult {
        if {[llength $line] != 6} continue
        set begin [lindex $line 0]
        if {$begin < $beatstart} continue
        if {$begin > $beatend} continue
        set end [lindex $line 1]
        set t [lindex $line 2]
        set c [lindex $line 3]
        # ignore percussion channel
        if {$c == 9} continue  
        set note [expr [lindex $line 4] % 12]
        set vel [lindex $line 5]
        if {$midi(weighted)} {
          set dur [expr ($end - $begin)/double($ppqn)]
          set histogram($note) [expr $histogram($note)+$dur]
          } else {
          set histogram($note) [expr $histogram($note)+1]
          }
        }
   set total 0;
    for {set i 0} {$i <12} {incr i} {
        set total [expr $total+$histogram($i)]
    }
    if {$total > 1} {
       for {set i 0} {$i <12} {incr i} {
           set histogram($i) [expr double($histogram($i))/$total]
       }
    }
}


#tonnetz diagram
set fifths {C G D A E B F# Db Ab Eb Bb F}

proc make_tonnetz_diagram {nhor nheight} {
  global midi
  global fifths
  global noteCoords
  global ymiddle
  global hspace
  global hspace2
  global vspace
  global shiftx
  global df

  if {[winfo exist .tonnetz]} {
         raise .tonnetz .
         return
         }
  toplevel .tonnetz
  canvas .tonnetz.c -width 350 -height 210
  set w .tonnetz.beatframe
  frame $w
  label $w.beat -text "" -font $df
  button $w.pause -text Pause -font $df -command tonnetzPauseResume -width 6
  label $w.spinlab -text milliseconds -font $df
  spinbox $w.spin -from 600 -to 2400 -increment 400 -width 5 -textvariable midi(msdelay) -font $df
  pack  $w.pause $w.spinlab $w.spin $w.beat -side left -anchor w
  pack .tonnetz.c
  pack $w -anchor w
  set hspace 40.0
  set vspace [expr $hspace * 0.8660]
 
  foreach note $fifths {
     set noteCoords($note) [list]
     }  

  set hspace2 [expr $hspace/2.0]
  set ymiddle 170
  set y $ymiddle
  set shiftPerLine 3
  set noteShift 0
  for {set j 0} {$j < $nheight} {incr j} {
    for {set i 0} {$i < $nhor} {incr i} {
       set k [expr ($i + $noteShift) % 12]
       set note [lindex $fifths $k]
       set xy [tonnetzGrid2xy $i $j]
       set x [lindex $xy 0]
       set y [lindex $xy 1]
       lappend noteCoords($note) "$i $j"
       .tonnetz.c create text $x $y -text $note -tag $note -font $df
    }
  set noteShift [expr $noteShift + $shiftPerLine + ($j % 2) ]
  }
#  puts "noteCoords(G) = $noteCoords(G)"
#  puts "noteCoords(B) = $noteCoords(B)"
}

proc tonnetzGrid2xy {i j} {
  global ymiddle
  global hspace
  global hspace2
  global vspace
  set y [expr $ymiddle - $vspace*$j]
  set xoffset [expr $hspace2 * (($j+1) % 2) + 20] 
  set x [expr $i * $hspace + $xoffset]
  return "$x $y"
  }


proc highlightNotes {notelist color} {
  if {![winfo exist .tonnetz]} return
  foreach note $notelist {
    .tonnetz.c itemconfigure $note -fill $color 
    }
  }

proc unhighlightNotes {} {
  set fifths {C G D A E B F# Db Ab Eb Bb F}
  if {![winfo exist .tonnetz]} return
  foreach note $fifths {
    .tonnetz.c itemconfigure $note -fill black
    }
  }

#--------- These functions are not used ------
proc tonnetzDistance {loc1 loc2} {
set d [expr abs([lindex $loc1 0] - [lindex $loc2 0]) +\
            abs([lindex $loc1 1] - [lindex $loc2 1])]
return $d
}

proc connectTonnetzNotes {note1 note2} {
global noteCoords
foreach loc1 $noteCoords($note1) {
  foreach loc2 $noteCoords($note2) {
    if  {[tonnetzDistance $loc1 $loc2] < 3} {
        set xy1 [tonnetzGrid2xy [lindex $loc1 0] [lindex $loc1 1]]
        set xy2 [tonnetzGrid2xy [lindex $loc2 0] [lindex $loc2 1]]
        set x1 [expr round([lindex $xy1 0])]
        set y1 [expr round([lindex $xy1 1])]
        set x2 [expr round([lindex $xy2 0])]
        set y2 [expr round([lindex $xy2 1])]
        .tonnetz.c create line $x1 $y1 $x2 $y2
        }
    }
  }
}
#################################################


proc showTonnetz {w x y} {
global stripscale
global midi
make_tonnetz_diagram 8 5
set spacing $midi(spacing)
set xv [.keystrip.c xview]
set xpos  [expr $x + [lindex $xv 0]*1000] 
set beatfrom [expr $spacing*floor($xpos/$stripscale/$spacing)]
segmentTonnetz $beatfrom
}

set midi2note {C Db D Eb E F F# G Ab A Bb B}


proc compare_onset {a b} {
    set a_onset [lindex $a 0]
    set b_onset [lindex $b 0]
    if {$a_onset > $b_onset} {
        return 1}  elseif {$a_onset < $b_onset} {
        return -1} else {return 0}
}

proc reorganizeMidiCmd {} {
    global pianoresult
    global sorted_midiactions
    global lengthOfSortedMidiactions
    global midi
    global trksel
    set midiactions {}
    #puts "pianoresult = \n$pianoresult"
    foreach cmd $pianoresult {
        if {[llength $cmd] < 5} continue
        #puts $cmd
        set onset [lindex $cmd 0]
        set stop  [lindex $cmd 1]
        set chn   [lindex $cmd 3]
        set pitch [lindex $cmd 4]
        if {$chn == 9} continue 
        lappend midiactions [list $onset $pitch 1]
        lappend midiactions [list $stop  $pitch 0]
        }
    set sorted_midiactions [lsort -command compare_onset $midiactions]
    set lengthOfSortedMidiactions [llength $sorted_midiactions]
}

proc turnOffAllNotes {} {
    global notestatus
    for {set i 0} {$i < 128} {incr i } {
        set notestatus($i) 0 }
    adjustNoteStatus12
}

proc switchNoteStatus {midicmd} {
    global notestatus
    global beat_notestatus
    set notestatus([lindex $midicmd 1]) [lindex $midicmd 2]
}

proc adjustNoteStatus12 {} {
    global notestatus
    global notestatus12
    for {set i 0} {$i <12} {incr i} {
      set notestatus12($i) 0
      }
    for {set i 0} {$i <128} {incr i} {
      if {$notestatus($i) == 1} {
         set i12 [expr $i % 12]
         set notestatus12($i12) 1
         }
    }
    #puts "[array get notestatus12]"
}

proc segmentTonnetz {beatfrom} {
    global pianoresult midi
    global histogram
    global ppqn
    global midi
    global midi2note
    global tonnetzPause
    set tonnetzPause 0
    set spacing $midi(spacing)
    for {set i 0} {$i < 12} {incr i} {set histogram($i) 0}
    set beatstart $beatfrom 
    set beatend [expr ($beatfrom + $spacing)]
    reorganizeMidiCmd
    turnOffAllNotes
    animateTonnetz $beatstart $beatend
}

proc update_notestatus12 {pulseStart pulseEnd actionIndex } {
global sorted_midiactions
global lengthOfSortedMidiactions 
global notestatus12
global midi2note
#sorted_midiactions is a list containing events (pulsetime, pitch, status)
#sublists, where status is either noteon or noteoff.
# The procedure updates notestatus12 based on the events found
# between pulseStart and pulseEnd, starting from actionIndex.
   #puts "pulseStart= $pulseStart pulseEnd = $pulseEnd actionIndex = $actionIndex"
   set loc $actionIndex
   while {$loc < $lengthOfSortedMidiactions} {
      set noteCmd [lindex $sorted_midiactions $loc]
      incr loc
      set pulse [lindex $noteCmd 0]
      if {$pulse < $pulseStart} continue
      if {$pulse > $pulseEnd} break
      set actionIndex $loc 
      #puts "loc = $loc actionIndex = $actionIndex noteCmd = $noteCmd"
      switchNoteStatus $noteCmd
      set note [lindex $noteCmd 1]
      set noteStatus [lindex $noteCmd 2]
      if {$noteStatus == 1} { 
         set note12 [expr $note % 12]
         set symnote [lindex $midi2note $note12]
         highlightNotes  $symnote purple
         }
      adjustNoteStatus12
      }
return $actionIndex
}

proc animateTonnetz {beatstart tobeat} {
    global midi
    global df
    global notestatus
    global notestatus12
    global midi2note
    global ppqn
    global tonnetzPause
    global beat
    global beatend
    global lengthOfSortedMidiactions
    set beatend $tobeat
    unhighlightNotes
    #puts "ppqn = $ppqn"
# iterates over each 1/4 beat interval
    set actionIndex 0
    for {set beat $beatstart} {$beat < $tobeat} {set beat [expr $beat + 0.25]} {

       #scan notestatus12 highlighting all pitch classes that are still
       #running
       for {set note12 0} {$note12 < 12} {incr note12} {
         set symnote [lindex $midi2note $note12]
         if {$notestatus12($note12) == 1} {
            highlightNotes $symnote red
            } else {
            highlightNotes $symnote black
            }
        }
       set pulseStart [expr $beat*$ppqn]
       set pulseEnd [expr $pulseStart+$ppqn/4]
       set actionIndex [update_notestatus12 $pulseStart $pulseEnd $actionIndex] 

       if {![winfo exist .tonnetz]} {return}

       # Pause before iterating to the next 1/4 beat interval
       .tonnetz.beatframe.beat configure -text "beat = $beat" -font $df
       update
       if {$tonnetzPause == 0} {
           after $midi(msdelay) 
          } else {
           break
          }
       }
}

# retain beatstart reset by tonnetzPauseResume
global beatstart

proc tonnetzPauseResume {} {
global tonnetzPause
global beat
global beatend
global beatstart
global df
if {$tonnetzPause == 0} {
  .tonnetz.beatframe.pause configure -text Resume -font $df
  set tonnetzPause 1
  set beatstart $beat
  return
  } else {
  set tonnetzPause 0
  .tonnetz.beatframe.pause configure -text Pause -font $df
  animateTonnetz $beatstart $beatend 
  return
  }
}

proc find_key {} {
# derived from pianoroll_statistics
    global pianoresult midi
    global histogram
    global ppqn
    global lastbeat
    global total
    global exec_out
    global midi
    global majorColors
    global stripscale
    global sharpflatnotes

    #puts "find_key $midi(spacing)"
    set sharpflatnotes  {C C# D Eb E F F# G G# A Bb B}

    set spacing $midi(spacing)

    keystrip_window
    .keystrip.c delete all

    if {![file exist $midi(path_midi2abc)]} {
       set msg "cannot find $midi(path_midi2abc). Install midi2abc
from the abcMIDI package and set the path to its location." 
        tk_messageBox -message $msg
        return 
        }
    if {![file exist $midi(outfileName)]} {
       set msg "cannot find $midi(outfileName). Use the file button to
set the path to a midi file."
       tk_messageBox -message $msg
       return 
       }
    set cmd "exec [list $midi(path_midi2abc)] [list $midi(outfileName)] -midigram"
    catch {eval $cmd} pianoresult
    set exec_out [append exec_out "find_key:\n\n$cmd\n\n $pianoresult"]
    set pianoresult [split $pianoresult \n]
    set ppqn [lindex [lindex $pianoresult 0] 3]
    if {$midi(debug)} {puts "ppqn = $ppqn"}
    set nrec [llength $pianoresult]
    set midilength [lindex $pianoresult [expr $nrec -1]]
    set lastbeat [expr $midilength/$ppqn]
    set stripscale [expr 1000.0/$lastbeat]
    if {$midi(debug)} {puts "midilength = $midilength lastbeat = $lastbeat"}
    set str1 ""
    for {set i 0} {$i <12} {incr i} {
        append str1 [format "%5s" [lindex $sharpflatnotes $i]]
        }
    if {$midi(debug)} {puts $str1}

    for {set beatfrom 0} {$beatfrom < [expr $lastbeat - $spacing]} {set beatfrom [expr $beatfrom + $spacing]} {
           segment_histogram $beatfrom
           set key [keyMatch]
           set jc [lindex $key 0]
           if {$jc < 0} continue
           set keysig [lindex $sharpflatnotes $jc][lindex $key 1]
    #puts $keysig
           if {$midi(debug)} {puts "$beatfrom $key"}
           set x0 [expr $stripscale*$beatfrom]
           set x1 [expr $stripscale*$spacing + $x0]
           if {[lindex $key 1] == "minor"} {
             .keystrip.c create rect $x0 25 $x1 1 -fill $majorColors($jc) -tag $keysig -stipple gray50
              } else {
             .keystrip.c create rect $x0 25 $x1 1 -fill $majorColors($jc) -tag $keysig
       }
         .keystrip.c bind $keysig <Enter> "keyDescriptor $keysig %W %x %y"
         .keystrip.c bind $keysig <1> "show_histogram %W %x %y"
         .keystrip.c bind $keysig <3> "showTonnetz %W %x %y"
         }
  }

proc key2sharps {key} {
    set fifths {C G D A E B F# C# G# Eb Bb F}
    set loc [string first "maj" $key] 
    if {$loc > 0} {
      incr loc -1
      set majmin "major"
      set ekey [string range $key 0 $loc]
      #puts $ekey
      set i [lsearch $fifths $ekey]
    } else {
      set loc [string first "min" $key]
      incr loc -1
      set ekey [string range $key 0 $loc]
      set i [lsearch $fifths $ekey]
      set majmin "minor"
    } 
    if {$majmin == "major"} {
       if {$i  == 0} {
         set ans "$key"
       } elseif {$i < 8} {
         set ans "$key $i sharp(s)"
       } else {
         set j [expr 3 - ($i - 8)]
         set ans "$key $j flats"
         }
    }  else {
       if {$i == 3} {
         set ans  "$key"
       } elseif {$i < 3} {
         set j [expr 3 - $i]
         set ans "$key $j flat(s)"
       } else {
         set j [expr $i - 3]   
         set ans "$key $j sharp(s)"
         }
    }
    return $ans
}
      

proc keyDescriptor {keysig w x y} {
  global midi
  global stripscale
  set str [append $keysig [key2sharps $keysig]]
  set spacing $midi(spacing)
  set xv [.keystrip.c xview]
  set xpos  [expr $x + [lindex $xv 0]*1000] 
  set beatfrom [expr $spacing*floor($xpos/$stripscale/$spacing)]
  append str " at beat $beatfrom"
  .status.txt configure -text $str
  }
 


proc show_histogram {w x y} {
global stripscale
global midi
global df
global rmajmin 
global sharpflatnotes
set spacing $midi(spacing)
set xv [.keystrip.c xview]
set xpos  [expr $x + [lindex $xv 0]*1000] 
set beatfrom [expr $spacing*floor($xpos/$stripscale/$spacing)]
segment_histogram $beatfrom
plot_pitch_class_histogram 
keyMatch 
set matches [lsort -real -decreasing -indices $rmajmin]
set iy 50
set ix 390
for {set i 0} {$i <4} {incr i} {
  set j [lindex $matches $i]
  set note [lindex $sharpflatnotes [expr $j/2]]
  set minor [expr $j % 2]
  if {$minor} {set mode minor
   } else {set mode major}
  set str "[format %5.3f [lindex $rmajmin $j]] $note$mode"
  .pitchclass.c create text $ix $iy -text $str -font $df
  incr iy 15
  }
}


proc keyMatch {} {
# correlates the normalized histogram with the major and
# minor functions for different keys and returns the key
# with the highest correlation.
global ssMj
global ssMn
global kkMj
global kkMn
global histogram
global midi
global rmajmin
set best 0.0
set bestIndex 0
set bestMode ""

set rmajmin [list]
for {set r 0} {$r < 12} {incr r} {
  set c2M 0.0
  set c2m 0.0
  set h2 0.0
  set hM 0.0
  set hm 0.0
  
  for {set i 0} {$i < 12} {incr i} {
    set k [expr ($i - $r)%12]
    switch $midi(pitchcoef) {
      kk {set coefM($i) $kkMj($k) 
          set coefm($i) $kkMn($k)
          }
      ss {set coefM($i) $ssMj($k)
          set coefm($i) $ssMn($k)
         }
      }
      
      set c2M [expr $c2M + $coefM($i)*$coefM($i)]
      set c2m [expr $c2m + $coefm($i)*$coefm($i)]
      set h2  [expr $h2 + $histogram($i)*$histogram($i)]
      set hm  [expr $hm + $histogram($i)*$coefm($i)]
      set hM  [expr $hM + $histogram($i)*$coefM($i)]
     }
   if {$h2 < 0.0001} {return "-1 0"}
   set rmaj($r) [expr $hM/sqrt($h2*$c2M)]
   set rmin($r) [expr $hm/sqrt($h2*$c2m)]
   lappend rmajmin $rmaj($r)
   lappend rmajmin $rmin($r)
   }

#search for best match
set str3 ""
set str4 ""
for {set r 0} {$r <12} {incr r} {
    append str3 [format %5.1f $rmaj($r)]
    append str4 [format %5.1f $rmin($r)]
    if {$rmaj($r) > $best} {set best $rmaj($r)
                       set bestIndex $r
                       set bestMode major}
    if {$rmin($r) > $best} {set best $rmin($r)
                       set bestIndex $r
                       set bestMode minor}
    }
if {$midi(debug)} {puts $str3}
if {$midi(debug)} {puts $str4}

    return "$bestIndex $bestMode [format %7.3f $best]"
  }


proc keyscape_keyboard {} {
# plots the color code scheme for the different keys.
global majorColors
global df
if {[winfo exist .keyboard]} {
     pack forget .keyboard
     destroy .keyboard
     return
     }

canvas .keyboard -width 350 -height 100
pack .keyboard -anchor w
set nat {0 2 4 5 7 9 11}
set shp {1 3 6 8 10}
set shploc {1 2 4 5 6}
.keyboard create text 70 8 -text "Major keys" -font $df
.keyboard create text 220 8 -text "Minor keys" -font $df
for  {set i 0} {$i < 7} {incr i} {
   set x1 [expr $i*20]
   set x2 [expr ($i+1)*20]
   .keyboard create rect $x1 90 $x2 40 -fill $majorColors([lindex $nat $i])
   .keyboard create rect [expr $x1+150] 90 [expr $x2+150] 40 -fill $majorColors([lindex $nat $i]) -stipple gray50
   }
for  {set i 0} {$i < 5} {incr i} {
   set jc [lindex $shp $i]
   set jl [lindex $shploc $i]
   set x1 [expr $jl*20-7]
   set x2 [expr ($jl+1)*20 -14] 
   .keyboard create rect $x1 70 $x2 20 -fill $majorColors($jc)
   .keyboard create rect [expr $x1+150] 70 [expr $x2+150] 20 -fill $majorColors($jc) -stipple gray50
   }
}

proc copy_midi_to_tmp_for_keymap {fbeat tbeat} {
    global midi
    if {![file exist $midi(path_midicopy)]} {
       set msg "cannot find $midi(path_midicopy). Install midicopy
from the abcMIDI package and set the path to its location."
       tk_messageBox -message $msg
       return
       }
    set cmd "exec [list $midi(path_midicopy)]" 
    append cmd " -frombeat $fbeat -tobeat $tbeat"
    append cmd " [list $midi(outfileName)] tmp.mid"
    catch {eval $cmd} midicopyresult
    set exec_out "$cmd\n $midicopyresult\n"
    #puts $exec_out
    return $midicopyresult
}


proc play_exposed {} {
global midi
global lastbeat 
set scrollregion [.keystrip.c cget -scrollregion]
set xv [.keystrip.c xview]
#puts "xv $xv"
set fbeat [expr [lindex $xv 0] * $lastbeat]
set tbeat [expr [lindex $xv 1] * $lastbeat]
copy_midi_to_tmp_for_keymap $fbeat $tbeat
if {![file exist $midi(midiplayer)]} {
     set msg "You need to specify the path to a program which plays
midi files. The box to the right can contain any runtime options."
     tk_messageBox -message $msg
     return
     }
set cmd "exec [list $midi(midiplayer)]" 
if {![file exist tmp.mid]} {
    set msg "Something is wrong. Midicopy should create a the tmp.mid
file."
    tk_messageBox -message $msg
    return
    }
append cmd " $midi(midiplayer_options) tmp.mid &"
catch {eval $cmd} midiplayerresult
#puts $cmd
#puts $midiplayerresult
}


proc plot_pitch_class_histogram {} {
    global scanwidth scanheight
    global xlbx ytbx xrbx ybbx
    global histogram
    global df
    set notes {C C# D D# E F F# G G# A A# B}
    set maxgraph 0.0
    set xpos [expr $xrbx -40]
    for {set i 0} {$i < 12} {incr i} {
        if {$histogram($i) > $maxgraph} {set maxgraph $histogram($i)}
    }
    
    set maxgraph [expr $maxgraph + 0.2]
    set pitchc .pitchclass.c
    if {[winfo exists .pitchclass] == 0} {
        toplevel .pitchclass
        position_window ".pitchclass"
        pack [canvas $pitchc -width [expr $scanwidth +130] -height $scanheight]\
                -expand yes -fill both
    } else {.pitchclass.c delete all}
    
    $pitchc create rectangle $xlbx $ytbx $xrbx $ybbx -outline black\
            -width 2 -fill grey
    Graph::alter_transformation $xlbx $xrbx $ybbx $ytbx 0.0 12.0 0.0 $maxgraph
    Graph::draw_y_ticks $pitchc 0.0 $maxgraph 0.1 2 %3.1f
    
    set iy [expr $ybbx +10]
    set i 0
    foreach note $notes {
        set ix [Graph::ixpos [expr $i +0.5]]
        $pitchc create text $ix $iy -text $note -font $df
        set iyb [Graph::iypos $histogram($i)]
        set ix [Graph::ixpos [expr double($i)]]
        set ix2 [Graph::ixpos [expr double($i+1)]]
        $pitchc create rectangle $ix $ybbx $ix2 $iyb -fill blue
        incr i
    }
    $pitchc create rectangle $xlbx $ytbx $xrbx $ybbx -outline black\
            -width 2
}

proc position_window {window} {
   global midi
   if {[string length $midi($window)] < 1} return
   set n [scan $midi($window)  "%dx%d+%d+%d" w h x y]
   if {$n < 4} return
   set geom $midi($window)
   if {![string match $window ".notice"]} {
     set geom "+$x+$y"
     }
   wm geometry $window $geom
   }

proc get_geometry_of_all_toplevels {} {
  global midi
  set toplevellist {"." ".notice" ".pitchclass"}
  set x x
  foreach top $toplevellist {
    if {[winfo exist $top]} {
      set g [wm geometry $top]
      #puts $g
      scan $g "%dx%d+%d+%d" w h x y
      #puts "$top $w $h $x $y"
      set midi($top) $g
      }
   }
}

# main program

keystrip_window
find_key 

source graph.tcl

set plotwidth 250
set plotheight 200
set xlbx 60; # left margin of bounding box
set ytbx 10; # top margin of bounding box
set xrbx [expr $xlbx + $plotwidth]
set ybbx [expr $ytbx + $plotheight]
set scanwidth [expr $xrbx+20]
set scanheight [expr $ybbx+30]

