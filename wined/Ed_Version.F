\ $Id: Ed_Version.F,v 1.3 2013/08/13 23:28:23 rdack Exp $

30304 value wined_version# 

\ Version numbers: v.ww.rr
\
\ v   Major version
\ ww  Minor version
\ rr  Release
\
\ Odd minor version numbers are possibly unstable beta releases.

: (.wined_version)    ( -- addr len )
                wined_version# 0 <# # # '.' hold # # '.' hold #s #> ;

create wined-compile-version time-len allot  \ a place to save the compile time
get-local-time                               \ save as part of compiled image
time-buf wined-compile-version time-len move \ move time into buffer

\s


\ ---------------------------------------------------------------------------
\ ----------------------  Initals of developers -----------------------------
\ ---------------------------------------------------------------------------
TZ      Tom Zimmer
{BE}    Brad Eckert
BJG     Bruno Gauthier
RLS     Robert L. (Bob) Smith
RDA     Robert Dudley Ackerman
JAP     John A. Peters (japeters@pacbell.net)
RBS     Rainbow Sally
DBU     Dirk Busch (dirk@schneider-busch.de)
JOS     Jos v.d. Ven
AWS     Andrew W. Stephenson (andrewws@Optushome.com.au)
CDO     Camille Doiteau

\ ---------------------------------------------------------------------------
\ ----------------------  Change Log ----------------------------------------
\ ---------------------------------------------------------------------------

rda Circa April 2002
  The escape key is crudely functioning as a escape from the editor to the
  console window if the console window is open right behind the editor.
  Otherwise it drops back to what ever window is in back of the editor. ????

rls Circa July 2002
  Indentation is reduced to cut down on long line lengths where possible. rls

rls September 2002
  The printing function has now been extended to allow very long lines to be
  displayed.  Continuation lines (with a leading "+" sign to the left of the
  left margin) will be printed under the following circumstances: (1) the
  "show page break markers" dialog box item (under "Edit/WinEd Preferences")
  must be UNchecked.  (2) The area to be printed is selected by highlighting
  the selected area, and then choosing the "Selection" option under the
  "Print" function.  (3) The lines are longer than that nominally allowed for
  the specified paper size and orientation.

  You may print selected regions of text by highlighting any number of
  sequential lines of text, and then choosing the "Selection" option in the
  Print dialog box.  Text is highlighted by clicking the mouse in the blue
  area to the left of the first line you wish to print.  Move to the last line
  but press the "Shift" key before clicking the mouse.  Finally, select the
  File/Print function, and click on the "Selection" box, and then the "OK" box.

  Note to future implementors: Code having comments with the sequence:
        rls - page   have partially implemented the ability to display the
  proper page numbers when using the "Continuation Line" discussed above. Full
  and proper implementation of that feature appears to be somewhat complicated
  and not worth the effort at this time.  It could be done if there is
  sufficient user interest.

jap October 14th, 2002
  F2 is now COLONS-ONLY shows only lines with a bang left colon.  You can use
     it to see if there are any words with missing documentaton.
  F7 is toggle from edit to browse mode and browse mode is now black bordered.

  Ctrl+PgDn jumps to the start of each paragraph that is deleniated by a
  pair of double blank lines at the top of each paragraph.

November 15, 2002 A pole on Yahoo was 4 to 0 to ok changing the command to flip
  thru open files to Shift-PgUp and Shift-PgDn from a Control-Page up or down.
  This makes room to use Control-PgUp and Control-PgDn for next and previous
  virtual screen or paragraph as deleniated by two consecutive blank lines.

jap Circa November 2002 Control-W is deffered.  It is now bound to close-text
as Tom Zimmer designed it.  I prefer it to be bound to push-right as follows:
    : Push-right  s"  " insert-string character-left ;
    ' Push-right is _Control+w

VIEW-KEY-LOOP is split in to pargraphs.  It is the main loop in the editor.

jap and rbs F1 STARTUP.TXT menu of hypertext links is the first of the file
jap October 17th, 2002  F2 and F7 now test good on 6.01 system.
rda October 17th, 2002  Fixed the overstrike/insert toggle.
rda & jap   17th, 2002 Added a CR in boot up notice in the word win32For.cfg
rda Circa November 2002 Added Brown color in place of yellow. Yellow is missing
rda & jap November 2002 Brown color used for border in browse mode.
jap November 20th, 2002 Changed wined.col to colorize.f
rda November 24th, 2002 Editor always saves even if you switch to browse mode.
jap November 28th, 2002 Search menu: Changed SEARCHLIST.TXT to lower case.
rda Circa October, 2002 Added <OvrStrk> and <insert> on bottom status line.
jap December 1st, 2002 Re-did the reliable save after corrections to my edit.
jap December 4th, 2002 Updated the version numbers on the top blue line.
jap April 19th, 2003 Reverted Ctrl+PgUp and Ctlr+PgDn to Zimmer's orig version.
jap April 22nd, 2003 Reverted from Brown border in to Green in browse mode.

