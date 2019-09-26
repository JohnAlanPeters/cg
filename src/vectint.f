
create vbuf 200 1024 * allot
2variable vec   \ save source to restore after interpret

: wplace ( addr cnt buf -- )  \ add text to word counted buffer
  over >r dup>r wcount + swap cmove r> r> swap w+! ;

: vQUERY ( addr cnt -- )
  dup conscol !
  (source) 2@ vec 2!
  (SOURCE) 2! >IN OFF 0 TO SOURCE-ID 0 TO SOURCE-POSITION ;

: vtype ( addr cnt -- )
  dup conscol +!
  vbuf wplace ;  \  s"  " vbuf wplace ;  \ add text to word counted buffer

: vcr conscol off crlf$ count 1- vbuf wplace ;

: ?vcr ( n -- )
  ?dup if 100 mod 0= if vcr then then ;

: vemit ( c -- ) 1 conscol +!
  sp@ 1 vbuf wplace drop ;

: vgetxy ( -- col row )
  conscol @ 100 > if vcr then conscol @ 0 ;

: vgetcolrow ( -- col row )
   100 32 ;

: 2crlfs ( addr len -- addr len )
   crlf$ count vbuf place crlf$ count vbuf +place
   vbuf count search -1 =
   if 4 - swap 4 + swap else 2drop 0 0 then ;

\ interpret input from a string; result in a string
: vectint ( addr cnt -- addr cnt)  \ vectored interpret
  0 vbuf w!
   ['] vtype is type
   ['] vcr is cr
   ['] ?vcr is ?cr
   ['] vemit is emit
   ['] vgetxy is getxy
   ['] vgetcolrow is getcolrow
   vquery
   ['] _interpret
   catch
    ?dup if ." error " dup . then
    vec 2@ (source) 2!
    [ hidden ] ['] c_emit is emit  ['] c_type is type ['] c_cr is cr
    ['] c_?cr is ?cr ['] c_getxy is getxy ['] c_getcolrow is getcolrow
     -1 conscol !  \ switch to ordinary output
    \ ?dup if ." error " . .. then
    s"  ok " vbuf wplace crlf$ count 1- vbuf wplace vbuf wcount ;

: sendline ( addr cnt -- )
  ssock WriteSocketLine drop ;

: sendheaders ( clen htmlflag -- )        \ headers to browser including content-length
   s" HTTP/1.1 200 OK" sendline
   if s" Content-type: text/html"
   else s" Content-type: text/plain" then sendline
   s" Server: Forth" sendline
   s" Content-length: " b2sock
   0 (d.) sendline crlf$ count b2sock ;
   \ 'sendline' sends 1 crlf; 2nd empty line needed before data

: sendfile ( addr cnt -- )
   r/o open-file not
   if >r vbuf 4096 r@ read-file not
      if  dup 1 sendheaders
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
   else 2crlfs ?dup if \ remove headers
        2dup type
        vectint
        cr 2dup type
        dup 0 sendheaders b2sock
       else drop then
   then ;



