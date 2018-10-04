\ $Id: Ed_About.F,v 1.1 2011/03/19 23:26:04 rdack Exp $
\
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 17    Win_Ed about dialog, copied from the Forth About Dialog 
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\   

:Object about-wined-dialog       <SUPER dialog

IDD_ABOUT_FORTH forthdlg find-dialog-id constant template

create about-head
        z," Win-Ed (Public Domain Januay 1995)"

create about-msg1
        z," Version: " -null,
        wined_version# ((version)) +z",
        +z," \nCompiled: "
        wined-compile-version >date" +z",
        +z," , "
        wined-compile-version >time" +z", +z,"  "

create about-msg2
        z," Written by:\n"
        +z,"    Tom Zimmer\n"

create about-msg3
        z," Contributors:\n"
        +z,"    John A. Peters, Brad Eckert, Bruno Gauthier,\n"
        +z,"    Robert L. (Bob) Smith, Robert Dudley Ackerman,\n"
        +z,"    Rainbow Sally, Dirk Busch, J.v.d.Ven, Jeff Klem,\n"
        +z,"    Andrew Stephenson\n"
        +z,"    other's contributions acknowledged\n"

:M On_Init:     ( hWnd-focus -- f )
                about-head zcount IDD_ABOUT_HEAD  SetDlgItemText: self
                about-msg1 zcount IDD_ABOUT_TEXT  SetDlgItemText: self
                about-msg2 zcount IDD_ABOUT_TEXT2 SetDlgItemText: self
                about-msg3 zcount IDD_ABOUT_TEXT3 SetDlgItemText: self
                1 ;M

:M GetTemplate: ( -- template )
                template
                ;M

:M On_Command:  ( hCtrl code ID -- f1 )
                CASE
                IDCANCEL OF     0 end-dialog    ENDOF
                                false swap ( default result )
                ENDCASE ;M

;Object

: about-wined   ( -- )
                EditorWindow Start: about-wined-dialog drop
                SetFocus: DocWindow ;
                
