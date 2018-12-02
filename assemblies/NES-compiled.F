( NES-150 )
: see ( <name> -- )     \ version of 'see' to NOT show file name where defined
  >in @  see >in ! cr ( .viewinfo 2drop cr ) ;

: HEADLINE ( -- )
cr 31 spaces ." Only       Part       Parts      Time       Labor      Sell " 
cr ;

: RISER-100 ( - )
  electric
\ setup  hot-220
1 RISER  100A   cr
1 90-INC 100A   cr
1 LB-INC 100A  cr
total headline ;

: RISER-125 ( - )
  electric
\ setup  hot-220
1 RISER  125A   cr
1 90-INC 125A   cr
1 LB-INC 125A  cr
total headline ;

: RISER-150 ( - )
  electric
\ setup  hot-220      
1 RISER  150A   cr
1 90-INC 	150A  cr
1 LB-INC 	150A  cr
total headline ;

: RISER-200 ( - )
  electric
\ setup  hot-220
1 RISER  200A  cr
1 90-INC 200A  cr
1 LB-INC 200A  cr
total cr headline ;

: NES-150 ( 150A 2 meter New Service )
( SETUP 	HOT-202     dfined e but it is there )
  electric
1 RISER     	150A 	cr
1 90-INC    	150A cr	
1 LB-INC    	150A ( order 	)
\ METER  2-gang  \ -IN
2 OS-NIP    	100A 	elect  cr
2 [ PANEL ]    	125A-12-24  cr
2 C-B       	100A 	           cr
\ 2 GROUND    	BOND 	
1 GROUND    	150A 	             cr
total headline ;



