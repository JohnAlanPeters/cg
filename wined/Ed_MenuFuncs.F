\ $Id: Ed_MenuFuncs.F,v 1.1 2011/03/19 23:26:04 rdack Exp $
\
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 43    Select Font and Size dialog
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

:Object TextSizeDlg  <Super  dialog

MAXSTRING bytes textfont$

IDD_SIZE WinEdit find-dialog-id constant template

:M ClassInit:   ( -- )
        ClassInit: super
        ;M

: "add-font     { hadr hlen lplf \ message$ -- }
      MAXSTRING localAlloc: message$
      hadr hlen message$ place
      lplf to lplf
      lplf 27 + c@ 3 and 3 and FIXED_PITCH =
      IF    lplf 28 + LF_FACESIZE 2dup 0 scan nip - message$ +place
                                                    message$ +NULL
                                                    message$ 1+
            0 LB_ADDSTRING ID_TEXTFONT SendDlgItemMessage: self drop
            message$ count 1+ GetFaceName: vFont compare 0=
            IF    0 0    LB_GETCOUNT  ID_TEXTFONT SendDlgItemMessage: self 1-
                  0 swap LB_SETCURSEL ID_TEXTFONT SendDlgItemMessage: self drop
            THEN
      THEN ;

: add-1font     { lplf lptm dwType lpData -- int }
        dwType
        CASE
                DEVICE_FONTTYPE   OF s" Device Font: "   lplf "add-font ENDOF
                RASTER_FONTTYPE   OF s" Raster Font: "   lplf "add-font ENDOF
                TRUETYPE_FONTTYPE OF s" TrueType Font: " lplf "add-font ENDOF
        ENDCASE
        1 ;

4 callback GetFontsFunc add-1font

: highlight-cur-font { \ font$ -- }
                64 LocalAlloc: font$
                0 0    LB_GETCOUNT  ID_TEXTFONT SendDlgItemMessage: self
                0
                ?DO     font$ dup
                        i LB_GETTEXT ID_TEXTFONT SendDlgItemMessage: self
                        ':' scan bl scan bl skip GetFaceName: vFont compare 0=
                        IF      0 i LB_SETCURSEL ID_TEXTFONT
                                SendDlgItemMessage: self drop
                                leave
                        THEN
                LOOP    ;

: add-fonts     ( -- )
        0 0 LB_RESETCONTENT ID_TEXTFONT SendDlgItemMessage: self drop
        GetDC: DocWindow >r
        0
        GetFontsFunc
        0
        r@                              \ the DocWindow's DC
        Call EnumFonts drop
        r> ReleaseDC: DocWindow ;

:M GetFont:     { \ csel -- a1 n1 }
        textfont$ off
        0 0 LB_GETCURSEL  ID_TEXTFONT SendDlgItemMessage: self to csel
        csel 0<
        IF      s" Courier"
        ELSE    textfont$ csel
                LB_GETTEXT ID_TEXTFONT SendDlgItemMessage: self
                \ -- a1 n1 skip two words
                textfont$ swap bl skip bl scan bl skip bl scan bl skip
        THEN
        ;M

create size-table 21 ,
        06008 , 07009 , 07012 , 08008 , 08010 , 08012 , 08014 , 08016 ,
        09012 , 09015 , 09018 , 10014 , 10016 , 10018 , 12015 , 12018 ,
        16024 , 32048 , 64072 , 72096 , 96128 ,

