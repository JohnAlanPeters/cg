\ $Id: Ed_FrameWindowObj.F,v 1.6 2011/07/21 05:57:28 rdack Exp $

needs Resources.f

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 58    Define the main window for the application
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

0 value err-vocab-show
defer HandleForthMsg

:Object FrameWindow  <super window

Rectangle EditRect
Rectangle ClientRect

MAXSTRING bytes StatusBuf

: abs-create-frame-window  ( -- hwnd )
        0 0                                 \ adjust x,y relative to zero, zero
        StartSize:     [ self ]             \ width, height
        SetRect: EditRect
        ^base                               \ creation parameters
        appInst                             \ program instance
        NULL LoadMenu: [ self ]             \ menu
        ParentWindow:  [ self ]             \ parent window handle
        Bottom: EditRect Top: EditRect -    \ adjusted height
        Right: EditRect Left: EditRect -    \ adjusted  width
        StartPos:      [ self ] swap        \ y, x starting position
        WindowStyle:   [ self ]             \ the window style
        WindowTitle:   [ self ]             \ the window title
        WindowClassName 1+                  \ class name
        ExWindowStyle: [ self ]             \ extended window style
        Call CreateWindowEx
        EraseRect: EditRect ;

:M DefaultIcon: ( -- hIcon )  \ return the default icon handle for window
                LoadAppIcon ;M

:M Start:       ( -- )          \ create a new window object
        hWnd 0=
        IF      s" EditorWindow" SetClassName: self \ set the class name
                default-window-class
                \ over-ride the default background (WHITE) color
                NULL to hbrBackground
                register-the-class drop
                abs-create-frame-window to hWnd
                SW_SHOWNORMAL Show: self
                Update: self
        ELSE    SetFocus: self
        THEN
        ;M

MACRO -status   " 19 -"         ( n1 -- n2 )

0 value vdraging?
0 value hdraging?

: in-hdrag?     ( -- f1 )       \ in horizontal drag bar
        hWnd get-mouse-xy       \ -- x y ;mouse position
        edit-top Height -status between swap
        drag-barH dup drag-thick + 2 +  between and ;

\ mouse click routines for FrameWindow to track the dragbar movement

: MheditW-track ( -- )
        mousedown? 0= ?EXIT
        vdraging?
        IF      mousey drag-thick 2/ - Height drag-thick 2 + -
                -status 1 - 0max min
\                 drag-barV edit-top listHeightDefault + <= Hide: Subjectlist
        THEN
        hdraging?
        IF      mousex drag-thick 2/ - 0max Width edit-min - 0max min
                0max to drag-barH
        THEN
        Showing: SubjectList
        IF      0 edit-top drag-barH 1- 160 Move: SubjectList
        THEN
        Refresh: EditorWindow
        WINPAUSE ;

: MheditW-click ( -- )
        mousedown? 0=
        IF      hWnd Call SetCapture drop
        THEN
        true to mousedown?
        in-hdrag?  to hdraging?
        MheditW-track ;

: MheditW-unclick ( -- )
        mousedown?
        IF      Call ReleaseCapture drop
        THEN
        false to mousedown?
        false to vdraging?
        false to hdraging? ;

: dbl-click-hdrag ( -- )
        in-hdrag? 0= ?EXIT
        drag-barH 8 >
        IF      0 to drag-barH
        ELSE    132 Width 2/ min to drag-barH
        THEN
        Showing: SubjectList
        IF      0 edit-top drag-barH 1- 160 Move: SubjectList
        THEN    ;

: MheditW-dblclick ( -- )       \ highlight the current word
        false to mousedown?
        mousey StartSize: Win-EdToolbar nip < ?EXIT
        dbl-click-hdrag
        SetFocus: DocWindow
        Refresh: EditorWindow ;

