\ $Id: Ed_Menu.F,v 1.2 2011/04/25 18:01:26 rdack Exp $
\    File: Ed_Menu.f
\  Author: Dirk Busch
\ Created: September 10th, 2003 - 12:20 dbu
\ Updated: February 29th, 2004 - 11:50 dbu
\ Menus for Ed-Editor
\
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 53    Define Editor popup menu for the application  See also Scr 57 below
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

POPUPBAR Edit-Popup-bar
    POPUP " "
        MENUITEM        "Find - Replace Text..."  replace-text ;
        MENUITEM        "Find Again forward"      find-text-again ;
        MENUITEM        "Find Again backward"     back-find-text-again ;
        MENUSEPARATOR
        MENUITEM        "Cut"                     cut-text    ;
        MENUITEM        "Copy"                    copy-text   ;
        MENUITEM        "Paste"                   paste-text  ;
        MENUITEM        "Delete"                  clear-text  ;
        MENUITEM        "Select All"              highlight-all  ;
        MENUSEPARATOR
        MENUITEM        "Copy && Paste to Win32Forth"   temp-text ;
        MENUSEPARATOR
        MENUITEM        "Set Right Margin to Cursor Column"  right-to-cursor ;
        MENUITEM        "Browse/Edit Toggle"      browse-toggle ;
        MENUSEPARATOR
        MENUITEM        "Open File..."            open-text ;
        MENUITEM        "Close File"              close-text ;
        MENUITEM        "Open Highlighted File"   open-text-highlighted ;
        MENUITEM        "Open SEARCHLIST.TXT"     searchlist-edit ;
        MENUSEPARATOR
        MENUITEM        "Open ToolBar"            StartToolBar: EditorWindow ;
        MENUSEPARATOR
        MENUITEM        "Print File..."           print-text ;
        MENUSEPARATOR
        MENUITEM        "REVERT text"             revert-text ;
        MENUITEM        "View Previous"           close-text ;  \ jap
        MENUITEM        "Exit"                    bye ;
ENDBAR                                \ note a semi-colon on each line


\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 55    Define the ToolBar popup menus for the application
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

POPUPBAR max-ToolBar-Popup-bar
    POPUP " "
        MENUITEM        "Minimum ToolBar"       SwitchToolBar: EditorWindow ;
        MENUITEM        "Float ToolBar toggle"          Float: Win-EdToolbar ;
        MENUITEM        "Close ToolBar"          CloseToolBar: EditorWindow ;
ENDBAR

POPUPBAR min-ToolBar-Popup-bar
    POPUP " "
        MENUITEM        "Full ToolBar"          SwitchToolBar: EditorWindow ;
        MENUITEM        "Float ToolBar toggle"          Float: Win-EdToolbar ;
        MENUITEM        "Close ToolBar"          CloseToolBar: EditorWindow ;
ENDBAR

also HIDDEN


:Class :POPUP <Super  POPUP

int insertedMenus                       \ count of inserted menus

8 CONSTANT MAXMENU

MAXMENU 1 + CELLS bytes mid[]           \ the ids of the menu items
MAXMENU 1 + CELLS bytes mfunc[]         \ the menu function pointers

:M DoMenu:      { theID \ text$ -- }
        MAXSTRING LocalAlloc: text$
        pm >r                   \ save in case we are reentered while running
        hpm to pm
        BEGIN   pm
        WHILE   theID DoMenu: pm
                   GetPrev: pm to pm
        REPEAT
        insertedMenus 0
        ?DO     theID mid[] i CELLS+ @ =
                IF      MF_BYCOMMAND
                        MAXSTRING
                        text$ 1+
                        theID
                        pid Call GetMenuString text$ c!

                        text$ count mfunc[] i CELLS+ @ execute-menufunc
                THEN
        LOOP
        r> to pm
        ;M

:M GetCount:    ( -- n1 )
                insertedMenus
                ;M

:M GetMaxCount: ( -- n1 )
                MAXMENU
                ;M

:M GetString:   ( adr index -- )
                over >r >r >r
                MF_BYCOMMAND
                MAXSTRING
                r> 1+
                mid[] r> CELLS+ @
                pid Call GetMenuString r> c!
                ;M

