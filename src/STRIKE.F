voila!

: _overstrike-character (char -- )    \ this is a new word
   dup bl >=
   over 0xff <= and
   if get-cursr-line                         \ get text from file into 
buffer
      cur-buf lcount cursor-col >  \ don't do it if at end of line
      if cursor-col + c!                     \ put new character into 
buffer
         put-cursor-line                   \ buffer back to file
         file-has-changed
         1 +col-cursor                     \ bump cursor
      else 2drop beep
     then
else drop beep then ;

variable overstrike                       \ new variable - toggle with 
Insert key

: insert-character ( char -- )       \ modified word
   browse?
   if drop exit then
   delete-highlight
   overstrike @
   if _overstrike-character
   else _insert-character
   then ?wrap-word refresh-line ;

in view-key-loop for case k-insert, replace comment to ignore the key 
with:
 >>  overstrike @ 0= overstrike !
toggles mode between insert and overstrike.
we could make code so that overstrike adds character to line if cursor 
is at end of line.

