\ CRIB DOCUMENTATON Revision date is October 27, 2001+


<B>GETTING STARTED</B>


SIZING THE CONSOLE WINDOW
When you bootup Win32 Forth, the first window you will see is the console
window. Resize (shrink) the window to about 1/4 of the screen. Do this by using
the mouse on any of the borders or lower right corner of the console window.
If the adjustable line at the bottom of your screen is behind the "Tray" you
may have to use the mouse on the blue top border and move the whole window up a
little bit so you can see the bottom border line. After you size the window to
about 1/4 of the screen you can move it to the bottom of your computer screen,
leaving room for the WinView edit window above the console window in the top 3/4 of
your computer screen.

RESIZE THE EDITOR WINDOW
Tap F1 or type BROWSE CRIB to open CRIB.F or any other other file in the
editor window. It usually opens up in full screen mode.  Resize the window to
fit the top 3/4 of your screen.  This setting will be recorded in the system
registry for future default. Now you are all set to be able to see the file
you are working on while still having a command line available.

DEBUG WITH SOURCE FILE DISPLAY
This is useful when you debug a word, because the debugger will show the usual
output in the console while at the same time opening the source file and
stepping the cursor through the code as you execute each word!  In fact you can
see the word that will execute next, before it is executed and take the time to
decide if you want to execute it or nest down one level or quit and so on.

WORD WRAP
Is not too obvious. It cuts in when you enter a space.  If you have a line that
is longer than the red border line at the right end of the editor, delete a
space between two words and then hit the space bar and the paragraph will
reformat from that line down using word wrap.


CHANGES AND ADDTIONS
These features have been added to my version with the help of Robert Ackerman.
They are awaiting the emergence of a volunteer who is needed to check the code.
Another volunteer is needed to issue a new version number, make a self
extracting zip file and mount the files on the Silicon Valley FIG chapter web
page.

Insert/Overstrike mode switch is now implemented, but it needs a mode indicator
to show the user which mode we are in.  You may not need this but I do.

Pge+Dn now goes to the first double set of blank lines. The advantage of this is
that the Page-Down key jumps to the head of the next paragraph, not just down
some partial screen full.

F7 now toggles between Edit mode and Brows mode


THE NORMAL COMMANDS WORK
Most of the Word Star keys work
^S     Saves the current file
View   Views the file in Browse mode
Toggle to the editor via Shift+F9
Hyper+ Put the hand on a word in browse mode and use enter
Hyper- Use F10 to get back to where you were.  (Very nice!)
V      View,  as in  V WORD  will take you to the source for the word.
BROWS word-name   to look at the source
DEBUG  word is fine
       Click on the other screen to get back.
^T     Takes the next word to the clipboard.
EDIT   File-Name  Creates one if it does not exist.
Shift+F10  Save all files and exit


HOW TO MODIFY THE WINVIEW EDITOR
The WinView editor is a stand-alone WINVIEW.IMG file that is called by
WINVIEW.EXE  The exe file does not change every time you change the editor and
save it

To be able to view the editor words you have to FLOAD WINVIEW on top of the
normal Win32Forth that you have running.  After you do this you can VIEW words
in the editor.  The main editor loop is VIEW-KEY-LOOP, which is a 3 page long
case statement.  Here you can change the assignment of any of the keys.


WISH LIST
When saving a file and more than one file is open, have the system tell the
user which file it is talking about when it asks "Save current file?"

A single key or a word to use from the command line, to close a file.

Smooth scrolling.

Redefine COMMENT: to emit all text to the screen in another color.
Redefine COMMENT; to emit in the default text color.

The above will make it clear to the reader which text is code and
which text is comments and documentation.

Smart CR or Enter to follow the left side of the text

Smarter Page+Down that can deal better with multiple blank lines.


COMMANDS THAT WORK
^G    Slurp the next character
I want ^Q+G  to slurp the whole line.
^Y    Is LINE-DELETE  I want it to work with ^V to paste it back.
^F    does a Find, I want to change to Foreword-Word
F8    (unused) I want to alternate between Undo last changes or delete
paragraph F10   Save the file
F6    Paste from the clip board
Note  Most all the above delete words update the clipboard too.


UNKNOWN  How do you use these?
DOS
SHELL


THERE IS A TUTORIAL ON LINE
http://www.sunterr.demon.co.uk/TutFile2/header2.htm

Send a CC of your changes and suggestions to japeters@pacbell.net as well as
publish your ideas at COMP.LANG.FORTH via Yahoo Groups.  Go to
http://www.Google.com/  and you will have a choice of 1)Web, 2)Images,
3)Groups, or 4)Directory. Click on the Google Groups.  In the search window
enter COMP.LANG.FORTH (Include the dots between each word)  You will be
greeted with a choice of messages threaded by topic.  Choose one and click on
it.  The nice thing is that all the messages are presented in a long scrolling
field.  In the old days of usenet you had to call each message and wait for it
to arrive.

When you are done reading, use the little black <<BACK button in the frame on
the left side of the screen instead of the browser back button.  To post a
follow-up message you will have to sign-up with Google, but it is free and
easy.

John A. Peters
File name is CRIB.F

