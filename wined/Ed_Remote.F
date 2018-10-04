\ $Id: Ed_Remote.F,v 1.1 2011/03/19 23:26:04 rdack Exp $
\
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 60    Message support from Win32Forth, allows files to be opened remotely
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\
\ Message support from Win32Forth, allows files to be opened remotely
\ also needed for debug support

defer remote-open   ( wParam -- )  ' noop is remote-open
defer remote-word   ( -- )         ' noop is remote-word

: HandleW32FMsg { hndl msg wParam lParam -- }  \ respond to Win32Forth messages
        wParam
        CASE
                \ debug support messages
                ED_OPEN_EDIT   OF wParam remote-open ENDOF
                ED_OPEN_BROWSE OF wParam remote-open ENDOF
                ED_WATCH       OF wParam remote-open ENDOF
                ED_WORD        OF remote-word        ENDOF
                ED_STACK       OF receive-stack      ENDOF
                ED_DEBUG       OF receive-debug      ENDOF

                \ console start and termination
\                ED_ALIVE       OF true  to ConsoleReady? ENDOF
\                ED_SHUTDOWN    OF false to ConsoleReady? ENDOF
        ENDCASE
        ;


: remote-window ( -- )
        cursor-line 2 - VPosition: edit-window
        refresh-screen ;

:noname { addr flag \ ed-line ed-filename -- }
        \ flag: 1=edit 2=browse 3=watch
        max-path localalloc: ed-filename
        addr @ to ed-line
        addr cell+ count ed-filename place
        >E
        SetForegroundWindow: self
        SW_RESTORE Show: self
        ed-filename  uppercase count "to-pathend"
        cur-filename uppercase count "to-pathend" compare 0=
        \ only move cursor if we are not near the correct location already
        IF      ed-line @ 1- 0max cursor-line dup screen-rows 4 - + between 0=
                IF      ed-line @ 1- 0max to cursor-line
                        remote-window
                THEN
        ELSE    ed-filename count "already-open? >R
                ed-filename count "+open-text
                ed-filename  count "to-pathend"
                cur-filename count "to-pathend" compare 0=
                IF      R@
                        ed-line 1- 0max to cursor-line
                        remote-window
                THEN
                R>DROP
        THEN
        Refresh: EditorWindow
        refresh-screen
        RefreshCursor: DocWindow
        EditMode: Win-EdToolbar ; is remote-open

:noname { addr \ ed-line ed-column -- }
        addr @       to ed-line
        addr cell+ @ to ed-column
        browse? 0=
        IF      browse-toggle
        THEN
        ed-line @ 1- 0max to cursor-line
        ed-column @       to cursor-col
        highlight-word
        line-cur cursor-line screen-rows 4 - - 0max cursor-line between 0=
        IF      cursor-line screen-rows 2 - 2/ -
                VPosition: edit-window
        THEN
        refresh-screen
        RefreshCursor: DocWindow
        EditMode: Win-EdToolbar ; is remote-word

:M Win32Forth: ( hndl msg wParam lParam -- )   \ respond to Win32Forth messages
        HandleW32FMsg ;M

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 61    Automatic save of edit changes after a specifiable number of minutes
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

:M WM_TIMER     ( h m w l -- res )
        over SAVE_TIMER =
        IF      SAVE_TIMER hWnd Call KillTimer drop
                save-text
        THEN    0 ;M

;Object

: "find-label   ( a1 n1 -- )
        2dup InsertString: findComboEdit
        "CLIP" find-buf place
        Home: DocWindow
        0 to cursor-col
        TRUE to find-label?
        find-text-again         \ then try to find it
        FALSE to find-label?
        line-cur cursor-line 1 - max to line-cur
        no-highlight  ;
