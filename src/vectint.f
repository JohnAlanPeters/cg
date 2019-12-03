
create vbuf 200 1024 * allot
2variable vec   \ save source to restore after interpret

: wplace ( addr cnt buf -- )  \ add text to word counted buffer
  over >r dup>r wcount + swap cmove r> r> swap w+! ;

: vQUERY ( addr cnt -- )
  dup conscol !
  (source) 2@ vec 2!
  (SOURCE) 2! >IN OFF 0 TO SOURCE-ID 0 TO SOURCE-POSITION ;

: vcr ( -- )      \ virtual CR
  conscol off crlf$ count 1- vbuf wplace ;

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
  conscol          \ a variable for the current console line
  @                \ fetch the current virtual console line
  getcolrow drop >        \ return true if n1 is greater than #columns
  if vcr           \
  then conscol @ [ hidden ] C_GETXY nip ;

: 2crlfs ( addr len -- addr len )
   crlf$ count vbuf place crlf$ count vbuf +place
   vbuf count search -1 =
   if 4 - swap 4 + swap else 2drop 0 0 then ;

: to-web
   ['] vemit is emit
   ['] vtype is type  \ add text to word counted buffer
   ['] ?vcr is ?cr
   ['] vcr is cr      \ virtual CR
   ['] vgetxy is getxy ;

: to-con
   [ hidden ]
   ['] c_emit is emit
   ['] c_type is type
   ['] c_cr is cr
   ['] c_?cr is ?cr
   ['] c_getxy is getxy ;


\ interpret input from a string; result in a string
: vectint ( addr cnt -- addr cnt)  \ vectored interpret
   0 vbuf             \ a 200 KB 2variable to save response from interpreting
   w!  ( w1 a1 -- )   \ store word (16bit) w1 into address a1
   to-web
   vquery
   ['] _interpret
   catch
   ?dup if ."  error " . then
   vec 2@ (source) 2!
   to-con
   -1 conscol !         \ switch to ordinary output
   vbuf w@ if s"  " vbuf wplace then
   s" ok " vbuf wplace crlf$ count 1- vbuf wplace vbuf wcount ;

: sendline ( addr cnt -- ) \ send a line to the socket
  ssock                    \ a self fetchng value named ssock init to zero
  ( addr u s -- ior )
  WriteSocketLine drop ;   \  ( addr u s -- ior ) \ drop the I/O remainder

: sendheaders ( clen htmlflag -- ) \ send headers to browser inc content-length
   s" HTTP/1.1 200 OK" sendline
   if s" Content-type: text/html"
   else s" Content-type: text/plain" then sendline
   s" Server: Forth" sendline
   s" Content-length: "         \ mesage compiler invoked by using a selector?
   b2sock                       \ write a byte(s) to the server socket
   0 (d.)                       \ convert a signed double to a strig
   sendline crlf$               \ compile 13 10 into a string of the length of 2 bites
   count b2sock ;               \ write a bit to the socket
                                \ 'sendline' sends 1 crlf
                                \ 2nd empty line needed before sending data

: sendfile ( addr cnt -- )      \ no problems here
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
     s" \cg\src\webinterpret\webinterpret-f.html" sendfile
   else 2crlfs              \ chop off headers up to 2 CRLFs to get to data  \ rda told me ( 2 headers? not one?) 
       ?dup                \ duplicate the len of the request string if not zero
       if                  \ test for true which is anything but a zero
         2dup type         \ type the forth command to the surface console
         vectint           \ get output of request into buffer
       else drop s" ok" then       \ no data, then skip it
       cr 2dup type        \ display response in console
       dup 0 sendheaders   \ send the HTML headers
       b2sock              \ send the response to the socket
   then ;