:M ClassInit:   ( -- )
                ClassInit: Super
                mid[]   MAXMENU CELLS erase    \ init id list
                mfunc[] MAXMENU CELLS erase    \ init function pointers to NULL
                0 to insertedMenus
                ;M


\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 56    RECENT FILES menu now shows the most recently used files on top,
\       LRF off bottom.  Thanks to Bruno Gauthier (bjg)
\       Future: Put a double down arrow on the bottom for more files like MS
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

:M InsertMenuItem: { zMenuText pFunc \ iRank iFlag text$ -- }
        recent-files?
        IF  MAXSTRING LocalAlloc: text$
            FALSE to iFlag                        \ mark as not already inserted
            FALSE To iRank
            insertedMenus 0
            ?DO
                mid[] i CELLS+ @ NULL <>          \ if the id isn't NULL
                IF  MF_BYCOMMAND
                    MAXSTRING
                    text$ 1+
                    mid[] i CELLS+ @              \ use the ID to get text
                    pid Call GetMenuString text$ c!
                    zMenuText text$ count tuck
                    CAPS-COMPARE dup 0= if i to iRank then
                                     0= iFlag or to iFlag
                THEN
            LOOP
            iFlag 0=                              \ if not already inserted
            IF  insertedMenus 0=
                IF  NextId    mid[] insertedMenus CELLS+ !  \ set the menu ID
                    pFunc   mfunc[] insertedMenus CELLS+ !  \ set the function

                    zMenuText
                     mid[] insertedMenus cells+ @
                    MF_STRING
                    pid
                    Call AppendMenu drop
                    1 +to insertedMenus
                ELSE                   \ make room for an additional entry
                    mid[]   dup CELL+ insertedMenus CELLS move
                    mfunc[] dup CELL+ insertedMenus CELLS move
                                       \ the the entry in the table
                    NextId   mid[] !
                    pFunc  mfunc[] !
                                       \ if the table is full, delete last entry
                    insertedMenus MAXMENU >=
                    IF  MF_BYCOMMAND
                        mid[] insertedMenus CELLS+ @
                        pid
                        Call DeleteMenu drop
                    ELSE
                        1 +to insertedMenus
                    THEN
                                       \ insert the new entry in menu
                    zMenuText
                    mid[] @
                    MF_STRING
                    MF_BYCOMMAND or
                    mid[] CELL+ @
                    pid
                    Call InsertMenu drop
                THEN

            ELSE        iRank 0<>  ( if already the 1st no need to change)

                IF                              \ delete the entry in menu
                        MF_BYCOMMAND
                        mid[] iRank  CELLS+ @
                        pid
                        Call DeleteMenu drop
                        -1 +to insertedMenus
                                                \ make room for the entry
                        mid[]  dup CELL+ iRank CELLS move
                        mfunc[] dup CELL+ iRank CELLS move
                                                \ the entry in the table
                        NextId   mid[] !
                        pFunc  mfunc[] !
                                                \ insert the new entry in menu
                        zMenuText
                        mid[] @
                        MF_STRING
                        MF_BYCOMMAND or
                        mid[] CELL+ @
                        pid
                        Call InsertMenu drop
                        1 +to insertedMenus

                THEN

            THEN
        THEN
        ;M

;Class

previous


\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 57    Define the menubar for the application
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
MENUBAR Edit-Menu-bar

:POPUP fileMenu "&File"
   MENUITEM     "&New  File               \tCtrl+N"      new-text ;
   MENUITEM     "&Open File...            \tCtrl+O"      open-text ;
   MENUITEM     "Open &Highlighted File   \tCtrl+Shft+O" open-text-highlighted ;
   MENUSEPARATOR
   MENUITEM     "Open &URL..."                           open-html ;
   MENUITEM     "Open &Bitmap..."                        load-bitmap ;
   MENUSEPARATOR
   MENUITEM     "Insert new line at cursor \tCtrl+Enter" split-line ;
   MENUSEPARATOR
   MENUITEM     "Close File & Window"                    close-text ;
   MENUITEM     "Close All File Windows   \tCtrl+Shft+W" close-all-text ;
   MENUSEPARATOR
   MENUITEM     "&SAVE FILE               \tCtrl+S"      save-text ;
   MENUITEM     "SAVE &ALL Changed Files"                save-all-text ;        
   MENUITEM     "Save File As..."                        save-text-as ;
   MENUSEPARATOR
   MENUITEM     "Save MAC/UNIX File As PC..."            save-text-as-pc ;
   MENUSEPARATOR
   MENUITEM     "&REVERT TO LAST SAVED VERSION  \tF8"    revert-text ; \ JP
   MENUSEPARATOR
   MENUITEM     "Print Setup... "                        text-setup ;
   MENUITEM     "Pages Up Setup..."                      text-up-setup ;
   MENUITEM     "&Print File...           \tCtrl+P"      print-text ;
   MENUSEPARATOR
   MENUITEM     "Save All Changes && Exit \tShft+F10"    save-all-text bye ;
   MENUITEM     "E&xit                    \tAlt+F4"      bye ;
   MENUSEPARATOR