\ changes for Version 2.14
dbu April 23rd, 2003 - Wheelmouse support added
dbu April 26th, 2003 - Fixed FLOAD bug
dbu May 1st, 2003    - Fixed ESC-Key bug (sometimes WinEd crashed)
dbu May 1st to May 4th, 2003
  I did some work on the highlighting.
  It's more compatible to other Texteditor's like Notepad now.

  New shortkey's:
  +shift +control +arrow left  => highlights the next word to the left
  +shift +control +arrow right => highlights the next word to the right
  +shift +control +home        => highlights to begin of file
  ESC                          => remove's the actual highlight (see do-esc)

dbu May 4th, 2003 - Fixed bug in "Forth-Source?". Colorization didn't work on
                    files with names like WinEd2.13.f

\ changes for Version 2.15
jap May 4th, 2003 - ???

\ changes for Version 2.16
dbu May 17th, 2003 - Changed name of "colorize.f" to "WinEdColorize.f"
dbu May 18th, 2003 - Changed to allow Filenames and path's not only in uppercase
                   - Changed the file dialog's to show the correct extentions
dbu May 19th, 2003 - When user presses ESC in the search combobox, the focus
                     is moved to the active document. No search is performed.
                   - Removed the entry "Recent Files" from the File menu
                   - New menu item "Select None" in the Edit menu
                     (it remove's the actual highlight)

\ changes for Version 2.17
dbu May 20th, 2003 - WinEd ring's the bell when user tries to edit in
                     browse mode.
dbu May 24th, 2003 - New Button "Open last active File on Startup" in the
                     "WinEd Preferences" Dialog. If it's checked WinEd will
                     automatically open the last active file when it start.
                     The cursor is placed at the last location in the file.
                   - Some minor changes in "WinEd Preferences" Dialog
                     (a New WinEd.res file is needed !!!)
                   - removed old win32s support
                   - "Load a Forth source File..." didn't work - fixed

\ changes for Version 2.18
dbu May 25th, 2003 - added a replacement for win32forth-message
                   - this Version was posted to show Alex this replacement only

\ changes for Version 2.19
dbu June 1st, 2003 - Changed StartUpForth to wait until Forth is loaded
dbu June 7th, 2003 - If the user open's a *.f file by doubleclick in
                     Windows Explorer WinEd showed the short (DOS) filename
                     in the window title - fixed
dbu June 8th, 2003 - Finished the replacement for win32forth-message
                   - F12 doesn't work any more after Win32Forth crash
                     (SF-RequestID 745393) - fixed

\ changes for Version 2.20
this was never released

\ changes for Version 2.21.00
dbu July 5th, 2003 - Started to split Wined.f into smaler source files
                   - Changed format of the Version number to v.ww.rr
                   - Moved Change log to Wined_Version.f
                   - Changed "About" dialog to display the new Version number,
                     the compile date and time, and the WinEd Contributors
                   - Bug in "Find Text in Files" Dialog (SF-RequestID 745385) - fixed
                   - Replaced the "Multi-Directory File processing" with J.v.d.Ven's sub_dirs.f
dbu July 6th, 2003 - Added wildcard text search
dbu July 8th, 2003 - changed to use J.v.d.Ven's new Version of w_search.f

\ changes for Version 2.21.01 - released on July 26th, 2003 by dbu
dbu July 19th, 2003 - fixed some bug's in the wildcard text search
dbu July 20th, 2003 - added a new menu "Win32Forth" and moved the entries
                      regarding the forth console from the other menues to it.
                    - checked the internet links in the "Documentation Help" menu
                      - removed invalid and added some new ones
                      - all the links in the menu will be opend in your default browser
                    - added a new menu entry "Open Bitmap..." to the File menu
                    - sorted the menu entry's in the menus "Edit" and "Format" a bit
                    -  "Save all changed files" only saves the active file.
                       All other changed files ARE NOT saved.
                       (SF-RequestID 745383) - fixed
dbu July 26th, 2003 - WinEd now saves all open files in registry when it's
                      closed and open's them if WinEd is started.
                      You can turn this of with the Button "Open last active File
                      on Startup" in the "WinEd Preferences" Dialog.

\ changes for Version 2.21.02 - released on July 28th, 2003 by jap
jap July 28th, 2003 - Renumbered the paragraphs

\ changes for Version 2.21.03 - released on July 28th, 2003 by jap
jap July 28th, 2003 - Added a CD (ChDir) in 2 places

\ changes for Version 2.21.04 - released on July 28th, 2003 by dbu
dbu July 28th, 2003 - changed WinEd to compile under Win32Forth 6.05 and 6.06
                      without error's
                    - removed the CD's added by jap in 2.21.03

\ changes for Version 2.21.05 - released on August 17th, 2003
\ this version was only released to show how wined will look like with
\ a 'modern' toolbar.

\ changes for Version 2.21.06
\ the codebase for this Version was 2.21.04
dbu September 10th, 2003 - changed shortkey: +shift +control +end
                           now it highlights to end of file (it was used to
                           highlight the actual line)
                         - now we have a multi part statusbar
                           (based on 'Statbar.f' by Jeff Klem)
                         - made it easier to debug WinEd (see: WinEdDbg)
                         - Moved the code for the menu, status- and toolbar
                           to separate files.
dbu September 12th, 2003 - Path's are now absolute in the hyperlink ndx-files.

\ changes for Version 2.21.07
dbu September 20th, 2003 - Colorization now works for *.f *.fr and *.seq files

\ changes for Version 2.21.09
dbu October 11th, 2003   - Changed "open-text to work with the new path support

\ changes for Version 2.21.10
jap                    - added "smart-cr" for overstrike mode
dbu January 11th, 2004 - Some cleanup
dbu January 16th, 2004 - removed the console window from turnkey'ed WinEd
rda January 18th, 2004 - Fixed a bug in wined_win32forth-message

\ changes for Version 2.21.11
dbu January 31st, 2004 - "fixed" a bug in wined_win32forth-message witch caused
                         WinEd's internal console window to hang. You can open
                         WinEd's internal console window with the menu entry:
                         "Open Forth Window" in the "Win32Forth" menu.
                       - Replaced w_search.f with Jos latest(?) Version dated
                         July 21st, 2003

rda February ???, 2004 - better scrolling and cursor handling in colon's only
                         mode (F2)
                       - changed F12 to work when (wineddbg) is defined
dbu February 29th, 2004 - fixed problems when WinEd tries to open a file
                          on startup and the file doesn't exist any more
                        - changed the file list in the file menu to display only
                          files that still exist on startup

\ changes for Version 2.21.12
dbu Donnerstag, April 29 2004 - fixed VIEW bug if there is a BLANK in the
                                Filename

\ changes for Version 2.21.13
dbu Samstag, May 15 2004 - Added a "Choose..." Button to the "Find in Files..."
                           Dialog, witch opens a Dialog to browse for the
                           folder to search in.
                         - Fixed a bug in the HIGHLIGHT-CASE-TOGGLE (Strg+U)

\ changes for Version 2.21.14
dbu Samstag, May 22 2004 - Fixed a bug in the HTML-Style Hyerlinking
                         - Note: All Editor words are now in the EDITOR
                           vocabulary !
                         - Clean up of the "Documentation Help" menu
                         - Fixed the "About WinEd" dialog

\ changes for Version 2.22.01
dbu Sonntag, Juni 20 2004 - Refactored _"HYPER-LINK
                          - Better Hyper-Linking for WORD's that are defined
                            in Win32Forth.exe
                            I'm using the information from the Header in the
                            dictionary for those words and not the index-file.
                            For this WinEd.exe must now be created with
                            APPLICATION !!!

\ changes for Version 2.23.01
dbu Samstag, Juli 10 2004  - Changed Win32Forth.exe to use SendMessage to
                             send Messages to the Editor instead of
                             Boradcasting the Message using SendMessageTimeout
                           - Renamed the value 'WinEdWindow' to 'EditorWindow'
                           - Factored out the code for debugging into
                             EdDebug.f (to use it in SciEdit, too)

\ changes for Version 3.00.01
aws     Thursday February 03 2005
        - New version of loading WinEd files
          Based on the work Tom Zimmer Winview & Rainbow Sally FxEdit.
          to brake up the monster that WinEd.f has become.

\ changes for Version 3.01.02
aws     Friday February 19 2005
        - Remove file name EdeditDlg.f
          Renamed file MiscFunc.2.f to EditorWords.f
          Tided up some words

\ changes for Version 3.01.03
aws     Monday March 18 2005
        - Added Win32-API help
          White background
          Added DPR-WARNING-ON/OFF Switch for the new Deprecated word
          Removed the word (WinEdDbg) form WinEd

\ changes for Version 3.01.04
dbu	Samstag, März 12 2005
	- Some cleanup for CVS upload

\ changes for Version 3.01.05
aws     Thursday April 7 2005
        - Remove file name EditWindow.f
          Know use the word endface in file EditWindowObj.f
          Placed 2Nip into Fkernel.f so that Words (2swap 2drop) can
          be droped form WinEd files

\ changes for Version 3.01.06
aws     Wednesday April 27 2005
        - Dirk fixed Deprecated words so DPR-WARNING-ON/OFF has bean removed
          Moved files from EdEdit into WinEd dirctory

\ changes for Version 3.01.07
dbu	Sonntag, Mai 01 2005
	- Some cleanup after CVS upload of Andrew's last version

\ changes for Version 3.02.00
dbu     Samstag, August 27 2005
        - Removed some files from the CVS whitch aren't needed any more.
        - Removed WinEd's internal console window
        - Removed the "Forth Instances" display from the status bar

\ changes for Version 3.02.01
dbu     Mittwoch, Oktober 18 2006
        - Added a Bugfix from Robert L. (Bob) Smith for the FindInFiles dialog.

\ changes for Version 3.02.02
cdo     2008/06/18
        - rewritten all parts related to win32forth-specific messaging
