\ $Id: Ed_Defaults.F,v 1.2 2013/08/12 05:11:55 rdack Exp $
\
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 63    Save and restore default settings for Win-Ed  
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
: set-ed-defaults  ( -- )         \ read/write to wined section of registry
    PROGREG-SET-BASE-PATH
    s" WinEd\" progreg +place ;   \ append the WinEd marker

: set-w32f-default  ( -- )        \ read/write to win32forth section of registry
    PROGREG-INIT ;

\ new May 24th, 2003 - 8:55 dbu
\ changed July 20th, 2003 - 18:30 dbu
: save-previous-file { n \ buff$ buff1$ -- }
\ save the filename and cursorposition off the active file in registry
        max-path 2 * localAlloc: buff$   \ a temporary buffer
        max-path 2 * localAlloc: buff1$  \ and a second one

        cur-filename count buff$ place
        s" ;" buff$ +place
        cursor-col s>d (d.) buff$ +place
        s" ;" buff$ +place
        cursor-line s>d (d.) buff$ +place
        buff$ +null

        s" PreviousFile" buff1$ place
        n s>d (d.) buff1$ +place
        buff1$ +null

        buff$ count buff1$ count "SetDefault
;

\ changed July 20th, 2003 - 18:30 dbu
: save-previous-files ( -- )
\ save the filenames and cursorpositions off the active files in registry 
        >E

        entry# >r

        \ save name off current active file
        cur-filename count s" PreviousFileActive" "SetDefault

        \ save all active files
        0 entry-max 0
        DO
                I to entry# \ select the hyper file index
                I SetStack: EditWindow \ and activate the file

                cur-filename c@
                if   \ save the filename and cursorposition
                     dup save-previous-file 1+
                then
        LOOP

        \ save the count of the active files
        s>d (d.) s" PreviousFileCount" "SetDefault

        r> to entry#
        entry# SetStack: EditWindow

        refresh-screen
        ReTitle: EditorWindow  ;

: save-defaults ( -- )
        DECIMAL                 \ MUST be in decimal when saving defaults
        set-ed-defaults

        GetHandle: FrameWindow
        IF    >E
              save-previous-files \ new May 24th, 2003 - 8:55 dbu
              save-find?                s>d (d.) s" SaveFind"       "SetDefault
              WinEd-web?                s>d (d.) s" WebBrowse"      "SetDefault
              tool-bar? Floating: Win-EdToolbar or
                                        s>d (d.) s" ToolBar"        "SetDefault
              Floating: Win-EdToolbar   s>d (d.) s" FloatBar"       "SetDefault
              min-tool-bar?             s>d (d.) s" MinToolBar"     "SetDefault
              open-previous?            s>d (d.) s" OpenPrevious"   "SetDefault
              page-lines?               s>d (d.) s" PageMarks"      "SetDefault
              border?                   s>d (d.) s" PrintBorders"   "SetDefault
              recent-files?             s>d (d.) s" RecentFiles"    "SetDefault
              CaseSensitive?            s>d (d.) s" CaseSensitive"  "SetDefault
              sub-dirs?                 s>d (d.) s" SubDirectories" "SetDefault
              all-occur?                s>d (d.) s" AllOccurances"  "SetDefault
              save-margin?              s>d (d.) s" SaveMargin"     "SetDefault
              colorize?                 s>d (d.) s" Colorize"       "SetDefault
              char-height 5 max         s>d (d.) s" CharHeight"     "SetDefault
              char-width  4 max         s>d (d.) s" CharWidth"      "SetDefault
              printer-lpi               s>d (d.) s" PrinterLPI"     "SetDefault
              def-right-edge            s>d (d.) s" RightEdge"      "SetDefault
              tab-size                  s>d (d.) s" TabSize"        "SetDefault
              save-minutes  0max 60 min s>d (d.) s" AutoSave"       "SetDefault
              printed-columns 30 max 230 min
                                        s>d (d.) s" PrinterCols"    "SetDefault
              defext$      count        s" DefExt"                  "SetDefault
              mask-ptr     count        s" SearchMask"              "SetDefault
              find-buf     count        s" SearchText"              "SetDefault
              search-path  count        s" SearchPathed"            "SetDefault
              minimized? 0=                 \ ONLY SAVE WINDOW IF NOT MINIMIZED
              IF      GetWindowRect: FrameWindow
                      2over             s>d (d.) s" WindowTop"      "SetDefault
                                        s>d (d.) s" WindowLeft"     "SetDefault
                      rot -             s>d (d.) s" WindowHeight"   "SetDefault
                      swap -            s>d (d.) s" WindowWidth"    "SetDefault
                  drag-barH             s>d (d.) s" SelectWidth"    "SetDefault
              THEN
              GetFaceName: vFont        s" WindowFont"              "SetDefault
              SaveFindStrings
              SaveFileMenuEntries
        THEN 
        set-w32f-default ;

