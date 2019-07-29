
create vbuf 200 1024 * allot        
variable vec

: pplace ( addr cnt buf -- )
  dup >r 2 + r@ w@ + swap >r r@ cmove
  r> r@ w@ + r> w! ;

: vQUERY ( addr cnt -- )
  (SOURCE) 2! >IN OFF 0 TO SOURCE-ID 0 TO SOURCE-POSITION ;

: vtype ( addr cnt -- )
  vbuf pplace s"  " vbuf pplace ;  \ add text to a counted string

: hcr s" <br>" vbuf pplace ;

: ?vcr ( n -- )
  ?dup if 64 mod 0= if hcr then then ;

\ interpret input from a string; result in a string
: vectint ( addr cnt -- addr cnt)  \ vectored interpret
  0 vbuf w!
  ['] type 4 + @ vec !
  ['] vtype is type
  ['] hcr is cr
  ['] ?vcr is ?cr
  ['] 2drop is gotoxy
  vquery
  ['] interpret
  catch ?dup if ." error " . then
  vec @ is type
  vbuf >r r@ w@ r> 2 + swap dup 0= if drop s" ok" then ;

: sendline ( addr cnt -- )
  pad place crlf$ count pad +place pad count b2sock ;

: srvrinput ( addr cnt -- addr cnt )
   \ check for webpage request
   \ first line has GET <path> HTTP
   \ assume if path == "\4th", client wants a webpage;
   \ else, if path == "\4th" client wants forth executed
   \ TODO: search for path; get past headers to data; edit webpage html
   s" HTTP/1.1 200 OK " sendline
   s" Content-type: text-html" sendline
   crlf$ count vec place crlf$ count vec +place vec count b2sock
   s" <!DOCTYPE html><title>webby</title><body>my my said the s to the f</body></html>" sendline
  ;

