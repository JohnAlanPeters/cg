\ $Id: Ed_KeyCMD.F,v 1.3 2011/05/03 17:58:47 rdack Exp $
\
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 20    Scrolling, ins/del lines & characters   
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

: +row-scroll   ( n1 -- )
                +cursor-line
                IF refresh-screen THEN ;

: +col-cursor   ( n1 -- )
                cursor-col +
                lend-len 0=
                IF      63 min
                THEN    >col-cursor
                cursor-on-screen
                ReTitle: EditorWindow ;

: _>row-col     ( row col -- )
                lend-len 0=
                IF      63 min
                THEN
                to cursor-col
                to cursor-line
                cursor-on-screen ;

: >row-col      ( row col -- )  \ move display to row and column
                _>row-col
                no-highlight
                refresh-screen ;

: +page-cursor  ( 1/-1 -- )
                all-lines: DocWindow
                -trailing-blanks
                screen-rows *
                +cursor-line
                if cursor-line file-lines screen-rows - min to cursor-line
                highlight-cursor
                IF line-cur VPosition: DocWindow
                refresh-screen THEN then ;

: cell-fill     { addr len value -- }
                addr len cells bounds
                ?DO     value i !       \ fill each cell with value
          cell +LOOP    ;

: insert-lines  { #lines -- }           \ insert a number of blank lines
                line-tbl cursor-line          cells+
                line-tbl cursor-line #lines + cells+
                file-lines cursor-line -  3 + cells move
                #lines +to file-lines
                line-tbl cursor-line          cells+    \ addr of new lines
                #lines                                  \ length in cells
                over @                                  \ address to fill with
                cell-fill                               \ fill the cells
                cursor-line #lines bounds
                ?DO     cur-buf 0 i #line!              \ CRLF in each line
                LOOP
                ;

               8192 constant del-max
del-max MAXSTRING + Pointer  del-buf
                  0 value    del-len

: del-buf"      ( -- a1 n1 )
                del-buf del-len 1- 0max
                BEGIN   2dup 0 scan dup
                WHILE   2nip
                        1 /string
                REPEAT  2drop
                dup 1+ negate del-len + 0max to del-len ;

: del-ov-check  ( -- )
                BEGIN   del-len del-max >       \ if the buffer is full
                WHILE                           \ then discard an old word
                        del-buf del-len 0 scan dup
                        IF      1 /string dup to del-len \ strip leading word
                                del-buf swap move        \ move remainder up
                        ELSE    0 to del-len
                                2drop
                        THEN
                REPEAT  ;

: "del-buf      ( a1 n1 -- )
                "LCLIP" >r del-buf del-len + dup r@ + off r@ move
                r> 1+ +to del-len 
                del-ov-check ;

: c+del-buf     ( c1 -- )
                del-buf del-len + dup off c!
                2 +to del-len
                del-ov-check ;

: stop-delete   ( -- )
                MAXCOUNTED c+del-buf ;

: delete-lines  { #lines \ cdiff -- }    \ delete n1 entire lines
                                                        \ clip to legal value
                #lines file-lines 1- cursor-line - 0max min to #lines
                #lines 1 < ?EXIT                        \ exit if none to del
                cursor-line file-lines 1- >= ?EXIT      \ leave if last line
                                                        \ or greater
                0 to cdiff                              \ init diff to none
                cursor-line #lines bounds
                DO      i #line" "del-buf
                        0x0D c+del-buf
                        i #line.bytes negate +to cdiff   \ accum total length
                LOOP
                cursor-line #lines + #line.addr         \ source
                cursor-line          #line.addr         \ destination
                end.addr
                cursor-line #lines + #line.addr - move  \ move rest of doc
                file-lines 2 + cursor-line #lines +
                ?DO     cdiff line-tbl i cells+ +!      \ adj line pointers
                LOOP
                line-tbl cursor-line #lines + cells+    \ then delete lines
                line-tbl cursor-line          cells+
                file-lines 2 + cursor-line #lines + - cells move
                file-lines #lines - 0max to file-lines  \ shorten by one line
                ( refresh-screen ) ;

: delete-characters { #chars -- }       \ delete a number of characters
                #chars 0max to #chars           \ at least zero characters
                #chars 0= ?EXIT
                get-cursor-line
                cur-buf @ cursor-col <=         \ deleting past end of line?
                cursor-line file-lines 1- <> and \ and not last file line?
                IF                              \ if so, then append next line
                        all-lines: DocWindow    \ update all lines in file
                        cursor-col cur-buf !    \ adjust line len to cursor
                                                \ append next line
                        cursor-line 1+ #line"   \ get next line
                        cur-buf +LPLACE         \ append to this line
                        1 delete-lines          \ delete current line
                        0x0D c+del-buf
                ELSE                            \ if not, then just del chars
                        cur-buf LCOUNT cursor-col /string
                        2dup #chars min "del-buf
                        >r
                        dup #chars + swap r> move
                        cursor-col cur-buf @ #chars + <
                        IF      cur-buf @ #chars - 0max cur-buf !
                        THEN
                THEN    put-cursor-line
                refresh-line ;

: _delete-character ( -- )
                get-cursor-line
                cur-buf LCOUNT cursor-col /string >r
                dup 1+ swap r> move
                cursor-col cur-buf @ 1+ <
                IF      cur-buf @ 1- 0max cur-buf !
                THEN    put-cursor-line ;

\ rls January 13th, 2001 - 4:37
: #line2"       ( n -- adr1 len1 len2 )
        dup>r #line" r> #line.bytes ;
        
: /split { str len part -- remainder len1 prefix len2 }
        str len part /string            \ adr len of remainder of string
        str len part min 0max ;         \ adr len of prefix of string

\ rls January 13th, 2001 - 4:37
: Delete-Rect   { \ rectx recty dadr0 dadr sadr slen1 slen2 lend jadr -- }
        hced hcst - to rectx
        hled hlst - 1+ to recty
        hled 1+ #line.addr to jadr
        hlst #line.addr to dadr
        recty 0
        DO      dadr to dadr0
                I hlst + #line2" to slen2 to slen1 to sadr
                slen2 slen1 - to lend
                slen1 hcst <=
                IF      sadr dadr slen2 move
                        slen2 +to dadr
                ELSE    sadr slen1 hcst /split
                        dadr swap move
                        hcst +to dadr
                        rectx /string dup
                        IF      >r dadr r@ lend + move
                                r> lend + +to dadr
                        ELSE    dadr0 dadr over - -trailing + to dadr
                                sadr slen1 + dadr lend move
                                lend +to dadr
                        THEN
                THEN
        LOOP
        line-cur >r
        jadr dadr end.addr jadr - move
        text-length jadr dadr - - set-line-pointers
        set-longest-line
        r> to line-cur ;

\ rls January 13th, 2001 - 4:37
: delete-highlight ( -- )
  highlighting? 0= ?EXIT
  hcst to cursor-col
  hlst to cursor-line
  cursor-on-screen
  hled file-lines 1- >
  IF      hled 1- 0max to hled            \ set to end of file
          hled #line" nip to hced         \ and not beyond end
  THEN
  stop-delete
  hlst hled =
  IF      hced hcst - 0max delete-characters
  ELSE    all-lines: DocWindow
    RectHigh
    IF      Delete-Rect
    ELSE    cursor-col
            IF  cursor-line #line" hcst /string nip ?dup
                IF      delete-characters
                        0x0D c+del-buf
                THEN
                0 to cursor-col         \ back to start of line
                cursor-line 1+ file-lines 1- min to cursor-line
                hled hlst 1+ - delete-lines
                hced delete-characters  \ beginning of last line

            ELSE    hled hlst -  delete-lines
                    hced delete-characters  \ beginning of last line
            THEN
    THEN
  THEN
  cursor-line file-lines 1- >             \ if beyond end of file
  IF      file-lines 1- 0 >row-col        \ backup to file end
  THEN
  no-highlight
  file-has-changed ;

: _insert-character ( char -- )          \ insert a char into text line
                dup  bl   >=                            \ blank or greater
                over 0xFF <= and                        \ and tilda or less
        IF
                get-cursor-line                         \ make a hole
                cur-buf LCOUNT cursor-col /string >r dup 1+ r> move
                cur-buf LCOUNT drop cursor-col + c!      \ lay in character
                                                        \ bump and clip count
                cur-buf @ cursor-col max 1+ "LCLIP" cur-buf !
                put-cursor-line
                file-has-changed
                1 +col-cursor
        ELSE    drop
                beep
        THEN    ;

: insert-character ( char -- )
                browse?
                IF      drop
                        EXIT
                THEN
                delete-highlight
                _insert-character
                ?wrap-word
                refresh-line ;

: insert-string { sadr slen -- }
                browse? ?EXIT
                slen 0= ?EXIT
                get-cursor-line
                                                        \ make a hole
                overstrike @  0=  \ rda
                if                \ rda
                cur-buf LCOUNT cursor-col /string >r dup slen + r> move
                then              \ rda
                sadr cur-buf CELL+ cursor-col + slen move  \ lay in string
                                                        \ adjust line length
                cur-buf @ cursor-col max slen + "LCLIP" cur-buf !
                put-cursor-line
                slen +col-cursor
                file-has-changed
                ?wrap-word
                refresh-line ;

: paste-date/time ( -- )
                bitImage? ?EXIT
                browse? ?EXIT
                delete-highlight
                get-local-time time-buf
                >month,day,year"        insert-string
                time&date
                3drop                   \ discard year, month and day
                s"  - "                   insert-string \ a space
                (.)   insert-string s" :" insert-string \ hour
                2 .#" insert-string                     \ minute
                drop
                refresh-line ;

: insert-spaces ( n1 -- )
                spcs-max min spcs swap insert-string ;

: delete-character ( -- )  \ shift from cursor +1 to eol, 1 left
  bitImage? ?EXIT
  browse? ?EXIT
  highlighting?
  IF  delete-highlight
  ELSE get-cursor-line
    stop-delete
      \ this is looking at the last character of the line
      cur-buf CELL+ cursor-col + 1- c@ bl <>  \ no bl before cursor?
      cursor-line #line.len cursor-col = and  \ and at line end?
      cursor-col 0> and                       \ and not in column zero
      IF      bl insert-character
              \ look at character under cursor
              cur-buf CELL+ cursor-col + c@ bl =      \ if on blank
              IF     1 delete-characters             \ then delete it
              THEN
      ELSE    1 delete-characters
      THEN
  THEN    file-has-changed ;

: _back-delete-character ( -- )
        bitImage? ?EXIT
        browse? ?EXIT
        highlighting?
        IF      delete-highlight
        ELSE    cursor-line 0>          \ if not on the first
                cursor-col  0> or       \ character of the file
                IF      stop-delete
                        cursor-col >r
                        -1 +col-cursor
                        0x08 c+del-buf
                                        \ if cursor is within the line
                        cursor-col cursor-line #line.len <
                        r> 0= or        \ or was on column zero
                        IF      get-cursor-line
                                cur-buf CELL+ cursor-col +
                                1- c@ bl <>             \ no bl before cursor?
                                cursor-line #line.len
                                cursor-col = and        \ and at line end?
                                cursor-col 0> and       \ and not in column zero
                                IF      bl insert-character
                                THEN
                                1 delete-characters
                                file-has-changed
                        THEN
                ELSE    beep
                THEN
        THEN    ;

' _back-delete-character is back-delete-character

: "-blanks"     ( a1 n1 -- a2 n2 )      \ remove leading and trailing blanks
                bl skip -trailing ;

: highlight"    ( -- a1 n1 )    \ return the highlighting for current line
                hlst hled =
                IF      hlst #line" drop hcst + hced hcst - 0max
                ELSE    hlst #line" swap hcst + swap hcst - 0max
                THEN    ;

: ?get-highlight ( -- )
                highlight" dup
                IF      2dup InsertString: findComboEdit
                        "CLIP" find-buf place
                ELSE    2drop
                THEN    ;

: home-line     ( -- )
                -trailing-blanks
                cursor-line #line" 2dup bl skip nip - nip
                dup cursor-col <
                left-margin 0> and
                IF      dup to left-margin
                        >col-cursor
                ELSE    drop
                        0 to left-margin
                        0 >col-cursor
                THEN    ReTitle: EditorWindow ;

: end-line      ( -- )
                -trailing-blanks
                cursor-col cursor-line #line.len <>     \ ?at line end
                if cursor-line #line.len       \ go to line start
                else  0
                then >col-cursor
                ReTitle: EditorWindow ;

: home-doc      ( -- )
                -trailing-blanks
                Home: DocWindow
                home-line home-line
                refresh-screen ;

: end-doc       ( -- )
                -trailing-blanks
                End: DocWindow
                end-line
                refresh-screen ;

: word-left     ( -- )
                cursor-col 0=
                IF      -1 +row-cursor
                        end-line
                        refreshAll: DocWindow
                ELSE    cursor-line #line" cursor-col 1- min tuck + swap
                        over c@ bl =
                        IF      bl -skip
                        THEN    bl -scan swap c@ bl = over or
                        IF      1+ dup cursor-col =
                                IF      1-
                                THEN
                        THEN    >col-cursor
                THEN    ReTitle: EditorWindow ;

: word-right    ( -- )
                cursor-col cursor-line #line.len >=
                IF      1 +row-cursor
                        home-line
                        refreshAll: DocWindow
                ELSE    cursor-line #line" tuck cursor-col /string
                        over c@ bl <>
                        IF      bl scan
                        THEN    bl skip nip - >col-cursor
                THEN    ReTitle: EditorWindow ;

: character-left ( -- )
                highlighting?
                IF      hlst hcst >row-col
                ELSE    -1 +col-cursor
                THEN    ;

: character-right ( -- )
                highlighting?
                IF      hled hced >row-col
                ELSE    1 +col-cursor
                THEN    ;

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ Major work on the highlighting (mostly rewritten) from
\ April 27th, 2003 to May 3st, 2003 by dbu
\
\ It should be more compatible to other editor's like Notepad now
\ but still it isn't completly.
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
: save-highlight ( -- ) \ save the state of the actual highlight
        hlst to hlst-save
        hled to hled-save
        hcst to hcst-save
        hced to hced-save
;

: restore-highlight ( -- ) \ restore the state of the highlight
        hlst-save to hlst
        hled-save to hled
        hcst-save to hcst
        hced-save to hced
;

: validate-col-cursor ( -- )
        \ if cursor is behined the last char of the actual line
        \ set it to the position of last char

        cursor-col cursor-line #line.len >
        if
                \ the highlight will be removed here !!!
                cursor-line #line.len >col-cursor
        then
;

: >hcst ( n -- ) \ set highlight column start
        cursor-line #line.len min 0max to hcst
;

: +hcst ( n -- ) \ increments highlight column start
        hcst + >hcst
;

: >hced ( n -- ) \ set highlight column end
        cursor-line #line.len min 0max to hced
;

: +hced ( n -- ) \ increments highlight column end
        hced + >hced
;

: >hlst ( n -- ) \ set highlight line start
        file-lines 1- min 0max to hlst
;

: +hlst ( n -- ) \ increments highlight line start
        hlst + >hlst
;

: >hled ( n -- ) \ set highlight line end
        file-lines 1- min 0max to hled
;

: +hled ( n -- ) \ increments highlight line end
        hled + >hled
;

: highlight-left ( -- ) \ highlight the next char to the left

                hcst hced =
                if      -1 +hcst hcst
                else    cursor-col hcst >
                        if   -1 +hced hced
                        else -1 +hcst hcst
                        then
                then

                save-highlight    \ save highlight because
                >col-cursor       \ the highlight will be removed here !
                restore-highlight \ restore highlight

        \ todo: if we reach the start of the actual line we should
        \       wrap to the previous one
;

: highlight-right ( -- )  \ highlight the next char to the right

                hcst hced =
                if      1 +hced hced
                else    cursor-col hced =
                        if   1 +hced hced
                        else 1 +hcst hcst
                        then
                then

                save-highlight    \ save highlight because
                >col-cursor       \ the highlight will be removed here !
                restore-highlight \ restore highlight

        \ todo: if we reach the end of the actual line we should
        \       wrap to the next one
;

: validate-line-highlight ( -- )

                cursor-col hcst <
                if cursor-col >hcst then

                cursor-col hced >
                if cursor-col >hced then
;

: highlight-up  ( -- )

                hlst hled =
                if      hlst -1 +hlst hlst
                else    cursor-line hlst >
                        if   hled -1 +hled hled
                        else hlst -1 +hlst hlst
                        then
                then

                save-highlight       \ save highlight because
                - negate +row-cursor \ the highlight will be removed here !
                validate-col-cursor
                restore-highlight    \ restore highlight

                validate-line-highlight

                refresh-screen ReTitle: EditorWindow ;

: highlight-down ( -- )

                hlst hled =
                if      hled 1 +hled hled
                else    cursor-line hled =
                        if   hled 1 +hled hled
                        else hlst 1 +hlst hlst
                        then
                then

                save-highlight       \ save highlight because
                - negate +row-cursor \ the highlight will be removed here !
                validate-col-cursor
                restore-highlight    \ restore highlight

                validate-line-highlight

                refresh-screen ReTitle: EditorWindow ;

: highlight-home-line ( -- ) \ highlight to the start of the current line

                hcst >hced
                0 >hcst

                save-highlight    \ save highlight because
                hcst >col-cursor  \ the highlight will be removed here !
                restore-highlight \ restore highlight

                refresh-screen ReTitle: EditorWindow ;

: highlight-end-line ( -- ) \ highlight to the end of the current line

                hced >hcst
                cursor-line #line.len >hced

                save-highlight    \ save highlight because
                hced >col-cursor  \ the highlight will be removed here !
                restore-highlight \ restore highlight

                refresh-screen ReTitle: EditorWindow ;

: highlight-whole-line ( -- ) \ highlight the current line

                0 >hcst
                cursor-line #line.len >hced

                save-highlight    \ save highlight because
                hced >col-cursor  \ the highlight will be removed here !
                restore-highlight \ restore highlight

                refresh-screen ReTitle: EditorWindow ;

\ changed May 2nd, 2003 dbu
: highlight-word-left     ( -- ) \ highlight the next word to the left
                cursor-col 0=
                IF
        \ todo: if we reach the start of the actual line we should
        \       wrap to the previous one
                        refreshAll: DocWindow
                ELSE    cursor-line #line" cursor-col 1- min tuck + swap
                        over c@ bl =
                        IF      bl -skip
                        THEN    bl -scan swap c@ bl = over or
                        IF      1+ dup cursor-col =
                                IF      1-
                                THEN
                        THEN    dup

                                hcst hced =
                                if   >hcst
                                else cursor-col hcst >
                                     if   >hced
                                     else >hcst
                                     then
                                then

                                save-highlight    \ save highlight because
                                >col-cursor       \ the highlight will be removed here !
                                restore-highlight \ restore highlight

                THEN    ReTitle: EditorWindow ;

\ changed May 2nd, 2003 dbu
: highlight-word-right    ( -- ) \ highlight the next word to the right
                cursor-col cursor-line #line.len >=
                IF
        \ todo: if we reach the end of the actual line we should
        \       wrap to the next one
                        refreshAll: DocWindow
                ELSE    cursor-line #line" tuck cursor-col /string
                        over c@ bl <>
                        IF      bl scan
                        THEN    bl skip nip - dup

                                hcst hced =
                                if   >hced
                                else cursor-col hced =
                                     if   >hced
                                     else >hcst
                                     then
                                then

                                save-highlight    \ save highlight because
                                >col-cursor       \ highlight will be removed here !!
                                restore-highlight \ restore highlight

                THEN    ReTitle: EditorWindow ;

: highlight-word ( -- ) \ highlight the current word under cursor

                cursor-line #line" nip cursor-col < ?EXIT
                cursor-line dup >hlst >hled
                hlst #line" dup cursor-col min to cursor-col
                2dup cursor-col nip
                BEGIN   2dup bl scan dup
                WHILE   2nip
                        bl skip
                REPEAT  3drop 2 pick - dup >hcst
                /string 2dup bl scan nip - hcst + >hced drop
                refresh-line ;

\ I don't want to change the original highlight-word because it's used
\ many times in Win-Ed. And I don't want to break the existing code.
\ So I decided to add a new version for highlighting the word under the cursor
\ if you do a double-click with your mouse.
\ May 3nd, 2003 dbu
: dblclick-highlight-word ( -- ) \ highlight the current word under cursor

                cursor-line #line" nip cursor-col < ?EXIT
                cursor-line dup >hlst >hled
                hlst #line"

                2dup cursor-col nip
                BEGIN   2dup bl scan dup
                WHILE   2nip
                        bl skip
                REPEAT  3drop 2 pick - dup >hcst
                /string 2dup bl scan ( bl skip ) nip - hcst + >hced drop

                \ Why doesn't this move the cursor behind the end
                \ of the highlight ?!?
                save-highlight    \ save highlight because
                hced >col-cursor  \ highlight will be removed here !!
                restore-highlight \ restore highlight
;

\ new May 2nd, 2003 dbu
: highlight-home-doc ( -- ) \ highlight to start of doc
        0 >hlst
        0 >hcst

        save-highlight    \ save highlight because
        home-doc          \ highlight will be removed here !!
        restore-highlight \ restore highlight
;

\ new May 2nd, 2003 dbu
\ not used yet, but working
: highlight-end-doc ( -- ) \ highlight to end of doc
        file-lines 1- >hled
        cursor-line #line.len >hced

        save-highlight    \ save highlight because
        end-doc           \ highlight will be removed here !!
        restore-highlight \ restore highlight
;

: word-delete   ( -- )
        bitImage? ?EXIT
        browse? ?EXIT
        highlighting?
        IF      delete-highlight
        ELSE    stop-delete
                cursor-line #line.len cursor-col <=  \ at or beyond line end?
                IF      delete-character
                        cur-buf LCOUNT cursor-col /string   \ is text remaining
                        IF      c@ bl =                     \ then on blank?
                        ELSE    drop FALSE                  \ else NO
                        THEN
                ELSE    true
                THEN
                IF      cursor-line #line" cursor-col /string 2dup
                        over c@ bl <>
                        IF      bl scan
                        THEN    bl skip nip - nip delete-characters
                THEN
        THEN
        file-has-changed ;

: line-delete   ( -- )
                bitImage? ?EXIT
                browse? ?EXIT
                highlighting?
                IF      delete-highlight
                ELSE    0 >col-cursor
                        stop-delete
                        1 delete-lines
                THEN    file-has-changed refresh-screen ;

: insert-tab    { \ hlsts hcsts hleds hceds -- }
                bitImage? ?EXIT
                browse? ?EXIT
                highlighting?
                IF      hlst to hlsts
                        hcst to hcsts
                        hled to hleds
                        hced to hceds
                        hced 0>                 \ if cursor isn't in col 0
                        IF      hled 1+         \ include last line
                        ELSE    hled            \ else don't
                        THEN    hlst
                        ?DO     i hcsts _>row-col
                                get-cursor-line
                                cur-buf @
                                IF      tab-size cursor-col tab-size 1 max mod -
                                        0max 0
                                        ?DO     bl _insert-character
                                        LOOP
                                THEN
                                refresh-line
                        LOOP
                        hceds 0>
                        IF      1 +to hceds             \ over one column
                        THEN
                        hleds hceds _>row-col
                        hlsts to hlst
                        hcsts to hcst
                        hleds to hled
                        hceds to hced
                        file-has-changed
                ELSE    tab-size cursor-col tab-size 1 max mod - 0max 0
                        ?DO     bl insert-character
                        LOOP
                THEN    ;

: smart-insert-tab ( -- )
  overstrike @
  if cursor-col 16 / 1+ 16 * dup 80 > if 1 +to cursor-line 0 then
     to cursor-col refresh-line
  else  insert-tab then ;

: back-tab      { \ hlsts hcsts hleds hceds -- }
        bitImage? ?EXIT
        browse? ?EXIT
        highlighting?
        IF      hlst to hlsts
                hcst to hcsts
                hled to hleds
                hced to hceds
                hced 0>                 \ if cursor isn't in col 0
                IF      hled 1+         \ include last line
                ELSE    hled            \ else don't
                THEN    hlst
                ?DO     i hcsts _>row-col
                        get-cursor-line
                        tab-size 0
                        ?DO     cur-buf CELL+ cursor-col +
                                c@ bl =                        \ blank at cursor
                                cursor-col cur-buf @ < and     \ & not at end
                                IF      _delete-character
                                THEN
                        LOOP
                        refresh-line
                LOOP

                hceds 1- 0max to hceds          \ back one column
                hleds hceds _>row-col
                hlsts to hlst
                hcsts to hcst
                hleds to hled
                hceds to hced
                file-has-changed
        ELSE    character-left
                cursor-col tab-size 1 max mod 0max 0
                ?DO     character-left
                LOOP
        THEN    ;

: smart-back-tab ( -- )
  overstrike @
  if cursor-col 1- tab-size / tab-size * to cursor-col   
  else back-tab then ;
   
: do-backspace  ( -- )  \ shift cursor to eol, 1 to left
        bitImage? ?EXIT
        browse?
        IF      ?get-highlight
                find-buf c@
                IF      back-find-text-again
                ELSE    -1 +row-scroll
                THEN
        ELSE    highlighting?
                IF      delete-highlight
                ELSE  overstrike @
                  if  cursor-col 0>
                    if get-cursor-line
                       -1 +to cursor-col 
                       bl cur-buf cell+ cursor-col + c!
                       put-cursor-line
                       file-has-changed
                    else back-delete-character
                    then
                  else  back-delete-character
                  then  refresh-line
                THEN
        THEN    ;

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 21    Search and replace Text  
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

named-new$ replace-buf

: replace-text-again ( -- )
                browse? ?EXIT
                highlighting?
                IF      busy? ?EXIT             \ leave if already busy
                        TRUE to busy?
                        delete-highlight
                        replace-buf count insert-string
                        refresh-line
                        FALSE to busy?          \ clear busy, so find will work
                        _find-text-again ?beep
                ELSE    beep
                THEN    ;

: replace-text-all ( -- )
                browse? ?EXIT
                highlighting?
                IF      busy? ?EXIT          \ leave if already busy
                        BEGIN   highlighting?
                        WHILE   replace-text-again
                        REPEAT
                ELSE    beep
                THEN    ;
