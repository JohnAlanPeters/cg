\ This file is to be INCLUDED in WinEd.f just before VIEW-KEY-LOOP
\ +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
\       Additions by John Peters, Coded by Robert Ackerman 2001
\ +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


: xit  focus-console r> drop exit ;
\ Allows one to exit from the editor.

\ Here is the version with no line length limit:
: OVERSTRIKE-CHARACTER ( char -- )     \ was _overstrike
   dup bl >= over 0xff <= and
   if get-cursor-line
      cur-buf lcount drop \ start of text in buffer
     cursor-col + c!                 \ put character into buffer
     cur-buf @ cursor-col max 1+ "LCLIP" cur-buf !    \ increment buf size
     put-cursor-line
     file-has-changed
     1 +col-cursor
  else drop beep then ;


variable OVERSTRIKE  ( insert )        \ new variable - toggle with insert key
: INSERT-CHARACTER   ( char -- )       \ modified word replaces the original
   browse?
   IF      drop
           EXIT
   THEN
   delete-highlight

( Test for ins/over mode and do it. jap )
   overstrike @
   if overstrike-character      \ was _overstrike-character or what!!
   else _insert-character
   then

   ?wrap-word
   refresh-line ;

cr .( It is redefined to handle overstrike mode )  ( jap )
   .( It works well and can be merged if you want to do it )              

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\       Instructions for adding to WinEd.f
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
((
In view-key-loop at case k-insert, replace comment to ignore the key with:
      overstrike @ 0= overstrike !
 toggles mode between insert and overstrike.
))


\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ These handle the backspace properly when in th overstrike mode
\ by Robert Ackerman with John Peters on March 9th, 2002 - 10:15 to 11:20
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

: DEL-CHAR ( -- )   \  sub for k_delete  \ May not be working ok.              
   overstrike @
   if bl overstrike-character
   else delete-character
   then ;

: DO-BS ( -- )    \ sub for k_backspace
   overstrike @
   if cursor-col 0>
      if cursor-col 1- dup to cursor-col
         bl overstrike-character
         to cursor-col
     then
   else do-backspace
   then ;

