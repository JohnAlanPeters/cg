\ Simple HTTP Server
\ Tom Dixon

needs SCOOP     \ scopes
needs DSTR      \ dynamic strings
needs sock      \ socket library
needs sockserv  \ socket server extention
needs HTTPerr   \ http error codes

\ Make the http request object
scope httpreq
with httpreq definitions

  \ Size of a request
  2 cells with dstr size endwith 2 * + CONSTANT size
  
  \ Data members
  : code ( -- addr ) servdata ;
  : file ( -- addr ) servdata cell+ ;
  : request ( -- dstr ) servdata 2 cells + ;
  : reply ( -- dstr ) servdata with dstr size endwith + 2 cells + ;
  
  1000 CONSTANT pktsize \ size of chunk to send
  create stopstr 4 c, 13 c, 10 c, 13 c, 10 c,
  create hbuf 256 allot \ temporary buffer
  
  0 value urllist  \ URL processing list
  
  defer next-req ' noop is next-req \ pass on to next request
    
  : freestrs ( -- ) \ free all strings and files
    with dstr
      request free
      reply free
    endwith 
    file @ if file @ close-file drop 0 file ! then ;
  
  : -lf ( addr len -- addr len ) \ trim the last line feed
    dup if 2dup + 1- c@ 13 = if 1- then then ;
  
  : toline ( n str len -- str len ) \ get the nth line
    rot 0 ?do 10 scan 10 skip loop 
    2dup 10 scan nip - -lf ;
    
  : toarg ( n str len -- str len ) \ get the nth argument
    rot 0 ?do bl scan bl skip loop 
    2dup bl scan nip - ;
    
  : getparam ( arg line -- str len ) \ get a parameter from the header
    request with dstr count endwith
    toline toarg ;
  
  : param ( str len -- str len ) \ gets a HTTP header parameter
    with dstr 
      request count 2swap search 
      if bl scan bl skip 2dup 10 scan nip - -lf -trailing
      else 2drop s" " then 
    endwith ;
    
  : url ( --  str len ) 1 0 getparam ; \ requested URL
  
  : (crcr?) ( dstr -- str len flag ) 
    with dstr count endwith stopstr count search ;
    
  : crcr? ( -- str len flag ) request (crcr?) ; \ search for double cr
  
  : bodylen ( -- n ) \ size of body
    file @ if file @ file-size drop d>s 
    else reply (crcr?) if nip 4 - else 2drop 0 then then ; 
    
  : stdheader ( -- ) \ generate a standard header
    s" HTTP/1.1 " hbuf place
    code @ (.) hbuf +place  s"  " hbuf +place 
    code @ err-code hbuf +place
    stopstr 1+ 2 hbuf +place
    s" Server: Win32forth " hbuf +place
    version# (.) hbuf +place s"  " hbuf +place build# (.) hbuf +place
    stopstr 1+ 2 hbuf +place
    bodylen if s" Content-Length: " hbuf +place bodylen (.) hbuf +place then
    stopstr 1+ 2 hbuf +place
    hbuf count reply with dstr prepend endwith ;
  

  \ socket server vectors
  : http-connect ( -- ) freestrs ;
  
  : http-Close ( -- ) freestrs ;
    
  : http-write ( -- )
    begin servsock sock-write? 0> while
      code @ reply with dstr count nip endwith >= if
        file @ if 
          hbuf 256 file @ read-file drop dup
          if hbuf swap servsock sock-write drop 
          else drop next-req exit then
        else
          next-req exit
        then
      else
        code @ pktsize reply with dstr mid endwith
        servsock sock-write code +!        
      then 
    repeat ;

  : http-done ( -- ) 
    stdheader 0 code ! ['] http-write onWrite! ;
    
  : process ( -- ) 
    urllist >r
    begin r@ while
      r@ cell+ @ execute if r> 2 cells + @ onWrite! exit then
      r> lrest >r 
    repeat r@ drop ;
  
  : http-read ( -- ) 
    begin servsock sock-read? 0> while
      hbuf 255 servsock sock-read hbuf swap
      request with dstr append endwith
      drop true
    repeat 
    crcr? nip nip if 
      200 code ! ['] process onWrite! ['] noop onRead! 
    then ;

\ Start next request     
  : connclose? ( -- flag ) 
    s" Connection:" param s" close" istr=
    reply with dstr count endwith 
    s" Content-Length:" search nip nip 0= or ;

  : next-request ( -- ) 
    file @ if file @ close-file drop 0 file ! then 
    connclose? if freestrs close-client exit then 
    crcr? if 4 /string 
      with dstr 
        reply place 
        reply count request place 
        reply free 
      endwith 
    else with dstr request free endwith then 
    ['] noop onWrite! 
    ['] http-read onRead! ;  
    
  ' next-request is next-req
    
  \ some simple IO overloading
  : type ( str len -- ) reply with dstr append endwith ;
  : cr ( -- ) stopstr count drop 2 type ;
  : emit ( n -- ) hbuf c! hbuf 1 type ;
  : space ( -- ) bl emit ;
  : . ( n -- ) (.) type ;
  : ." ( "str" -- ) [char] " parse type ;
    
endwiths definitions


\ Setup the initial vectors of a HTTP server
: setup-http ( server -- )
  serv-vecselect
  with httpreq
    ['] http-connect  onConnect!
    ['] http-read     onRead!
    ['] http-close    onClose!
    ['] noop          onWrite!
  endwith ;

\ Define a HTTP Server
: httpserver ( port <name> -- ) 
  with httpreq size endwith swap sockserver ;


\ This is how you add components to the http server

: doURL ( <test-xt> <do-xt> -- ) 
  node, ' , ' , with httpreq urllist cons to urllist endwith ;
  
\ test-xt returns a flag if the compnent accepts the request.
\ if accepted, do-xt will be called repetatively each time 
\ the server polls until 'http-done' is called by it.


\ default behavior for HTTP server
with httpreq
  : doNotFound ( -- )  404 code !
    s" <html><body>HTTP Error 404 - File or directory not found.</body></html>" type
    http-done ;
  doURL true doNotFound
endwith


\ extra functionality is added to the HTTP server through
\ the 'doURL' function.  See HTTPecho for a simple example.
