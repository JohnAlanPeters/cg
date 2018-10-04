\ $Id: Buttons.f,v 1.3 2006/08/29 08:52:25 georgeahubert Exp $

\ *D doc\classes\
\ *> Controls

anew -Buttons.f

WinLibrary COMCTL32.DLL

cr .( Loading Button Classes...)

INTERNAL
EXTERNAL

\ ------------------------------------------------------------------------
\ *W <a name="CheckBox"></a>
\ *S CheckBox class
\ ------------------------------------------------------------------------
:Class CheckBox          <super CheckControl
\ *G Class for check buttons
\ ** (enhanced Version of the CheckControl class)

int style

:M ClassInit:   ( -- )
\ *G Initialise the class.
                ClassInit: super
                0 to style ;M

:M WindowStyle: ( -- style )
\ *G Get the window style of the control.
                WindowStyle: super
                style or ;M

:M AddStyle:    ( n -- )
\ *G Set any additional style of the control. Must be done before the control
\ ** is created.
                to style ;M

:M IsButtonChecked?:    ( -- f )
\ *G send message to self through parent
		ID IsDlgButtonChecked: parent \ to checked
		;M

:M CheckButton:	( -- )
                BST_CHECKED ID CheckDlgButton: parent ;M

:M UnCheckButton:       ( -- )
		BST_UNCHECKED ID CheckDlgButton: parent ;M

:M Check:	( f -- )
		if     CheckButton: self
		else UnCheckButton: self
		then ;M

:M Enable:      ( f -- )
\ *G Enable the control.
                ID EnableDlgItem: parent ;M

:M Disable:     ( -- )
\ *G Disable the control.
                false Enable: self ;M

:M Setfont:     ( handle -- )
\ *G Set the font in the control.
                1 swap WM_SETFONT SendMessage:SelfDrop ;M

;Class
\ *G End of CheckBox class

\ ------------------------------------------------------------------------
\ *W <a name="RadioButton"></a>
\ *S RadioButton class
\ ------------------------------------------------------------------------
:Class RadioButton	<super RadioControl
\ *G Class for radio buttons
\ ** (enhanced Version of the RadioControl class)

int style

:M ClassInit:   ( -- )
\ *G Initialise the class.
                ClassInit: super
                0 to style ;M

:M WindowStyle: ( -- style )
\ *G Get the window style of the control.
                WindowStyle: super
                style or ;M

:M AddStyle:    ( n -- )
\ *G Set any additional style of the control. Must be done before the control
\ ** is created.
\ *P If you need more than one group of radio buttons within a dialog you must
\ ** add the BS_GROUP style to the first button of each group.
                to style ;M

:M IsButtonChecked?: ( -- f )
\ *G Check if the radio button is checked or unchecked.
                ID IsDlgButtonChecked: parent ;M

:M CheckButton:	( -- )
\ *G Set the button state to checked.
                BST_CHECKED ID CheckDlgButton: parent ;M

:M UnCheckButton: ( -- )
\ *G Set the button state to unchecked.
		BST_UNCHECKED ID CheckDlgButton: parent ;M

:M Check:   	( f -- )
\ *G Set the button state to either checked or unchecked.
		if     CheckButton: self
		else UnCheckButton: self
		then ;M

:M Enable:      ( f -- )
\ *G Enable the control.
                ID EnableDlgItem: parent ;M

:M Disable:     ( -- )
\ *G Disable the control.
                false Enable: self ;M

:M Setfont:     ( handle -- )
\ *G Set the font in the control.
                1 swap WM_SETFONT SendMessage:SelfDrop ;M

;Class
\ *G End of RadioButton class

\ ------------------------------------------------------------------------
\ *W <a name="GroupRadioButton"></a>
\ *S GroupRadioButton class
\ ------------------------------------------------------------------------
:Class GroupRadioButton	<super RadioButton
\ *G Class for radio buttons.
\ ** Use a GroupRadioButton object for the first radio button in every group
\ ** of radio buttons within your dialog.

:M WindowStyle: ( -- style )
\ *G Get the window style of the control. Default is BS_GROUP.
                WindowStyle: super
                WS_GROUP or ;M
;Class
\ *G End of GroupRadioButton class

\ ------------------------------------------------------------------------
\ *W <a name="PushButton"></a>
\ *S PushButton class
\ ------------------------------------------------------------------------
:Class PushButton	<super ButtonControl
\ *G Class for push buttons
\ ** (enhanced Version of the ButtonControl class)

int style

:M ClassInit:   ( -- )
\ *G Initialise the class.
                ClassInit: super
                0 to style ;M

:M WindowStyle: ( -- style )
\ *G Get the window style of the control.
                WindowStyle: super
                style or ;M

:M AddStyle:    ( n -- )
\ *G Set any additional style of the control. Must be done before the control
\ ** is created.
                to style ;M

:M Setfont:     ( handle -- )
\ *G Set the font in the control.
                1 swap WM_SETFONT SendMessage:SelfDrop ;M

