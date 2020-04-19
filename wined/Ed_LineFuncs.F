\ $Id: Ed_LineFuncs.F,v 1.1 2011/03/19 23:26:04 rdack Exp $
\
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 18    Setup the line pointers and scroll bar for a new file
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

: set-line-pointers { textlen \ bincnt -- }
    wait-cursor             \ release/allocate line pointer table
    line-tbl ?dup IF release THEN
    1000 to max-lines
    max-lines 10 + cells malloc to line-tbl
    0 to file-lines         \ one total lines to start
    text-ptr line-tbl !     \ init first line
    1 to line-cur           \ bump to next line pointer
    0 to lend-len           \ mark as no line terminator initially
    0 to lend-char          \ and therefore the terminator is a null
    editAsBinary? 0=        \ if not editing as binary, then check file type
    IF  text-ptr textlen LMAXCOUNTED 1- umin 0x0D
        scan drop 1+ c@ 0x0A =                  \ CRLF or
        textlen 0= or                           \ empty file
        IF  0x0D to lend-char
            2    to lend-len
            text-ptr textlen + 2 - w@ 0x0A0D <>
            \ really 0x0D, 0x0A, cause bytes are reversed for W@
            IF  0x0A0D text-ptr textlen + w!
                2 +to textlen
            THEN
        THEN
        text-ptr textlen LMAXCOUNTED umin 0x0A
        scan 0> swap 1- c@ 0x0D <> and          \ LF only APPLE
        IF  0x0A to lend-char
            1 to lend-len
            text-ptr textlen + 1 - c@ lend-char <>
            IF   lend-char text-ptr textlen + c!
                 1 +to textlen
            THEN
        THEN
        text-ptr textlen LMAXCOUNTED 1-  umin 0x0D scan 0> swap 1+ c@
        0x0A <> and \ CR only UNIX
        IF  0x0D to lend-char
            1 to lend-len
            text-ptr textlen + 1 - c@ lend-char <>
            IF  lend-char text-ptr textlen + c!
                1 +to textlen
            THEN
        THEN
    THEN
    FALSE to editAsBinary?
    lend-len                        \ normal line terminator
    IF  text-ptr textlen
        BEGIN
            lend-char scan dup
        WHILE
            lend-len /string over line-tbl line-cur cells+ !
            \ if line longer than LMAXCOUNTED chars
            line-tbl line-cur cells+ dup @ swap
            cell- @ 2dup - LMAXCOUNTED 1- u>
            IF  tuck -                   \ convert to adr,len
                BEGIN
                    BLOCKLINE-SIZE /string dup   \ treat each 64 chars as a line
                WHILE
                    BEGIN
                        2dup swap c@ bl <> and  \ look for next blank
                    WHILE
                        1 /string         \ scan till find one
                    REPEAT
                    over c@ bl =          \ found a blank?
                    IF  1 /string         \ skip to next char
                    THEN                  \ fill in line pointer table, but only
                    dup                   \ if anything remains
                    IF      over line-tbl line-cur cells+ !
                            1 +to line-cur  \ bump current line
                            1 +to file-lines
                    THEN
                REPEAT                    \ fill in last part of very long line
                drop    line-tbl line-cur cells+ !
            ELSE
                2drop
            THEN
            1 +to line-cur                \ bump current line
            1 +to file-lines
            line-cur max-lines u>         \ while not full
            IF      4000 +to max-lines
                    max-lines 10 + cells line-tbl realloc
                    s" Failed to adjust the line pointer table"
                    ?TerminateBox
                    to line-tbl
            THEN
        REPEAT  drop
    ELSE                      \ no line terminator, make 64 character lines
        text-ptr textlen
        BEGIN
            dup
        WHILE
            BLOCKLINE-SIZE /string over line-tbl line-cur cells+ !
            1 +to line-cur                  \ bump current line
            1 +to file-lines
            max-lines line-cur u<           \ if it's full
            IF  4000 +to max-lines          \ then extend table
                max-lines 10 + cells line-tbl realloc
                s" Failed to adjust the line pointer table"
                ?TerminateBox
                to line-tbl
            THEN
        REPEAT  drop
    THEN
    line-cur   1 max to line-cur
    file-lines 1 max to file-lines
    dup line-tbl line-cur     cells+ !
    dup line-tbl line-cur 1+  cells+ !
        line-tbl line-cur 2 + cells+ !
    0 to line-cur ;

