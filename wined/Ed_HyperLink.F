\ $Id: Ed_HyperLink.F,v 1.4 2013/08/12 05:14:04 rdack Exp $
\
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 34    Hyper Text linkage words
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

needs   HyperLink.f


: hyper-delete  ( -- )
        cur-filename count "already-open# 2 <   \ if open less than twice
        IF      text-ptr ?dup IF release 0 to text-ptr THEN
                line-tbl ?dup IF release 0 to line-tbl THEN
                bitImage?
                IF      imageDC GetHandle: [ ] Call DeleteDC ?win-error
                        FALSE to bitImage?
                        vga-bitmap call DeleteObject drop
                        0 to vga-bitmap
                        imageDC Dispose         \ destroy object
                        0 to imageDC            \ reset pointer
                THEN

        THEN
        entry-buffer                            \ buffer start
        entry-#bytes entry-max *                \ total buffer bytes
        entry-#bytes entry#    *                \ current hyper offset
        /string                                 \ remove leading bytes
        >r dup entry-#bytes + swap r> move      \ remove one file cell
        entry-buffer
        entry-#bytes entry-max * +              \ end of hyper buffer
        entry-#bytes erase ;                    \ clear last entry

: hyper-insert  ( -- )
        entry-buffer                            \ buffer start
        entry-#bytes entry-max *                \ total buffer bytes
        entry-#bytes entry#    *                \ current hyper offset
        /string                                 \ remove leading bytes
        over >r                                 \ save for later erase
                                                \ insert one file cell
        >r dup entry-#bytes + r> entry-#bytes - move
        r> entry-#bytes erase ;                 \ clear the inserted entry

: +hyper        ( n1 -- )       \ next hyper
        DocWindow EditWindow =
        IF      GetStack: EditWindow + 0max entry-max 1- min
                dup to entry# SetStack: EditWindow
        ELSE    drop    \ May 5th, 1998 tjz added from Bruno Gauthier
        THEN    ;

: hyper-open    ( -- )
                cur-filename c@ 0=              \ leave if no name specified
                IF      beep
                        EXIT
                THEN
                refresh-screen
                ReTitle: EditorWindow
                Refresh: EditorWindow
                Refresh: FilesList ;

: "hyper-find   ( a1 n1 -- n2 ) \ look for filename a1,n1 in the file list,
                                \ return n2 the index of the desired file,
                                \ or -1 not found
                -1 -rot         \ default n2 if not found is -1
                entry# >r
                entry-max 0
                DO      i to entry#     \ select the hyper file index
                        2dup cur-filename count compare 0=
                        IF      rot drop i -rot
                                LEAVE
                        THEN
                lOop    2drop
                r> to entry# ;          \ restore entry#

: "already-open? { adr len \ open$ -- f1 } \ if already open, return ENTRY#
                                           \ if not     open, return -1
                MAXSTRING LocalAlloc: open$
                adr len open$ place
                open$ count "path-file drop open$ place
                open$ ?defext
                -1                              \ -1 marks not found
                entry# >r
                entry-max 0
                DO      i to entry#             \ select the hyper file index
                                                \ if they match
                        cur-filename count open$ count caps-compare 0=
                        cur-filename c@ 0<> and
                        IF      drop            \ discard the -1
                                i               \ return the ENTRY#
                                LEAVE
                        THEN
                LOOP
                r> to entry# ;  \ f1 = -1 if not found, else ENTRY# if found

: "already-open-switch? { adr len \ open$ -- f1 } \ if already open, switch, TRUE
        MAXSTRING LocalAlloc: open$
        adr len open$ place
        open$ count "path-file drop open$ place
        open$ ?defext
        FALSE entry#
        entry-max 0
        DO      i to entry#             \ select the hyper file index
                                        \ if they match
                cur-filename count open$ count caps-compare 0=
                cur-filename c@ 0<> and
                IF      2drop
                        i SetStack: DocWindow
                        hyper-open
                        TRUE entry#     \ return this entry#
                        LEAVE
                THEN
        LOOP    to entry# ; \ f1=true if found and the file was selected

