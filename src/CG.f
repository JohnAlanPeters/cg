\ $Id: CG.f,v 1.14 2013/08/13 23:30:32 rdack Exp $
\ to use merged editor compile in cg.f   [rda 11/02]

: CG ;  \ place marker for use with VIEW or VV  Can I move it to line 84?

sys-warning-off
dup-warning-off

forth definitions

needs unicode
needs xref
needs xwinver
create forthbase ," \win32forth\"
here ," \win32forth\SRC\KERNEL\FKERNEL.F" ' KERNFILE 4 + !

: SETFDIR  ( ss -- )   COUNT &FORTHDIR PLACE ;
forthbase setfdir
: CGBase" ( addr len -- addr2 len2 ) \ prefix str with cg base directory
  Prepend<home>\ ;

synonym CD chdir

: (((  s" )))"     "comment ; immediate  \ comment till )))

\ s" \win32forth\src\dc.f" included

Include START-STOP.F  \ hit esc or the enter key twice to abort.

1 value (WinEdDbg)    \ avoid turnkey at end of wined.f

defer grand-total     \ Defined early so AA can be used in cg-special ctrl-
' noop is grand-total \ View _grandtot for the deferred word       

defer AAA
defer reedit
defer un-add \ for wined
defer settle \ See also (settle) <- by triple clicking here
defer ro
defer date-stamp  \ defered to _date-stamp
defer xcopyfile
defer kkillTimer  \ autosave timer

: widefind ( a1 l1 -- a2 l2 fl )  \ for hyper-link
  search-path >r
  s" .;c:\cg;\win32forth" search-path place
  "path-file r> count search-path place ;

: capslock? ( -- f )  20 call GetKeyState 1 and ;   \ true->caps lock is on

0 value in-web? \ Are we interpreting in a webpage request?
0 value webload?  \ in an file load request from the webpage?
0 value webextend? \ in an extend request from webpage?
defer webext-error
variable conscol -1 conscol !  \ column for output in current console line

0 value  topwin
0 value invkloop  \ so we know when we are editing (in view-key-loop)
0 0 2value last-total  \ has to be remembered before clearing
defer total-est   \ so we can put total on status line
0 value consWin
: _xit ro loadline off false to invkloop
   call GetFocus consWin =
   if s" c:\stockwatcher" "chdir focus-console cr ." ok" quit then ;

cd ..
current-dir$ setfdir
s" wined\res" cgbase" "fpath+       \ for wined resource file
forthbase setfdir
cd wined

Include Wined.f

cd ..\src
s" src" cgbase" "fpath+
s" ContractGen " edname$ place

only forth also editor also forth also definitions

: >ed .. reedit ;
' >ed hidden is f1key  \ f1 in console to go to editor

overstrike on
2 to FilterIndex
' _xit is do-esc
s" WinEd.ndx" cgbase" &wined.ndx place

s" .;" search-path place    \ init search path
current-dir$ count search-path +place
s" ;\win32forth"  search-path +place
set-ed-defaults
search-path count s" SearchPathed" "SetDefault
set-w32f-default

0 to slfactor  \ slow the build try '5'  Use the space bar to start/stop
sys-warning-off


forth also forth definitions editor
0 to saved-depth
variable do-serv-flag \ Are we in local or web
create vbuf 200 1024 * allot
variable conscol -1 conscol !  \ column for output in current console line
0 value webindent  \ len of request from webby

Include patch.f         \ Hot patch a word for a temporary change
Include vSCR.f          \ +vSCR  vINDEX  >vSCR
Include CGUtils.f
Include GetAt.f         \ Screen read and write
Include SO.F            \ SO is screen output with RO Regular output
Include CUSTOM-KEYS.F   \ John's specials
Include CONVERT.F       \ Back tick and some other compiler directives
Include PRETTY.F        \ Pretty printing words including PRT# and more
Include P-OK.F          \ ELECT Vocabulary created, only load once!
Include CODE.f          \ EXTEND the prices.
Include EXTEND-PRICES.F \ Used by Ctrl+E
Include Surface.emt     \ need to load before nps.scr b/c of use of 'neat-emt'
Include nps1.f
Include nps2.f
Include OPEN-1S.SEQ     \ Walls are open-1-side
Include conpaste.f
Include GrandTot.f      \ bid-thru - extend all vscrns
Include Adding.f        \ aa - do bid-thru and display totals
Include ppsig.f         \ payment progress and signature
Include convbid.f
Include Email.f         \ create email.html for current file
Include Logger.f        \ Used as ASP  Application Service Provider
Include common.f
Include plans.scr
Include big-ok.scr
Include fish.scr
Include Ampier.scr
\ include nes-compiled.f  \ colon defs with multiple modules
forth definitions
Include Tools.f          \ SELL will add tax, overhead and profit to a part.
Include dir2seq.f
cd ..\webinterpret
include socksrvr.f
cd ..

\ note: cg won't run if next file isn 't last - I don't know why
\ Include Rent.f          \ Anti pirate

0 to slfactor           \ Zero is normal speed, Use space bar for stop/start
forth also forth definitions editor
:noname ( -- ) \ Re edit (Does not take any thing) 
  true to invkloop gethandle: docwindow call SetFocus drop
  view-key-loop ;   is reedit

: RE-Edit  reEdit ;



0 value defer-margin  \ wait to apply until file is current in editor

: setedmode ( -- )
  defer-margin 1 = if true to browse?  else
  defer-margin 2 = if true overstrike ! false to browse? else
  defer-margin 3 = if false overstrike ! false to browse? then then then ;

: (OO)   ( <optional file-name> -- ) \ Open current unless given a file name
   0 word c@                         \ Must be in right directory
   if pocket count BL SKIP "CLIP" "+open-text
      setedmode defer-margin 1 =
      if focus-console else  cursor-on-screen reEdit then
   then ;

: oo  1 to defer-margin  ['] (oo) catch 0<> if message  then ;
: OPEN  OO ;
: ooo 2 to defer-margin ['] (oo) catch 0<> if message then ;

: widesearch ( <word> -- cfa fl )   \ for 'vv' and 'vvv'
  s" .;c:\cg;\win32forth" search-path place
  bl word anyfind dup 0= if ." not found" then ;

: VV-con ( <word> -- )      \ TODO: fix hilite on viewed word, index of base
  widesearch
  if $.viewinfo dup 0< if 2drop else
     count "+open-text 0 swap 1- setedmode
     to-find-line refresh-line reEdit then
  else drop then ;

: VV-web-instructions ( <word> -- ) bl word drop cr
  ." Use VIEW <word>" cr ;

: VIEW ( <word> -- ) \ Web if warn else view the source code of the word
  in-web?
  if VV-web-instructions  \ shouldn't get here; 'view' trapped in vectint.f code
  else vv-con
  then ;

: vbk  ( -- )  \ make bookmarked file the current file
  [ editor ] vbmark ;

: v reedit ; \ edit the currently open file

: VV  ( <word> -- ) \ opens file in the editor for <word>; stays in console
   in-web?
   if vv-web-instructions
   else widesearch
    if $.viewinfo dup 0< if 2drop else
     count "+open-text 0 swap 1- 1 to defer-margin setedmode
     to-find-line refresh-line focus-console  then
    else drop then
   then ;

: vvv ( <word> -- )   \ open file in insert mode in editor
   3 to defer-margin view ;

: VVVV  ." Hay! ;-) Too many V's for me handle!" ;

: LOC .viewinfo 2drop ;

: dir-modules
  s" \cg\modules\*.*" print-dir-files ;

\ only show words in 'electric' vocab
: eWORDS         ( -<optional_name>- ) \ WORDS partial-string will focus the list
  electric [ hidden ]
  words-pocket off
  bl word uppercase c@
  if      pocket count words-pocket place
          bl word uppercase drop
          voc-link @
          begin   dup vlink>voc ( #threads cells - )
                  dup ['] electric >
                  if ['] (words) catch
                   if      cr ." Interrupted!"
                          drop TRUE       \ stop now
                   else @ dup 0= then
                  else drop @ dup 0= then
          until   drop
  else    context @ ['] (words) catch
          if      drop
                  cr ." Interrupted!"
          then
  then  ;
editor
: Done   ( -- ) save-text focus-console ." File Saved" ;
: CAF    ( -- ) Done ;  \ As in close all files
: Revert ( -- ) Revert-text ." Reverted to last save" ;
: E-B    ( -- ) revert ;
: Rev    ( -- ) revert ;
: UnDo   ( -- ) revert ;

: vp     ( -- ) prev-link v ; \ view previous file
: vprev  ( -- ) prev-view v ; \ don't close current file
: N      ( -- ) +vscr ; \ does not work
: B      ( -- ) -vscr ;
: HH     ( -- ) words ; \ You can give it a string
: EE     ( -- ) ewords ;
: WW            words ;
: DEL   ( <fname> -- ) /parse delete-file abort" failed to delete file" ;

: Title-CG   \ puts it on the top of the." console
  Z" Contract Generator 3.03.04" CONHNDL call SetWindowText drop ;

: READY clear-totals cls only forth also electric also ;

: HELLO-CG
    s" bootup" logmsg \ getuser
    Title-CG  ( current-dir$ setfdir ) s" c:\cg" &forthdir place
    -1 to dp-location cd-demo ready
    2 to newappid RunAsNewAppID 0 to with-source?   \ enable debugging
    8 16 >fontht  \ console font
    elect editor also overstrike off loadline off
    forth definitions call GetFocus to consWin
    cmdline 0= swap 0= or
    if file-to-edit$ off wined VIEW-KEY-LOOP
    else  cmdline drop c@ ascii 0 =
          if file-to-edit$ off clear-totals wined
             focus-console false to invkloop
             cmdline 2 -2 d+ evaluate
          else cmdline file-to-edit$ place  wined VIEW-KEY-LOOP
          then
    then
    quit ;
    \  clear-totals focus-console ." ok" cr quit ;
    \ ['] view-key-loop catch 0<> if message then ;

s" c:\cg\" &forthdir place

ELECT             \ Sets the vocabulary
Editor also

' Extend-Prices is My-Application
\ ' Flat-Rate     is My-Application \ changing m-in does not seem to do anything
' dotcomma-number is number

' hello-cg Save CG   .(  Saved the CG file ) cr

Bye

\s ----------------------------------------------------------------------

October 18th, 2002 - 18:49 Modified INCLUDE to load WinEd from 6.02 version
October 19th, 2002 -  9:42 Now it compiles, Now we can move foreward
November 17th 2002 - 19:53 Deffered Ctrl+W and Title-CG
January 10th, 2004 - 18:56 Only two changes left before merge
January 17th, 2004 - 12:03 Now we are using the same Wined source as the group!
                           VIEW-to-top needs an ok from the group
Sun, April 23 2006 -  8:15 We moved WinEd to our folder, not in sync with guys
