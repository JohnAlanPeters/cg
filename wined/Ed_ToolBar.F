\ $Id: Ed_ToolBar.F,v 1.2 2011/04/04 18:20:24 rdack Exp $
\    File: Ed_Toolbar.f
\  Author: Dirk Busch
\ Created: September 10th, 2003 - 12:20 dbu
\ Updated: September 10th, 2003 - 12:20 dbu
\ Toolbar for Win-Ed
\
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 51    Enhance the ToolBar class for Win-Ed
\       We need a special class, because of the extra status information
\       that is displayed in the toolbar, with the nice box around it.
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

0 value EditingButton

:Class WVToolBar <Super ToolBar

int offsetX
int offsetY

:M Floating:    ( -- f1 )
        floatBar
        ;M

: Bold  ( -- )
        Handle: bFont 0=                \ set font to bold
        IF    FW_BOLD Weight: bFont
                      Create: bFont
        THEN
        Handle: bFont SetFont: dc ;

: show-edit-mode ( -- )
        tool-bar? 0= floatBar 0= and ?EXIT
        min-tool-bar? ?EXIT
        GetHandle: self 0= ?EXIT
        LTGRAY  SetBkColor: dc
        12 StartSize: self nip border-width 2* -
        floatBar
        IF 20 -
        THEN
        4 / 3 *
        swap 14 + swap 7 -
        \ -- x y
        2dup
        edit-changed?
        if s" MODIFIED" else s"                   " then
        DkMagenta  SetTextColor: dc TextOut: dc
        (((
        browse?
        IF  s" Browse     " BmarginColor                        \ browsing
            SetTextColor: dc TextOut: dc
        ELSE
          overstrike @
          if s" OVERSTRIKE"          OmarginColor ( CYAN )
          else s" Insert        "    ImarginColor ( LTRED )
          then BOLD
            SetTextColor: dc TextOut: dc
            Handle: vFont SetFont: dc
        THEN
        )))
        3 - swap 11 - swap
        2dup           MoveTo: dc
        2dup 114  0 d+ LineTo: dc
        2dup 114 22 d+ LineTo: dc
        2dup   0 22 d+ LineTo: dc
        2dup           LineTo: dc
        DkGray      LineColor: dc
        2dup   1 20 d+ MoveTo: dc
        2dup   1  1 d+ LineTo: dc
        2dup 113  1 d+ LineTo: dc

        White       LineColor: dc
        2dup 113  1 d+ MoveTo: dc
        2dup 113 21 d+ LineTo: dc
        2dup   1 21 d+ LineTo: dc
        2drop ;

:M EditMode:    ( -- )
                tool-bar?
                IF      get-dc
                        show-edit-mode
                        release-dc
                THEN
                ;M

: vline         { offset color -- }
                color                           LineColor: dc
                offset 13                          MoveTo: dc \ vert
                offset StartSize: self nip border-width 2* -
                floatBar
                IF 20 -
                THEN
                4 -                                LineTo: dc ; \ line 

:M On_Paint:    ( -- )
                On_Paint: Super
                 4 WHITE vline
                 6 BLACK vline
                 8 WHITE vline
                10 BLACK vline
                show-edit-mode
                ;M

:M Close:       ( -- )
                Close: Super
                floatBar
                IF      FALSE to floatBar
                        0 0 SetOrigin: self
                        StartToolBar: EditorWindow
                        FALSE to floating-bar?
                THEN    Paint: self
                ;M

:M Float:       (  -- )
                floatBar 0=
                IF      CloseToolBar: EditorWindow
                        TRUE to floatBar
                        EditorWindow Start: self
                        min-tool-bar?
                        IF      StartPos: EditorWindow 54 - SetOrigin: self
                        ELSE    StartPos: EditorWindow 80 - SetOrigin: self
                        THEN
                        Update: self
                        TRUE to tool-bar?
                        LoadFindStrings
                        FALSE to tool-bar?
                        TRUE to floating-bar?
                        Paint: self
                ELSE    Floating: Win-EdToolbar
                        IF      Close: self
                        THEN
                THEN
                ;M

;Class
             
|Class TinyButton <Super PictureButton

:M ClassInit:   ( n1 -- )
                ClassInit: Super
                7 to bwidth
                7 to bheight
                ;M

