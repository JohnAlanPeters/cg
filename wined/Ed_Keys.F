\ $Id: Ed_Keys.F,v 1.15 2013/11/03 18:37:13 rdack Exp $
\ The double spaces between paragraphs are for use with Shift+PgDn
\

: findstr ( adr len -- f )
  0 to cursor-line  dup>r
  find-buf place _find-text-again
  r> over if +to cursor-col else drop then no-highlight ;


\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 64    View
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
: View-before-bye { \ last-entry title$ -- }
      MAXSTRING localAlloc: title$
      decimal
      -1 to last-entry
      entry# >r
      save-defaults
      FALSE to term-canceled?         \ initially NOT canceled
      entry-max 0
      DO    i to entry#             \ select the hyper file index
            edit-changed?
            IF    save-minutes 0>
                  IF    save-text
                  ELSE  i to last-entry
                        refresh-screen
                        s" Save the changes to " title$ place
                        cur-filename count title$ +place
                        s"  before quitting? " title$ +place
                        0 title$ count 1- + c!   \ make it a zstring
                        title$ 1+
                        z" File has been modified!"
                        MB_YESNOCANCEL MB_ICONSTOP or
                        WinEdMessageBox: EditorWindow
                        CASE
                              IDYES     OF    save-text               ENDOF
                              IDNO      OF    FALSE to edit-changed?
                                              update-mirrors          ENDOF
                              IDCANCEL  OF    TRUE to term-canceled?  ENDOF
                        ENDCASE
                  THEN
            THEN
            term-canceled? ?LEAVE
      LOOP
      last-entry -1 <>
      IF      last-entry SetStack: EditWindow
      ELSE    r@ to entry#
      THEN    r>drop ;

: view-release  ( -- )                          \ release the editors buffers
        DestroyWindow: FrameWindow
        text-ptr ?dup IF release 0 to text-ptr THEN
        line-tbl ?dup IF release 0 to line-tbl THEN  ;

unload-chain chain-add-before view-release         \ make sure memory is released

: viewbye       ( -- )
        view-before-bye
        term-canceled? 0=
        IF      k_BYE
        THEN    ;

: "viewmessage  ( a1 n1 )       \ force all message window on top of application
        GetHandle: FrameWindow
        IF      StartPos: FrameWindow 100 100 rot + >r + r> message-origin
        THEN
        [ also HIDDEN ] _"message [ previous ] ;

