\ usage: init-sockets do-client SocketsCleanup
\ assumes send linse, get linse in loop
\ this version serves webpage directly instead of going through python

anew dosock
fload sockets    \ Windows Sockets By Andrey Cherezov
create ssrvr ," 127.0.0.1" 0 c,
4444 value sport      \ arbitrary

0 value ssock
0 value srvrsock
250 value szbuf
create rbuf szbuf allot

: init-sockets            \ call once per forth startup
   SocketsStartup  abort" SocketsStartup error."
   cr  ." IP: " my-ip-addr NtoA type  cr ;

: init-client    \ connect to server
  ssrvr count  sport
  CLIENT-OPEN to ssock ;

: init-server    \ accept connection from client
  CreateSocket abort" can't create socket"
  to srvrsock
  sport srvrsock BindSocket abort" can't bind to port"
  srvrsock ListenSocket abort" can't listen"
  ." waiting to accept client" cr
  rbuf szbuf srvrsock SOCKET-ACCEPT abort" can't accept"
  to ssock ." server is accepted" cr ;

: sockread ( -- addr cnt )      \ wait for input
  begin  key? 27 = if -1 exit then   \ quit on escape
   250 ms  \ pause
   ssock ToRead abort" can't get # to read" ?dup
  until  \ loop until something to read
  rbuf swap ssock ReadSocket abort" can't read socket"
  rbuf swap ;

: sockwrite ( -- fl )  \ get text from keybrd and xmit it. -- 0 => ok
   pad szbuf erase
   pad szbuf accept       \ get line
   pad szbuf 0 scan       \  -- adr len-left
   drop pad - dup         \  -- len len
   if pad swap ssock      \ cnt -- adr cnt s
      WriteSocket abort" can't write socket" true
   then cr 0= ;

: b2sock ( adr cnt -- )
  ssock WriteSocket abort" failed socket write" ;

fload ..\vectint      \ load here to access code above

\ connect to server, read input, xmit kybrd til emptyline
: do-client init-client
  sockread type cr .. [ editor ] 0 to saved-depth
  begin  sockread vectint
    ( 2dup type cr ) b2sock false
  until ssock closeSocket ;

\ accept connection, xmit msg, read input, xmit kybrd til emptyline
: do-server init-server  \ how fork? - only 1 client for now
  begin sockread dup -1 =
    if true
    else type
     srvrinput  \ either send webpage or execute the forth
     false
    then
  until srvrsock closeSocket ;