;Class


\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 52    Define the large ToolBar for the application
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

WVToolBar max-Edit-Tool-Bar "WINED.BMP"  \ Close all instances of Forth
\ and then it willwork.  Also Fload from the proper directory
\ currently it is  win32for

max-Edit-Tool-Bar to max-toolbar
        3 HSpace
    22 TinyButton    Float: Win-EdToolbar ;
        ButtonInfo"  Float ToolBar toggle "
        5 HSpace
     0 PictureButton                    new-text        ; \ new
        ButtonInfo"  New Text File  (Ctrl+N) "
     1 PictureButton                    open-text       ; \ open
        ButtonInfo"  Open Text File  (Ctrl+O) "
     2 PictureButton                    save-text       ; \ save
        ButtonInfo"  Save Text File  (Ctrl+S) "
    21 PictureButton                    save-all-text   ; \ save all files
        ButtonInfo"  Save All Changed Files "
     4 PictureButton                    close-text      ; \ close
        ButtonInfo"  Close Text File  (Ctrl+W) "

        8 HSpace
     3 PictureButton print-text  ;   \ print   ** not doing this any more -> TRUE to direct-print?
        ButtonInfo"  Print File  (Ctrl+P) "

        8 HSpace
     6 PictureButton                    cut-text        ; \ cut
        ButtonInfo"  Cut Text  (Ctrl+X) "
     7 PictureButton                    copy-text       ; \ copy
        ButtonInfo"  Copy Text  (Ctrl+C) "
     8 PictureButton                    paste-text      ; \ paste
        ButtonInfo"  Paste Text  (Ctrl+V) "

DefToolWidth DefToolSpacing + HSpace
        8 HSpace
        8 HSpace
    13 PictureButton     hyper-link      ; \ hyper link
        ButtonInfo"  Hyper Link to: Highlighted Word  (Ctrl+Shft+F9) "
    16 PictureButton next-hyper-link RefreshCursor: DocWindow ShowCursor: DocWindow ;
        ButtonInfo"  Hyper Link to: Next Occurance of Word  (Ctrl+F9) "
        8 HSpace
    14 PictureButton prev-link RefreshCursor: DocWindow ShowCursor: DocWindow ;
        ButtonInfo"  Previous File or  (Ctrl+PgUp) \n Previous Hyper Link "
    15 PictureButton next-link RefreshCursor: DocWindow ShowCursor: DocWindow ;
        ButtonInfo"  Next File or  (Ctrl+PgDn) \n Next Hyper Link "

        8 HSpace
    20 PictureButton     debug-word      ; \ Debug Forth
        ButtonInfo"  Set a Break Point (Ctrl+B) \n in Win32Forth "
    19 PictureButton                    text-options    ; \ Preferences
        ButtonInfo"  WinEd Preferences  (Ctrl+Shft+P) "

        8 HSpace
     5 PictureButton   ( rbbs )            s" doc\p-getstart.htm"
     Prepend<home>\ "browse ; ButtonInfo"  Help me get started  (F1) "
        5 HSpace

        -1 HSpace                       \ split the ToolBar into two lines

       14 HSpace

DefToolWidth DefToolSpacing + 5 * HSpace
        8 HSpace
    17 PictureButton                    find-in-files   ; \ find in files
        ButtonInfo"  Find Text in Files...  (Ctrl+Shft+F) "

        8 HSpace
     9 PictureButton                    replace-text    ; \ find
        ButtonInfo"  Find - Replace Text... \n (Ctrl+F) or (Ctrl+Shft+F3) "
    11 PictureButton                find-text-highlight ; \ find highlight
        ButtonInfo"  Find Highlighted Text Forward  (Ctrl+F3) "

        8 HSpace
    12 PictureButton               back-find-text-again ; \ find again back
        ButtonInfo"  Find Text Again Backward  (Shft+F3) "
    10 PictureButton                    find-text-again ; \ find again
        ButtonInfo"  Find Text Again Forward  (F3) "

        8 HSpace
                                  \ "findCombo" is used to manipulate the list
DefToolWidth DefToolSpacing + 8 * ComboField findCombo
        ButtonInfo"  Find Text "
        250 SetHeight: findCombo
        findCombo to findComboEdit     \ link for forward reference

        5 HSpace

