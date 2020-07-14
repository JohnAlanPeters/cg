2variable vec   \ save source to restore after interpret
0 value sentcr

defer to-con   \ temp while debugging vcr
defer to-web

: sendline ( addr cnt -- ) \ send a line to the socket
  ssock                    \ the socket connected to webpage
  WriteSocketLine drop ;   \  ( addr u s -- ) \ drop the I/O remainder

: sendheaders ( clen htmlflag -- ) \ send headers to browser inc content-length
   s" HTTP/1.1 200 OK" sendline
   dup 2 = if s" ForthContinue: 2" sendline 1 to sentcr 0= else
   dup 3 = if s" ForthContinue: 3" sendline 0= else
   dup 5 = if s" ForthContinue: 5" sendline 0= then then then
   if s" Content-type: text/html"
   else s" Content-type: text/plain" then sendline
   s" Server: Forth" sendline
   s" Content-length: " b2sock
   0 (d.) sendline              \ send double value of data length
   crlf$ count b2sock ;         \ 1 empty line needed before sending data

: wplace ( addr cnt buf -- )  \ add text to word counted buffer
  over >r dup>r wcount + swap cmove r> r> swap w+! ;

: vQUERY ( addr cnt -- )
  dup conscol ! dup to webindent
  (source) 2@ vec 2!
  (SOURCE) 2! >IN OFF 0 TO SOURCE-ID 0 TO SOURCE-POSITION ;

: chkcntnu ( addr len -- )  \ 3->start/stop  4->end long response
  + 1- c@ dup ascii 3 =     \ pause
    if drop vbuf wcount dup 3 sendheaders b2sock
       sockread 2drop       \ ready for send next line of response
    else ascii 4 = if 4 to sentcr s" interrupted" vbuf wplace abort then then ;

: vcr ( -- )         \ virtual CR
  200 ms
  crlf$ 2 + 1 vbuf wplace     \ add newline=linefeed=decimal-10=hex-0a
  vbuf wcount dup 2 sendheaders
  2dup data>fuser
  b2sock                      \ send the response to the socket
  conscol off 0 vbuf w!       \ ready for next line
  sockread chkcntnu ;         \ get continue request from webpage

: ?vcr ( n -- )   \ if past #visible columns, do a cr
  ?dup            \ ignore if zero characters to output
  if conscol @ + getcolrow drop >   \ check if we need a cr
   if vcr then         \ send a virtual CR
  then ;

: vtype ( addr cnt -- )
  dup ?vcr
  dup conscol +!
  vbuf wplace ;   \  add text to word counted buffer

: vemit ( c -- ) 1 conscol +!
  sp@ 1 vbuf wplace drop ;

: vgetxy ( -- col row )
  conscol @               \ length of current output line
  getcolrow drop >        \ return true if n1 is greater than #columns
  if vcr           \
  then conscol @ [ hidden ] C_GETXY nip ;

: _to-web
   ['] vemit is emit
   ['] vtype is type  \ add text to word counted buffer
   ['] ?vcr is ?cr
   ['] vcr is cr      \ virtual CR
   ['] vgetxy is getxy ;

: _to-con
   [ hidden ]
   ['] c_emit is emit
   ['] c_type is type
   ['] c_cr is cr
   ['] c_?cr is ?cr
   ['] c_getxy is getxy ;

' _to-con is to-con
' _to-web is to-web

: 2crlfs ( addr len -- addr len )
   crlf$ count vbuf place crlf$ count vbuf +place
   vbuf count search -1 =
   if 4 - swap 4 + swap else 2drop 0 0 then ;

\ interpret input from a string; result in a string
: vectint ( addr cnt -- addr cnt)  \ vectored interpret
   0 vbuf w! 0 to sentcr  \ a 200 KB buffer to save response from interpreting
   to-web                 \ vector console output to vbuf buffer
   vquery                 \ get ready to interpret request
   ['] _interpret
   catch
   ?dup if sentcr 4 = if drop else ."  error " . then then
   vec 2@ (source) 2!
   -1 conscol ! 0 to in-web? to-con     \ switch to ordinary output
   s"  ok " vbuf wplace crlf$ 2 + 1 vbuf wplace vbuf wcount ; \ ' ok lf' added

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
   \ else client wants Forth executed
   \ get past headers to the data
   over 3 s" GET"           \ address over to the top of stack
   compare not              \ compare the comand string and the string with the 'GET'
   if 2drop                 \ if not = drop the address of both strings and send HTML file
     s" \cg\webinterpret\webinterpret-f.html" sendfile
   else
     2crlfs              \ chop off headers up to 2 CRLFs to get to data
     2dup data>fuser ( type )        \ type the forth command to the surface console
     2dup type cr
     vectint             \ get output of request into buffer
     2dup data>fuser   cr 2dup type      \ display response in console
     dup sentcr if 5 else 0 then sendheaders   \ send the HTML headers
     b2sock             
 \ send the response to the socket
   then ;

