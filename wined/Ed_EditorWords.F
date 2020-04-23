\ $Id: Ed_EditorWords.F,v 1.5 2011/11/22 18:47:32 brookline Exp $
\

defer ?wrap-word
defer back-delete-character
defer save-text
defer save-bitmap-as
defer close-text
defer ?save-text
defer "+open-text
defer before-bye
defer open-previous

: ?line-tbl-ok  ( -- )
                line-tbl ?EXIT
                TRUE s" Line-TBL not initialized" ?terminatebox ;

: end.addr      ( -- a1 )
                ?line-tbl-ok
                line-tbl file-lines cells+ @ ;

: #line.addr    ( n1 -- a1 )
                ?line-tbl-ok
                line-tbl swap 0max file-lines min cells+ @ ;

: #line.bytes   ( n1 -- n2 )            \ the real line length, including CRLF
                line-tbl
                IF      line-tbl swap 0max file-lines 1- min cells+ 2@ -
                ELSE    drop 0
                THEN    ;

: #line"        ( n1 -- a1 n2 )       \ get line # n1, return address and length
        dup file-lines >=
        IF      drop                  \ discard requested line number
                end.addr 0
        ELSE    line-tbl swap 0max cells+ 2@ tuck - 0max
                lend-len
                IF      2dup + lend-len - c@ lend-char =
                        IF      lend-len - 0max
                        THEN
                THEN
        THEN    ;

\ rls January 11th, 2001 - 23:19      \ Used in Rectangular Paste
: #line+"  ( n1 offset -- a1 n2 )     \ get line # n1, return address and length
        over file-lines >=
        IF      2drop                 \ discard requested line number
                end.addr 0
        ELSE    >r line-tbl swap 0max cells+ 2@ r@ + tuck
                swap r> + swap - 0max
                lend-len
                IF      2dup + lend-len - c@ lend-char =
                        IF      lend-len - 0max
                        THEN
                THEN
        THEN    ;

: #line.len     ( n1 -- n2 )            \ the line length without CRLF
        line-tbl
        IF      #line" nip
        ELSE    drop 0
        THEN    ;

: text-length   ( -- n1 )       \ total text length in buffer
        line-tbl
        IF      file-lines #line.addr text-ptr -
        ELSE    0
        THEN    ;

: LastPage   ( -- n )           \ rls February 3rd, 2002 - 10:00
        file-lines 1- PRINTER-ROWS / 1+ ;

0 value warned?

defer warn-to-save
defer must-save
defer primitive-save-text

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 4     Colons-only code
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

40 value maxscrlines
create colontbl maxscrlines cells allot  \ to xlate scrline to fileline
0 value colons-only

: line#>indx ( l# -- indx#)
  colons-only
  if 0 screen-rows 0
     do over colontbl i cells+ @ =
        if i + leave then
     loop nip
  else line-cur - then ;

: indx>line# ( scrln# -- filel#)
  colons-only
  if  dup colontbl +cells @ dup 0=
      if swap 0> if drop file-lines then else nip then
  else line-cur + then ;

: setcolontbl ( -- )      \ table holds #filelines each screen
  \ line is from the fileline# of screen line# zero
  colons-only
  if line-cur colontbl dup maxscrlines cells erase  screen-rows 0
     ?DO over file-lines >= if leave then
      over #line" drop c@ ascii : =
       if 2dup !   \ remember scrline#s
          cell+  1
       else 0
       then >r 1 0 d+ r>
     +LOOP 2drop
  then ;

: +line-cur { nn \ dd -- }  \ change line# of top of screen
  nn dup abs / to dd  line-cur
  colons-only
  if nn abs 0
     ?do dd + dup 0< over file-lines >= or
         if dd - leave then
         dup #line" drop c@ ascii : = abs
     +loop
  else nn + file-lines screen-rows 2 / - min 0max
  then to line-cur setcolontbl ;

: +cursor-line ( n1 -- fl)  \ changeline  fl:true=>update scrn
  dup cursor-line + file-lines <
  if  dup cursor-line line#>indx dup>r +
      0 screen-rows 1- between
      if r> + 0 swap else +line-cur true r> then
      indx>line# to cursor-line
  else drop 0
  then ;

