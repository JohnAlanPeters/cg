anew _ppsig_

  editor also

: crs ( n -- ) 0 ?do cr loop ;

\ --------
: sig ( -- )
  2 crs s" Signature Agreement" findstr \ total vscr
  if 4 crs
     56 spaces  month-day-year" type  cr
     13 7 do i #line" type cr cr loop
     7 spaces ." The Goal is: " 6 #line" 32 min type cr
     1 +to cursor-line                                                  
     begin cursor-line #line" -trailing dup
     while type cr 1 +to cursor-line
     repeat 2drop
  then   ;

\ --------------
: curlineaddr ( -- addr )
   cursor-line #line.addr ;
: +curlineaddr ( n -- addr len )  \ cursor-line + 'n' lines
  cursor-line + #line.addr ;
: sigtot ( -- d fl )
  s" Signature Agreement" findstr  \ total vscr
  if 6  +curlineaddr 54 + get-number
  else 0 0 then ;
: setppline ( -- fl )
  s" PAYMENT SCHEDULE" findstr dup
  if 2 +to cursor-line then ;                             

: BID-PCT ( -- )  \ fill in 50% if blank, else 90%
  sigtot  \  -- d fl
  if  setppline
      if curlineaddr get-number        \ paid
         curlineaddr  7 + d+ get-number d+  \ deposit (10%)
         curlineaddr 41 + get-number d+    \ contingency
         curlineaddr 52 + get-number d+    \ inspection
         curlineaddr 17 + get-number       \ 50%
         2dup d0= >r d+ d-   \ total - (paid+dep+50%+contngcy+inspct)
         r> if 2. d/ 100.00 d/ 1 0 d+ 100.00 d*
              cursor-line 23 at-cents
            else cursor-line 34 at-cents  then
      then
  then ;
                
: bid-eof ( -- )
  \ fill in 10%, Contingency & Inspect on line 12 of last scr.
  sigtot
  if 10. d/ 2dup 1000.00 d> if 2drop 1000.00 then \ limit to $1000
  setppline
  if curlineaddr 12 at-cents         \ 10% -> emit deposit
     cursor-line >r \ hold it
     s" Contingency Reserve" findstr
     if 4 +curlineaddr 54 + get-number
        r@ 47 at-cents   \ -> contingency
     then s" City Permit &" findstr
     if 3 +curlineaddr 52 + get-number
        r@ 58 at-cents then r> drop
  then then ;

: totalize { \ tt -- dd }  \ add all #s on the current line
  4 localAlloc: tt  0 0 tt 2!
  cursor-line #line"
  0 do dup c@ dup 47 > swap 58 < and
       if dup get-number tt 2+!
          begin 1+ dup c@ bl <>
          again
       then 1+
    loop tt 2@ ;

: TOTS  ( -- )
  sigtot
  if  \ -- d      (total payments)
    setppline
    if totalize   \ -- bid payments
       cr  2over 8 d.j
       cr  2dup 8 d.j
       cr ." ========= "
       cr 2swap d- 8 d.j
  then then ;

: Payments ( -- )  bid-eof BID-PCT BID-PCT ;
: pp payments 3 crs tots ;



