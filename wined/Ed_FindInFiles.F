\ $Id: Ed_FindInFiles.F,v 1.1 2011/03/19 23:26:04 rdack Exp $
\    File: Ed_FindInFiles.f
\  Author: Dirk Busch
\ Created: Dienstag, Juli 27 2004 - 18:23 dbu
\ Updated: Dienstag, Juli 27 2004 - 18:23 dbu
\
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ "Find text in Files" dialog
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

FALSE   value   all-occur? \ find all occurances of a string in a file, not just first
0       value   FoundList
0       value   FindInWindow

\ in the form: [line-number(cell)][count(byte)][characters]

0x20000 constant maxListIncrement
maxListIncrement value   maxList     \ start with a 128k search buffer
maxList Pointer sifList
0       value   sifListLen
0       value   total-files
0       value   total-found
0       value   maxName              \ longest filename length without the path
      
\ October 3rd, 2000 - 9:46 tjz
\ on my 256 megabyte machine, this upper limit of occurances to find works well
\ if you have less memory, then your computer will probably appear to mostly
\ come to a halt with memory allocation problems before 20000 occurances can be
\ found.  I have 750 megabytes of virtual memory allocated, and my machine
\ actually crashed the application when it allocated over 700 megabytes to the
\ search occurance list, while trying to find all occurances of spaces in all
\ files.  WinEd was setup to look for upto 40000 occurances, and had reached
\ about 36000, before it ran out of memory.  It appears that WindowsNT doesn't
\ handle allocation well when your buffers get to be larger than physical
\ memory.  What a suprise.
\ The moral of this story, is; Don't make the below number bigger.
19999 CONSTANT  MAXOCCURANCES

MAXSTRING 2 * cell+ CONSTANT sifSIZE

: >sifEntry     ( n1 -- a1 f1 ) \ locate address a1 of search in sfiles entry n1
                                \ return f1=TRUE if entry is valid, else FALSE
                sifSIZE * dup sifList +
                swap sifSIZE + sifListLen <= ;

: >sifLine#     ( a1 -- n1 )
                @ 1 - 0max ;

: >sifFile"     ( a1 -- a2 n1 )
                cell+ count -trailing ;

: >sifText"     ( a1 -- a2 n1 )
                MAXSTRING cell+ + count -trailing ;

: "AddFile      ( a1 n1 a2 n2 line -- ) \ add file a2,n2 to file list
        \ also add search line text a1,n1 to file list
        sifListLen maxList 990 - <
                               \ should never be less than about 1500 bytes free
        IF      dup>r sifList sifListLen + !           \ lay in line number
                "clip" 2dup
                2dup "to-pathend" nip maxName max
                to maxName           \ save longest filename length without path
                sifList sifListLen + cell+ place       \ lay in filename
                2swap "clip"
                sifList sifListLen + cell+
                MAXSTRING + place                      \ lay in search line text
                sifListLen sifSIZE + TO sifListLen
                r> "AddFile: FindInWindow
                1 +to total-found
                total-found 1000 >
                IF      total-found 15 and 0=
                        IF      total-found total-files  Total: FindInWindow
                                5 MS
                        THEN
                ELSE    total-found total-files  Total: FindInWindow
                THEN
                total-found MAXOCCURANCES >         \ stop if over MAXOCCURANCES
                IF      TRUE to search-aborted?
                THEN
        ELSE    3drop 
                TRUE to search-aborted?
        THEN

        \ now resize search list if it is relatively near being full.
        \ perform this adjustment after adding, so that the addresses passed
        \ into "AddFile will be valid during the add.  A resize may
        \ invalidate the addresses.
        \ this fixes a bug, where a garbage file was inserted, when the
        \ search buffer was resized before the file was inserted.
        sifListLen maxList 2000 - >=
                                \ keep lots of free space at end of search list
        IF                      \ expand search buffer by 128k if needed
                maxList maxListIncrement + ResizePointer sifList 0=
                IF      maxListIncrement +to maxList     \ readjust max list size
                THEN
        THEN    WINPAUSE ;

: search-1file  { \ line$ -- }  \ search this file for find string
        search-aborted? ?EXIT
        MAXSTRING LocalAlloc: line$
        1 +to total-files
        name-buf count 60 "file-clip" LineText: FindInWindow
        1 loadline !                            \ reset line counter to zero
        line$ MAXSTRING erase                   \ clear buffer
        BEGIN                                   \ get a line
                line$ 1+ MAXCOUNTED search-hndl read-line
                rot line$ c!
                                0= and
                search-aborted? 0= and
        WHILE   line$ count find-buf count xsearch nip nip
                IF      line$ count name-buf count loadline @ "addFile
                        search-aborted? ?EXIT
                        all-occur?   0= ?EXIT   \ leave, all done
                THEN    1 loadline +!
        REPEAT
        name-buf 0 LineText: FindInWindow ;