\ removed next two lines - May 19th, 2003 - 18:01 dbu
\ false MENUMESSAGE     "Recent Files"
\   MENUSEPARATOR


 POPUP "&Edit"
\   MENUITEM        "&Undo                      \tCtrl+Z"      word-undelete ;
   MENUITEM        "&Undo                      \tCtrl+Z"      xundo ;
   MENUSEPARATOR
   MENUITEM        "Cu&t                       \tCtrl+X"      cut-text    ;
   MENUITEM        "&Copy                      \tCtrl+C"      copy-text   ;
   MENUITEM        "&Paste                     \tCtrl+V"      paste-text  ;
   MENUITEM        "&Delete                    \tDel"         clear-text  ;
   MENUSEPARATOR
   MENUITEM        "Select &All                \tCtrl+A"      highlight-all ;
\ next is a new nemu item - May 19th, 2003 - 18:01 dbu
   MENUITEM        "Select &None               \tESC"         no-highlight ;
   MENUITEM        "Select Toggle              \tCtrl+Q"      highlight-mark ;
   MENUSEPARATOR
   MENUITEM        "&Insert Date Time          \tCtrl+Shft+V" paste-date/time ;
   MENUSEPARATOR
   MENUITEM        "&Browse/Edit Toggle\tF7"             browse-toggle ;
   MENUITEM        "Win-Ed &Preferences...\tCtrl+Shft+P"  text-options ;
\ moved here from "File" menu July 20th, 2003 - 12:01 dbu
   MENUITEM        "Load &Color Configuration File..."   load-colors ;
\ moved here from "Format" menu July 20th, 2003 - 12:01 dbu
   MENUITEM        "&Select Font and Type Size..."         text-size ;
   MENUSEPARATOR
   SUBMENU     "ToolBar Options"
       MENUITEM        "Open/Close ToolBar"
                       tool-bar?
                       IF      CloseToolBar: EditorWindow
                       ELSE    StartToolBar: EditorWindow
                       THEN ;
       MENUITEM        "Float/Dock ToolBar"    Float: Win-EdToolbar ;
       MENUITEM        "Full/Minimum ToolBar"  SwitchToolBar: EditorWindow ;
       ENDSUBMENU

 POPUP "F&ormat"
   MENUITEM      "&Paragraph Reformat        \tCtrl+R"   reformat-text ;
   MENUITEM      "Sort Paragraph &Lines..."              sort-paragraph ;


