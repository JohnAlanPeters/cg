
: TOTAL-WEB CR ( -- ) \ display sub-totals on web
     55 >ccol parts-total 2@ bucks
     65 >ccol time-total  2@ bucks ."  hr"
     77 >ccol labor-total 2@ bucks
     87 >ccol sell-total  2@ bucks ;

: TOTAL-CON ( -- ) \ display sub-totals in console
     55 10 - >ccol parts-total 2@ bucks
     65 10 - >ccol time-total  2@ bucks ."  hr"
     77 10 - >ccol labor-total 2@ bucks
     87 10 - >ccol sell-total  2@ bucks ;

: HEADLINE-WEB ( -- )
     cr 01 spaces ." Only Part  Parts   Time   Labor   Sell " ." HEADLINE-WEB" ;

: HEADLINE-CON ( -- ) \ is good
     10 >ccol  ." Quan"
     20 >ccol  ." Part"
     37 >ccol  ." Parts"
     48 >ccol  ." Time"
     59 >ccol  ." Labor"
     70 >ccol  ." Sell" ;


: HEADLINE
  in-web?
  if   headline-web
  else headline-con
  then ;

: TOTAL
  in-web? cr
  if   total-web
  else total-con
  then ;


: TT headline total ; \ An alias, yes there is a better way