\ new July 26th, 2003 - 10:43 dbu
: "GetDefaultValue ( addr n -- n1 flag ) \ read a value from registry
        "GetDefault
        -if     number? >r d>s r>
        else    2drop 0 false then
;

\ changed July 26th, 2003 - 11:03 dbu
: load-defaults ( -- )
    BASE @ >R DECIMAL        \ MUST be in decimal when loading defaults

    set-ed-defaults

    s" SaveFind"       "GetDefaultValue IF 0<> to save-find?     ELSE drop THEN
    s" WebBrowse"      "GetDefaultValue IF 0<> to WinEd-web?     ELSE drop THEN
    s" ToolBar"        "GetDefaultValue IF 0<> to tool-bar?      ELSE drop THEN
    s" MinToolBar"     "GetDefaultValue IF 0<> to min-tool-bar?  ELSE drop THEN
    s" OpenPrevious"   "GetDefaultValue IF 0<> to open-previous? ELSE drop THEN
    s" PageMarks"      "GetDefaultValue IF 0<> to page-lines?    ELSE drop THEN
    s" PrintBorders"   "GetDefaultValue IF 0<> to border?        ELSE drop THEN
    s" RecentFiles"    "GetDefaultValue IF 0<> to recent-files?  ELSE drop THEN
    s" CaseSensitive"  "GetDefaultValue IF 0<> to CaseSensitive? ELSE drop THEN
    s" SubDirectories" "GetDefaultValue IF 0<> to sub-dirs?      ELSE drop THEN
    s" AllOccurances"  "GetDefaultValue IF 0<> to all-occur?     ELSE drop THEN
    s" SaveMargin"     "GetDefaultValue IF 0<> to save-margin?   ELSE drop THEN
    s" Colorize"       "GetDefaultValue IF 0<> to colorize?      ELSE drop THEN
    s" CharHeight"     "GetDefaultValue IF to char-height        ELSE drop THEN
    s" CharWidth"      "GetDefaultValue IF to char-Width         ELSE drop THEN
    s" PrinterLPI"     "GetDefaultValue IF to printer-lpi        ELSE drop THEN
    s" TabSize"        "GetDefaultValue IF to tab-size           ELSE drop THEN
    s" AutoSave"       "GetDefaultValue IF to save-minutes       ELSE drop THEN
    s" PrinterCols"    "GetDefaultValue IF to printed-columns    ELSE drop THEN

    save-margin?
    IF   s" RightEdge"  "GetDefaultValue IF to def-right-edge ELSE drop THEN
    THEN

    page-lines? 0= to print-extended-lines

    \ added new clipping to DEFEXT$, for new max length of 16 chars
    s" DefExt"      "GetDefault -IF 2dup DEFEXTMAX min defext$ place THEN 2drop set-filter
    s" SearchMask"  "GetDefault -IF 2dup "CLIP" mask-ptr place THEN 2drop

    save-find?
    IF
            s" SearchText"     "GetDefault dup
            IF 2dup "CLIP" find-buf  place THEN 2drop
    THEN

    s" SearchPathed"   "GetDefault -IF 2dup "CLIP" search-path  place THEN 2drop

    s" WindowLeft"   "GetDefault number? 0= if 2drop 285 else drop then
    s" WindowTop"    "GetDefault number? 0= if 2drop 5 else drop then
          SetOrigin: FrameWindow
    s" WindowHeight" "GetDefaultValue IF to start-height      ELSE drop THEN
    s" WindowWidth"  "GetDefaultValue IF to start-width       ELSE drop THEN
    s" SelectWidth"  "GetDefaultValue IF to drag-barH         ELSE drop THEN
    s" FloatBar"     "GetDefaultValue IF to floating-bar?     ELSE drop THEN

    s" WindowFont"   "GetDefault -IF 2dup SetFaceName: vFont THEN 2drop
    set-w32f-default
    R> BASE ! \ restore base
