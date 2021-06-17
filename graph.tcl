# Part 28.0      Graphics Namespace


###   Graph ### support functions

namespace eval Graph {
    
    variable x_scale
    variable y_scale
    variable x_shift
    variable  y_shift
    variable left_edge
    variable bottom_edge
    variable top_edge
    variable right_edge
    
    
    
    namespace export set_xmapping
    proc set_xmapping {left right xleft xright} {
        variable x_scale
        variable x_shift
        variable left_edge
        variable right_edge
        set left_edge $left
        set right_edge $right
        set x_scale [expr double($right - $left) / double($xright - $xleft)]
        set x_shift [expr $left - $xleft*$x_scale]
    }
    
    namespace export set_ymapping
    proc set_ymapping {bottom top ybot ytop} {
        variable y_scale
        variable  y_shift
        variable bottom_edge
        variable top_edge
        set bottom_edge $bottom
        set top_edge $top
        set y_scale [expr double($top - $bottom) / double($ytop - $ybot)]
        set y_shift [expr $bottom - $ybot*$y_scale]
    }
    
    
    namespace export save_transform
    proc save_transform { } {
        variable x_scale
        variable x_shift
        variable y_scale
        variable y_shift
        list $x_scale $y_scale $x_shift $y_shift
    }
    
    
    namespace export restore_transform
    proc restore_transform {xfm} {
        variable x_scale
        variable x_shift
        variable y_scale
        variable y_shift
        foreach {x_scale y_scale x_shift y_shift} $xfm {}
    }
    
    
    namespace export alter_transformation
    proc alter_transformation {left right bottom top xleft xright ybot ytop} {
        set_xmapping $left $right $xleft $xright
        set_ymapping $bottom $top $ybot $ytop
    }
    
    namespace export ixpos
    proc ixpos xval {
        variable x_scale
        variable x_shift
        return [expr $x_shift + $xval*$x_scale]
    }
    
    namespace export iypos
    proc iypos yval {
        variable y_scale
        variable y_shift
        return [expr $y_shift + $yval*$y_scale]
    }
    
    
    namespace export pix_to_x
    proc pix_to_x ix {
        variable x_scale
        variable x_shift
        return [expr ($ix - $x_shift)/$x_scale]
    }
    
    namespace export pix_to_y
    proc pix_to_y iy {
        variable y_scale
        variable y_shift
        return [expr ($iy - $y_shift)/$y_scale]
    }
    
    
    namespace export draw_x_ticks
    proc draw_x_ticks {can xstart xend xstep nskip labindex fmt} {
        global df
        variable bottom_edge
        set xticks {}
        set i 0
        for {set x $xstart} {$x < $xend} {set x [expr $x + $xstep]} {
            set ix [ixpos $x]
            set xticks [concat $xticks [$can create line $ix $bottom_edge $ix \
                    [expr $bottom_edge - 5]]]
            if {[expr $i % $nskip] == $labindex} {
                set str [format $fmt $x]
                set xticks [concat $xticks [$can create text $ix \
                        [expr $bottom_edge + 20] -text $str -font $df]]
                set xticks [concat $xticks [$can create line $ix $bottom_edge $ix \
                        [expr $bottom_edge - 10]]]

            }
            incr i
        }
        set xticks
    }
    
