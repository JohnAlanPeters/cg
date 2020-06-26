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

: (settle)  ( -- )  \ eliminate extra blank lines  see also settle below
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
    if get-viewfile if dup count cur-file place else exit then
    else c@ abort" Undefined word!"
         cur-line @ cur-file
    then over to orig-loc ;

: _show ( <word> -- )  \ show first line of definition from source
 [  editor ] vwinfo count "+open-text 0 swap 1-
  to-find-line get-cursor-line cur-buf lcount focus-console cr type ;

: SHOW  >in @ _show >in ! see ;  \ 'show' plus 'see'
: SEE+  show ; \ Show the stack comment before the decompiled source
: SUPER-SEE show ;
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
\ Dudley, please delete these 5 lines
\ forth
\ words ( -<optional_name>- )
\ in-web?
\ if words-WEB-msg else words ( wordscount ) then ;

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