;

\ changed February 29th, 2004 - 11:41 dbu
: load-more-defaults    ( -- )
        set-ed-defaults
        LoadFindStrings
        LoadFileMenuEntries
        set-w32f-default ;      \ restore 'winforth' for registry access


: setdeffile ( -- fl )   \ true=>set a file to be opened
  0 s" FileString0" "GetDefault ?dup 
  IF  \ we only add the file's which still exist
      2dup FILE-STATUS nip 0=
      IF file-to-edit$  place 0=
      ELSE 2drop THEN
  THEN ;

\ search for char in string, return string till
\ char and rest of string after char
\ May 23rd, 2003 - 17:14 dbu
: /get          { str len char \ str1 len1 -- str len str1 len1 }
        str len char scan  to len1 to str1
        len1 0>
        if
                len len1 - to len
                str1 1+ to str1
                len1 1- ?dup if to len1 then
        then    str len str1 len1 ;

\ May 24th, 2003 - 8:55 dbu
\ changed February 29th, 2004 - 11:41 dbu
: open-previous-file ( addr n -- ) \ load file and restore cursor position
        ?dup
        if     ';' /get ';' /get \ split string
                number? drop d>s >r \ calc cursor line
                number? drop d>s >r \ calc cursor row
                "CLIP" ?dup
                if      \ only try to open the file if it's still exist
                        2dup FILE-STATUS nip 0=
                        if   "+open-text         \ open file
                             r> r> to-find-line  \ restore the cursor positon
                        else 2drop r>drop r>drop
                        then
                else    2drop r>drop r>drop
                then
        else    drop
        then    ;

\ new July 20th, 2003 - 18:30 dbu
\ changed February 29th, 2004 - 11:41 dbu
: set-active-file ( addr n -- ) \ activate a given file
        2dup FILE-STATUS nip 0=
        if   entry-max 0
             DO   I to entry# \ select the hyper file index
                  I SetStack: EditWindow \ and activate the file

                  2dup cur-filename count compareia
                  0= if leave then
             LOOP 2drop
             hyper-open \ update window etc.
        else 2drop
        then ;

\ changed May 24th, 2003 - 8:55 dbu
\ changed July 26th, 2003 - 10:43 dbu
\ changed February 29th, 2004 - 11:41 dbu
: _open-previous { \ buff1$ -- } \ load last active files and restore cursor positions
        max-path 2 * localAlloc: buff1$
        set-ed-defaults

        \ get count of the last active files
        s" PreviousFileCount" "GetDefaultValue
        if  ?dup
            if 0 ?do  s" PreviousFile" buff1$ place
                    i s>d (d.) buff1$ +place
                    buff1$ +null
                    buff1$ count "GetDefault \ load last active file from registry
                    open-previous-file \ open it
                    no-highlight \ remove higlight
               loop
               \ set the active file
               s" PreviousFileActive"  "GetDefault set-active-file
            else make-new-text
            then
        else drop make-new-text
        then set-w32f-default ;

' _open-previous is open-previous