: do-files-search ( -- )
        busy? ?EXIT          \ leave if already busy
        TRUE to busy?
        0 to total-files
        0 to total-found
        0 to sifListLen
        0 to maxName
        Reset: FindInWindow
        WINPAUSE                               \ refresh dialog
        ['] search-1file   is process-1file
        FALSE to search-aborted?
        do-files-process
        Update: FindInWindow
        total-found MAXOCCURANCES >             \ stop if over MAXOCCURANCES
        IF      s" STOPPED, Search Results Buffer Full"
        ELSE    search-aborted?
                IF      s" Search Interrupted !"
                ELSE    total-found 0=
                        IF      s" No Matching Files Found"
                        ELSE    s" Done"
                        THEN
                THEN
                FoundList if Update: FoundList then
        THEN    LineText: FindInWindow
        0 SetFile: FindInWindow
        FALSE to busy? ;

0 value Selected?

defer do-file-search-open ' noop is do-file-search-open

load-dialog WinEdit       \ load the dialogs for WinEd

:Object FindInFilesDlg  <Super  ModelessDialog

IDD_SEARCHINFILES WinEdit find-dialog-id constant template

MAXSTRING bytes siText
int originX
int originY

:M ClassInit:   ( -- )
                ClassInit: super
                self to FindInWindow
                0 to originX
                0 to originY
                ;M

:M GetTemplate: ( -- template )
                template
                ;M

:M ExWindowStyle: ( -- )
                ExWindowStyle: super
                WS_EX_TOOLWINDOW or
                ;M

:M Total:       { found# total# \ message$ -- }
                64 localAlloc:  message$
                s" Found: "     message$  place
                found# 0 (d.)   message$ +place
                s"  in "        message$ +place
                total# 0 (d.)   message$ +place
                                message$ count ID_FILECOUNT SetDlgItemText: self
                ;M

:M LineText:    ( a1 n1 -- )
                ID_LINETEXT SetDlgItemText: self
                WINPAUSE                               \ force a screen update
                ;M

:M Reset:       ( -- )
                0 0 LB_RESETCONTENT ID_FILELIST SendDlgItemMessage: self drop
                total-found total-files Total: self
                Paint: self
                ;M

:M SetFile:     ( n1 -- )
                0 swap LB_SETCURSEL ID_FILELIST SendDlgItemMessage: self drop
                ;M

:M GetFile:     ( -- a1 n1 )
                siText dup
                0 0 LB_GETCURSEL  ID_FILELIST SendDlgItemMessage: self ( -- n1 )
         ( n1 -- )  LB_GETTEXT    ID_FILELIST SendDlgItemMessage: self
                ;M

:M GetSelection: ( -- n1 )
                0 0 LB_GETCURSEL  ID_FILELIST SendDlgItemMessage: self
                ;M

:M "AddFile:    { adr len line \ msg$ -- }
                MAXSTRING localAlloc: msg$
                s"   "                  msg$    place
                line 0max 0 (d.)        msg$   +place   \ line number
                k_tab                   msg$  c+place   \ a tab
                adr len 50 "file-clip"  msg$   +place   \ filename
                                        msg$   +NULL
                                        msg$ 1+
                0 LB_ADDSTRING ID_FILELIST SendDlgItemMessage: self drop
                ;M

:M Update:      { \ msg$ -- }
        MAXSTRING localAlloc: msg$
        Gethandle: self
        IF      total-found 1000 >
                IF      originX 7 + originY 50 + SetOrigin: msg-window
                        s" Building List Window" MessageText: msg-window
                        FALSE OnTop: msg-window
                        Start: msg-window
                THEN
                0 0 LB_RESETCONTENT ID_FILELIST SendDlgItemMessage: self drop
                0                                               \ start at zero
                BEGIN   dup >sifEntry
                WHILE   s"     "                msg$   place
                        dup @ 0max 0 (d.)       msg$  +place    \ line number
                        K_TAB                   msg$ c+place    \ a tab
                        >sifFile"
                        50 "file-clip"          msg$  +place    \ filename
                                                msg$  +NULL
                                                msg$ 1+
                        0 LB_ADDSTRING ID_FILELIST SendDlgItemMessage: self drop
                        1+
                REPEAT  2DROP
                total-found 1000 >
                IF      message-off
                THEN
                total-found total-files Total: self
                Paint: self
        THEN
        ;M

:M On_Init:     ( hWnd-focus -- f )
                Update: self
                originX originY or
                IF      originX originY SetWindowPos: self
                THEN
                0 SetFile: self
                search-path   count ID_DIRECTORY   SetDlgItemText: self
                mask-ptr count ID_MASK          SetDlgItemText: self
                Find-buf count ID_SEARCHTEXT    SetDlgItemText: self
                CaseSensitive? ID_CASE          CheckDlgButton: self
                sub-dirs?      ID_SUBDIR        CheckDlgButton: self
                all-occur?     ID_ALLOCCUR      CheckDlgButton: self
                FALSE to Selected?
                FALSE to search-aborted?
                1 ;M

: save-search-list { \ lsthndl lsterr msg$ file$ -- }
      MAXSTRING localAlloc: msg$
      MAXSTRING localAlloc: file$
      Gethandle: self
      IF    total-found 1000 >
            IF    originX 7 + originY 50 + SetOrigin: msg-window
                  s" Saving Search List" MessageText: msg-window
                  FALSE OnTop: msg-window
                  Start: msg-window
            THEN
( rbs )     s" Searchlist.txt" Prepend<home>\ r/w create-file 0=
            IF    to lsthndl
                  0 to lsterr
                  file$ off
                  0                                           \ start at zero
                  BEGIN   dup >sifEntry                       \ -- a1 f1
                        lsterr 0= and                         \ and no error
                  WHILE dup >sifFile" file$ count compare     \ if file changed
                        IF    dup >sifFile"   file$  place    \ filename
                              SPCS 2          msg$   place    \ leading spaces
                              file$ count     msg$  +place
                              msg$ count lsthndl write-line lsterr or to lsterr
                        THEN
                        dup @ 0max 0 (d.)
                        8 over - SPCS swap 0max msg$   place  \ leading spaces
                                                msg$  +place  \ line number
                        SPCS 4                  msg$  +place  \ trailing spaces
                        >sifText"               msg$  +place  \ search line
                        msg$ count lsthndl write-line
                        lsterr or to lsterr
                        1+
                  REPEAT
                        2DROP
                  lsthndl close-file drop
            ELSE  drop beep
            THEN
            total-found 1000 >
            IF      message-off
            THEN
      THEN ;

: get-parameters ( -- )
        search-path 1+ MAXCOUNTED ID_DIRECTORY  GetDlgItemText: self search-path c!
        mask-ptr    1+ MAXCOUNTED ID_MASK       GetDlgItemText: self mask-ptr c!
        Find-buf    1+ MAXCOUNTED ID_SEARCHTEXT GetDlgItemText: self Find-buf c!
        Find-buf count InsertString: findComboEdit
        ID_CASE   IsDlgButtonChecked: self to CaseSensitive?
        ID_SUBDIR IsDlgButtonChecked: self to sub-dirs?
        ID_ALLOCCUR IsDlgButtonChecked: self to all-occur?
        GetWindowRect: self 2drop to originY to originX ;

: do-list-box   ( select_message -- )
                CASE
                LBN_DBLCLK OF   busy? to search-aborted?
                                get-parameters
                                0       end-dialog      ENDOF   \ done
             LBN_SELCHANGE OF   busy? to search-aborted?
                                get-parameters
                                do-file-search-open
                                                        ENDOF   \ select changed
                ENDCASE ;

: do-choose-path { \ path$ -- }
                MAXSTRING LocalAlloc: path$
                path$ 1+ MAXCOUNTED ID_DIRECTORY GetDlgItemText: self path$ c!
                z" Choose search folder" path$ Gethandle: self BrowseForFolder
                if   path$ +null
                     path$ count ID_DIRECTORY SetDlgItemText: self
                then ;

:M On_Command:  ( hCtrl code ID -- )
        CASE
                IDOK        OF  busy?
                                IF      TRUE to search-aborted?
                                ELSE    get-parameters
                                        s" Stop !" IDOK SetDlgItemText: self
                                        do-files-search
                                        s" Search" IDOK SetDlgItemText: self
                                        FALSE to search-aborted?
                                THEN                            ENDOF   \ search
                IDCANCEL    OF  busy? to search-aborted?
                                get-parameters
                                DestroyWindow: self
                                SetFocus: DocWindow 
                                                                ENDOF   \ done
                ID_FILELIST OF     do-list-box                  ENDOF
                IDB_SAVE    OF     save-search-list             ENDOF
                IDB_CHOOSE_PATH OF do-choose-path               ENDOF
                        false swap ( default result )
        ENDCASE ;M

:M WM_CLOSE     ( -- )
                busy? to search-aborted?
                get-parameters
                WM_CLOSE WM: Super
                ;M

;Object

:noname ( -- )
        ?save-text ?EXIT
        ['] search-1file is process-1file
        Selected? 0=
        IF      cur-file-unnamed? 0=
                IF   1 +hyper
                     hyper-insert
                THEN
                TRUE to Selected?
        THEN
        GetSelection: FindInWindow              \ selected item number
        >sifEntry                               \ -- a1 f1
        IF      dup >sifFile" "open-text        \ and open the file
                >sifLine# to cursor-line        \ then set line number
                0 to cursor-col
                sync-mirrors
                cursor-line find-top-margin 2 / - VPosition: DocWindow
                no-highlight
                hlst 1+ to hled
                refresh-screen
                Refresh: FilesList
        ELSE    drop                            \ discard address
                beep
        THEN    ; is do-file-search-open

: find-in-files ( -- )
        ?get-highlight
        >E
        GetHandle: FindInFilesDlg       \ if window already open,
                                        \ then set search text
        IF      Find-buf count ID_SEARCHTEXT SetDlgItemText: FindInFilesDlg
        ELSE    EditorWindow Start: FindInFilesDlg
        THEN    ;

: searchlist-edit    ( -- )
        >E
( rbs) s" SEARCHLIST.TXT" Prepend<home>\ "+open-text ;

