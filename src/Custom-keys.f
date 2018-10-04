\ Id:
\ CUSTOM-KEYS.F  Rev 1.01  November 16th, 2002 - 10:58
\ Custom keys for John Peters in the CG application
\ This application uses Wined merged with the console.
\ E becomes not unique when re-used in my application.
\ It stands for each as in 100 e
\ We also use C for per hundred and M as per thousand.

                 

forth also forth definitions
: Load   Fload ;
: BB   ( word -- )   Browse ;      \ This one works from here!!
\ : ED   ( name )  Z ;     \ Split brain  use OO

\ Ctrl+W  shove text right. This one is needed

\ : VP   ( -- )  [ editor ]  close-text ;  \ Says undefined yet hyper works!!

\ Alias .order order \ Not working here
\ Alias .vocs vocs   \ Not working here



Comment:  SPECIFICATIONS  How it should be.

V   ( ---- )  Activate the editor & move the cursor to the currently open file.
              Position the cursor at the location where it was last time.
              It is used only after opening a file or if a file is still open.

VV  ( word )  Short hand for View. View the source of a word in the editor

BB  ( word )  Browse the given word ready to hyper-link around.
              Do not exit browse mode and fall in to edit mode.

VP  ( ---- )  Short for View-Previous re-opens the previous file in a list
              Remembers where the cursor was the last time.

BB VV ED all can be programmed to work either with a given word or a given file.

INSERT mode to be indicated in the dark blue line at the top of screen instead
of at the bottom?

Comment;
