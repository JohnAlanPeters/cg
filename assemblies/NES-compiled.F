( NES-150 )
: see ( <name> -- )     \ version of 'see' to NOT show file name where defined
  >in @  see >in ! cr ( .viewinfo 2drop cr ) ;

: RISER-150 ( - )              
electric
\ setup  hot-220
1 RISER  150A
1 90-INC 	150A
1 LB-INC 	150A
;

: NES-150 ( 150A 2 meter New Service )
( SETUP 	HOT-220 Undefine but it is there )
electric
1 RISER     	150A 	
1 90-INC    	150A 	
1 LB-INC    	150A order 	
\ METER  2-gang  \ -IN
2 OS-NIP    	100A 	elect
2 [ PANEL ]    	125A-12-24
2 C-B       	100A 	
\ 2 GROUND    	BOND 	
1 GROUND    	150A 	
Sub
;
