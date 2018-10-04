\ $Id: BROWSEFLD.F,v 1.2 2011/08/19 21:23:24 georgeahubert Exp $

\  Author: Jos v.d. Ven, Dirk Busch
\ Created: ??? - jos
\ Updated: Sonntag, Mai 16 2004 - 12:58 - dbu
\
\ SHBrowseForFolder() support for Win32Forth

cr .( Loading SHBrowseForFolder support)

anew -browsefld.f

INTERNAL

0 value hwndOwner
0 value pidlRoot
0 value pszDisplayName
0 value lpszTitle
0 value ulFlags
0 value lpfn
0 value lParam
0 value iImage

create BROWSEINFO
here 0 , to hwndOwner
here 0 , to pidlRoot
here 0 , to pszDisplayName
here 0 , to lpszTitle
here 0 , to ulFlags
here 0 , to lpfn
here 0 , to lParam
here 0 , to iImage


\ Browsing for directory.
  0x0001 constant BIF_RETURNONLYFSDIRS    \ For finding a folder to start document searching
\ 0x0002 constant BIF_DONTGOBELOWDOMAIN   \ For starting the Find Computer
\ 0x0004 constant BIF_STATUSTEXT          \ Top of the dialog has 2 lines of text for BROWSEINFO.lpszTitle and one line if
                                          \ this flag is set.  Passing the message BFFM_SETSTATUSTEXTA to the hwnd can set the
                                          \ rest of the text.  This is not used with BIF_USENEWUI and BROWSEINFO.lpszTitle gets
                                          \ all three lines of text.
\ 0x0008 constant BIF_RETURNFSANCESTORS   \ ???
  0x0010 constant BIF_EDITBOX             \ Add an editbox to the dialog
  0x0020 constant BIF_VALIDATE            \ insist on valid result (or CANCEL)
  0x0040 constant BIF_NEWDIALOGSTYLE      \ Use the new dialog layout with the ability to resize
                                          \ Caller needs to call OleInitialize() before using this API
\ 0x0080 constant BIF_BROWSEINCLUDEURLS   \ Allow URLs to be displayed or entered. (Requires BIF_USENEWUI)
\ 0x0100 constant BIF_UAHINT              \ Add a UA hint to the dialog, in place of the edit box. May not be combined with BIF_EDITBOX
\ 0x0200 constant BIF_NONEWFOLDERBUTTON   \ Do not add the "New Folder" button to the dialog.  Only applicable with BIF_NEWDIALOGSTYLE.
\ 0x0400 constant BIF_NOTRANSLATETARGETS  \ don't traverse target as shortcut
\ 0x1000 constant BIF_BROWSEFORCOMPUTER   \ Browsing for Computers.
\ 0x2000 constant BIF_BROWSEFORPRINTER    \ Browsing for Printers
\ 0x4000 constant BIF_BROWSEINCLUDEFILES  \ Browsing for Everything
\ 0x8000 constant BIF_SHAREABLE           \ sharable resources displayed (remote shares, requires BIF_USENEWUI)
\ BIF_NEWDIALOGSTYLE BIF_EDITBOX or constant BIF_USENEWUI

\ message from browser
  1 constant BFFM_INITIALIZED
\ 2 constant BFFM_SELCHANGED
\ 3 constant BFFM_VALIDATEFAILEDA \ lParam:szPath ret:1(cont),0(EndDialog)
\ 4 constant BFFM_VALIDATEFAILEDW \ lParam:wzPath ret:1(cont),0(EndDialog)
\ 5 constant BFFM_IUNKNOWN        \ provides IUnknown to client. lParam: IUnknown*

\ messages to browser
\ WM_USER 100 + constant BFFM_SETSTATUSTEXTA
\ WM_USER 101 + constant BFFM_ENABLEOK
  WM_USER 102 + constant BFFM_SETSELECTIONA
\ WM_USER 103 + constant BFFM_SETSELECTIONW
\ WM_USER 104 + constant BFFM_SETSTATUSTEXTW
\ WM_USER 105 + constant BFFM_SETOKTEXT
\ WM_USER 106 + constant BFFM_SETEXPANDED

WinLibrary OLE32.dll
1 PROC OleInitialize
1 PROC CoTaskMemFree
1 PROC SHBrowseForFolder
2 PROC SHGetPathFromIDList
1 PROC PathIsDirectory
4 PROC SendMessage

\ callback for SHBrowseForFolder() to set the startup-folder in the dialog
: BrowseCallbackProc    { hwnd msg wParam lParam -- flag }
        msg BFFM_INITIALIZED =
        if   pszDisplayName @
             true BFFM_SETSELECTIONA hwnd call SendMessage drop
        then 0 ;

4 callback &BrowseCallbackProc  BrowseCallbackProc

EXTERNAL

: BrowseForFolder       ( lpszTitle pszFolder hwndOwner -- flag )

        hwndOwner !
        swap lpszTitle !

        \ if we have a valid Folder, than we need a callback for
        \ SHBrowseForFolder() to set the startup-folder in the dialog
        dup +null 1+ dup call PathIsDirectory
        if &BrowseCallbackProc else 0 then lpfn !

        dup dup pszDisplayName !

        [ BIF_RETURNONLYFSDIRS BIF_EDITBOX or BIF_VALIDATE or ( BIF_NEWDIALOGSTYLE or ) ] literal ulFlags !

        0 pidlRoot !
        0 lParam !

        \ OleInitialize() must be called if BIF_NEWDIALOGSTYLE flag is set
\       ulFlags @ BIF_NEWDIALOGSTYLE and
\       if 0 call OleInitialize drop then

        BROWSEINFO call SHBrowseForFolder dup>r
        call SHGetPathFromIDList
        if   zcount swap 1- c! true
        else drop false
        then r> Call CoTaskMemFree drop ; \ release memory

MODULE

\s test code

create test ," c:\temp\win32forth" MAX-PATH allot

: test-it ( -- )
        z" Choose a folder" test CONHNDL BrowseForFolder
        cr if test count type else ." aborted" then ;

test-it

