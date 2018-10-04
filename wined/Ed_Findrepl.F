\ $Id: Ed_Findrepl.F,v 1.1 2011/03/19 23:26:04 rdack Exp $
\
:Object ReplaceTextDialog <Super  ModelessDialog

IDD_EDIT2_DIALOG forthdlg find-dialog-id constant template

int originX
int originY

:M ClassInit:   ( -- )
                ClassInit: super
                0 to originX
                0 to originY
                ;M
                
:M On_Init:     ( hWnd-focus -- f )
                originX originY or
                IF      originX originY SetWindowPos: self
                THEN
                s" Find - Replace Text"                 SetText: self
                find-buf    count IDD_EDIT_TEXT         SetDlgItemText: self
                replace-buf count IDD_EDIT2_TEXT        SetDlgItemText: self
                s" Search for:"   IDD_PROMPT_TEXT       SetDlgItemText: self
                s" Replace with:" IDD_PROMPT2_TEXT      SetDlgItemText: self
                s" Find"          IDOK                  SetDlgItemText: self
                s" Done"          IDCANCEL              SetDlgItemText: self
                s" Replace"       IDOK2                 SetDlgItemText: self
                s" Replace ALL"   IDOK3                 SetDlgItemText: self
                s" Case Sensitive Search" IDB_OPTION    SetDlgItemText: self
                CaseSensitive?            IDB_OPTION    CheckDlgButton: self
                1 ;M

:M GetTemplate: ( -- template )
                template
                ;M

:M ExWindowStyle: ( -- )
                ExWindowStyle: super
                WS_EX_TOOLWINDOW or
                ;M

: get-dialog    ( -- )
                find-buf    1+ 254 IDD_EDIT_TEXT  GetDlgItemText: self
                find-buf    c!
                find-buf count InsertString: findComboEdit
                replace-buf 1+ 254 IDD_EDIT2_TEXT GetDlgItemText: self
                replace-buf c!
                IDB_OPTION IsDlgButtonChecked: self to CaseSensitive? ;

:M On_Command:  ( hCtrl code ID -- )
    CASE
        IDOK     OF     get-dialog 1 +to cursor-col       \ skip one character
                                   _find-text-again ?beep  ENDOF
        IDOK2    OF     get-dialog replace-text-again      ENDOF
        IDOK3    OF     get-dialog replace-text-all        ENDOF
        IDCANCEL OF     get-dialog DestroyWindow: self
                        SetFocus: DocWindow                ENDOF
                        false swap ( default result )
    ENDCASE ;M

 :M WM_CLOSE    ( -- )
                get-dialog
                GetWindowRect: self 2drop to originY to originX
                WM_CLOSE WM: Super
                ;M

;Object

: replace-text  ( -- ) \ Find & replace text in the current file
        bitImage? ?EXIT
        browse?
        IF      find-buf EditorWindow Start: FindTextDlg
                dup 2 = to CaseSensitive?
                IF      1 +to cursor-col       \ skip one character
                        _find-text-again ?beep
                THEN
        ELSE    EditorWindow Start: ReplaceTextDialog
        THEN    ;

\ AAA ( - ) 1-column grand-total ;  ( JP? 4-5-09 )      

' replace-text is find-text  \ what is the purpose of this ( JP? 4-5-09 )

: find-text-highlight ( -- )
        bitImage? ?EXIT
        highlighting? 0=                \ nothing is highlighted
        cursor-col cursor-line or  and  \ not at start of file
        IF      highlight-word          \ try to highlight something
        THEN
        ?get-highlight
        find-buf c@                     \ if we have something
        IF      find-text-again         \ then try to find it
        ELSE    replace-text            \ else show find and replace dialog
        THEN    ;

