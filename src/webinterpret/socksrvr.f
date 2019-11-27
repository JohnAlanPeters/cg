\ usage: init-sockets do-client SocketsCleanup
\ assumes send linse, get linse in loop
\ this version serves webpage directly instead of going through python

anew dosock              \ load a new version of everything below
fload sockets            \ Windows Sockets By Andrey Cherezov
create ssrvr             \ create a word in the dictionary named socket-server
  ," *"                  \ compile a counted strig containing asterisks
  0 c,                   \ compile 0 at HERE & increment the dictionary pointer
4444 value sport         \ arbitrary number for what use?

0 value ssock            \ create a value for the server-socket
0 value srvrsock         \ set the server-socket to zero
2048 value szbuf         \ set the size-buffer to 2048 or 2KB
create rbuf szbuf allot  \ allocate the r-buffer to 2KB
create lastwebuser 64 allot

: init-sockets           \ call once per forth startup
   SocketsStartup  abort" SocketsStartup error."
   cr  ." IP: " my-ip-addr NtoA type  cr ;

: init-client            \ connect to server
  ssrvr count  sport
  CLIENT-OPEN to ssock ;

: showwebuser ( -- )
  getdatetime rbuf place s"  " rbuf +place rbuf +place
  rbuf count type cr s"  " rbuf +place
  ssock getpeername drop
  2dup lastwebuser count compare
  if 2dup lastwebuser place 2dup type
     rbuf +place crlf$ count rbuf +place
     rbuf count data>fuser
  else 2drop then ;

: init-server   ( -- )         \ accept connection from client
  CreateSocket abort" can't create socket"
  to srvrsock
  sport srvrsock BindSocket abort" can't bind to port"
  srvrsock ListenSocket abort" can't listen"
  ." Waiting to accept client." cr 
  rbuf szbuf srvrsock SOCKET-ACCEPT abort" can't accept"
  to ssock ." server is accepted" cr ." socket: " ssock . 
  showwebuser ;

: sockread ( -- addr cnt | -1 or -2 )      \ wait for input
  0
  begin key? if key 27 = if drop -1 exit then then   \ quit on escape
   1 +   50 ms   \ pause for socket to receive input
   dup 1200 > if drop -2 ." timeout" cr  exit then \ time to reset the system
   ssock ToRead abort" can't get # to read" ?dup
  until nip  \ loop until something to read
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
: do-server
  -1 to in-web?
  init-server
  begin
    sockread dup -1 =
    if  ." done"
    else dup -2 =
     if drop srvrsock closesocket drop ssock closesocket drop
       ." reconnect" cr init-server 0
     else srvrinput   \ either send webpage or execute the forth
      false
     then 
    then
  until srvrsock closesocket drop
  ssock closesocket drop 0 to in-web? ;

: ds  do-server ;
