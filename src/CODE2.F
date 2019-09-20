
: Total-WEB ( -- ) \ display sub-totals on web
37 ( 34 ) >ccol parts-total 2@ bucks
46 ( 43 ) >ccol time-total  2@ bucks ."  hr"
58 ( 57 ) >ccol labor-total 2@ bucks
65 ( 62 ) >ccol sell-total  2@ bucks ;       

: Total-con ( -- ) \ display sub-totals in console
    ( 35 ) >ccol parts-total 2@ bucks
    ( 45 ) >ccol time-total  2@ bucks ."  hr"
    ( 59 ) >ccol labor-total 2@ bucks
    ( 70 ) >ccol sell-total  2@ bucks ;

: Headline-WEB ( -- )
     10 spaces ." Only            Part       Parts     Time       Labor     Sell " ;

: Headline-con ( -- ) \ Tells the name of the column
16 ( 16 ) >ccol  ." Quan"   \ ok
30 ( 30 ) >ccol  ." Part"   \ ok
45 ( 45 ) >ccol  ." Parts"  \ ok
50 ( 50 ) >ccol  ." Time"   \ ok
59 ( 59 ) >ccol  ." Labor"  \ ok
67 ( 67 ) >ccol  ." Sell" ; \ Does not show up


: HEADLINE
  in-web?
  if   headline-WEB
  else headline-con
  then ;

: TOTAL
  in-web? cr
  if   total-WEB
  else total-con
  then ;


: TT headline total ; \ An alias, yes there is a better way








