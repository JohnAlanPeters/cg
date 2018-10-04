\ email.f - create file email.html of current file

0 value hfid
: hferr ( fl -- )  abort" failed to write to file" ;
: outfiletype ( adr len -- )
  hfid write-file hferr ;
: outfileemit ( chr -- )
  pad c! pad 1 outfiletype ;
: outcr ( -- ) crlf$ count outfiletype ;
: qemit ( -- ) ascii " emit ;
: <Header> ( -- )
   ." <!DOCTYPE HTML PUBLIC "
   qemit ." -//W3C//DTD XHTML 1.0 Strict//EN" qemit ." >" cr
   ." <HTML><HEAD><META content="
   qemit ." text/html; charset=ISO-8859-1" qemit
   ."  http-equiv=" qemit ." content-type" qemit ." />" cr
   ." </HEAD><BODY bgColor=#ffffff style='color:black'>" cr ;

: <Footer>  ." </BODY></HTML>" cr ;

: <STRONG>   ."  <STRONG>" ;
: </STRONG>  ." </STRONG>" ;
: <BOLD> ." <B>" ;
: </BOLD> ." </B>" ;
: <BLUE> ." <SPAN style='color:blue'>" ;
: </BLUE> ." </SPAN>" ;
: <STRONG-BLUE>  ." <STRONG style='color:blue'>" ;
: <BLACK>    ." <SPAN style='color:black'>";
: </BLACK>   ." </SPAN>" ;
: <DIV>      ." <DIV>"  ; \ Divides into a block.
: </DIV>     ." </DIV>" ; \ You can use <P> inside it.
: <PRE>      ." <PRE>"  ; \ Makes the text preforematted
: </PRE>     ." </PRE>" ; \ As in not justified etc.
: <BR>       ." <BR>"   ; \ line Break
: <spaces> 0 ?do ." &nbsp;" loop ;
\ output file as a new marked-up html file

editor also
0 value gottot  // true->past grand total line
: vtot? ( -- fl )
  cursor-line #line" vtot-col >
  if vtot-col + dup c@ ascii . =
     if begin 1- dup c@ bl =
        until 1+ c@ ascii $ = 
     else drop false then
  else drop false then ;

: xtop? ( -- fl )     \ if on top line of a virtual screen
   cursor-line 25 <  gottot or
   cursor-line #line" -trailing nip 0= or 
   if 0 else  \ blank line isn't a vscr
     cursor-line 1 - #line" -trailing nip 0=  \ line above is blank
   then ;

: plines-left
  printer-rows cursor-line PRINTER-ROWS mod - ;  \ #lines left

: orphan-check  ( -- )
  xtop?
  if cursor-line >r   \ remember currrent cursor line
    plines-left           \ -- #lines left on page
    +vscr                 \ find next vscreen
    cursor-line r@ -      \ #lines needed
    r> to cursor-line     \ restore cursor line
    <                     \ not enough, so
    if plines-left 0      \ output extra blank lines to end of printer page
      do <BR>  loop
    then
  then ;

1 value eline#s           \ set true to output line numbers on left edge

: letterhead ( -- )
  8 dup>r 0                     \ address, phone#s   Change it here and below
  do eline#s
     if i 0 <# #s #> type then    \ output single digit line#
     i #line" type cr
  loop </STRONG> r> to cursor-line ;

0 value v1st  \ start of vscreen numbering;  0 -> no vscreen numbers 

:  outfile-html  ( -- )
   0 to gottot letterhead
   v1st
   begin \ orphan-check  
     cursor-line file-lines <
   while eline#s
     if cursor-line 0 <# #s #> dup>r type 4 r> - <spaces> then
     vtot?       \ test for decimal point in specific column
     if <STRONG-BLUE> cursor-line #line" drop
       dup vtime-col 3 + type space vtot-col 8 - + 12  type
      </STRONG>
     else xtop? if <STRONG-BLUE>
                   cursor-line #line" drop s"      " swap over compare
                   if v1st
                     if dup 0 <# #s #> type space    \ display the vscreen#
                      1+ then  \ increment virtual screen number
                   then cursor-line #line" -trailing type
                  </STRONG>
          else  <black>
             cursor-line #line" -trailing type    </black>
          then
     then
     cursor-line #line" drop s" Total Estimate" tuck istr=
     if true to gottot then     cr
     1 +to cursor-line
   repeat drop ;
                     
: EMAIL ( -- )
  cursor-line cursor-col
  settle
  s" bids\email.html" cgbase" 2dup delete-file drop
  w/o create-file abort" can't open email file"
  to hfid ['] type >body @ ['] emit >body @ ['] cr >body @
  ['] outfiletype is type ['] outfileemit is emit ['] outcr is cr
  <Header> <PRE>
  outfile-html
  </PRE> <Footer>
  hfid close-file drop is cr is emit is type 
  to cursor-col to cursor-line ;

: Emailit    email ;
: Mailit   emailit ;
: E-M      emailit ." Converted" ;
: EM           E-M ;        
