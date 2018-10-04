\ $ Id: Ed_Globals.f,v 1.2 2005/03/25 20:22:34 aws Exp $
\
\
\ My-Application is bound to Ctrl+E in Win-Ed.f in view-key-loop. It is or
\ will be resolved to _EXTEND-PRICES in an application named CG.F  Feel free to
\ vector it to what ever you want in your own application. Please do not remove
\ this word from this file.  It uses very little memory and will do no harm. jap
defer MY-APPLICATION ' noop is MY-APPLICATION


FALSE value RectHigh
0x0100 constant RectTerm               \ Flag for Rectangular Higlight Clipboard
create MSPCS  LMAXSTRING allot         \ create a large array of spaces
mspcs lmaxstring blank



    0 value EditorWindow        \ for forward references
    0 value Win-EdToolbar       \ allow forward references to Toolbar

   80 value printed-columns     \ printed columns on paper
   14 value find-top-margin     \ lines from top where to display found text

    0 value def-right-edge      \ default right edge for word wrap

   12 value low-right-edge      \ don't allow the right margin to be too low

10000 value start-text-size     \ initial text buffer size in bytes

  931 value start-width         \ was 640
  562 value start-height        \ was 480

   60 value drag-barH
    4 value drag-thick
    5 value edit-min            \ minimum with (pixels) of edit window
   26 value listHeight          \ height of the SubjectList control
   26 value listHeightDefault   \ default list height

    0 value using98/NT?         \ are we running Windows98 or WindowsNT?
    0 value first-line-saved    \ first line of file to be saved

TRUE  value recent-files?       \ should a list of recent files be kept in the
                                \ Files menu if it doesn't already exist
    0 value findComboEdit
      defer addFileMenu

 TRUE value colorize?           \ {BE}
 TRUE value page-lines?         \ should page markers be displayed?
FALSE value auto-new?           \ automatically make a new file
 TRUE value auto-margin?
FALSE value mousedown?
FALSE value focusing?           \ we are just setting the focus to a window
FALSE value minimized?
 TRUE value tool-bar?           \ is the toolbar turned on?
FALSE value floating-bar?       \ is the toolbar floating?
FALSE value min-tool-bar?       \ are we using the minimum toolbar?
FALSE value save-find?          \ preserve the find buffer across edit sessions?
FALSE value WinEd-web?          \ use Win-Ed for Web page browsing when TRUE
FALSE value save-margin?
FALSE value save-minutes        \ automatically save changes after n minutes
FALSE value open-previous?      \ should we open the file we had open previously
FALSE value term-canceled?      \ did we cancel program termination
FALSE value as-pc?              \ save file as a PC file?
FALSE value start-browse?       \ are we starting in browse mode?
    0 value max-toolbar         \ address of the Max toolbar
    0 value displayingLine
FALSE value ConsoleReady?       \ true if the console is ready to accept char's from the editor

9001 CONSTANT SAVE_TIMER        \ a marker for the auto save timer

named-new$ command-args         \ commandline arguments

    0 value FilesList
    0 value DocWindow
    0 value EditWindow
    0 value the-width
    0 value the-height
    0 value html-link?
    0 value on-text?
    0 value saved-depth

create tempLine MAXSTRING allot

WinDC screenDC          \ The screen's device context

create unnamed-file ," <UNNAMED FILE>"

: unnamed-file? { nameadr \ file$ -- f1 }
        max-path localAlloc: file$              \ a temporary buffer
        nameadr unnamed-file c@ file$ place     \ lay in filename
        file$ count upper                       \ make it uppercase
        file$ count                             \ compare against UNNAMED-FILE
        unnamed-file count compare 0= ;

: cur-file-unnamed?     ( -- f ) \ check if current file is unnamed
        cur-filename 1+ unnamed-file? ;

: last-entry#   ( -- n1 )
        entry# >r
        0 entry-max 0
        DO      i max
                i to entry#             \ select the hyper file index
                cur-filename c@ 0= ?leave
        LOOP
        r> to entry#  ;

: edit-top      ( -- n1 )
        tool-bar?
        IF      StartSize: Win-EdToolbar nip
        ELSE    0
        THEN    ;

: WaitForConsole { \ deadlook -- } \ wait until console is ready to accept char's
                                   \ return's after 10 seconds even when the console is not ready
        0 to deadlook
        begin 100 ms WINPAUSE
              deadlook 1+ dup to deadlook 10000 =
              ConsoleReady? or
        until ;

\ changed June 1st, 2003 - 10:08 dbu
\ to wait until Forth is loaded
: StartUpForth  { \ file$ -- } \ Start forth console
        MAXSTRING LocalAlloc: file$
        &prognam count "path-only" file$ place
                                   file$ ?+\
        s" Win32For.exe"           file$ +place
                                   file$ EXEC-CMD drop

        \ wait untill Forth is loaded
        WaitForConsole ;

: highlight-cursor ( -- )
        cursor-line dup to hlst dup to hled to mlst
        cursor-col  dup to hcst dup to hced to mcst ;



