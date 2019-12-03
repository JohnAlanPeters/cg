\ adding.f  from bluescreen code
\ put summary/totals on scr#0
   anew _adding_

editor also
  \ This test needs to be moved to the word calling CALC not in calc itself.
7 constant topout
: Rev? ( -- fl)  \ true-> not '0' or 'S' for major rev#
  topout 2 + #line" drop 32 + c@ dup ascii 0 = swap ascii S = or not ; \ 32

: GET-GL-BUD  topout 3 + 65 get-number ;  \ GL estimated to do the work
: GET-GL-ACT  topout 4 + 65 get-number ;  \ Actual GL spent, comes from QB
: GET-DBI     topout 5 + 65 get-number ;  \ GL for the time to do DBI Inspection
  : GET-GL-REM  topout 6 + 65 get-number ;  \ GL Rem in the budget

: HrsDiff ( -- )  \ calc (real.hrs) - (10% hrs )
  topout 7 + 68 get-number       \ -- d1-real.hrs    (calculated and bid)
  topout 66 get-number 10. d/    \ -- d1 d2-10% hrs
  d- topout 8 + 71 at-cents ;    \ 90% of real hrs

\ : CALC-GL-REM ( -- d )
\  get-gl-bud get-DBI get-gl-act  d+  d-  ;
\  EX-TOTAL get-DBI d- ;

\ : SHOW-GL-REM ( -- ) calc-gl-rem  topout 6 + 71  at-cents ;

\ : CALC-HRS GET-GL-REM CURRENT-RATE 2@ 4.00 D/ D/  topout 7 + 71  at-cents ;

: CALC  ( -- ) rev? drop 0     \ only if non-zero
  if topout 6 + #line" drop 61 + 14 blank  \ erase calc-gl-rem
     topout 7 + #line" drop 61 + 14 blank  \ erase calc-hrs
  \  show-gl-rem calc-hrs  hrsDiff calc-percent
  then ;


: TIME-OUT    ( first last -- )   \ Calender or schedule the job days & hours
  time-total 2@                  topout    51 at-cents  \ Total Hrs  Goal
  time-total 2@  .80 d* 100. d/  topout    64 at-cents  \ Total Hrs  Actual
  time-total 2@  1.00 d* 5.00 d/ topout 1+ 51 at-cents  \ Total Days Envelope
  time-total 2@  1.00 d* 7.50 d/ topout 1+ 64 at-cents  \ Total Days Actual
  ;

: SELL-OUT    ( -- )     \ total estimate including what?
  EX-TOTAL topout 2 + 51 at-cents ;

: LABOR-OUT    ( -- )    \ actuall hours
  labor-total 2@ topout 3 + 51  at-cents ;

: PARTS-OUT  ( -- )      \ materials marked-up
  parts-total 2@  topout 4 + 51  at-cents ;

: WHOLESALE-OUT ( -- )   \ materials at whowsale
  wholesale-total 2@ topout 4 + 64 at-cents ;

: OTHER-OUT ( -- )       \ credit, profit, etc.
  other-total 2@ topout 5 + 51 at-cents ;

: ALLOWANCE-OUT ( -- )   \ contingency fund
  allowance-total 2@ topout 5 + 64 at-cents ;

: PERMIT-OUT ( -- )      \ DBI costs and time to meet inspector?
  permit-total 2@ topout 6 + 51 at-cents ;

: ADD-ALL-SCREENS ( -- ) \ It all happens here
  bid-thru               \ extend all vscrns accumulating totals
  sell-out  time-out wholesale-out  parts-out   labor-out 
  other-out            \ what?
  permit-out           \ DBI fees
  allowance-out      \ contingency fund
  ;

: LAB-BUD-35  ( -- d) labor-total 2@ 1.00 d* .286 d/  ;
: LAB-BUD-100 ( -- d) labor-total 2@ ;

: Copy-job ( -- ) [ editor ]
  cursor-line
  10 #line" drop 40 -trailing
  9 to cursor-line get-cursor-line buf-blank
  cur-buf cell+ 54 + swap cmove
  put-cursor-line to cursor-line refresh-screen ;

: CJ  Copy-job ;  \ Shorter
: C-J  CJ ;

: COPY-CONTINGENCY ( d -- )  [ editor ]
    \ find place on scr# 0 and overwrite it
    s" Contingency Fund is " findstr
    if 2dup d0= if 2drop  so  ." removed  "  ro
                else out-cents then
    else 2drop then ;

<<<<<<< HEAD
: CCC  ( -- )
=======
: CCCR  ( -- )
>>>>>>> 26beda8326f33cf17f87d56212bce849b574431e
  s" Contingency Reserve" findstr
  if cursor-line find-tot-line ?dup
     if cursor-line 72 get-number else 0 0 then
     copy-contingency
  then ;

: OVER-SIG? ( -- f )       \ true=> estimate is over sig
  5 54 get-number          \ get the amount signed for
  2dup or rev? and         \ make sure not a zero
  IF 2 54 get-number       \ get the total est.mate price
   d-                      \ subtract sig from bid
   2dup d0<
   >r 12 64 out-cents r>
  ELSE  2drop false
  THEN ;

: OVER-SIG  ( -- ) 0 \ over-sig?
  if s" STOP WORK" else  s"          " then
  19 #line" drop swap cmove ;

: add-dot ( -- )
   5 54 get-number d0= not
   if ascii . 4 #line" drop 60 + c!
   then ;

: copy-sig ( -- )
   2 54 get-number
   5 60 at-cents add-dot ;

: ALL-THRU     ( -- )
   add-all-screens
\   over-sig
    lab-bud-35  topout 3 + 64 at-cents    \  the 35% amount The 3 is line
    calc  5 +to cursor-col ;

: 20%    ( -- ) s" 20%" findstr
  if sell-total 2@  5. d/ 8 +to cursor-col out-cents
  then  ;

: 25%    ( -- ) s" 25%" findstr
  if sell-total 2@  4. d/  8 +to cursor-col out-cents
  then  ;


: _total-est  ( -- add cnt )   \ for status output
  last-total prt# ;

' _total-est is total-est

: AA     ( -- ) \ Extend all paragraphs and grand total the estimate
  noext?
  if line-cur cursor-line cursor-col
     keyboard off ['] all-thru  catch 0=
     if  to cursor-col to cursor-line to line-cur refresh-screen
     else 2drop drop then
\    20% 25% cc
  then  EX-TOTAL to last-total
  ( clear-totals ) save-text ( overstrike on ) ;

' AA is grand-total   \ AA from the console or use F2 from within the editor

: AAA-1 1-column grand-total 2-column ;  \ same as AA but single column mode
' AAA-1 is AAA  ( JP? 4-5-09 )

: No-Time aaa ;  \ The same name as in the blue screen
: Notime  aaa ;  \ Some like it without hypens

: Note ." Reserved for use with the PP or progress payment calculations."
      cr ." Use F2 for AA"
      cr ." Use F-10 to link to source of highlighted word"
      cr ." Use F-11 to link back to prior source word" ;
