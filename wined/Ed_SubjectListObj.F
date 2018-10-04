\ $Id: Ed_SubjectListObj.F,v 1.1 2011/03/19 23:26:04 rdack Exp $
\
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 52    Select List Class      
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

:Class SelectListClass    <Super ListControl

int temp-entry#
int hidden?
MAXSTRING bytes lineBuf

:M ClassInit:   ( -- )
                ClassInit: super
                0     to temp-entry#
                FALSE to hidden?
                ;M

:M NextLine:    ( -- a1 n2 f1 )         \ override for other select-windows
                s" Empty" FALSE
                ;M

:M Select:      ( -- )                  \ override for other select windows
                ;M

: "AddLine      { adr len \ list$ -- }
                MAXSTRING LocalAlloc: list$
                adr len list$ place
                        list$ +NULL
                list$ 1+
                0 LB_ADDSTRING
                GetID: self SendDlgItemMessage: EditorWindow drop
                ;

: selected-item ( -- n1 )       \ the currently selected item of list box
                0 0 LB_GETCURSEL
                GetID: self SendDlgItemMessage: EditorWindow ; ( -- n1 )

:M GetLine:     { ndx -- a1 n1 }
                lineBuf 1+ ndx LB_GETTEXT
                GetID: self SendDlgItemMessage: EditorWindow drop
                0 ndx LB_GETTEXTLEN
                GetID: self SendDlgItemMessage: EditorWindow lineBuf c!
                lineBuf count
                ;M

:M SetLine:     ( n1 -- )
                0max temp-entry# min
                0 swap LB_SETCURSEL
                GetID: self SendDlgItemMessage: EditorWindow drop
                ;M

: setTheFont    ( -- )
                0 Handle: sFont WM_SETFONT
                GetID: self SendDlgItemMessage: EditorWindow drop ;

:M Update:      ( -- )
                hWnd
                hidden? 0= and
                IF      0 0 LB_RESETCONTENT
                        GetID: self SendDlgItemMessage: EditorWindow drop
                        entry# >r
                        0 to temp-entry#
                        BEGIN   NextLine: [ self ]      \ -- a1 n1 f1
                        WHILE   "AddLine
                                1 +to temp-entry#
                        REPEAT
                        temp-entry# 0=
                        IF      "AddLine
                        ELSE    2drop
                        THEN
                        r> to entry#
                          SetFocus: EditWindow
                        RefreshAll: EditWindow
                THEN
                ;M

:M Refresh:     ( -- )
                hWnd
                hidden? 0= and
                IF      Paint: self
                THEN
                ;M

:M Hide:        ( f1 -- )
                dup hidden? <>
                IF      dup to hidden?
                        IF      SW_HIDE       Show: self
                        ELSE    SW_SHOWNORMAL Show: self
                        THEN
                        Update: self
                        Refresh: EditorWindow
                ELSE    drop
                THEN
                ;M

:M Showing:     ( -- f1 )
                hidden? 0=
                ;M

:M Start:       ( -- )
                Start: Super
                setTheFont
                Update: self
                ;M

\ List boxes don't normally send WM_COMMAND messages to the listbox, but
\ in this case, the WM_COMMAND message is being reflected from the "parent".
\ See: WM_COMMAND message processing in the parent window
:M WM_COMMAND   { hwnd msg wparam lparam -- res }
                wparam HIWORD ( NOTIFY ) LBN_SELCHANGE =
                IF      Select: [ self ]
                        1
                ELSE    0
                THEN
                ;M

;Class

:Object files-list <Super SelectListClass

int last-entry

13 constant list-height

:M ClassInit:   ( -- )
                ClassInit: super
                -1 to last-entry
                ;M

:M Update:      ( -- )
                Update: Super
                0 entry# LB_SETCURSEL
                GetID: self SendDlgItemMessage: EditorWindow drop
                ;M

:M NextLine:    ( -- a1 n2 f1 )
                temp-entry# to entry#
                cur-filename c@ 0=
                IF      unnamed-file count
                        FALSE
                ELSE    cur-filename count "to-pathend"
                        TRUE
                THEN    ;M

:M BInfo:       ( -- a1 )       \ return address of filename under cursor
                                \ in the files list box
        Vertical list-height / last-entry# 1- >
        IF      binfo off
        ELSE    entry# >r
                Vertical list-height / to entry#
                s"   File:  "                   binfo  place
                cur-filename count              binfo +place
                s"   \n  Line: "                binfo +place
                cursor-line 1+ 0 <# #s #>       binfo +place
                s"   "                          binfo +place
                s"   Column: "                  binfo +place
                cursor-col 1+ 0 <# #s #>        binfo +place
                s"   "                          binfo +place
                r> to entry#
        THEN    binfo
        ;M