ENDBAR

\ save away find text and perform search when user presses ENTER
: myWmChar      ( h m w l obj -- res )
        2 pick VK_RETURN  =             \ if return
        IF      >r GetText: [ r@ ]      \ get adr,len of edit control text
                "CLIP" find-buf place   \ save string in find buffer
                find-text-again         \ search for it
                SetFocus: [ r> ]        \ retain the focus
                FALSE                   \ we already processed this message
        ELSE
                drop                    \ discard object
                TRUE                    \ and use default processing
        THEN    ;

' myWmChar SetWmChar: findCombo

\ - Save away find text and perform search when user presses F3
\ - Move Focus to DocWindow when user presses ESC
\ Changed May 19th, 2003 - 18:16 dbu
: myWmKeyDown   ( h m w l obj -- res )
        2 pick VK_F3  =                 \ if F3
        IF      GetText: [ ]            \ get adr,len of edit control text
                "CLIP" find-buf place   \ save string in find buffer
                ?shift                  \ if we have the shift key
                IF      back-find-text-again
                ELSE    find-text-again \ search for it
                THEN
                FALSE                   \ we already processed this message
        ELSE
                2 pick VK_ESCAPE =          \ if ESC
                if      SetFocus: DocWindow \ move Focus to doc window
                        drop                \ discard object
                        false               \ we already processed this message
                else    drop            \ discard object
                        true            \ and use default processing
                then
        THEN    ;

' myWmKeyDown SetWmKeyDown: findCombo

\ save the find text away when the combo box gets a WM_KILLFOCUS message
: myWmKillFocus   ( h m w l obj -- res )
        GetText: [ ]                    \ get adr,len of edit control text
        "CLIP" find-buf place           \ save string in find buffer
        TRUE ;                          \ and use default processing

' myWmKillFocus SetWmKillFocus: findCombo

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 52a   Define the smale ToolBar for the application
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

WVToolBar min-Edit-Tool-Bar "WINED.BMP"     \ jap ????
        3 HSpace
    22 TinyButton    Float: Win-EdToolbar ;
        ButtonInfo"  Float ToolBar toggle "
        5 HSpace
     0 PictureButton                    new-text        ; \ new
        ButtonInfo"  New Text File  (Ctrl+N) "
     1 PictureButton                    open-text       ; \ open
        ButtonInfo"  Open Text File  (Ctrl+O) "
     2 PictureButton                    save-text       ; \ save
        ButtonInfo"  Save Text File  (Ctrl+S) "
    21 PictureButton                    save-all-text   ; \ save all files
        ButtonInfo"  Save All Changed Files "
     4 PictureButton                    close-text      ; \ close
        ButtonInfo"  Close Text File  (Ctrl+W) "

\ DefToolWidth DefToolSpacing + HSpace
        8 HSpace
        8 HSpace
        8 HSpace
    17 PictureButton                    find-in-files   ; \ find in files
        ButtonInfo"  Find Text in Files...  (Ctrl+Shft+F) "

\ DefToolWidth DefToolSpacing + HSpace
        8 HSpace
        8 HSpace
        8 HSpace
     9 PictureButton                    replace-text    ; \ find
        ButtonInfo"  Find - Replace Text... \n (Ctrl+F) or (Ctrl+Shft+F3) "
    11 PictureButton                find-text-highlight ; \ find highlight
        ButtonInfo"  Find Highlighted Text Forward  (Ctrl+F3) "

        8 HSpace
    12 PictureButton               back-find-text-again ; \ find again back
        ButtonInfo"  Find Text Again Backward  (Shft+F3) "
    10 PictureButton                    find-text-again ; \ find again
        ButtonInfo"  Find Text Again Forward  (F3) "

\ DefToolWidth DefToolSpacing + HSpace
        8 HSpace
        8 HSpace
        8 HSpace
    19 PictureButton                    text-options    ; \ Preferences
        ButtonInfo"  WinEd Preferences  (Ctrl+Shft+P) "

        8 HSpace
     5 PictureButton    ( rbbs )           s" doc\p-getstart.htm"

     Prepend<home>\ "browse ; ButtonInfo"  Help me get started  (F1) "
        5 HSpace

ENDBAR

