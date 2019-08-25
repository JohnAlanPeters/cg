
create vbuf 200 1024 * allot
variable vec

: pplace ( addr cnt buf -- )
  dup >r 2 + r@ w@ + swap >r r@ cmove
  r> r@ w@ + r> w! ;

: vQUERY ( addr cnt -- )
  (SOURCE) 2! >IN OFF 0 TO SOURCE-ID 0 TO SOURCE-POSITION ;

: vtype ( addr cnt -- )
  vbuf pplace s"  " vbuf pplace ;  \ add text to a counted string

: hcr crlf$ count vbuf pplace ;

: ?vcr ( n -- )
  ?dup if 64 mod 0= if hcr then then ;

: 2crlfs ( addr len -- addr len )
   crlf$ count vbuf place crlf$ count vbuf +place
   vbuf count search -1 =
   if 4 - swap 4 + swap else 2drop 0  0 then ;

\ interpret input from a string; result in a string
: vectint ( addr cnt -- addr cnt)  \ vectored interpret
  0 vbuf w!
  ['] vtype is type
  ['] hcr is cr
  ['] ?vcr is ?cr
  ['] 2drop is gotoxy
  vquery
  ['] interpret
  catch ?dup if ." error " . then
   [ hidden ] ['] c_type is type ['] c_cr is cr
   ['] c_gotoxy is gotoxy ['] c_?cr is ?cr
  vbuf >r r@ w@ r> 2 + swap dup 0= if 2drop s" ok" then ;

: sendline ( addr cnt -- )
  ssock WriteSocketLine drop ;

: scontentlen ( len -- )
   s" Content-length: " b2sock
   0 (d.) sendline crlf$ count b2sock ;

: sendfile ( addr cnt -- )
   r/o open-file not
   if >r vbuf 2048 r@ read-file not
      if  dup scontentlen
          vbuf swap b2sock
      else drop then r> close-file
   then drop ;

: srvrinput ( addr cnt -- )
   \ check for webpage request
   \ first line has GET <path> HTTP
   \ else client wants forth executed
   \ get past headers to data
   s" HTTP/1.1 200 OK" sendline
   s" Content-type: text/html" sendline
   s" Server: Forth" sendline
   over 3 s" GET" compare not
   if 2drop
     s" \cg\src\webinterpret\webinterpret-f.html" sendfile
   else 2crlfs 2dup type cr \ remove headers
        vectint dup scontentlen cr 2dup type cr b2sock
   then ;