:M Classinit:   ( -- )
        ClassInit: super                \ init super class
                     3 to OriginX
                     3 to OriginY
                  self to EditorWindow \ make myself the cur window
         8                Width: sFont
        14               Height: sFont
        s" Courier" SetFaceName: sFont  \ default to Courier
        min-Edit-Tool-Bar  to Win-EdToolbar
        ['] MheditW-click       SetClickFunc: self
        ['] MheditW-unclick   SetUnClickFunc: self
        ['] MheditW-track       SetTrackFunc: self
        ['] MheditW-dblclick SetDblClickFunc: self
        ;M

:M On_Init:     ( -- )          \ initialize the class
      On_Init: super            \ first init super class
      Create: sFont             \ create the font for file list

      min-tool-bar?
      IF    min-Edit-Tool-Bar  to Win-EdToolbar
      ELSE  max-Edit-Tool-Bar  to Win-EdToolbar
      THEN
      tool-bar?
      IF      3    SetId: Win-EdToolbar       \ then the next child window
              self Start: Win-EdToolbar       \ then startup child window
      THEN
      edit-top SetTopOf: EditWindow           \ set the edit window's top
      4    SetId: EditWindow                  \ then the child window
      self Start: EditWindow                  \ then startup child window
      5    SetId: SplitterH
      self Start: SplitterH
      self Start: SubjectList
      FilesList  InitSubject: SubjectList     \ we start with files subject
      self Start: Win-EdStatusbar             \ start the status bar
      window-list
      BEGIN   dup @ ?dup
      WHILE   >r
              self Start: [ r@ ]
              TRUE  Hide: [ r> ]
              cell+
      REPEAT  DROP
      FALSE Hide: FilesList
      FALSE Hide: Subjectlist         \ then hide SubjectList
      Edit-Menu-Bar  SetMenuBar: self
      min-ToolBar-Popup-bar SetPopupBar: min-Edit-Tool-Bar
      max-ToolBar-Popup-bar SetPopupBar: max-Edit-Tool-Bar
      Edit-Popup-Bar SetPopupBar: EditWindow
      ;M

: set-col/rows  { theWindow -- }
        entry# >r
        GetHandle: theWindow
        IF      GetStack: theWindow to entry#
                screen-cols >r
                     Width: theWindow
                 CharWidth: theWindow / to screen-cols
                    Height: theWindow
                CharHeight: theWindow / to screen-rows
                r> screen-cols 2dup <
                IF      2dup - col-cur + 0max to col-cur
                THEN    2drop
        THEN    r> to entry#  ;

: adjust-col/rows ( -- )
        EditWindow    set-col/rows
        ;

:M SetMultiStatus: ( a1 n1 a2 n1 -- ) \ set the current text on statusbar

        SetMulti: Win-EdStatusbar \ set statusbar to show multiparts

        s"  Column: "                                   StatusBuf  place
        cursor-col     0 <# #s #>                       StatusBuf +place
        s"  of "                                        StatusBuf +place
        max-cols       0 <# #s #>                       StatusBuf +place
        StatusBuf +null StatusBuf 1+ 0 SetText: Win-EdStatusbar

        s"  Line: "                                     StatusBuf  place
        cursor-line    0 (ud,.)                         StatusBuf +place
        s"  of "                                        StatusBuf +place
        file-lines     0 (ud,.)                         StatusBuf +place
        StatusBuf +null StatusBuf 1+ 1 SetText: Win-EdStatusbar

        s"  Size: "                                     StatusBuf  place
        text-length    0 (ud,.)                         StatusBuf +place
        s"  Characters"                                 StatusBuf +place
        lend-len 0=
        IF      s" ("                                   StatusBuf  place
                text-length BLOCK-SIZE   /mod 0 (ud,.)  StatusBuf +place
                s"  Blocks, "                           StatusBuf +place
                BLOCKLINE-SIZE           /mod 0 (ud,.)  StatusBuf +place
                s"  Lines, "                            StatusBuf +place
                                              0 (ud,.)  StatusBuf +place
                s"  Chars) "                            StatusBuf +place
        THEN
        StatusBuf +null StatusBuf 1+ 2 SetText: Win-EdStatusbar
        StatusBuf 80 blank
        overstrike @
        if   s"  Overstrike mode"   \ JP 4-4-09
        else s"  INSERT MODE" then               StatusBuf  place
        capslock? if s"   CAPS LOCK" StatusBuf +place then
        autoextend if s"   Auto Extend On" else s"   Auto Extend Off" then StatusBuf +place
        err-vocab-show if s"   Vocdump On" else s"   Vocdump Off" then StatusBuf +place
        StatusBuf +null StatusBuf 1+ 3 SetText: Win-EdStatusbar
        ;M

:M SetSimpleStatus: ( a1 n1 a2 n1 -- ) \ set the current text on statusbar

        SetSingle: Win-EdStatusbar \ set statusbar to show single-part

        StatusBuf  place
        StatusBuf +place
        StatusBuf +null StatusBuf 1+ 0 SetText: Win-EdStatusbar
        ;M

:M Refresh:     ( -- )
      minimized? 0=
      IF      drag-barH Width edit-min - 0max min to drag-barH

              edit-top        SetTopOf: EditWindow

(( The peculiar calculations for window positions and sizes, result from the
   fact that Windows places windows "inside" of the window space specified, and
   was thus leaving unrefreshed lines between all my child windows if I didn't
   fill in the space with an extra pixel here and there.
   tjz February 24th, 1997
))
              all-lines: EditWindow
              drag-barH drag-thick + 1+
              edit-top
              Width drag-barH drag-thick + -
              Height edit-top - -status
              Move: EditWindow
              window-list
              BEGIN   dup @ ?dup
              WHILE   >r
                      Showing: [ r@ ]
                      IF      0 edit-top listHeight + dup>r
                              drag-barH 1-
                              Height r> -   -status
                              Move: [ r@ ]
                      THEN    r>drop
                      cell+
              REPEAT  drop

              drag-barH 1- edit-top 1-
              drag-thick 2 +
              Height edit-top - 2 +         -status
              Move: SplitterH

              Showing: SubjectList
              IF      0 edit-top drag-barH 1- 160   -status Move: SubjectList
              THEN

              adjust-col/rows
        THEN
        ;M

:M StartToolBar: ( -- )
        tool-bar? 0=
        Floating: Win-EdToolbar 0= and
        IF      TRUE to tool-bar?
                self Start: Win-EdToolbar          \ then startup child window
                LoadFindStrings
                Refresh: self
        ELSE    tool-bar? 0=                       \ if flagged as not open
                Floating: Win-EdToolbar and        \ but flagged as floating
                IF      SetFocus: Win-EdToolbar    \ then bring to front
                THEN
        THEN
        ;M

:M CloseToolBar: ( -- )
        tool-bar? Floating: Win-EdToolbar or
        IF      SaveFindStrings
                Close: Win-EdToolbar
                FALSE to tool-bar?
                Refresh: self
        THEN
        ;M

:M SwitchToolBar: ( -- )
        Floating: Win-EdToolbar >r
        CloseToolBar: self
        Win-EdToolbar max-Edit-Tool-Bar =
        IF      min-Edit-Tool-Bar  to Win-EdToolbar
                TRUE to min-tool-bar?
        ELSE    max-Edit-Tool-Bar  to Win-EdToolbar
                FALSE to min-tool-bar?
        THEN
        StartToolBar: self
        r>
        IF      Float: Win-EdToolbar
        THEN
        ;M

:M On_Done:     ( h m w l -- res )
        Delete: sFont
        0 call PostQuitMessage drop     \ terminate application
        On_Done: super                  \ cleanup the super class
        0 ;M

:M WM_CLOSE     ( h m w l -- res )
        before-bye
        term-canceled? 0=               \ if we didn't cancel the close
        IF      bye                     \ then just terminate the program
                0
        ELSE    1                       \ abort program termination
                FALSE to term-canceled?
        THEN
        ;M

:M StartSize:   ( -- width height )     \ starting window size
        start-width
        SM_CXSCREEN Call GetSystemMetrics  4 -
        StartPos: self drop - min               \ screen width
        start-height
        SM_CYSCREEN Call GetSystemMetrics  4 -
        StartPos: self nip  - min               \ screen height
        ;M

:M StartPos:    ( -- x y )
        OriginX 0max OriginY 0max
        ;M

:M MinSize:     ( -- width height )     \ minimum window size
        0 -20
        ;M

:M WindowTitle: ( -- Zstring )          \ window caption
        z" Win-Ed"
        ;M

:M On_Paint:    ( -- )
        On_Paint: super
        tool-bar?
        IF
                0 0  StartSize: Win-EdToolbar  Move: Win-EdToolbar
                LTGRAY_BRUSH Call GetStockObject
                StartSize: Win-EdToolbar drop 0        \ x,y origin
                Width
                StartSize: Win-EdToolbar nip 1+ SetRect: EditRect
                AddrOf: EditRect GetHandle: dc call FillRect ?win-error
                WHITE                                LineColor: dc \ white color
                Left: EditRect Top: EditRect            MoveTo: dc \ horiz
                StartSize: self drop Width max 0        LineTo: dc \ line
                BLACK                                LineColor: dc
                Left: EditRect Bottom: EditRect 2 - dup>r MoveTo: dc \ horiz
                StartSize: self drop Width max r>       LineTo: dc \ line
                EraseRect: EditRect
        THEN
        ListHeight      \ Only if SubjectList is turned on
        IF      \ line below the subject selection dropdown list
                BLACK                                LineColor: dc
                0 edit-top listHeight + 2 -             MoveTo: dc
                drag-barH  edit-top listHeight + 2 -    LineTo: dc
                WHITE                                LineColor: dc
                0 edit-top listHeight + 1-              MoveTo: dc
                drag-barH  edit-top listHeight + 1-     LineTo: dc
        THEN
        ;M

:M WM_SETCURSOR ( h m w l -- )
        EraseRect: ClientRect                \ init to zeros
        AddrOf: ClientRect GetClientRect: self
        hWnd get-mouse-xy
             Top: ClientRect  Bottom: ClientRect between
        swap Left: ClientRect Right: ClientRect  between and
        IF      false
                IF      splitv-cursor 1
                ELSE    in-hdrag?
                        IF      splith-cursor 1
                        ELSE    arrow-cursor 1
                        THEN
                ELSE    DefWindowProc: [ self ]
                THEN
        ELSE    DefWindowProc: [ self ]
        THEN
        1 ;M

:M ReTitle:     { \ title$ pad$ -- }
        LMAXSTRING localAlloc: title$
                32 localAlloc: pad$

        pad 32 - pad$ 32 move  \ save PAD
        entry# >r \ save entry

        GetStack: EditWindow to entry#
        Edname$  count   title$ lplace
        (.wined_version) title$ +lplace
        s"  - "          title$ +lplace
        from-web?
        IF   URL$ lcount        title$ +lplace
        ELSE cur-filename count title$ +lplace
        THEN
        title$ lcount 255 min SetTitle: self
                              EditMode: Win-EdToolbar

        \ update statusbar
        SetMultiStatus: EditorWindow

        r> to entry# \ restore entry
        pad$ pad 32 - 32 move \ restore PAD
        ;M

:M WinEdMessageBox:  ( szText szTitle style -- result )
        MB_TASKMODAL or 3reverse
        ( hWnd ) NULL Call MessageBox
        ;M

\ the l parameter has already been removed by WINDOW.F, and put
\ into Height and Width
:M On_Size:     ( h m w -- )                  \ handle resize message
        dup SIZE_MINIMIZED = to minimized?      \ w is sub-message
        Redraw: Win-EdStatusbar
        Refresh: self
        ;M

:M ReSize:      ( -- )
        entry# >r
        GetStack: EditWindow to entry#
         Width: EditWindow  CharWidth: EditWindow / to screen-cols
        Height: EditWindow CharHeight: EditWindow / 1- to screen-rows
        Paint: self
        r> to entry#
        ;M

:M On_SetFocus: ( h m w l -- )
        On_SetFocus: super
        SetFocus: edit-window
        ;M

:M On_KillFocus: ( h m w l -- )
        On_KillFocus: super
        ;M

: reflect-window { wparam \ theWindow -- WID }  \ return ID of reflected window
        window-list
        BEGIN   dup @ dup to theWindow
        WHILE   Showing: theWindow
                IF      wparam LOWORD ( ID ) GetID: theWindow =
                        IF      DROP    \ May 9th, 1998 tjz added DROP
                                theWindow
                                EXIT
                        THEN
                THEN    cell+
        REPEAT  drop
        FALSE   ;

:M WM_COMMAND   { hwnd msg wparam lparam -- res }
        wparam reflect-window ?dup
        IF      \ if message is from a listbox, then reflect it
                \ back to the listbox for processing

                >r hwnd msg wparam lparam WM_COMMAND WM: [ r> ]

        ELSE       hwnd msg wparam lparam WM_COMMAND WM: Super

                \ We must send others to 'Super', so that keyboard
                \ processing will work properly, since 'Super'
                \ handles keyboard WM_COMMAND messages
        THEN
        ;M

:M WM_COPYDATA  ( hndl msg wParam lParam -- result ) \ respond to Win32Forth messages
                HandleForthMsg ;M

:M WM_SYSCOMMAND ( hwnd msg wparam lparam -- res )
                \ All SC_xxxx command types always have the high nibble set to 0xF
                over 0xF000 and 0xF000 <>
                IF      over LOWORD
                        DoMenu: CurrentMenu
                        0
                ELSE    DefWindowProc: [ self ]
                THEN    ;M

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 59    Support for Drag and Drop files from File Manager to Win-Ed
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

:M ExWindowStyle: ( -- )
        ExWindowStyle: super
        WS_EX_ACCEPTFILES or            \ allow files to be dropped on WinEd
        WS_EX_OVERLAPPEDWINDOW or
        ;M

:M WM_DROPFILES { hndl message wParam lParam \ cFiles drop$ -- res }
        MAXSTRING LocalAlloc: drop$
        >E
        SetForegroundWindow: self
        0
        NULL
        -1
        wParam                          \ HDROP structure
        Call DragQueryFile to cFiles    \ -- count of files dropped
        RefreshOff: EditWindow
        FALSE defext_on? dup @ >r !     \ save, but reset the default extension
                                        \ addition
        cFiles 0
        ?DO     MAXCOUNTED
                drop$ 1+
                i
                wParam
                Call DragQueryFile drop$ c!
                drop$ count "+open-text
        LOOP
        r> defext_on? !                 \ restore the default extension additon
        wParam Call DragFinish drop
        RefreshOn: EditWindow
        ;M