: set-longest-line ( -- )
        wait-cursor
        0 file-lines 0
        ?DO     i #line" nip max
        LOOP    1+ to max-cols ;

: refresh-line  ( -- )
                cursor-line 1-line-flag: DocWindow
                                Refresh: DocWindow ;

: refresh-screen ( -- )
                RefreshAll: DocWindow
                ReTitle: EditorWindow ;

: no-highlight  ( -- )
                normalBG to textBG
                highlight-cursor
                refresh-screen ;

: highlight-all ( -- )
                0 to hlst 0 to mlst
                0 to hcst 0 to mcst
                file-lines dup to hled #line" nip to hced
                refresh-screen ;

\ begin/end hilighting

\ Concept provided   by: Brad Eckert
\ Some modifications by: Tom Zimmer
\ Other modifications by rls January 4th, 2001 - 20:57

0 value rowmark
0 value colmark

: highlight-mark ( -- )         \ Ctrl+Q Select Toggle
\ endpoint is cursor, startpoint is last marker
        RectHigh
        IF      cursor-col  colmark <
                IF      cursor-col  to hcst
                        colmark to hced
                ELSE    colmark to hcst
                        cursor-col  to hced
                THEN
                cursor-line rowmark <
                IF      cursor-line to hlst
                        rowmark to hled
                ELSE    rowmark to hlst
                        cursor-line to hled
                THEN
                cursor-col  to colmark
                cursor-line to rowmark
        ELSE
                cursor-line rowmark =
                cursor-col  colmark < and
                cursor-line rowmark < or
                IF      rowmark to hled
                        colmark to hced
                        cursor-col  to hcst cursor-col  to colmark
                        cursor-line to hlst cursor-line to rowmark
                ELSE    rowmark to hlst
                        colmark to hcst
                        cursor-col  to hced cursor-col  to colmark
                        cursor-line to hled cursor-line to rowmark
                THEN
        THEN
        refresh-screen ;


\ While looking at the source I found this:
\ I think this was written to be used in the Control key bindings
\ to handle the ESC-Key. So I put it in.
\ May 4th, 2003 - 11:49 dbu
: _do-esc ( -- ) \ handle the ESC-Key
        no-highlight ;

defer do-esc ' _do-esc is do-esc

: cursor-on-screen ( -- )
      cursor-line line-cur <
      IF    cursor-line find-top-margin - VPosition: DocWindow
      ELSE  DocWindow EditWindow =
            IF    cursor-line line#>indx screen-rows 3 - =
                  IF      cursor-line screen-rows 8 - - VPosition: DocWindow
                  THEN
                  cursor-line line#>indx screen-rows 4 - >
                  IF      cursor-line 2 - VPosition: DocWindow
                  THEN
            ELSE  cursor-line line#>indx screen-rows 1 - >=
                  IF      cursor-line screen-rows 2 - - VPosition: DocWindow
                  THEN
            THEN
      THEN ;

: browse-toggle ( -- )
       >E
       bitImage? ?EXIT
       ( browse? 0= ) FALSE  to browse?
       update-mirror-browse
       refresh-screen
       Refresh: EditorWindow
        ;

: +row-cursor   ( n1 -- )
        highlighting?
        IF      no-highlight
        ELSE    cursor-line 1-line-flag: DocWindow
        THEN
        -trailing-blanks
        +cursor-line
        highlight-cursor
        if refresh-screen else refresh-line then
        ReTitle: EditorWindow  ;

: >col-cursor   ( n1 -- )
        highlighting?
        IF      no-highlight
        THEN
        col-cur >r
        dup 0<                                  \ before start of line
        cursor-line 0> and                      \ and not on line zero
        IF
                -1 +row-cursor
                1+                              \ one less chars
                cursor-line #line" nip +        \ move to end of line
        THEN    0max to cursor-col
        cursor-col max-cols max "LCLIP" to max-cols \ adj right margin
        cursor-col col-cur - screen-cols 4 - >
        IF      cursor-col screen-cols 4 - -
                HPosition: DocWindow
        ELSE    cursor-col col-cur <
                IF      cursor-col
                        HPosition: DocWindow
                THEN
        THEN
        highlight-cursor
        refresh-line
        r> col-cur <>
        IF      refresh-screen
        THEN   ;

: lf-left ( -- )  \ Goes down one line
  cursor-line file-lines <
  if 1 +to cursor-line
  then 0 to cursor-col refresh-screen ;

