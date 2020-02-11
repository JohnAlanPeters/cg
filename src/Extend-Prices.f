\ $Id: Extend-Prices.f,v 1.4 2011/10/24 18:38:11 rdack Exp $
\ File is EXTEND-PRICES.F  by Robert D. Ackerman (hard stuff) and John Peters
\ Created December 08, 2001  Revised January 1, 2002
\ Now it is working better on Thursday, April 29 2004 - 18:47
(( Do you want to right justify output so decimal points line up?
then use rightmost column minus count from prt# as starting column
for emit-at-column.
This code was created fresh for the WinCG version.
))

    editor
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 03    Extend the prices  It's vector is resolved in CG.G
\       You can find it by viewing TITLE-CG
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
: exttotline? ( -- fl )    \ true=>an extended total line
  cursor-line #line" vtot-col >
  if dup 16 + 28 bl skip nip 0=
     swap vtot-col + c@ ascii . = and   
  else drop false then ;

: extstop? ( -- fl )        \ true=>go on  false=>blank/total 1=>\s
  cursor-line isblank 0= dup
  if drop cursor-line #line" drop
     dup c@ ascii \ =             \ check for backslash
     if 1+ c@ ascii s =           \ check for 'backslash s'
       if 1 else 1 +to cursor-line recurse then
     else drop exttotline? 0= then
  then ;

: chkskipscr ( -- fl ) \ true = stop extending scr b/c top line starts with dash
  cursor-line #line" drop c@ ascii \ = dup
  if 1 true skiplines then ;
                   
: EXTEND ( -- )  \ Ctrl+E  Extends all the lines from 17 down to TOTAL ESTIMATE
                 \ This is hard coded in BID-THRU
     un-add      \ erase all three columns                     \ JP                                     
    -1 true skiplines 1 +to cursor-line  \ get to top of current vscr
    clear-totals
    cursor-line #line" drop s" total est" tuck istr=
    cursor-line #line" drop s" \\s" tuck istr= or   \ Allows comments in a vscr
    if file-lines to cursor-line exit then
    chkskipscr ?exit
    1 +to cursor-line                    \ skip top line of vscreen
    S-O                                  \ screen output
    Begin
      extstop? true =                    \ stop at '\s' or blank
    While   get-cursor-line              \ get current line into buffer
     -1 to dp-location
     clear-sub
     buf-blank                           \ blank pad the buffer
     cur-buf lcount  drop
     tab-size + 30                       \ zero based, but editor is 1 based
     -1 -1 quan 2!                       \ flag for showing totals
     evaluate-ext                        \ interpret cols 16-48
     if sub<>0                           \ ?is line not empty
      if sell-sub 2@ -1 s>d d=           \ -1 -> flag for display as '0'
         if 0 0 sell-sub 2! then
         show-all                        \ on screen line totals
      then
      update+                            \ type a line, update and refresh
      1 +to cursor-line                  \ make next line current
     else exit then
    Repeat                               \ repeat until blank line or \s
    vtotal<>0
    if exttotline? 0=
       drop \ if 1 insert-lines then     \ Now AA & settle agree  JAPP3   
       discount
       if 90 cur-buf ! cur-buf lcount blank update+
       else total-vscr then       \ show the virtual page column totals
       -1 +to cursor-line                \ line above total
       HOME-LINE 'CURSOR C@ BL =         \ set cursor column
       IF WORD-RIGHT THEN
       1 +to cursor-line                 \ to total line         
    then           R-O                   \ regular output to console
    refresh-screen ;

: Flat-rate ( -- )    \ call before extending to only show single total column
  false to partscolshow false to timecolshow false to unitcolshow ;

: 1-column   flat-rate ;  \ c/b an alias I guess.
: 1-col      flat-rate ;                

: 2-column   ( -- )   \ show time column and total column
  false to partscolshow true to timecolshow false to unitcolshow ;
                                         
: 3-column ( -- )     \ show parts, time, and total columns
  true to partscolshow true to timecolshow false to unitcolshow ;
: 3C          3-column ;
: 3-col       3-column ;
: 3-columns   3-column ." 3 columns" ;

: 4-column ( -- )   \ show cost of 1 part, total time and total cost+time
  true to unitcolshow ;

: Extend-Prices Extend ;
: no-time     1-column ;

: more ( n -- )  \ remove vscr subtotal and insert n blank lines
  begin
    cursor-line #line" nip 0>
    [ editor ] exttotline? 0= and
  while 1 +to cursor-line
  repeat 0 cur-buf ! put-cursor-line
  cursor-line swap insert-lines   to cursor-line 0 to cursor-col
  file-has-changed refresh-screen  reedit ;

: 1m 16 more ;
: 2m 32 more ;
: 3m 48 more ;