:M On_MouseMove: ( h m w -- )
        Vertical list-height / dup
        last-entry <>                   \ if on a different filename
        IF      clear-info              \ then clear info message
                                        \ so it can redisplay it correctly
        THEN    to last-entry
        On_MouseMove: Super
        ;M

:M Select:      ( -- )
        clear-info
        selected-item SetStack: EditWindow
        hyper-open
        >E
        SetFocus: EditWindow
        ;M

:M Refresh:     ( -- )
        hWnd
        hidden? 0= and
        IF      GetStack: EditWindow SetLine: self
        THEN
        Refresh: Super
        ;M

;Object

Addr: files-list to FilesList
                        \ initialize the object pointer for forward references

:Object found-list <Super files-list

create fileEntry MAXSTRING allot
        fileEntry OFF

:M ClassInit:   ( -- )
        ClassInit: super
        FALSE SetAutoClose: self
        ;M

:M NextLine:    ( -- a1 n2 f1 )
        temp-entry# >sifEntry
        IF      dup >sifFile" "to-pathend"                      fileEntry place
                SPCS maxName 22 min fileEntry c@ - 0max 2 +     fileEntry +place
                    >sifText"                                   fileEntry +place
                fileEntry count                                 TRUE
        ELSE    drop
                s" No Found Text"                               FALSE
        THEN    ;M

:M BInfo:       ( -- a1 )       \ return address of filename under cursor
                                \ in the files list box
        0 0 LB_GETTOPINDEX
        GetID: self SendDlgItemMessage: EditorWindow  \ -- n1 index of top item
        Vertical list-height / +                       \ add offset to list item
        >sifEntry                                      \ get entry address
        IF      s"   File:  "           binfo  place
                dup >sifFile"           binfo +place   \ and add to buffer
                s"   at Line: "         binfo +place
                dup >sifLine# (.)       binfo +place   \ then set line number
                s"   \n  Text: "        binfo +place
                >sifText"               binfo +place
                s"   "                  binfo +place
        ELSE    drop                                   \ discard address
                binfo off
        THEN    binfo
        ;M

:M Select:      ( -- )
        clear-info
        selected-item >sifEntry
        IF      dup >sifFile" "open-text        \ and open the file
                >sifLine# to cursor-line        \ then set line number
                sync-mirrors
                cursor-on-screen
                refresh-screen
                SetFocus: EditWindow
        ELSE    drop                            \ discard address
                beep
        THEN
        ;M

;Object

Addr: found-list to FoundList

create window-list              \ the list of subject windows
        FilesList    ,
        FoundList    ,
        0 ,

:Object SubjectList <Super ComboListControl

int hidden?
int curSubject

:M ClassInit:   ( -- )
        ClassInit: super
        0 to hidden?
        0 to curSubject
        ;M

:M InitSubject: ( window -- )
        to curSubject
        ;M

: SelectSubject { theWindow -- }
        curSubject
        IF      TRUE  Hide: curSubject
        THEN
        FALSE Hide: theWindow
        theWindow to curSubject ;

: addToList     ( z" -- )
        0 CB_ADDSTRING
        GetID: self SendDlgItemMessage: EditorWindow drop
        ;

:M Start:       ( Parent -- )
        Start: Super
        0 0 CB_RESETCONTENT
        GetID: self SendDlgItemMessage: EditorWindow drop

        z" Open Files"    addToList
        z" Found Files"   addToList

        0 0 CB_SETCURSEL
        GetID: self SendDlgItemMessage: EditorWindow drop
        0 edit-top drag-barH 1- 160 Move: self
        ;M

:M Select:      ( -- )
        0 0 CB_GETCURSEL
        GetID: self SendDlgItemMessage: EditorWindow ( -- n1 )
        ( n1 -- ) window-list +cells @ SelectSubject
        ;M

:M Hide:        ( f1 -- )
        dup hidden? <>
        IF      dup to hidden?
                IF     0 to listHeight
                        SW_HIDE
                ELSE    listHeightDefault to listHeight
                        SW_SHOWNORMAL
                THEN    Show: self
        ELSE    drop
        THEN    Refresh: curSubject
        ;M

:M Showing:     ( -- f1 )
                hidden? 0=
                ;M

:M WM_COMMAND   ( hwnd msg wparam lparam -- res )
        over HIWORD ( NOTIFY ) CBN_SELCHANGE =
        IF      Select: self
                1
        ELSE    0
        THEN
        ;M

;Object

