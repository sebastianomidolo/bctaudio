-- lastmod 10 agosto 2012

CREATE OR REPLACE FUNCTION public.espandi_collocazione(text) returns text AS
  'set r $1
   set tmp [set res ""]
   foreach v [split $r ".-/"] {
    lappend tmp [string trim $v]
   }
   if { [string is alpha [lindex $tmp 1]] && [string is alpha [lindex $tmp 3]] } {
     set tmp [linsert $tmp 3 ""]
   }
   foreach v [split $tmp] {if {$v=="{}"} {set v ""}; append res [format "% 10s" $v]}
   return $res
' language pltcl IMMUTABLE RETURNS NULL ON NULL INPUT;


CREATE OR REPLACE FUNCTION public.sanifica_collocazione(text) returns text AS
  'set r $1
   set r [split [string toupper $r] " ."]
   set n ""; foreach x $r { if {$x != ""} {lappend n $x}}
   return [join $n "."]
   regsub -all " +" $1 " " r
   regsub -all "\. +" $1 "." r
   set r [split [string toupper $r] " "]
   return [join $r "."]
' language pltcl IMMUTABLE RETURNS NULL ON NULL INPUT;
