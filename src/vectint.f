
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
  vbuf >r r@ w@ r> 2 + swap dup 0= if drop s" ok" then ;

