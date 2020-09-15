\ cgutils.f

 anew _cgutil

forth definitions
: (cgbase+) ( a1 l1 -- a2 l2) ( replace a cg path prepend with new prepend )
  over 1+ c@ ascii : =
  if
    2dup
    s" WIN32FORTH" search \ leave alone if not a cg file
    if 2drop
    else 2drop
       s" SRC" search
       if prepend<home>\
       else s" WINED" search
         if prepend<home>\
         then
       then
     then
  then ;

: cgbase+ ( addr1 -- addr2)
  >FFA@ dup if count (cgbase+) over 1- c! 1- then ;
' cgbase+ ' get-viewfile 16 + !

editor

: (goto)    ( n -- )
  to cursor-line refresh-line cursor-on-screen reedit ;

: goto ( <line#> -- )
  /parse number? if drop (goto) else 2drop then ;

\ copy a vscr from a file to current editor file

: \v ( -- )     \ skip compiling to end of vscr -- i.e., 1st blank line
  loading?
  if -1 begin source  -trailing nip and      \ skip lines until a blank line
     while refill
     repeat
  then ;

: vlines>  { buf blen fid -- }    \ copy a vscr from buffer
  true
  begin buf blen -trailing nip and     \ check for end of vscr
  while 1 insert-lines
        blen cur-buf !
        buf cur-buf lcount cmove
        put-cursor-line
        buf 100 fid read-line 0= nip  \ -- len fl
        swap to blen   \ -- fl
        1 +to cursor-line
  repeat file-has-changed refresh-screen ;

\ note that the search is case sensitive
\ need to read a line at a time b/c it fails on large file
: vcopy { fadr flen vadr vlen \ fid buf blen eof -- }  \ from-file vscr-title
  fadr flen r/o OPEN-FILE 0=
  if to fid 0 to eof 120 localalloc: buf
     begin eof not
     while
      buf 100 fid read-line 0= and  \ -- len fl
      if to blen buf vlen vadr vlen istr=      \ -- adr len fl
        if 2 to eof                \ found match
        then
      else drop -1 to eof then     \ read error
     repeat eof 2 =
     if buf blen fid vlines> then fid close-file drop
  else drop ." can't open file" then ;

\ find text on line start in a file
\ and open the file to the line where found
editor
: vfind { fadr flen vadr vlen \ fid buf blen eof -- }  \ from-file vscr-title
  fadr flen r/o OPEN-FILE 0=
  if to fid 0 to eof 120 localalloc: buf
     0
     begin eof not  \ track line#
     while
      buf 100 fid read-line 0= and  \ -- len fl
      if to blen buf vlen vadr vlen istr=      \ -- adr len fl
        if 2 to eof                \ found match
        then
      else drop -1 to eof then 1+     \ read error
     repeat fid close-file drop eof 2 =
     if 1- s" bids\-bids" cgbase" "+open-text     \ open file
           to cursor-line cursor-on-screen reedit
     else drop ." can't find text" then
  else drop ." can't open file" then ;


\ find text in file at column zero
: vnes
  s" bids\-bids" cgbase" s" NES" vfind ;


: blk2seq { \ rh wh -- } ( fadr flen -- )     \ convert blk file to sequential file
  r/o OPEN-FILE 0=
  if to rh  pad 80 blank 2573 pad 80 + !
     s" tmp.f" delete-file drop
     s" tmp.f" w/o create-file drop to wh
     begin pad 64 blank
           pad 64 rh read-file 0= swap 64 = and
     while pad 82 wh write-file drop
     repeat rh close-file  wh close-file 2drop
  then ;

: (put) ( addr len -- )
   s" bids\put" cgbase" 2swap vcopy ;
: put ( <txt> -- )        \ copy paragraph from \bids\put to curso
   bl word count (put) ;

: hit ( -- ) [ editor ] cursor-line #line" evaluate ;

: (dotcomma-number?) ( addr len -- d1 f )
  num-init -ve-test
  0 0 2SWAP >NUMBER dup      \ convert number
  if begin over c@ [char] , =      \ got a comma
     while 1 /string >number       \ convert some more
     repeat
     OVER C@ [CHAR] . =  \ next char is a '.' ?
     if dup 1- to dp-location
        true to double?
        1 /string >number          \ convert the rest
     then
  then nip 0= >r -ve-num? if dnegate then r> ;

: dotcomma-number  UPPERCASE COUNT (dotcomma-number?) ?MISSING ;

\ ' dotcomma-number is number

: (settle)  ( -- )  \ eliminate extra blank lines. settle is vectored below
  noext? 0= if exit then
  cursor-line un-add
  17 to cursor-line   0  \ initial value for #blank lines read \ was 24  JPPP
  begin cursor-line 1+ file-lines <
  while cursor-line #line" -trailing nip 0=
        if 1+ dup 2 >  \ 1 is one line 2 is two lines between  \ JP 3-24-11
           if  1 delete-lines
           else 1 +to cursor-line then
        else 1 = if 1 insert-lines then
           0  1 +to cursor-line   \ non-blank, so reset count
        then    \  dup . cursor-line .  cr   ( for debugging )
   repeat drop to cursor-line ;

' (settle) is settle  \ See (settle) right above

: ren ( -<old new> ) { \ RenameFrom$ RenameTo$ -- }
        MAXSTRING LocalAlloc: RenameFrom$
        MAXSTRING LocalAlloc: RenameTo$
        /parse-s$ count RenameFrom$  place
        /parse-s$ count RenameTo$ place
        RenameFrom$ count RenameTo$ count rename-file
        if ." failed to rename file" then ;

: copy-file \ COPY-FILE <NewfileName> then <ExistingFileName>
           { | to$ from$ buf }  ( <to from -- )
  max-path localAlloc: to$
  max-path localAlloc: from$
  100000 localAlloc: buf
  /parse-s$ count to$  place
  /parse-s$ count from$ place
  to$ count w/o create-file if abort" failed to create new file" then >r
  from$ count r/o open-file if abort" failed to open existing file" then
  dup buf 100000 rot read-file if abort" failed to read file" then
  swap close-file drop
  buf swap r@ write-file if abort" failed to write to new file" then
  r> close-file drop ." copied file" ;


: >ccol ( n -- )   \ move console cursor to given column
  conscol @ -1 =  
  if getxy nip gotoxy
  else conscol @ - spaces then ;        \  ;

: ins ( -- )  \ put editor in insert mode
  [ editor ] overstrike on toggle-insert ;

: fsee ( <name> -- )     \ version of 'see' to show file name where defined
  >in @  see >in ! cr .viewinfo 2drop cr ;

: msgbp ( -- )  0 call MessageBeep drop ;
' msgbp is beep

: vwinfo     ( -<name>- line filename )  [  editor ]
    bl word anyfind
    if get-viewfile if dup count cur-file place over to orig-loc then
    else ." Undefined word!" 0
    then  ;

\ Show line of a file given filename count and iine#
: show1line ( fnm l1 line#  -- ) { \ $txt -- }
  200 localalloc: $txt
  >r r/o open-file 0=
  if 0 0 2 pick reposition-file drop
     r@ 0 do
       $txt 1+ 200 2 pick read-line
       if ." faled read line: " i 0 d. leave
       else 0= if ." end of file" i 0 d. leave else $txt c! then
       then
     loop close-file drop $txt count type 1
  then r> 2drop ;

: se ( <word> -- )  \ show first line of definition from source
 [  editor ] vwinfo ?dup if count rot show1line else drop then ;

: SHOW ( <word> -- )    \ 'se' plus 'see'
  >in @ bl word c@
  if dup >in ! se >in !  see
  else drop then ;

: SUPER-SEE show ;

: vocabs ( -- )   \ list vocabulary names in rows
    cr VOC-LINK @
    BEGIN   DUP VLINK>VOC
            dup voc>vcfa
            ?isclass not \ don't look through classes
            IF      voc>vcfa .NAME 18 #tab space  10 ?cr
            ELSE    DROP
            THEN    @ DUP 0=
    UNTIL   DROP ;

hidden

: list  ( -<optional_name>- ) \ WORDS partial-string will focus the list
                0 to words-cnt
                words-pocket off
                bl word uppercase c@
                if      pocket count words-pocket place
                        bl word uppercase drop
                        voc-link @
                        begin   dup vlink>voc ( #threads cells - )
                                (words)
                                @ dup 0=
                        until   drop
                else    context @ (words)
                then    0 to with-address? ;
forth

: getdatetime ( -- daddr dlen taddr tlen )
  get-local-time time-buf >date"
  time-buf >time" ;

: data>fuser ( addr len -- )  \ write datetime, username, or ip address to file
  s" \cg\webinterpret\users" 2dup r/w open-file
  if drop r/w create-file drop
  else -rot 2drop then
  dup >r file-append drop
  r@ write-file drop r> close-file drop ;

: (rename-file) ( <filename> <newname> -- )
  { \ RenameFrom$ RenameTo$ -- }
  MAXSTRING LocalAlloc: RenameFrom$
  MAXSTRING LocalAlloc: RenameTo$
  /parse-s$ count RenameFrom$  place
  /parse-s$ count RenameTo$ place cr
  RenameFrom$ count RenameTo$ count rename-file
  if ."  Failed" then ;

: rename ( <Old-name> <New-name> -- )   \ rename a file (Old then new)
  (rename-file) ;

: deletefile ( <file> -- )
  bl word count delete-file if ." failed to delete" then ;

\ date
: month-day-year" ( -- addr len )
  get-local-time time-buf
  >r 31 date$  z" MMMM dd',' yyyy"
  r> null LOCALE_USER_DEFAULT
  call GetDateFormat date$ swap 1- ;

editor
: _date-stamp ( -- )    \ put date stamp (F8)
  noext? 0= ?exit  \ only if not a .f file
  month-day-year"    \ -- addr len
  >r get-cursor-line
  cur-buf lcount drop cursor-col + r@ cmove
  r@ cursor-col + cur-buf @ >
  if cursor-col r@ + cur-buf ! then r> drop
  put-cursor-line file-has-changed refresh-line ;

' _date-stamp is date-stamp

6 proc ShellExecute
: ("ShellExecute) { operation addr cnt hWnd --  errorcode } \ open file using default application
        1 ( SW_SHOWNORMAL )   \ nShowCmd
        Null                  \ default directory
        Null                  \ parameters
        addr cnt asciiz       \ file name to execute
        operation             \ operation to perform
        hWnd                  \ parent
        Call ShellExecute ;

: "ShellExecute { addr cnt hwnd -- errorcode } \ execute batch file
        z" open" addr cnt hWnd ("ShellExecute) ;

: makenewcg ( -- )
  s" c:\cg\_makenewcg.bat" 0 "shellexecute bye ;

: skipscan ( addr cnt sub sublen char -- addr2 cnt2 flag )
  \ find substring in string; get chars from end of substring to char
  >r dup >r search
  if r> dup negate d+ 2dup r> scan
     swap drop - -1
  else r> r> 2drop 0 then ;

hidden also
: (wordvoc)       { voc \ w#threads -- }  ( -- fl)
        voc dup voc#threads to w#threads
        dup voc>vcfa
        ?isclass not \ don't look through classes
        if dup here 500 + w#threads cells move     \ copy vocabulary up
           voc>vcfa vocsave !
           begin   here 500 + w#threads largest dup
           while   dup l>name count words-pocket count istr=
                   if vocsave @ .name space then
                   @ swap !
           repeat  2drop
        else    drop
        then    vocsave off ;

: wordvoc ( -<name>- ) \ show vocabulary of the <name>
   words-pocket off
   bl word c@
   if pocket count words-pocket place
      voc-link @
      begin dup vlink>voc ( #threads cells - )
          (wordvoc)
          @ dup 0=
      until drop
   then ;