:M Enable:      ( f -- )
\ *G Enable the control.
                ID EnableDlgItem: parent ;M

:M Disable:     ( -- )
\ *G Disable the control.
                false Enable: self ;M

;Class
\ *G End of PushButton class

\ ------------------------------------------------------------------------
\ *W <a name="DefPushButton"></a>
\ *S DefPushButton class
\ ------------------------------------------------------------------------
:Class DefPushButton	<Super PushButton
\ *G Class for the default push buttons

:M WindowStyle: ( -- style )
\ *G Get the window style of the control. Default style is: BS_DEFPUSHBUTTON.
		WindowStyle: super BS_DEFPUSHBUTTON OR ;M

;Class
\ *G End of DefPushButton class

\ ------------------------------------------------------------------------
\ *W <a name="BitmapButton"></a>
\ *S BitmapButton class
\ ------------------------------------------------------------------------
:Class BitmapButton	<Super PushButton
\ *G BitmapButton control

int hbitmap     \ bitmap handle for button

:M ClassInit:   ( -- )
\ *G Initialise the class.
                ClassInit: super
                0 to hbitmap
                ;M

:M DeleteBitmap: ( -- )
                hbitmap
                if      hbitmap Call DeleteObject drop
                        0 to hbitmap
                then
                ;M

:M SetBitmap:   ( hbitmap -- )
                dup hbitmap <>
                if    \  DeleteBitmap: self
                        to hbitmap
                        hbitmap IMAGE_BITMAP BM_SETIMAGE SendMessage:SelfDrop
                else    drop
                then    ;M

:M SetImage:    ( hbmp -- )
                SetBitmap: self ;M

:M GetBitmap:   ( -- hbitmap )
\                0 IMAGE_BITMAP BM_GETIMAGE SendMessage:Self to hbitmap
                hbitmap
                ;M

:M GetImage:    ( -- hbitmap )
                GetBitmap: self ;M

:M WindowStyle: ( -- style )
\ *G Get the window style of the control. Default style is: BS_BITMAP.
                WindowStyle: super
                BS_BITMAP or
                ;M

:M ToolString:  ( addr cnt -- )
                binfo place
                binfo count \n->crlf
                ;M

:M Close:       ( -- )
\     		DeleteBitmap: self
                Close: super
                ;M

;Class
\ *G End of BitmapButton class

\ ------------------------------------------------------------------------
\ *W <a name="IconButton"></a>
\ *S IconButton class
\ ------------------------------------------------------------------------
:Class IconButton 	<Super PushButton
\ *G IconButton control

int hicon

:M ClassInit:   ( -- )
\ *G Initialise the class.
                ClassInit: super
                0 to hicon
                ;M

:M WindowStyle: ( -- style )
\ *G Get the window style of the control. Default style is: BS_ICON.
                WindowStyle: super
                BS_ICON OR
                ;M

:M DeleteIcon: 	( -- )
                hicon
                if      hicon Call DeleteObject drop
                        0 to hicon
                then
                ;M

:M SetIcon:     ( hIcon -- )
\ *G set the icon image to use with the button
                dup hicon <>
                if    \  DeleteIcon: self
                        to hicon
                        hicon IMAGE_ICON BM_SETIMAGE SendMessage:SelfDrop
                else    drop
                then    ;M

:M SetImage:    ( hicon -- )
                SetIcon: self ;M

:M GetIcon:    	( -- hIcon)
\ *G get the icon image used with the button
\                0 IMAGE_ICON BM_GETIMAGE SendMessage:Self to hicon
                hicon
                ;M

:M GetImage:    ( -- hicon )
                GetIcon: self ;M

:M ToolString:  ( addr cnt -- )
		binfo place
		binfo count \n->crlf
                ;M

:M Close:       ( -- )
\    		 DeleteIcon: self
                Close: super
                ;M

;Class
\ *G End of IconButton class

\ ------------------------------------------------------------------------
\ *W <a name="GroupBox"></a>
\ *S GroupBox class
\ ------------------------------------------------------------------------
:Class GroupBox		<super GroupControl
\ *G GroupBox control
\ ** (enhanced Version of the GroupControl class)

int style

:M ClassInit:   ( -- )
\ *G Initialise the class.
                ClassInit: super
                0 to style ;M

:M WindowStyle: ( -- style )
\ *G Get the window style of the control.
                WindowStyle: super
                style or ;M

:M AddStyle:    ( n -- )
\ *G Set any additional style of the control. Must be done before the control
\ ** is created.
                to style ;M

:M Setfont:     ( handle -- )
\ *G Set the font in the control.
                1 swap WM_SETFONT SendMessage:SelfDrop ;M

:M Enable:      ( f -- )
\ *G Enable the control.
                ID EnableDlgItem: parent ;M

:M Disable:     ( -- )
\ *G Disable the control.
                false Enable: self ;M

;Class
\ *G End of GroupBox class

MODULE

\ *Z
