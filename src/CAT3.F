\ $.Id
\ rda for jap on Sunday, July 18 2004 - 16:46 and Saturday, July 31 2004
\ CAT3.F read the top lines of documentation in all files in a folder
\ It could use a pause per eyefull (screenfull)
\ Print the name of the folder first.
\ Print the name of each file in bold
\ supress the name of the file if it is already shown in the $Id
\ WINBROWS.F is an example of a tough cookie  starts with a ((
\ How about using a smaller font?
\ how about a clone of colons-only? aka folded
\ need a larger console buffer to CAT the SRC folder

40 value #lines \ number of lines to show
 0 value InComment \ True = want to print it
editor

Variable ~TEMP
: ANY?   ( n1, n2, n3, etc count -- ) \ See YES? below
   dup 1+ roll ~temp !  0 swap 0 do swap ~temp @
   = or loop ;

: Check-comment { str-adr len -- }
  str-adr len s" Comment:"   caps-search -rot 2drop
  if true to inComment
  else str-adr len s" comment;" caps-search -rot 2drop
   if false to inComment then then ;

: display-1-top  { \ ll$ -- }
  0 to inComment
  search-aborted? ?EXIT
  MAXSTRING LocalAlloc: ll$
  cr 10 spaces name-buf count type    \ file name
  cr ." ================================"
  #lines 0
  do ll$ MAXCOUNTED search-hndl read-line
     0= and over 0<> and
     if cr ll$ over check-comment
      ll$ C@ ASCII \ ASCII ( ASCII /  3 ANY? inComment or
      IF ll$ swap type ELSE drop leave THEN  \ show line
     else DROP
     then
  loop ;

: cat ( -- )
        cr cr
        cr ." XXXXXXXXXXXXXXXXXXXXXXXXXX"
        cr ." =========================="
        cr ." CATALOG of" current-dir$ count type
        cr ." =========================="
        cr ." XXXXXXXXXXXXXXXXXXXXXXXXXX"
        cr
        False to sub-dirs?     false to search-aborted?
        s" *.f" mask-ptr place mask-ptr +NULL
        s" ." search-path place search-path +NULL
        ['] display-1-top is process-1file
        do-files-process ;
\s
: CD-Demos        chdir s" \win32forth\demos" "CHDIR CR .DIR ;
: CD-Extras       chdir .( \win32forth\extras) ;
: CD-Ext-sources  chdir .( \win32forth\Ext-Sources) ;
: CD-htm          chdir .( \win32forth\demos) ;
: CD-Projs        chdir .( \win32forth\proj) ;
: CD-Res          chdir .( \win32forth\res) ;
: CD-src          chdir .( \Win32Forth\src) ;

 