    namespace export draw_x_grid
    proc draw_x_grid {can xstart xend xstep nskip labindex fmt} {
        global df
        variable bottom_edge
        variable top_edge
        set xticks {}
        set i 0
        for {set x $xstart} {$x < $xend} {set x [expr $x + $xstep]} {
            set ix [ixpos $x]
            set xticks [concat $xticks [$can create line $ix $bottom_edge $ix \
                    [expr $bottom_edge - 5]]]
            if {[expr $i % $nskip] == $labindex} {
                set str [format $fmt $x]
                set xticks [concat $xticks [$can create text $ix \
                        [expr $bottom_edge + 20] -text $str -font $df]]
                set xticks [concat $xticks [$can create line $ix $bottom_edge $ix \
                        $top_edge -dash {1 2}]]]
            }
            incr i
        }
        set xticks
    }

    namespace export draw_y_ticks
    proc draw_y_ticks {can ystart yend ystep nskip fmt} {
        global df
        variable left_edge
        set i 0
        set yticks {}
        for {set y $ystart} {$y < $yend} {set y [expr $y + $ystep]} {
            set iy [iypos $y]
            set yticks [concat $yticks [$can create line  $left_edge \
                    $iy [expr $left_edge + 5] $iy]]
            if {[expr $i % $nskip] == 0} {
                set str [format $fmt $y]
                set yticks [concat $yticks [$can create text \
                        [expr $left_edge - 33] $iy -text $str -font $df]]
                set yticks [concat $yticks [$can create line \
                        $left_edge $iy [expr $left_edge + 10] $iy]]
            }
            incr i
        }
        set yticks
    }
    
    namespace export draw_y_grid
    proc draw_y_grid {can ystart yend ystep nskip fmt} {
        global df
        variable left_edge
        variable right_edge
        set i 0
        set yticks {}
        for {set y $ystart} {$y < $yend} {set y [expr $y + $ystep]} {
            set iy [iypos $y]
            set yticks [concat $yticks [$can create line  $left_edge \
                    $iy [expr $left_edge + 5] $iy]]
            if {[expr $i % $nskip] == 0} {
                set str [format $fmt $y]
                set yticks [concat $yticks [$can create text \
                        [expr $left_edge - 33] $iy -text $str -font $df]]
                set yticks [concat $yticks [$can create line \
                        $left_edge $iy $right_edge $iy -dash {1 2}]]
            }
            incr i
        }
        set yticks
    }
    
    namespace export draw_x_log10ticks
    proc draw_x_log10ticks {can  start end fmt} {
        variable bottom_edge
        set xstart [expr floor($start)]
        set xend [expr floor($end)]
        for {set x $xstart} {$x<$xend} {set x [expr $x +1.0]} {
            set xval [expr pow(10.0,$x)]
            set ix [ixpos $x]
            $can create line $ix $bottom_edge $ix [expr $bottom_edge -10]
            set str [format $fmt $xval]
            $can create text $ix [expr $bottom_edge+20] -text $str
            for {set i 2} {$i<10} {incr i} {
                set xman [expr log10($i)]
                set ix [ixpos [expr $xman + $x]]
                $can create line $ix $bottom_edge $ix [expr $bottom_edge -5]
            }
        }
    }
    
    namespace export draw_y_log10ticks
    proc draw_y_log10ticks {can  start end fmt} {
        variable left_edge
        set ystart [expr floor($start)]
        set yend [expr floor($end)]
        for {set y $ystart} {$y<$yend} {set y [expr $y +1.0]} {
            set yval [expr pow(10.0,$y)]
            set iy [iypos $y]
            $can create line $left_edge $iy [expr $left_edge +10] $iy
            set str [format $fmt $yval]
            $can create text [expr $left_edge-20] $iy -text $str
            for {set i 2} {$i<10} {incr i} {
                set yman [expr log10($i)]
                set iy [iypos [expr $yman + $y]]
                $can create line  $left_edge $iy [expr $left_edge +5] $iy
            }
        }
    }
    
    
    namespace export draw_graph_from_arrays
    proc draw_graph_from_arrays {can xvals yvals npoints} {
        upvar $xvals xdata
        upvar $yvals ydata
        set points {}
        for {set i 0} {$i < $npoints} {incr i} {
            set ix [ixpos $xdata($i)]
            set iy [iypos $ydata($i)]
            lappend points $ix
            lappend points $iy
        }
        eval {$can create line} $points
    }
    
    
    namespace export draw_graph_from_list
    proc draw_graph_from_list {can datalist} {
        #can canvas
        #datalist {x y x y x y ...}
        set points {}
        foreach {xdata ydata} $datalist {
            set ix [ixpos $xdata]
            set iy [iypos $ydata]
            lappend points $ix
            lappend points $iy
        }
        eval {$can create line} $points
    }
    
    namespace export draw_impulses_from_list
    proc draw_impulses_from_list {can datalist} {
        #can canvas
        #datalist {x y x y x y ...}
        foreach {xdata ydata} $datalist {
            if {$ydata != 0.0} {
                set ix [ixpos $xdata]
                set iy [iypos $ydata]
                $can create line $ix [iypos 0] $ix $iy -fill blue -width 2
            }
        }
    }
} ;# end of namespace declaration

namespace import Graph::*


#end of midistats.tcl

