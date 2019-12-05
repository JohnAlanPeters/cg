\ grandtotal            rda 7-11-2005
\ NOTE: m-in has to be set before doing a grand-total to what it was
\ when vscr extendsions/totals were generated

anew _grandtot

  editor also
: find-tot-line ( l# -- l# )  \ return 0 if at end of file
  begin 1+ dup  file-lines <
   if dup #line" sell-col >
      IF SELL-COL + DUP C@ ascii . =   \ got a decimal point in right place
        if BEGIN   1- DUP C@ BL =      \ scan back to blank
           UNTIL   1+ C@ ascii $ =    \ char after blank is '$'?
        else drop false then
      ELSE DROP FALSE THEN      \ keep looking
   else drop 0 true then    \ end of file
  until ;                   \ l# of vtot line or 0


: get-subs  ( #l  -- )
  partscolshow
  if dup parts-col 6 - get-number parts-total 2+! then
  timecolshow
  if dup time-col 6 - get-number time-total 2+! then
  sell-col 6 - get-number sell-total 2+! ;

: grand-total-line ( -- l#)
  0 >col-cursor   20 to cursor-line
  s" TOTAL ESTIMATE" find-buf place _find-text-again  0=  
  if  file-lines 1- to cursor-line    \ end of file
        1 insert-lines                  \ add line
        s" Total Estimate" >r cur-buf cell+ r@ cmove r> cur-buf !
        put-cursor-line
  then  cursor-line ;

: show-grand ( -- )  \ bottom of the bid
  grand-total-line
  if get-cursor-line cur-buf lcount drop
     60 + 20 blank 100 cur-buf !
     vtot-col tab-in EX-TOTAL so $.r ro
     update+
  then ;

: aa- ( -- )     \ just calc sell-total and display it (no extend vscrns)
  noext?
  if  CLEAR-TOTALS 20    \ skip vscr#0
    begin find-tot-line ?dup
    while dup get-subs 1+
    repeat show-grand
  then ;

: bid-thru ( -- )    \ extend every vscr in current file and do a grandtotal
  noext?    \ only total if a bid, no file extension like .F 
  if false to ext-err CLEAR-TOTALS
     17 to cursor-line
     1 0 skiplines   \ to first non-blank line
    begin cursor-line file-lines <
    while parts-total 2@ labor-total 2@
          time-total 2@ other-total 2@ permit-total 2@  allowance-total 2@
          wholesale-total 2@ sell-total 2@
          depth to saved-depth
          extend                     \ calculate extensions
          depth saved-depth <>
          if beep cr ." stack is off at line: " cursor-line . abort then
          cursor-line file-lines <
          if
            ext-err if beep cr ." err line: " cursor-line . abort then
            1 -1 skiplines              \ to end of vscr
            1 0 skiplines              \ to next vscr
          then
          sell-total 2+!  wholesale-total 2+! 
          allowance-total 2+! permit-total 2+!  other-total 2+!
          time-total 2+!  labor-total  2+!  parts-total 2+!
          0 to saved-depth
    repeat discount 0= if show-grand then
  then ;



