
create vbuf 4 1024 * allot
2variable vec   \ save source to restore after interpret

: wplace ( addr cnt buf -- )  \ add text to word counted buffer
  over >r dup>r wcount + swap cmove r> r> swap w+! ;

: vQUERY ( addr cnt -- )
  (source) 2@ vec 2!
  (SOURCE) 2! >IN OFF 0 TO SOURCE-ID 0 TO SOURCE-POSITION ;

: vtype ( addr cnt -- )
  vbuf wplace s"  " vbuf wplace ;  \ add text to word counted buffer

: hcr crlf$ count vbuf wplace ;

: ?vcr ( n -- )
  ?dup if 64 mod 0= if hcr then then ;

: 2crlfs ( addr len -- addr len )
   crlf$ count vbuf place crlf$ count vbuf +place
   vbuf count search -1 =
   if 4 - swap 4 + swap else 2drop 0 0 then ;

\ interpret input from a string; result in a string
: vectint ( addr cnt -- addr cnt)  \ vectored interpret
  0 vbuf w!
   ['] vtype is type
   ['] hcr is cr
   ['] ?vcr is ?cr
   vquery
   ['] _interpret
   catch
    vec 2@ (source) 2!
    [ hidden ] ['] c_type is type ['] c_cr is cr
    ['] c_?cr is ?cr
    ?dup if ." error " . then
    s"  ok " vbuf wplace crlf$ count vbuf wplace vbuf wcount ;

: sendline ( addr cnt -- )
  ssock WriteSocketLine drop ;

: sendheaders ( clen -- )        \ headers to browser including content-length
   s" HTTP/1.1 200 OK" sendline
   s" Content-type: text/html" sendline
   s" Server: Forth" sendline
   s" Content-length: " b2sock
   0 (d.) sendline crlf$ count b2sock ;
   \ 'sendline' sends 1 crlf; 2nd empty line needed before data

: sendfile ( addr cnt -- )
   r/o open-file not
   if >r vbuf 2048 r@ read-file not
      if  dup sendheaders
          vbuf swap b2sock
      else drop then r> close-file
   then drop ;

: srvrinput ( addr cnt -- )
   \ check for webpage request
   \ first line has GET <path> HTTP
   \ else client wants forth executed
   \ get past headers to data
   over 3 s" GET" compare not
   if 2drop
     s" \cg\src\webinterpret\webinterpret-f.html" sendfile
   else 2crlfs ?dup if 2dup type cr \ remove headers
        vectint 2dup type dup sendheaders b2sock
       else drop then
   then ;