: "topviewmessage  ( a1 n1 )
        GetHandle: FrameWindow
        IF      StartPos: FrameWindow 100 100 rot + >r + r> message-origin
        THEN
        [ also HIDDEN ] _"top-message [ previous ] ;

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 65    Include some improvements  by Robert Ackerman for John Peters
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
: isblank ( l# -- fl )
  #line" -trailing dup 0=  \ line is definitely blank
  if 2drop -1
  else dup>r bl skip nip r> swap - 44 >   \ blank through column 44
  then  ;

: skiplines { n fl -- }  \ -1=going up  1=going down; fl- true=>until blankline
  BEGIN  cursor-line n + 0 file-lines within
    if cursor-line n + dup to cursor-line   \ inc/dec line#
       isblank fl =   \ keep going until empty/non-empty line
    else true then    \ end of file
  UNTIL ;

: vtop ( -- )  \ get to top of current vscrn
  -1 true skiplines 1 +to cursor-line ;

1 value nskip           \ # blank lines to skip when paging

: +VSCR ( -- )          \ down 1 screen ending with empty line
  cursor-line line-cur -  \ #lines from top where current line is
  nskip true skiplines   \ skip non-empties
  nskip false skiplines  \ skip empties
  cursor-line swap - file-lines screen-rows - min to line-cur    \ new position
  refresh-screen save-text ;

: -VSCR  ( -- )      \ up to top of lines ending with empty line
  cursor-line line-cur -  \ #lines from top where current line is
  nskip negate true  skiplines   \ skip non-empties
  nskip negate false skiplines   \ skip empties
  nskip negate  true  skiplines   \ skip non-empties
  cursor-line 1+ file-lines min to cursor-line
  cursor-line swap - 0 max to line-cur refresh-screen save-text ;  \ new position

: +1VSCR  ( -- )  \ only stop if more than 1 empty-line  going down
  begin
   1 true skiplines  \ get to 1st empty
   cursor-line 1+ isblank
   1 false skiplines
  until cursor-line to line-cur refresh-screen ;

: -1VSCR ( -- )    \ only stop if more than 1 empty-line going up
  begin
   -1 true skiplines
   cursor-line 1- isblank
   -1 false skiplines
  until  -1 true skiplines
  cursor-line 1+ file-lines min dup to cursor-line
  to line-cur refresh-screen ;

: vhome-end ( -- )
  cursor-col
  0 to cursor-col
  cursor-line #line" -trailing   \ ?line is not blank
  swap c@ bl = and               \ but 1st char is blank
  if word-right
  then cursor-col =
  if 0 to cursor-col 0 to cursor-line 0 to line-cur then     
  refresh-screen ;

: noext? ( -- fl )    \ If filename has .F then it is not a bidfile
  cur-filename count ascii . scan drop 1+ c@ upc 'F' <> ;

\ Here is the version with no line length limit:
: OVERSTRIKE-CHARACTER  ( char -- )             \ was _overstrike
        dup bl >= over 0xff <= and
        IF      get-cursor-line
                cur-buf lcount drop             \ start of text in buffer
                cursor-col + c!                 \ put character into buffer
                cur-buf @ cursor-col max
                1+ "LCLIP" cur-buf !            \ increment buf size
                put-cursor-line
                file-has-changed
                1 +col-cursor
        ELSE    drop beep
        THEN ;

: INSERT/OVERSTRIKE-CHARACTER  ( char -- ) \ modified word replaces the original
        browse?
        IF      beep \ new May 20th, 2003 - 18:57 dbu
                drop EXIT
        THEN
        delete-highlight

        ( Test for ins/over mode and do it. jap )
        overstrike @
        IF overstrike-character
        ELSE _insert-character
        THEN
        ?wrap-word
        refresh-line ;

: +entry# ( n -- )  \ move to previous/next open file
  entry# dup rot + 0 max
  to entry#             \ select the hyper file index
  cur-filename c@ 0=
  if to entry#
  else drop entry# SetStack: EditWindow hyper-open then ;

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 66    These words handle the backspace properly when in the overstrike mode
\       Robert Ackerman with John Peters on March 9th, 2002 - 10:15 to 11:20
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

: DEL-CHAR      ( -- )          \  sub for k_delete  \ Working ok.
        overstrike @
        IF      bl overstrike-character
        ELSE    delete-character
        THEN ;

: do-bs ( -- )
  delete-highlight
  overstrike @
  if  cursor-col 1- 0 max to cursor-col refresh-line
  else  do-backspace
  then  ;

defer _Control+W ' close-text is _control+w

\ date
: month-day-year" ( -- addr len )
  get-local-time time-buf
  >r 31 date$  z" MMMM dd',' yyyy"
  r> null LOCALE_USER_DEFAULT
  call GetDateFormat date$ swap 1- ;

: datestamp ( -- )    \ put date stamp (f9)
  noext? 0= ?exit  \ only if not a .f file
  s" Revision" findstr 0= ?exit
  1 +to cursor-line  \
  month-day-year"    \ -- addr len    
  get-cursor-line
  cur-buf lcount drop 19 + 20 blank
  cur-buf lcount drop 28 + over 2/ - swap cmove  \ datestamp char location
  put-cursor-line file-has-changed refresh-line
  -1 +to cursor-line  32 to cursor-col
  cursor-line #line" drop cursor-col
  begin 2dup + c@ ascii . <>
  while 1+ repeat 1+ to cursor-col drop ;

\ put data on clipboard
: copy2clipboard  { str cnt \ hnd memptr -- }
  NULL Call OpenClipboard 0=  ?exit
  Call EmptyClipboard   0=  if Call CloseClipboard drop exit then
  cnt 1+ GHND Call GlobalAlloc to hnd       \ allocate memory
  hnd Call GlobalLock to memptr             \ for data
  memptr
  if str memptr cnt move                    \ move the data
    hnd CF_TEXT Call SetClipboardData drop  \ transfer to clipboard
  then hnd Call GlobalUnlock drop
  Call CloseClipboard drop ;

: _line2clip ( -- )   \ cursor line to clipboard
  [ editor ] cursor-line #line" -trailing copy2clipboard ;
  ' _line2clip is line2clip

: del-rt ( -- )  \ delete characters rt of cursor to end of line
  cursor-line #line" -trailing >r cursor-col + r> cursor-col - dup>r
  copy2clipboard  r> delete-characters  ;

: swap2lines ( -- )  \ swap current line with line below it
  cursor-line 1+ #line" pad place
  get-cursor-line  1 +to cursor-line
  put-cursor-line -1 +to cursor-line
  pad count cur-buf lplace put-cursor-line refresh-screen ;

: swaplines { lfrom lto -- }  \ swap 2 given lines
  lto #line" pad place
  cursor-line  \ remember
  lfrom to cursor-line
  get-cursor-line  lto to cursor-line
  put-cursor-line  lfrom to cursor-line
  pad count cur-buf lplace put-cursor-line refresh-screen ;

: toggle-colons-only ( -- )    \ RDA
        cursor-line to line-cur
        colons-only 0= dup to colons-only
        if setcolontbl then
        refresh-screen ;

: toggle-insert ( -- )
        overstrike @ 0= overstrike !
        refresh-screen ;

: Pro-mode  ( -- )         \ One mode for code work and one for estimating
        overstrike @       \ JP 4-5-09  It works!
        if word-right      \ Move cursor to the next word to the right
        else replace-text  \ Should be named find&replace
        Then ;             \ Ctl+F  But what does it do?

: fstacksave ( -- ) \ remember current edit file position
  set-ed-defaults entry# s>d (d.) s" Recall" "SetDefault
  set-w32f-default ;

: recallopen ( -- )
  set-ed-defaults
  s" Recall" "GetDefaultValue
  if dup to entry# SetStack: EditWindow hyper-open
  else drop then set-w32f-default ;


\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 67    The main editor loop
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

: handle-keyboard-interpretation
                  BEGIN key?                   \ handle keyboard interpretation
                  WHILE key?
                        IF key rem-sendkey     \ just send keys to Forth console
                        THEN
                  REPEAT ;

: SMS-WEW-key-Con-doc-interp-send
            BEGIN   SetMultiStatus: EditorWindow
                    key             \ handle keyboard interpretation
                    false \ interpreting?
            WHILE   rem-sendkey                \ just send keys to Forth console
            REPEAT ;
: edopen ( -- )
  s" \cg\bids\help.txt" "+open-text ;

: F13  ; \ Yet another
                      
: VIEW-KEY-LOOP ( -- )
      true to invkloop   \ we are editing
      call GetFocus to topwin
      browse-toggle
      BEGIN
            depth to saved-depth            \ so we can check stack depth
            ibeam-cursor
            RefreshCursor: DocWindow
            ShowCursor: DocWindow
            EditMode: Win-EdToolbar
            \ SMS-WEW-key-Con-doc-interp-send
            key
            call GetFocus topwin <> if PutKey: cmd _xit then                 
            SetFocus: DocWindow
            HideCursor: DocWindow
            CASE


\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 68    Control key bindings
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
      'A'     +k_control            OF      highlight-all               ENDOF
      'A'     +k_control +k_shift   OF      toggle-colons-only          ENDOF
      'B'     +k_control            OF      debug-word                  ENDOF
      'B'     +k_control +k_shift   OF      debug-word                  ENDOF
      'C'     +k_control            OF      copy-text                   ENDOF
      'D'     +k_control            OF      datestamp   ( also F9 )     ENDOF
      'D'     +k_control +k_shift   OF      revert-text ( also Q )      ENDOF
      'E'     +k_control            OF      grand-total                 ENDOF
      'E'     +k_control +k_shift   OF      expand-tabs                 ENDOF
\     'F'     +k_control ( del me ) OF    ( word-right ) replace-text   ENDOF \ JAPP long ago
      'F'     +k_control            OF      pro-mode  ( JP 4-5-09 )     ENDOF
      'F'     +k_control +k_shift   OF      find-in-files               ENDOF
      'G'     +k_control            OF      del-rt                      ENDOF
      'H'     +k_control +k_shift   OF      make-hex                    ENDOF
      'L'     +k_control            OF      load-active-file            ENDOF
\     'M'     +k_control            OF      smart-cr                    ENDOF
\     'M'     +k_control +k_shift   OF   [ also HIDDEN ] replay-macro [ previous ] ENDOF
      'N'     +k_control            OF      xsplit-line                 ENDOF
      'N'     +k_control +k_shift   OF      new-text                    ENDOF
      'O'     +k_control            OF      open-text                   ENDOF
      'O'     +k_control +k_shift   OF      open-text-highlighted       ENDOF
      'P'     +k_control            OF      print-text                  ENDOF
      'P'     +k_control +k_shift   OF      text-options                ENDOF
      'Q'     +k_control            OF      cg-special                  ENDOF
      'Q'     +k_control +k_shift   OF      revert-text ( see also D )  ENDOF
      'R'     +k_control            OF      reformat-text               ENDOF
      'R'     +k_control +k_shift   OF      [ also HIDDEN ] EditorWindow repeat-amacro [ previous ] ENDOF
      'S'     +k_control            OF      save-text                   ENDOF
      'S'     +k_control +k_shift   OF      swap2lines                  ENDOF
      'T'     +k_control            OF      word-delete                 ENDOF
      'T'     +k_control +k_shift   OF      word-undelete               ENDOF
\     'U'     +k_control            OF      highlight-case-toggle       ENDOF
\     'U'     +k_control            of      d_un-add                    ENDOF \ JAPP 5-2019 
      'V'     +k_control            OF      Paste-text                  ENDOF
      'V'     +k_control +k_shift   OF      Paste-date/time             ENDOF
      'W'     +k_control            OF      do-ctrl-w  ( push right )   ENDOF
      'W'     +k_control +k_shift   OF      close-text                  ENDOF
      'X'     +k_control            OF      cut-text                    ENDOF
      'Y'     +k_control            OF      line-delete                 ENDOF
      'Z'     +k_control            OF      xundo                       ENDOF


\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 69    Function key bindings   +SCR is 1 page down
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
      k_F1    ( rbs )               OF      edopen  ( w32f-doc )        ENDOF
      k_F1    +k_control            OF      word-help                   ENDOF
      k_F2                          OF      settle grand-total          ENDOF                                            
      k_F3                          OF      find-text-again             ENDOF
      k_F3    +k_shift              OF      back-find-text-again        ENDOF
      k_F3    +k_control            OF      find-text-highlight         ENDOF
      k_F3    +k_shift +k_control   OF      replace-text                ENDOF
      k_F4                          OF      settle                      ENDOF
      k_F4    +k_shift              OF      AAA   ( n n line swap )     ENDOF
      k_F5                          OF      grand-total                 ENDOF
      k_F5    +k_control +k_shift   OF      cwords                      ENDOF
      K_f6                          OF      un-add                      ENDOF
      k_F7                          OF      toggle-insert               ENDOF
      k_F8                          OF      revert-text                 ENDOF
      k_F9                          OF      grand-total                 ENDOF
      k_F9    +k_control +k_shift   OF      do-html-link                ENDOF
      k_F10                         OF      un-add  ( hyper-link )      ENDOF
      k_F10   +k_control +k_shift   OF      save-text-pc                ENDOF
      k_F10   +k_control            OF      save-and-load               ENDOF
      k_F11                         OF      fstacksave                  ENDOF
      k_F11   +k_shift              OF      next-link                   ENDOF
      k_F11   +k_control +k_shift   OF      un-add     ( word-link )    ENDOF
      k_F12                         OF      fstacksave                  ENDOF
      k_F12   +k_shift              OF      save-all-text bye           ENDOF
\                                         ( prev-link )  ( datestamp )

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 70    Arrow Down, End, Home
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
      k_down                        OF      1 +row-cursor               ENDOF
      k_down  +k_control            OF      1 +entry#                   ENDOF
      k_down  +k_shift              OF      highlight-down              ENDOF
      k_end                         OF      end-line                    ENDOF
      k_end   +k_shift              OF      highlight-end-line          ENDOF
      k_end   +k_control            OF      end-doc                     ENDOF
      k_end   +k_shift +k_control   OF      highlight-end-doc           ENDOF
      k_home                        OF      home-line                   ENDOF
      k_home  +k_shift              OF      vhome-end                   ENDOF
      k_home  +k_control            OF      home-doc                    ENDOF
      k_home  +k_shift +k_control   OF      highlight-home-doc          ENDOF


\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 71    Arrow left
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
      k_left                        OF      character-left              ENDOF
      k_left  +k_control            OF      word-left                   ENDOF
      k_left  +k_shift              OF      highlight-left              ENDOF
      k_left  +k_shift +k_control   OF      highlight-word-left         ENDOF


\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 72    PgDn  PgUp
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
      k_pgdn                        OF      +vSCR ( 1 +page-cursor )    ENDOF
      k_pgdn  +k_control            OF      1 +page-cursor ( +VSCR )    ENDOF
      k_pgdn  +k_shift              OF      +1VSCR                      ENDOF
      k_pgup                        OF      -vSCR ( -1 +page-cursor )   ENDOF
      k_pgup  +k_control            OF      -1 +page-cursor ( -VSCR )   ENDOF
      k_pgup  +k_shift              OF      -1VSCR                      ENDOF


\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 73    Arrow-right  Arrow-up
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
      k_right                       OF      character-right             ENDOF
      k_right +k_control            OF      word-right                  ENDOF
      k_right +k_shift              OF      highlight-right             ENDOF
      k_right +k_shift +k_control   OF      highlight-word-right        ENDOF
      k_up                          OF      -1 +row-cursor              ENDOF
      k_up    +k_control            OF      -1 +entry#                  ENDOF
      k_up    +k_shift              OF      highlight-up                ENDOF


\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 74    Enter, Tab, Insert, Delete, BS, Esc, LF  CR
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
      k_tab                         OF      smart-insert-tab            ENDOF
      k_tab   +k_shift              OF      smart-back-tab              ENDOF
      k_insert                      OF      toggle-insert               ENDOF
      k_insert +k_shift             OF      paste-text                  ENDOF
      k_insert +k_control           OF      copy-text                   ENDOF
      k_delete                      OF      delete-character            ENDOF
      k_delete  +k_shift            OF      cut-text                    ENDOF
      k_delete  +k_control          OF      word-delete                 ENDOF
      k_BACKSPACE                   OF      do-backspace                ENDOF
      k_BACKSPACE   +k_shift        OF      next-window                 ENDOF
      k_ESC                         OF      do-esc                      ENDOF
      k_LF                          OF      lf-left                     ENDOF
      k_CR                          OF      smart-cr                    ENDOF
      k_CR +k_control               OF      xsplit-line                 ENDOF
      k_CR +k_shift                 OF 1 +row-cursor 16 to cursor-col   ENDOF
      k_CR +k_alt                   OF     ." doesn't work"             ENDOF
                    dup insert/overstrike-character
        ENDCASE
      AGAIN   ;

: F14  ; \ I like to be able to VIEW this word to quickly jump to this file
         \ Please do not remove it.
