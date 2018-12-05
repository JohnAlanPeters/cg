( NES-150 )
: see ( <name> -- )     \ version of 'see' to NOT show file name where defined
  >in @  see >in ! cr ( .viewinfo 2drop cr ) ;

: HEADLINE ( -- )
  31 spaces ." Only       Part       Parts      Time       Labor      Sell "
  cr ;

: RISER-100 ( - )
  [ electric ] keyboard on kclr
\ setup  hot-220
1 [ RISER  ] 100A   cr
1 [ 90-INC ] 100A   cr
1 [ LB-INC ] 100A   cr
headline total ;

: RISER-125 ( - )
  electric keyboard on kclr
1 [ RISER  ] 125A    cr
1 [ 90-INC ] 125A    cr
1 [ LB-INC ] 125A    cr
headline total ;

: RISER-150 ( - )
  electric keyboard on kclr
1 [ RISER  ] 150A    cr
1 [ 90-INC ] 	150A   cr
1 [ LB-INC ] 	150A   cr
headline total ;

: RISER-200 ( - )
  electric keyboard on kclr
1 [ RISER  ] 200A  cr
1 [ 90-INC ] 200A  cr
1 [ LB-INC ] 200A  cr
headline total ;

: NES-150 ( 150A 2 meter New Service )
( SETUP 	HOT-202     edfined but it is there )
  electric keyboard on kclr
1 [ setup   ]  job    cr
1 [ RISER   ]  	150A  	cr
1 [ 90-INC  ]  	150A  cr	
2 [ LB-INC  ]  	150A  cr
1 [ METER   ]  2-gang cr
2 [ OS-NIP  ]  	100A  cr
1 [  PANEL  ]  125A-12-24 cr
1 [ C-B     ]  	100A  	cr
1 [ GROUND  ]  	BOND  cr
1 [ GROUND  ]  	150A  cr
headline total ;



