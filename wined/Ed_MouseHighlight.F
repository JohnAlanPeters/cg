\ $Id: Ed_MouseHighlight.F,v 1.1 2011/03/19 23:26:04 rdack Exp $
\
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 62    Mouse-High-Lights
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

: calc-column   ( -- )  \ try to round the click position between characters
        mousex window-lmargin - 0max CharWidth: EditWindow /mod
        swap CharWidth: EditWindow 2 - > IF 1+ THEN
        col-cur + to cursor-col ;

: get-mouse-pos ( -- x y )
        Gethandle: DocWindow get-mouse-xy ;

: update-highlight ( -- )               \ rls January 2nd, 2001 - 16:06
        line-cur mousey CharHeight: DocWindow / +
        file-lines 1- min to cursor-line
        RectHigh
        IF      cursor-col  mcst >
                IF      mcst        to hcst
                        cursor-col  to hced
                ELSE    cursor-col  to hcst
                        mcst        to hced
                THEN
                cursor-line mlst >
                IF      mlst        to hlst
                        cursor-line to hled
                ELSE    cursor-line to hlst
                        mlst        to hled
                THEN
        ELSE
                cursor-line mlst =
                cursor-col  mcst > and
                cursor-line mlst > or
                IF                      \ Highlight forwards from (mlst,mcst)
                        cursor-line to hled
                        cursor-col  to hced
                        mlst        to hlst
                        mcst        to hcst
                        mousex window-lmargin 2 - <
                        IF      cursor-line 1+ to hled
                                cursor-col     to hced
                        THEN
                ELSE    cursor-line mlst =
                        cursor-col  mcst < and
                        cursor-line mlst < or
                        IF              \ Highlight backwards from (mlst,mcst)
                                cursor-line to hlst
                                cursor-col  to hcst
                                mlst        to hled
                                mcst        to hced
                                mousex window-lmargin 2 - <
                                IF      mlst #line.len to hced
                                THEN
                        THEN
                THEN
        THEN
        cursor-col cursor-line #line.len >
        RectHigh 0= and
        IF      hlst #line.len hcst min to hcst
                hled #line.len hced min to hced
        THEN
        refresh-screen ;

0 value tracking?

\ rls January 14th, 2001 - 2:20  added variable scrolling speed
: Mhedit-track { \ cursor-row excess -- }
        html-link?    ?EXIT
        tracking?     ?EXIT
        mousedown? 0= ?EXIT
        focusing?     ?EXIT
        tracking?     ?EXIT
        TRUE to tracking?
        calc-column
        update-highlight                                \ scroll down
        BEGIN   get-mouse-pos nip Height: DocWindow CharHeight: DocWindow -
                2dup - to excess >
        WHILE   1 +row-scroll
                update-highlight
                WINPAUSE
                CharHeight: DocWindow 4 * 20 excess 2 + */
                500 min 20 max ms
        REPEAT
                                                        \ scroll up
        BEGIN   get-mouse-pos nip dup negate to excess 0 <
                line-cur 0> and
        WHILE   -1 +row-scroll
                update-highlight
                WINPAUSE
                CharHeight: DocWindow 4 * 20 excess 2 + */
                500 min 20 max ms
        REPEAT
                                                        \ scroll right
        BEGIN   get-mouse-pos drop screen-cols 1- CharWidth: DocWindow *
                2dup - to excess >
        WHILE   cursor-col 1+ >col-cursor
                WINPAUSE
                CharWidth: DocWindow 8 * 20 excess 2 + */
                500 min 20 max ms
        REPEAT
        get-mouse-pos drop 0 <=                         \ scroll left
        col-cur 0> and                                  \ if needed
        IF      BEGIN   cursor-col 1- 0max >col-cursor
                        WINPAUSE
                        get-mouse-pos drop dup abs 2 max to excess
                        CharWidth: DocWindow 20 excess */
                        300 min 20 max ms
                        window-lmargin >=
                UNTIL
        THEN
        FALSE to tracking? ;

0 value click-column

: Mhedit-click { \ cursor-row -- }
        html-link? ?EXIT
        DocWindow >r
        EditWindow to DocWindow

        GetStack: DocWindow to entry#
        SetFocus: DocWindow
        HideCursor: DocWindow
        mousedown? 0=
        IF      Gethandle: DocWindow Call SetCapture drop
        THEN
        true to mousedown?
        ?CONTROL to RectHigh
        DocWindow r> =
        IF      calc-column
                cursor-col to click-column
                mousey CharHeight: DocWindow / to cursor-row
                cursor-row indx>line# file-lines 1- min
                dup cursor-line <>
                IF      -trailing-blanks
                THEN   to cursor-line
                ?shift 0=       \ if NOT extending the selection
                IF      cursor-line dup to hlst dup to hled to mlst
                        cursor-col  dup to hcst dup to hced to mcst
                        mousex window-lmargin 2 - <
                        IF      cursor-line 1+ to hled
                                cursor-col     to hced
                        THEN
                        refresh-screen
                ELSE
                        RectHigh
                        IF      cursor-col  hcst <
                                IF      hced to mcst
                                ELSE    hcst to mcst
                                THEN
                                cursor-line hlst <
                                IF      hled to mlst
                                ELSE    hlst to mlst
                                THEN
                                Mhedit-track
                        ELSE
                                cursor-line hlst =
                                cursor-col  hcst < and
                                cursor-line hlst < or
                                IF      hled to mlst
                                        hced to mcst
                                ELSE    cursor-line hled =
                                        cursor-col  hced > and
                                        cursor-line hled > or
                                        IF      hlst to mlst
                                                hcst to mcst
                                        THEN
                                THEN
                                Mhedit-track
                        THEN
                THEN
                ReTitle: EditorWindow
        ELSE    SetFocus: DocWindow
                 ReTitle: EditorWindow
                   Paint: EditorWindow
                TRUE to focusing?
                Mhedit-track
        THEN    ;

: Mhedit-unclick ( -- )
      mousedown?
      IF      Call ReleaseCapture drop
      THEN
      FALSE to mousedown?
      FALSE to focusing?
          all-lines: DocWindow
      RefreshCursor: DocWindow
      ShowCursor: DocWindow
      html-link?
      IF    k_F11 +k_control +k_shift PushKey
      ELSE  browse?                         \ browsing
            cursor-col click-column = and   \ and save column
            IF
                  on-text?                \ on text
                  IF    highlight-word
                        highlighting?
                        IF      k_F9 PushKey
                                browse? 0= \ destination should be in browse
                                IF      browse-toggle
                                THEN
                        ELSE    beep
                        THEN
                  ELSE  beep
                  THEN
            THEN
      THEN    ;

: Mhedit-dblclick ( -- )       \ highlight the current word
        FALSE to mousedown?
        FALSE to focusing?
        html-link? ?EXIT
        calc-column
        mousey CharHeight: DocWindow /
        line-cur + file-lines 1- min to cursor-line
        dblclick-highlight-word ;
