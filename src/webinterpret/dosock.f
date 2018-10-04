\ usage: init-sockets do-client SocketsCleanup
\ assumes send a line, get a line in loop til empty send (cr)

anew dosock
fload sockets    \ Windows Sockets By Andrey Cherezov
fload ..\vectint
create ssrvr ," 127.0.0.1" 0 c,
9999 value sport                       \ arbitrary

0 value ssock
0 value srvrsock
250 value szbuf
create rbuf szbuf allot

: init-sockets            \ call once per forth startup
   \ avoid hang in client forth while waiting for keybrd input
   \ ['] 2drop is win32forth-message   \ should restore when done
   SocketsStartup  abort" SocketsStartup error."
   cr  ." IP: " my-ip-addr   NtoA type  cr ;

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
  begin  ( key? ) 1 0= if exit then   \ abort on keystroke
   250 ms  \ pause
   ssock ToRead abort" can't get # to read" ?dup
  until  \ something to read
  rbuf swap ssock ReadSocket abort" can't read socket"
  rbuf swap ;        \ display the input

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

\ connect to server, read input, xmit kybrd til emptyline
: do-client init-client
  sockread type cr
  begin  sockread vectint  
    2dup type cr b2sock false
  until ssock closeSocket ;

\ accept connection, xmit msg, read input, xmit kybrd til emptyline
: do-server init-server  \ how fork? - only 1 client for now
  \ s" hello and howdy, pardner" ssock
  \ WriteSocket abort" can't write to client"
  begin sockread
     sockwrite
  until ssock closeSocket srvrsock closeSocket ;