\ ---------- end colons-only -----------

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 5     Editor words
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

: #line!        { caddr clen cline \ cbuf$ cdiff -- }
      LMAXSTRING localAlloc: cbuf$
      cbuf$ LMAXSTRING blank                  \ prefill with blanks
      caddr clen  cbuf$  LPLACE               \ save string in a temp
      lend-len 2 =                            \ two char line terminator?
      IF    crlf$ count cbuf$ +LPLACE         \ then append CRLF
      ELSE  lend-len 1 =                      \ are we using a line terminator?
            IF    lend-char cbuf$ C+LPLACE    \ append single line terminator
            ELSE                              \ otherwise no line terminator,
                  BLOCKLINE-SIZE cbuf$ !      \ set length to 64
            THEN
      THEN
      cline #line.bytes cbuf$ @ - to cdiff    \ difference in lengths
      cline 1+ #line.addr                     \ source
      dup cdiff -                             \ destination
      end.addr cline 1+ #line.addr - move     \ move rest of doc
      cdiff negate to cdiff
      file-lines 2 + cline 1+
      ?DO     cdiff line-tbl i cells+ +!
      LOOP
      cbuf$ LCOUNT cline #line.addr swap move     \ move the line into buffer
      text-length 4000 + text-blen >              \ check for buffer full
      warned? 0= and                              \ and haven't warned used?
      IF    beep
            IF      beep
                    warn-to-save
                    true to warned?       \ we warned you!
            THEN
      THEN
      text-length 1000 + text-blen >
      IF      must-save
      THEN  ;

: page>line     ( page -- startline )   \ rls - page
        0max file-lines min
        cells page-tbl + @ 0x0FFFFF and ;

\ rls - page
: this-page     { line \ lopage hipage loline hiline page -- page }
        0 to lopage  num-pages to hipage  lopage to page
        BEGIN   lopage page>line to loline
                hipage page>line to hipage
                hipage lopage 1+ >
        WHILE
                hipage lopage - line loline - hiline loline - */mod
                IF      1+      THEN
                +to page
                page page>line line >=
                IF      page to lopage
                ELSE    page to hipage
                THEN
        REPEAT
        page ;

: get-cursor-line ( -- )               \ get the current line from file
        cursor-line #line" "LCLIP" cur-buf LPLACE
        \ Use MAXSTRING minus one since there is a count byte at the
        \ beginning of the buffer that isn't accounted for any other way.
        cur-buf LCOUNT LMAXSTRING CELL-
        swap /string blank ;            \ add trailing blanks

: put-cursor-line ( -- )
         cur-buf LCOUNT -trailing cursor-line #line! ;

: -trailing-blanks ( -- )
                cursor-line #line" 2dup -trailing nip - nip
                IF      get-cursor-line
                        cur-buf LCOUNT -trailing nip cur-buf !
                        put-cursor-line
                THEN    ;