MENUSEPARATOR
   MENUITEM      "Change Cas&e               \tCtrl+U"  highlight-case-toggle ;
   MENUITEM      "Change &Hex/Decimal        \tCtrl+Shft+H"  make-hex ;
   MENUSEPARATOR
   MENUITEM      "&Expand File TABS to Spaces\tCtrl+Shft+E"  expand-tabs ;
   MENUSEPARATOR
   MENUITEM      "Convert to a PC file"               change-to-pc ;
   MENUITEM      "Convert to a Apple file"            change-to-apple ;
   MENUITEM      "Convert to/from a Binary file"      change-to-binary-toggle ;

 POPUP "&Search"
   MENUITEM      "&Find / Replace Text...\tCtrl+F"       replace-text ;
   MENUITEM      "Find &Again Forward   \tF3"            find-text-again   ;
   MENUITEM      "Find Again &Backward  \tShft+F3"       back-find-text-again   ;
   MENUITEM      "Find &Highlight       \tCtrl+F3"       find-text-highlight ;
   MENUSEPARATOR
   MENUITEM      "Find &Text IN FILE(s)...\tCtrl+Shft+F" find-in-files ;
   MENUITEM ( rbs ) "&Edit Searchlist.txt"               searchlist-edit ;
   MENUSEPARATOR
   MENUITEM      "&Goto Line Number...  \tShft+Enter"    goto-line ;

 POPUP "&Macros"
   MENUITEM      "&New Key Recording File..."            new-macro ;
   MENUITEM      "&Start - Stop Key Recording \tCtrl+Shft+S" start/stop-macro ;
   MENUSEPARATOR
   MENUITEM      "&Edit Key File"                        edit-macro ;
   MENUITEM      "&Play Key File"                        play-macro ;
   MENUITEM      "&RePlay last Key File       \tF5"
                     replay-macro ;
   MENUITEM      "&Repeat Key File n times..  \tCtrl+Shft+R"
                     EditorWindow repeat-amacro ;

 POPUP "H&yper"
   MENUITEM   "&Link to a Word...               \tCtrl+Shft+F11"  word-link ;
   MENUITEM   "Link to &Highlighted Word        \tF10"           hyper-link ;
   MENUITEM   "Link to Next &Occurance of &Word \tF11+Shft"     next-link ;
   MENUITEM   "&UnLink to Previous Link         \tF12"          close-text ;
   MENUSEPARATOR
   MENUITEM   "&Previous Hyper Link             \tF11"           prev-link ;
   MENUITEM   "&Next Hyper Link                 \tF11+Shft"      next-link ;
   MENUSEPARATOR
   MENUITEM   "&Edit Hyper Link Configuration File"              hyper-edit ;
   MENUITEM   "&Build Hyper Link Index File"                   hyper-compile ;
            \ CD to the folder with wined cfg if it does not work.
SYS-WARNING-OFF


\ added a new menu "Win32Forth" and moved the entries regarding the forth
\ console from the other menues to it (dbu July 20th, 2003)
 POPUP "&Win32Forth"
   MENUITEM     "&Save and Load the active Forth Source\tF12" save-and-load ;
   MENUITEM     "&Load the active Forth Source\tCtrl+L"       load-active-file ;
   MENUITEM     "Load a Forth Source &File..."                load-forth-file ;
   MENUSEPARATOR
   MENUITEM     "Copy && &Paste to Win32Forth\tF11"           temp-text ;
   MENUSEPARATOR
   MENUITEM     "Display Debug &ButtonBar\tCtrl+D"             debug-buttons ;
   MENUITEM     "&Set a BreakPoint\tCtrl+B"                    debug-word ;

POPUP "&Help"                  \ jp
        MENUITEM   "&Win32Forth &Documentation \tF1"       w32f-doc ;
        MENUITEM   "&Get help for selected word \tCtrl+F1" word-help ;
   MENUSEPARATOR
        MENUITEM   "&Win-Ed DOS Commandline Help" show-command-help ;
   MENUSEPARATOR
        MENUITEM   "&About Win32Forth" about-Win32Forth ;
        MENUITEM   "&About Win-Ed"     about-wined ;
ENDBAR

SYS-WARNING-ON

: "OpenMenuFile ( a1 n1 -- )
                >E "+open-text ;

: _addFileMenu   ( -- )
               cur-filename 1+ ['] "OpenMenuFile InsertMenuItem: fileMenu ;

' _addFileMenu is addFileMenu

\ new February 29th, 2004 - 11:41 dbu
: LoadFileMenuEntries   ( -- ) \ load the file menu entries
        GetMaxCount: fileMenu 0
        ?DO  s" FileString "
             2dup + 1- 7 i - '0' + swap c!   \ append the count 0-7
             "GetDefault ?dup
             IF   \ we only add the file's which still exist
                  2dup FILE-STATUS nip 0=
                  IF   drop ['] "OpenMenuFile InsertMenuItem: fileMenu
                  ELSE 2drop
                  THEN
             ELSE drop
             THEN
        LOOP ;

\ new February 29th, 2004 - 11:41 dbu
: SaveFileMenuEntries   ( -- ) \ save the file menu entries
        GetCount: fileMenu GetMaxCount: fileMenu min 0
        ?DO  tempBuf i GetString: fileMenu
             tempBuf count  s" FileString "
             2dup + 1- i '0' + swap c!           \ append the count 0-7
             "SetDefault
        LOOP ;

