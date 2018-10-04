\ $Id: Ed_LoadFileFuncs.F,v 1.1 2011/03/19 23:26:04 rdack Exp $
\
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 53    Close Text
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

: close-all-text ( -- ) \ Colse all files
        EditWindow to DocWindow
        RefreshOff: EditWindow
        last-entry# 1+ 0
        ?DO     ?save-text ?LEAVE
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
        LOOP
        RefreshOn: EditWindow
        RefreshAll: EditWindow ;

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 54     Compile file in Win32Forth
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

: rem-sendkey   ( c1 -- )          \ pass a key to a remote Forth
                msgpad c!
                msgpad 1 WM_KEY w32fForth Sendw32fMsg drop ;

: "Forth ( a1 n1 -- )   \ send a string to the console
        bounds
        ?do  i c@ rem-sendkey
             0 ms \ release control to OS for a moment
        loop
        0x0D rem-sendkey ;  \ send CR to execute the string

: Compile-File ( addr n -- ) { \ load$ file$ -- } \ compile a file
        MAXSTRING LocalAlloc: load$
        MAXSTRING LocalAlloc: file$

        file$ place

        s" foreground-console" "Forth   \ make Forth the front application
        s" chdir '" load$ place
        file$ COUNT "path-only" load$ +place
        s" '" load$ +place
        load$ COUNT "Forth              \ Make file directory active
        s" FLOAD '" load$ place
        file$ COUNT load$ +place
        s" '" load$ +place
        load$ COUNT "Forth              \ Compile the source file
        ;

: load-forth-file ( -- ) \ Load file from disk and compile it
        [ also hidden ]
        Gethandle: EditorWindow start: LoadForth COUNT ?DUP
        [ previous ]
        IF Compile-File ELSE DROP THEN ;

: load-active-file ( -- ) \ Load the active file from disk and compile it
        cur-filename COUNT Compile-File ;

: save-and-load ( -- ) \ Save the current active file and compile it
        save-text  load-active-file  ;

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 55    Save or Load Strings
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

\ Read the a2,n2 sub-section section of 'Settings' to a data string of a1,n1
\ which could be the ascii comma delimited x,y coordinate of where the
\ window should be placed next time the application starts up.
: "GetDefault   ( a1 n1 -- a2 n2 )
                s" Settings" RegGetString ;

\ Write the a2,n2 sub-section section of 'Settings' to a data string of a1,n1
\ which could be the ascii comma delimited x,y coordinate of where the
\ window should be placed next time the application starts up.
: "SetDefault   ( a1 n1 a2 n2 -- )
                s" Settings" RegSetString ;

named-new$ tempBuf

: SaveFindStrings ( -- )
        GetHandle: findComboEdit               \ only save if combo is open
        tool-bar? and
        IF      GetCount: findComboEdit
                10 min 0                       \ only save first 10 find strings
                ?DO     tempBuf i GetString: findComboEdit
                        tempBuf count  s" FindString "
                        2dup + 1- i '0' + swap c!     \ append the count 0-9
                        "SetDefault
                LOOP
        THEN    ;

: LoadFindStrings ( -- )
        GetHandle: findComboEdit                \ only save if combo is open
        tool-bar? and
        IF      10 0
                ?DO     s" FindString "
                        2dup + 1- 9 i - '0' + swap c!  \ append the count 0-9
                        "GetDefault dup
                        IF      2dup InsertString: findComboEdit
                                "CLIP" find-buf place
                        ELSE    2drop
                        THEN
                LOOP
        THEN    ;