: set-mirrored  { m-entry# -- } \ if n1<>-1 then mark current as mirrored
        m-entry# -1 <>
        IF      text-ptr ?dup IF release 0 to text-ptr THEN
                line-tbl ?dup IF release 0 to line-tbl THEN
                m-entry# entry-#bytes * entry-buffer +
                  entry# entry-#bytes * entry-buffer +
                entry-#bytes move       \ move master to mirror
        THEN    ;

: update-mirrors { \ open$ -- }                 \ make mirrors have same flags
        entry# entry-max > ?EXIT
        MAXSTRING LocalAlloc: open$
        cur-filename count open$ place
        entry#
        entry-max 0
        DO      i to entry#
                dup i <>                        \ not myself
                                                \ and matching filename
                cur-filename count open$ count caps-compare 0= and
                cur-filename c@ 0<> and
                IF      dup entry-#bytes * entry-buffer +
                        i   entry-#bytes * entry-buffer +
                        mirror# move            \ move master to mirror
                        file-lines cursor-line <
                        \ if other copies are beyond end of file
                        IF      file-lines 1- 0max to cursor-line
                                cursor-line Height: DocWindow
                                CharHeight: DocWindow / - 1+ to line-cur
                        THEN
                THEN
        LOOP
        to entry# ;  \ f1 = -1 if not found, else ENTRY# if found

: update-mirror-browse { \ open$ browse?? edit-changed?? -- }
\ make mirror browse flags the same
                entry# entry-max > ?EXIT
                MAXSTRING LocalAlloc: open$
                cur-filename count open$ place
                entry#
                browse? to browse??
                edit-changed? to edit-changed??
                entry-max 0
                DO      i to entry#             \ select the hyper file index
                                                \ if they match
                        dup i <>                \ not myself
                                                \ and matching filename
                        cur-filename count open$ count caps-compare 0= and
                        cur-filename c@ 0<> and
                        IF      edit-changed?? to edit-changed?
                                browse?? to browse?
                        THEN
                LOOP
                to entry# ;  \ f1 = -1 if not found, else ENTRY# if found

: "already-open# { adr len \ open$ -- n1 } \  return number of times it's open
                len 0=
                IF      0 EXIT                  \ leave if null filename
                THEN
                MAXSTRING LocalAlloc: open$
                adr len open$ place
                open$ count "path-file drop open$ place
                open$ ?defext
                0                               \ non open with this name
                entry# >r
                entry-max 0
                DO      i to entry#             \ select the hyper file index
                                                \ if they match
                        cur-filename count open$ count caps-compare 0=
                        cur-filename c@ 0<> and
                        IF      1+
                        THEN
                LOOP
                r> to entry# ;  \ f1 = -1 if not found, else ENTRY# if found

: sync-mirrors  { \ open$ -- } \ copy new pointers to mirrors
                entry# entry-max > ?EXIT
                MAXSTRING LocalAlloc: open$
                cur-filename count open$ place
                entry#
                entry-max 0
                DO      i to entry#             \ select the hyper file index
                                                \ if they match
                        dup i <>                \ not myself
                                                \ and matching filename
                        cur-filename count open$ count caps-compare 0= and
                        cur-filename c@ 0<> and
                        IF      dup entry-#bytes * entry-buffer +
                                i   entry-#bytes * entry-buffer +
                                mirror# move    \ move master to mirror
                        THEN
                LOOP
                to entry# ;

: file-has-changed ( -- )
                save-minutes 0>
                IF      NULL save-minutes 60000 * SAVE_TIMER
                        Gethandle: EditorWindow Call SetTimer drop
                THEN
                edit-changed? 0=                \ -- f1 ; not already changed?
                true to edit-changed?           \ mark as changed
                IF                              \ f1 -- ; then update mirrors
                        update-mirrors
                THEN
                EditMode: Win-EdToolbar ;

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 6     Beep
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

: beeper        ( -- )
                700 50 tone ;
' beeper is beep

: ?beep         ( f1 -- )       \ if f1=FALSE, then BEEP
                0=
                IF      beep
                THEN    ;

\ need for editwindowobj
defer totline?
defer vtop?
' false is totline?
' false is vtop?

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 7      Define the EDIT-WINDOW object
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

                     0 value textBG
                     0 value textFG
    0   0   0 rgb  new-color highBG
  255 255 255 rgb  new-color highFG
  Color: WHITE     new-color normalBG
  Color: BLACK     new-color normalFG
  109 155 241 rgb  new-color marginColor        \ overstrike margin color blue

  Color: LTGRAY    new-color linesColor
  Color: BLACK     new-color binaryColor
  109 155 241 rgb  new-color OmarginColor       \ browse margin color: blue
  128 225 128 rgb  new-color ImarginColor       \ insert margin color: green
  240 128 128 rgb  new-color BmarginColor       \ browse margin color

defer trailBG  ' normalBG is trailBG
defer selectBG ' normalBG is selectBG

: highlighting? ( -- f1 )
                hcst hlst hced hled d= 0= ;     \ if start and end are same


 : increment/    ( n1 -- n2 )            \ adjust for very large file
                file-lines 65536 >                      \ if MANY lines, then
                IF      file-lines 65536 / 1+ /         \ divide scroll lines
                THEN    ;