: (hyper-insert)  ( -- ) \ insert-hyper if current file isn't unnamed
                cur-file-unnamed? 0=
                IF 1 +hyper hyper-insert THEN ;

: (hyper-open)  ( adr len -- )
                2dup hyper-string place
                2dup prev-hyper-string place
                2dup "already-open? >r
                     "open-text
                r> set-mirrored ; \ mark as mirrored if already open

: (hyper-display-line)  ( #line -- )
                file-lines 1- min 1- 0max to cursor-line
                0 to cursor-col
                cursor-line find-top-margin - VPosition: DocWindow
                no-highlight
                RefreshCursor: DocWindow ;

\ Search for a word, open the file if found and show the line
: _"hyper-link  { adr len adr2 len2 InVoc? -- }
                \ adr  len  => the Word
                \ adr2 len2 => the Index-File
                >E
                ?save-new ?EXIT

                cur-filename count hyper-string place

                adr len bl skip -trailing 10 -TRAILCHARS 13 -TRAILCHARS
                254 min 0max hyper-buf place

                \ try to find the word
                InVoc?
                if   hyper-buf count adr2 len2 "hyper
                else hyper-buf count upper \ for uniqueness
                     hyper-buf count adr2 len2 "hyper-index
                then

                IF   \ we found the word in the index-file
                     (hyper-insert)
                     (hyper-open)         \ open the file
                     (hyper-display-line) \ and jump to the line
                ELSE \ can't open index file
                     beep
                THEN ;

: "hyper-link   ( a1 n1 -- )
 ( rbs )        s" HYPER.NDX" Prepend<home>\ true _"hyper-link ;

: "help-link    ( a1 n1 -- )
 ( rbs )        s" HELP.NDX" Prepend<home>\ false _"hyper-link ;

: next-hyper-link ( -- )
                hyper-buf count "hyper-link ;

NewEditDialog  HyperTextDlg "Hyper Link to a Word" "Hyper Link to:" "Link" "" ""

: word-link     ( -- )           \ let user type in a word to link to
                hyper-buf count -trailing nip hyper-buf c!  \ no trailing bl's
                hyper-buf EditorWindow start: HyperTextDlg
                IF      0 to hyper-start
                        next-hyper-link
                THEN    SetFocus: DocWindow ;

: hyper-link    ( -- )           \ link to the currently highlighted word
                browse?
                bitImage? ?EXIT
                highlighting? 0=                \ something is highlighted
                IF      highlight-word
                THEN
                highlighting?
                hlst hled = and                 \ but only on one line
                IF      0 to hyper-start
                        highlight" "-blanks" "hyper-link
                ELSE    word-link               \ if nothing highlightable
                THEN
                to browse? ;     \ Sticky browse mode JAP RDA

: w32f-doc      ( -- )
                0 0 ExecHelp drop ;

: word-help     ( -- )
                bitImage? ?EXIT  \ it is bound to Ctrl-F2
                highlighting? 0=                 \ something is highlighted
                if highlight-word then
                highlighting?
                hlst hled = and                  \ but only on one line
                if   0 0 ExecHelp drop           \ launch help or put it in front
                     highlight" "-blanks"
                     msgpad place                \ try to show word from help
                     msgpad dup c@ 1+ WM_WORDHELP w32fHelp Sendw32fMsg
                     drop \ cannot use GetViewFile like in IDE
                else beep
                then ;

needs hyper.f

: hyper-edit    ( -- )
                >E
                s" WINED.CFG" Prepend<home>\ "+open-text ;

: hyper-compile ( -- )
                build-index ;

: prev-link     ( -- )  \ link back and close the current file
                >E
                ?save-new ?EXIT
                GetStack: EditWindow 0=
                IF      beep
                ELSE    close-text update-mirrors
                        \ -1 +hyper
                        cur-filename c@
                        IF      hyper-open
                        ELSE    beep
                                1 +hyper
                        THEN
                THEN    ;

: prev-view     ( -- )   \ same as prev-link except does not close the file
                >E
                ?save-new ?EXIT
                GetStack: EditWindow 0=
                IF      beep
                ELSE    update-mirrors
                        -1 +hyper
                        cur-filename c@
                        IF      hyper-open
                        ELSE    beep
                                1 +hyper
                        THEN
                THEN    ;

: next-link     ( -- )
                >E
                ?save-new ?EXIT
                update-mirrors
                1 +hyper                \ next hyper file
                cur-filename c@         \ but only if it has a name in it
                IF      hyper-open
                ELSE    beep
                        -1 +hyper
                THEN    ;

: make-new-text ( -- )
                >E
                ?save-new ?EXIT
                cur-filename count hyper-string place
                unnamed-file count "+open-text
                TRUE to browse? ;
                \ browse-toggle ;

: new-text      ( -- )  \ Make a new unnamed file
                >E
                make-new-text ;

: _close-text   ( -- )
                >E
                ?save-text ?EXIT
                hyper-delete
                -1 +hyper
                cur-filename c@ 0=              \ if there's no file to open
                IF      hyper-delete            \ then delete it too
                        cur-filename c@         \ and try again
                        IF      hyper-open      \ open a file if it's there
                        ELSE                    \ else just open a new file
                                unnamed-file count "open-text
                                TRUE to browse?
                                browse-toggle
                        THEN
                ELSE    hyper-open              \ else open preceeding
                THEN
                refresh-screen
                Update: FilesList
                ReTitle: EditorWindow ;

' _close-text is close-text

: _"+open-text  { adr len -- }
                len 0= ?EXIT                    \ EXIT if NULL length file
                                                \ switch if already open & EXIT
                ?save-new ?EXIT                 \ EXIT if changed and canceled
                cur-filename count hyper-string place
                cur-file-unnamed? 0=              \ if not unnamed
                cur-filename c@ 0> and            \ and if already opened a file
                \ IF      1 +hyper                  \ bump to next file entry
                IF  last-entry# Getstack: editwindow - +hyper
                        hyper-insert              \ make room for a file
                THEN
                adr len "already-open? >r
                adr len "open-text
                r> set-mirrored ;                 \ mark as mirrored
                                                  \ if already open

' _"+open-text is "+open-text

1 value FilterIndex

: open-text     { \ open$ -- }
      max-path LocalAlloc: open$
      >E
      ?save-new ?EXIT
      FilterIndex
      GetHandle: EditorWindow Start2: ViewText dup c@ \ -- a1 n1
      IF    count open$ place
            open$ count '.' scan nip 0=           \ if file contains no '.'
            IF      open$ count r/o open-file 0=  \ then try to open it
                    IF      close-file drop       \ if it opened, then close it
                            '.' open$ c+place     \ and append a decimal point
                    ELSE    drop               \ else let others append file ext
                    THEN
            THEN
            open$ count "+open-text
            \ removed "2dup upper" to allow filnames not only in uppercase - May 18th, 2003 dbu
            open$ count ( 2dup upper ) "path-only" SetDir: ViewText
      ELSE  drop
            cur-filename count 2dup '.' scan nip - nip 0=
            IF      new-text
            THEN
      THEN
      SetFocus: EditWindow
      RefreshAll: EditWindow
      get-filter-index to FilterIndex
      ;


: open-text-highlighted { \ highlight$ Oldpath$ -- }
        bitImage? ?EXIT
        MAXSTRING LocalAlloc: highlight$
        MAXSTRING LocalAlloc: Oldpath$
        search-path count  Oldpath$ place  \ Save the current path
        program-path-init               \ Get the Forth path
        highlighting? 0=                \ something is highlighted
        IF      highlight-word
        THEN
        highlighting?                   \ something is highlighted
        hlst hled = and                 \ but only on one line
        IF                              \ get the screen text

                highlight"  highlight$ place
                >E
                ?save-new ?EXIT
                cur-filename count hyper-string place
                highlight$ count "-blanks" "+open-text
        ELSE    open-text
        THEN
        Oldpath$ count search-path place   \ Restore the old path
        ;

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 35    Command line parsing
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

create commandline-string
        z," Win-Ed [</option> </option>...] [[<filename> <line> <col>]...]\n\n"
        +z,"     /B                             Startup in Browse mode\n"
        +z,"     /INDEX <filename>  Build hypertext index with 'filename.CFG'\n"
        +z,"     /Rnn                         Right margin = 'nn'\n"
        +z,"     /Xext                        Default file extension = 'ext'"

: show-command-help     ( -- )
        commandline-string
        >r
        MB_OK MB_TASKMODAL or
        z" Win-Ed DOS Commandline Help"
        r> NULL call MessageBox drop ;

named-new$ file-to-edit$

: command-options ( -- )  \ command line parsing
        command-args off
        BEGIN   /parse-word
                dup  1+ c@ '/' =               \ either '/'
                over 1+ c@ '-' = or            \ or     '-'
                over 1+ c@ '?' = or            \ or     '?'
        WHILE   count 1 /string                \ remove leading char
                over dup c@ '?' =              \ help ONLY
                swap 1- c@ '?' = or
                IF      show-command-help
                        bye
                THEN
                2dup upper
                2dup s" INDEX" compare 0=      \ re-build hyper index
                IF     /parse-word count       \ pick up next word
                       2dup '.' scan nip -     \ remove trailing file extension
                       dup                     \ if name specified use it
    ( rbs )            IF      2dup     &WINED.CFG  place
    ( rbs )                    s" .CFG" &WINED.CFG +place
    ( rbs )                             &WINED.NDX  place
    ( rbs )                    s" .NDX" &WINED.NDX +place
                       THEN
                        hyper-compile
                       BYE
                THEN

                \ just a dummy command to ignore the /IMAGE directive to the wrapper
                2dup s" IMAGE" compare 0=               \ in case started with
                                                        \ /IMAGE imagename
                IF     dup /string                      \ discard remainder
                       /parse-word drop
                THEN

                \ These should be last because they only look at the
                \ first character to decide if they match or not.
                2dup 1 min s" B" compare 0=
                IF      ( TRUE) FALSE to start-browse?           \ browse mode switch
                        dup /string                     \ discard remainder
                THEN

                2dup 1 min s" F" compare 0=
                IF      ( TRUE) FALSE to start-browse?
                        dup /string
                        0 word count command-args place \ remainder of line
                        command-args c@ 0=
                        IF      s"  " command-args place
                        THEN
                THEN

                2dup 1 min s" X" compare 0=
                IF
                \ added new clipping to DEFEXT$, for new max length of 16 chars
                        2dup 1 /string DEFEXTMAX min
                        defext$ place                   \ default file extension
                        dup /string                     \ discard remainder
                THEN

                2dup 1 min s" R" compare 0=             \ right margin
                IF      2dup 1 /string number? 2drop
                        dup 0<>
                        IF      low-right-edge max "LCLIP"
                        THEN
                        to right-edge
                        dup /string                     \ discard remainder
                THEN

                \ if command was not recognized, just display the help dialog
                nip
                IF      show-command-help
                        bye
                THEN
        REPEAT

\ GetLongPathName() isn't supported under Win95, NT 3.51 and NT4,
\ so we can only use it under Win98, WinME and Win2000 and later.
\ This bug was reported on Wed, 02 Jun 2004 by Bruce Rennie
[ winver win95 = winver winnt351 = or winver winnt4 = or ]
[IF]
        count file-to-edit$ place
        file-to-edit$ +NULL
[else]
        \ make sure that we have the long filename and not
        \ the short one - June 7th, 2003 - 11:34 dbu
        count if        >r MAXSTRING pad r>
                        Call GetLongPathName 0=
                        if pad off then  \ avoid bogus file name rda
                        pad zcount file-to-edit$ place
              else      count file-to-edit$ place
              then      file-to-edit$ +NULL
[then]  ;

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 36    Open-initial-file
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

: open-initial-file ( -- ) \ open the first file on startup
        EditWindow to DocWindow
        GetStack: EditWindow to entry#

        file-to-edit$ count 0= swap c@ 0= or \ if no file specified
        IF      open-previous? 0=            \ open the previous file?
        	IF      make-new-text        \ no, create a new file
        	ELSE    open-previous        \ yes, open previous file
        	THEN
        ELSE    file-to-edit$ count 0= swap c@ 0= or 0= \ is there a file to open
          IF     file-to-edit$ count
             bl skip over c@ '"' = IF 1 /string THEN
             2dup '"' scan nip - "open-text
             start-browse?
             IF  FALSE to browse?
                 browse-toggle
             THEN

             BEGIN bl word count ?dup
             WHILE number? nip
                 IF 1- 0max to cursor-line
                    bl word count number? nip
                    IF      1- 0max to cursor-col
                    ELSE    drop
                         pocket count "+open-text
                    THEN
                 ELSE    drop
                       pocket count "+open-text
                 THEN
                 start-browse?
                 IF      FALSE to browse?
                         browse-toggle
                 THEN
              REPEAT  drop
        ELSE                            \ no file to open
            open-previous? 0=       \ open the previous file?
            IF      new-text
            ELSE    open-previous   \ yes, open previous file
            THEN
            start-browse?
            IF      FALSE to browse?
                browse-toggle
            THEN
        THEN
      THEN ;

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 37    Split, Undelete, wrap
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

: split-line    {  \ cbuf$ -- }                         \ split line at cursor
        200 localAlloc: cbuf$
        delete-highlight
        get-cursor-line
        cur-buf lcount cbuf$ lplace
        1 +to cursor-line                         \ move down to new line
        1 insert-lines                            \ insert a new blank line
        cbuf$ lcount 1+ cursor-col - dup 0>       \ cursor not past end of line
        if 1- >r cursor-col +                     \ #chars to move down
         cur-buf cell + r@ cmove
         r> cur-buf !                             \ length of new line
         put-cursor-line                          \ save the new line
         -1 +to cursor-line                       \ back
         cbuf$ cell + cur-buf cell + cursor-col cmove    \ put back chars to cursor
         cursor-col cur-buf !                     \ set length orig
         put-cursor-line                          \ save orig to cursor
         overstrike @  0=                         \ insert -> move cursor down-left
         if  1 +to cursor-line
            0 to cursor-col
         then
        then
        file-has-changed
        refresh-screen ;

: xsplit-line    {  \ cbuf$ -- }                  \ split line at cursor
        200 localAlloc: cbuf$                     \ put chars starting below cursor
        delete-highlight                          \ leave cursor where it was
        get-cursor-line
        cur-buf lcount cbuf$ lplace
        1 +to cursor-line                         \ move down to new line
        1 insert-lines                            \ insert a new blank line
        cbuf$ lcount 1+ cursor-col - dup 0>       \ cursor not past end of line
        if cur-buf cell + cursor-col blank
         put-cursor-line                          \ save the new line
         -1 +to cursor-line                       \ back
         cbuf$ cell + cur-buf cell + cursor-col cmove    \ put back chars to cursor
         cursor-col cur-buf !                     \ set length orig
         put-cursor-line                          \ save orig to cursor
        then
        file-has-changed
        refresh-screen ;


\ rls January 16th, 2001 - 17:36
: word-undelete ( -- )
        bitImage? ?EXIT
        browse? ?EXIT
        no-highlight
        del-buf" dup
        IF      BEGIN   2dup 1 =                \ one character long string
                        swap c@ 255 = and 0=    \ the stop undelete char
                        over 0> and             \ and have more than zero chars
                WHILE   over c@ 0x0D =
                        IF      2drop
                                split-line
                                0 >col-cursor
                                character-left
                        ELSE
                                over c@ 0x08 =
                                IF      2drop
                                        character-right
                                ELSE    cursor-col >r
                                        insert-string
                                        r> to cursor-col
                                THEN
                        THEN
                        del-buf"        \ get the next string
                REPEAT  2drop
        ELSE    2drop beep
        THEN
        refresh-line ;

: _?wrap-word   { \ original-col wrap-col -- }
    right-edge 0>                            \ right-edge=0 for no word wrap
    cursor-line #line.len right-edge >= AND
    IF   all-lines: DocWindow
         cursor-col to original-col          \ save original cursor position
         right-edge to cursor-col
         get-cursor-line
         cur-buf CELL+ cursor-col + 1- c@
         bl <>                               \ char before cursor not a blank?
         IF      word-left
         THEN
         cursor-col to wrap-col              \ save wrap position
         cur-buf CELL+ cursor-col + c@ bl =  \ char at cursor is a blank
                                             \ and some text remains on line
         cur-buf LCOUNT cursor-col /string
         bl skip nip 0<> and
         IF      word-right                  \ then skip forward to after blanks
         THEN
         split-line
         cursor-col cursor-line #line.len <  \ if not at or beyond end of line
         IF      end-line                    \ go to end of line
         THEN
         cursor-col right-edge <             \ only if word wasn't too long
         cursor-line 1+ #line.len 0<> and    \ and following line has text in it
         IF      word-delete
                 recurse
         THEN
         original-col wrap-col <
         IF                                 \ return to previous cursor position
                 cursor-line 1- original-col
         ELSE                                \ back to middle of wrap word
                 cursor-line original-col
                 wrap-col - left-margin +
         THEN
         >row-col
    THEN    ;

' _?wrap-word is ?wrap-word

: do-cr         ( -- ) \ handle cr in insert mode
        browse?
        IF      beep
        ELSE    split-line
        THEN    ;

: 'line         ( -- addr )  \ get address of the line
        get-cursor-line cur-buf LCOUNT drop ;

: 'cursor       ( -- addr )  \ Get the address of the cursor.
        'line  cursor-col +  ;

0 value autoextend   \ extend all on cr when true

\ *p SMART-CR  ( -- ) follows the ragged left
\ ** left border of the text when in the overstrike mode. Dec 22nd, 2002 jap
: smart-cr      ( -- )   \ handle cr
   bitImage? ?EXIT
   browse? if cursor-line 1+ to cursor-line 0 to cursor-col exit then
   autoextend if settle grand-total then
   overstrike @
   if cursor-line 1+ to cursor-line cursor-col 15 >
      if  1 insert-lines
        0 to cursor-col 'line c@ bl = cur-buf w@ and
        if word-right 'cursor c@ ascii $ =
          if 16 to cursor-col then
        else cur-buf w@ 0= if 16 to cursor-col then then
      else 0 to cursor-col then refresh-screen
   else split-line then  ;

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 40    Do-goto-line
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

: do-goto-line  ( -- )
                goto-line ;

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 41    Change case of highlighted text
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

0 value upper-case?

: "upper/lower  ( a1 n1 -- )
        upper-case? IF upper ELSE lower THEN ;

2variable prevhst
2variable prevhed

: highlight-case-toggle ( -- )
        bitImage? ?EXIT
        browse? ?EXIT

        highlighting? 0=           \ if nothing is highlighted
        IF highlight-word THEN     \ then try to highlight something

        hlst hcst prevhst 2@ d=
        hled hced prevhed 2@ d= and 0= \ if NOT the same highlight as last time
        IF   TRUE to upper-case?    \ then goto uppercase
             hlst hcst prevhst 2!
             hled hced prevhed 2!
        ELSE upper-case? 0= to upper-case? \ if the same, toggle case
        THEN

        hled 1+ hlst
        ?DO     i hlst =                \ first line
                IF      i hled =        \ and last line
                        IF      i #line"  hced min hcst /string "upper/lower
                       ELSE            \ to end of line
                                i #line" hcst /string "upper/lower
                        THEN
                ELSE    i hled =        \ last line
                        IF      i #line" hced min "upper/lower
                        ELSE            \ middle lines
                                i #line" "upper/lower
                        THEN
                THEN
        LOOP
        refresh-screen
        file-has-changed ;