: add-size      { size# \ message$ pad$ -- }
        64 localAlloc: message$
        32 localAlloc: pad$
        pad 32 - pad$ 32 move                   \ save contents of PAD
        size# 1+ size-table +cells @ 1000 /mod  \ -- height width
        0 <# #s #>     message$  place
        s"  x "        message$ +place
        0 <# #s #>     message$ +place
                       message$ +NULL
                       message$ 1+
        0 LB_ADDSTRING ID_TEXTSIZE SendDlgItemMessage: self drop
        pad$ pad 32 - 32 move ;                 \ restore PAD

:M On_Init:     ( hWnd-focus -- f )
        0 0 LB_RESETCONTENT ID_TEXTSIZE SendDlgItemMessage: self drop
        size-table @ 0
        DO      i add-size
        LOOP
        size-table lcount NIP 0 \ May 4th, 1998 added NIP, adr not needed
        ?DO     size-table i 1+ cells+ @ 1000 mod char-height =
                IF      0 i LB_SETCURSEL ID_TEXTSIZE
                        SendDlgItemMessage: self drop
                        LEAVE
                THEN
        LOOP
        add-fonts
        highlight-cur-font
        1 ;M

:M GetTemplate: ( -- template )
                template
                ;M

:M GetFont/Size: ( -- )
        0 0 LB_GETCURSEL  ID_TEXTSIZE SendDlgItemMessage: self
        size-table @ over >
        IF      1+ size-table +cells @ 1000 /mod to char-width to char-height
                #fonts 0
                DO      font-list i cells+ @ >r
                        char-width              Width: [ r@ ]
                        char-height            Height: [ r@ ]
                        GetFont: self     SetFaceName: [ r@ ]
                                               Create: [ r> ]
                LOOP
                GetWindowDC:   self PutHandle: screenDC
                Handle: vFont    SelectObject: screenDC drop
                s" #" ( JUST A CHARACTER ) GetTextExtent: screenDC
                to the-height  to the-width
                GetHandle: screenDC ReleaseDC: self
                ReSize: EditorWindow
                Paint: DocWindow
        ELSE    drop
        THEN
        ;M

: do-font/size-box   ( select_message -- )
        CASE
                LBN_DBLCLK    OF   GetFont/Size: self
                                   0 end-dialog         ENDOF \ dbl click
                LBN_SELCHANGE OF   GetFont/Size: self   ENDOF \ select font/size
        ENDCASE ;

:M On_Command:  ( hCtrl code ID -- f1 ) \ returns 0=cancel,
                                        \ returns 1=option-off
                                        \ returns 2=option-on
        CASE
                IDOK        OF     GetFont/Size: self
                                   0     end-dialog        ENDOF   \ set size
                IDCANCEL    OF     GetFont/Size: self
                                   0     end-dialog        ENDOF   \ cancel size
                ID_TEXTSIZE OF     do-font/size-box        ENDOF
                ID_TEXTFONT OF     do-font/size-box        ENDOF
                false swap ( default result )
        ENDCASE ;M

;Object

: text-size     ( -- )
                bitImage? ?EXIT
                EditorWindow Start: TextSizeDlg drop
                SetFocus: DocWindow ;

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 44    Win-Ed Preferences dialog
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

named-new$ filter-save

: set-filter    { \ filter$ -- }
                MAXSTRING localAlloc: filter$
                defext$ count 2dup upper s" F" compare
                IF      defext$ count     filter$  place
                        s"  Files (*."    filter$ +place
                        defext$ count     filter$ +place
                        s" )|*."          filter$ +place
                        defext$ count     filter$ +place
                        s" |"             filter$ +place
                        filter-save count filter$ +place
                                          filter$  count
                ELSE    filter-save count
                THEN    SetFilter: ViewText ;

:Object OptionsDlg  <Super  dialog

IDD_OPTIONS WinEdit find-dialog-id constant template

:M ClassInit:   ( -- )
                ClassInit: super
                ;M

:M GetTemplate: ( -- template )         \ each dialog MUST have this method
                template
                ;M

:M On_Init:     ( hWnd-focus -- f )
        tool-bar? Floating: Win-EdToolbar or
                                 IDB_TOOLBAR     CheckDlgButton: self
        min-tool-bar? 0=         IDB_FULL        CheckDlgButton: self
        save-find?               IDB_SAVEFIND    CheckDlgButton: self
        WinEd-web?               IDB_WEB         CheckDlgButton: self
        save-margin?             IDB_SAVEMARGIN  CheckDlgButton: self
        colorize?                IDB_COLORIZE    CheckDlgButton: self
        open-previous?           IDB_OPENPROMPT  CheckDlgButton: self
        page-lines?              IDB_PAGELINES   CheckDlgButton: self
        border?                  IDB_BORDER      CheckDlgButton: self
        recent-files?            IDB_RECENTFILES CheckDlgButton: self
        defext$ count            IDE_EXT         SetDlgItemText: self
        tab-size          0 (d.) IDE_TAB         SetDlgItemText: self
        save-minutes      0 (d.) IDE_MIN         SetDlgItemText: self
        printed-columns   0 (d.) IDE_COLS        SetDlgItemText: self
        printer-lpi       0 (d.) IDE_LPI         SetDlgItemText: self
        search-path count        IDE_PATH        SetDlgItemText: self
        def-right-edge    0 (d.) IDE_WRAP        SetDlgItemText: self
        1 ;M

: skip-number?  ( a1 n1 -- n2 f1 )      \ single precision number conversion
                                        \ discards leading & trailing blanks
        bl skip -trailing number? nip ;

: get-options   { \ number$ -- }
        64 localAlloc: number$
        \ added new clipping to DEFEXT$, for new max length of 16 chars
        defext$ 1+ DEFEXTMAX IDE_EXT  GetDlgItemText: self defext$ c!
        defext$ count '.' scan dup  \ remove any leading decimal point
        IF      1 /string DEFEXTMAX min defext$ place
                \ May 6th, 1998 - 17:53 tjz added 'ELSE 2DROP' per bjg
        ELSE    2drop
        THEN
        set-filter
        search-path 1+ MAXCOUNTED IDE_PATH  GetDlgItemText: self search-path c!
        search-path count + 1- c@ '\' =
        IF      search-path c@ 1- 0max search-path c!     \ remove trailing '\' char
        THEN
        number$ dup 6  IDE_WRAP  GetDlgItemText: self skip-number?
        IF      dup 0<>
                IF      low-right-edge max "LCLIP"
                THEN    dup to right-edge to def-right-edge
        ELSE    drop
        THEN
        number$ dup 6  IDE_TAB   GetDlgItemText: self skip-number?
        IF      0max 32 min to tab-size
                tab-size SetTabSize: ThePrinter
        ELSE    drop
        THEN
        number$ dup 6  IDE_MIN   GetDlgItemText: self skip-number?
        IF      0 max 60 min to save-minutes
        ELSE    drop
        THEN
        number$ dup 6  IDE_LPI   GetDlgItemText: self skip-number?
        IF      3 max 12 min to printer-lpi
        ELSE    drop
        THEN
        number$ dup 6  IDE_COLS   GetDlgItemText: self skip-number?
        IF      30 max 230 min to printed-columns
        ELSE    drop
        THEN

        IDB_SAVEFIND    IsDlgButtonChecked: self 0<> to save-find?
        IDB_WEB         IsDlgButtonChecked: self 0<> to WinEd-web?
        IDB_SAVEMARGIN  IsDlgButtonChecked: self 0<> to save-margin?
        IDB_COLORIZE    IsDlgButtonChecked: self 0<> to colorize?
        IDB_OPENPROMPT  IsDlgButtonChecked: self 0<> to open-previous?
        IDB_PAGELINES   IsDlgButtonChecked: self 0<> to page-lines?
        page-lines? 0= to print-extended-lines
        IDB_BORDER      IsDlgButtonChecked: self 0<> to border?
        IDB_RECENTFILES IsDlgButtonChecked: self 0<> to recent-files?
        IDB_FULL        IsDlgButtonChecked: self 0=  to min-tool-bar?
        min-tool-bar? 0=
        Win-EdToolbar max-toolbar = XOR
        tool-bar? Floating: Win-EdToolbar OR AND
        IF      SwitchToolBar: EditorWindow
        THEN
        IDB_TOOLBAR    IsDlgButtonChecked: self 0<> ( -- f1 )
        IF      StartToolBar: EditorWindow
        ELSE    Floating: Win-EdToolbar
                IF      TRUE to tool-bar?
                THEN    CloseToolBar: EditorWindow
        THEN
        ;

:M On_Command:  ( hCtrl code ID -- f1 )         \ returns 0=cancel
                                                \ returns 1=ok
        CASE
                IDOK     OF     get-options
                                1        end-dialog     ENDOF   \ set size
                IDCANCEL OF     0        end-dialog     ENDOF   \ cancel size
                false swap ( default result )
        ENDCASE ;M

;Object

: text-options  ( -- )
                EditorWindow Start: OptionsDlg drop
                SetFocus: DocWindow
                refresh-screen ;

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 45    Reformat-paragraph split a long line so that it your window.  Ctrl+R
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

: reformat-paragraph ( -- )
        end-line
        BEGIN   cursor-line 1+ #line.len 0>             \ next line not blank
                cursor-line file-lines 1- < and         \ not on last line
        WHILE   RefreshOff: DocWindow
                word-delete
                end-line ?wrap-word                     \ to last column of line
                end-line ?wrap-word
                end-line ?wrap-word
                end-line ?wrap-word
                end-line
                RefreshOn: DocWindow
                refresh-screen
                WINPAUSE
        REPEAT  end-line ?wrap-word
        home-line ;

: reformat-text ( -- ) \ reformat the current paragraph to the current margins
        >E
        bitImage? ?EXIT
        right-edge 0>   \ if wrap edge is not zero, then enable word wrap
        IF      reformat-paragraph
        ELSE    s" Need to set Right Margin First\n\nOpening Win-Ed Preferences Dialog...\n"
                "message beep 2 seconds message-off
                text-options
        THEN    ;

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 46    Various Higher Level Functons
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

: right-to-cursor ( -- ) \ set right margin to cursor position
        cursor-col low-right-edge max "LCLIP" to right-edge ;

: expand-tabs   { \ cntr -- } \ expands all tab's in the file to spaces
        >E
        bitImage? ?EXIT
        home-doc
        find-buf @ >r           \ save count and first three chars of FIND-BUF
        1 find-buf c!
        k_tab find-buf 1+ c!    \ init find buffer to a tab
        s" Expanding ALL TABs..." "top-message
        WINPAUSE
        RefreshOff: DocWindow
        TRUE
        BEGIN   _find-text-again and
        WHILE   1 +to cntr
                delete-highlight
                spcs tab-size cursor-col tab-size 1 max mod - 0max Insert-string
                0 >col-cursor
                0 to left-margin
                cntr 15 and 0=
                IF      RefreshOn: EditWindow
                        refresh-screen
                        WINPAUSE
                        key? 0=
                        RefreshOff: EditWindow
                ELSE    TRUE
                THEN
        REPEAT
        RefreshOn: DocWindow
        message-off
        r> find-buf !           \ restore the contents of FIND-BUF
        refresh-screen ;

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 47    Paragraph Sort Routines
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

\ A paragraph consists of a number of lines which are not empty.
\ Put the cursor at the first line of a paragraph and choose
\ "Sort paragraph lines" the paragraph will then be sorted.
0 value sort-to
0 value sort-from
0 value sort-col

: sortline      { \ sort1$ sort2$ -- }
        LMAXSTRING LocalAlloc: sort1$
        LMAXSTRING LocalAlloc: sort2$
        cursor-line #line" sort1$ LPLACE
        sort1$ LCOUNT upper
        line-delete
        sort-from dup sort-to
        DO      i #line" sort2$ LPLACE
                sort2$ LCOUNT upper
                sort2$ LCOUNT sort-col /string
                sort1$ LCOUNT sort-col /string  compare 0>
                IF      drop i LEAVE
                THEN
        LOOP    0 _>row-col
        word-undelete
        1 +to sort-from
        sort-from cursor-col _>row-col
        sort-from 15 and 0=
        IF      refresh-screen
                WINPAUSE
        THEN    ;

: do-sort-paragraph ( -- )
        cursor-line #line.len 0=
        cursor-line file-lines 1- >= or
        IF      1 +row-scroll
                EXIT
        THEN
        0 to left-margin        \ clear left margin to zero
        cursor-col  to sort-col
        cursor-line to sort-to
        1 +row-cursor                   \ move cursor down one line
        cursor-line to sort-from
        BEGIN   get-cursor-line
                cursor-line #line.len 0>
                cursor-line file-lines 1- < and
                key? 0= and
        WHILE   sortline
        REPEAT
        sort-col to cursor-col
        sort-to cursor-col >row-col  ;

: sort-paragraph ( -- )         \ sort lines of a paragraph
        bitImage? ?EXIT
        browse? ?EXIT
        z" Do you want to sort the lines of the current\nparagraph on the Cursor Column?"
        z" Sort Paragraph Lines"
        MB_OKCANCEL WinEdMessageBox: EditorWindow IDOK =
        IF      >E
                do-sort-paragraph
                key?
                IF      key drop
                THEN
                file-has-changed
        THEN
        refresh-screen ;

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 49    Convert a decimal number to hex in the 0x00000000 format
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

create hex-buf  32 allot

: make-hex      ( -- )
        bitImage? ?EXIT
        highlighting? 0=                \ something is highlighted
        IF      highlight-word
        THEN
        highlighting?
        hlst hled = and                              \ but only on one line
        IF      base @ >r                            \ save the base
                highlight" "-blanks"                 \ extract highlighted text
                2dup bl scan nip - 31 min            \ parse out first word
                hex-buf place
                FALSE   hex-buf count bounds
                ?DO     i c@     '0' '9' between
                        i c@ upc 'A' 'F' between or
                        i c@ upc 'X' = or 0= or      \ TRUE if not DECIMAL or HEX or X
                LOOP            \ -- f1=TRUE if not a good DECIMAL or HEX number
                IF      r> base !
                        beep                         \ bad number
                        EXIT
                THEN
                hex-buf 1+  c@     '0' =             \ if starts with "0x", then
                hex-buf 2 + c@ upc 'X' = and         \ already a HEX number
                IF      delete-highlight             \ delete old number
                        hex-buf count                \ make it DECIMAL
                        2 /string                    \ remove "0x" from start
                        HEX                          \ using HEX number base
                        number? 2drop                \ convert to binary
                        DECIMAL                      \ using DECIMAL number base
                ELSE    FALSE hex-buf count bounds   \ else make it HEX
                        ?DO     i c@ '0' '9' between 0= or
                        LOOP    \ -- f1=TRUE if not a good DECIMAL number
                        IF      r> base !
                                beep                 \ beep and EXIT
                                EXIT
                        THEN
                        delete-highlight             \ delete old number
                        DECIMAL                      \ using DECIMAL number base
                        hex-buf count number? 2drop  \ convert to binary
                        HEX                          \ using HEX number base
                        s" 0x" insert-string         \ preceed with "0x"
                THEN
                0 <# # # # # # # # #                 \ convert 8 digits
                   #>   insert-string                \ insert the new number
                word-left                            \ back to start of word
                r> base !                            \ restore the base
        ELSE    beep                                 \ nothing to convert
        THEN ;

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 50    Macro Functions
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

also HIDDEN

: edit-macro    ( -- )
                Gethandle: EditorWindow Start: EditLog dup c@
                IF      cur-filename count hyper-string place
                        count "+open-text
                ELSE    drop
                THEN    SetFocus: DocWindow ;

: play-macro    ( -- )
                Gethandle: EditorWindow Start: PlayLog dup c@
                IF      count "playkeys
                ELSE    drop
                THEN    SetFocus: DocWindow ;

: new-macro    ( -- )
                Gethandle: EditorWindow Start: NewLog dup c@
                IF      count "new-log
                ELSE    drop
                THEN    SetFocus: DocWindow ;

10 to playrate  \ set the macro execution DELAY to small number for
                \ HIGH SPEED, normally set to 1000

previous

defer do-ctrl-w
: in-bl ( -- )
  cursor-col
  bl insert-character
  to cursor-col refresh-line ;  ' in-bl is do-ctrl-w



