\ MODIFY.F      A file for words that improve or modify the Win32Forth system
\ here is code to insert text It takes the address and count of text to insert
\ and a line# to insert at.
\ ' s" abc" 4 process-line' is an example of inserting text to line #4.
Comment:
This is already inserted


: PROCESS-LINE  ( addr cnt line# -- )  \ RDA September 2001
   [ editor ]
   to cursor-line                    \ set line
   >r get-cursor-line
   cur-buf lcount dup 48 >
   if 48 cur-buf c! drop 48 then +
   r> dup cur-buf c@ + cur-buf c!    \ set new length
   move
   put-cursor-line file-has-changed refresh-line ;

: test-pl s" Insert me in to the file at line 17" 17 process-line ;

Comment;
