\ HTTP Web Server
\ Tom Dixon

\ *! WebServer
\ *T WebServer -- Webserver
\ *S Glossary

anew -WebServer.f

false value create-turnkey? \ set to false when you don't want a turnkey app

needs http
needs httpecho
needs httpmime
needs httpfile
needs browsefld

80 httpserver http
\ *G our http-server instance

: server-set-title ( -- )
\ *G set title of the console window
    Z" Win32Forth - HTTP Web Server" conHndl call SetWindowText drop ;

s" Help\html\" Prepend<home>\ webpath place
\ *G the path to the web content

: server-choose-path   { \ $path -- }
\ *G choose the path for the folder with the web content
    z" Choose the web content folder."
    MAXSTRING LocalAlloc: $path webpath count $path place
    $path conHndl BrowseForFolder
    if   $path count webpath place
         webpath ?+\
    then ;

: server-init   ( -- )
\ *G init the server
    http setup-http http serv-init ;

: server-run    ( -- )
\ *G run the server
    begin http serv-poll 10 ms key? until ;

: server-exit   ( -- )
\ *G close the server
    http serv-close

    create-turnkey?
    if   bye
    else cr ." Type 'www-server <cr>' to restart the server."
    then ;

: www-server    ( -- )
\ *G Starts the server.
\ ** Tell your firewall that Win32Forth is allowed to use port 80. \n
\ ** Then you should able to see the server in your browser by using: \n
\ ** http://localhost/DPANSE.HTM \n
\ ** Assuming that the file p-index.htm is in your webpath. \n
\ ** When you would like to use the websever over the internet. \n
\ ** you must replace "localhost" by your IP-adress. \n
\ ** The IP-adress can be seen at http://checkip.dyndns.org \n

    server-set-title

    cls ." The Win32Forth HTTP Web Server is running." cr

    server-choose-path  ( EG: ~\win32forth\Help\html\dpans )

    cr ." webpath = " webpath count type cr
    cr ." Press any key to stop the server."

    server-init
    server-run
    server-exit
    ;

\s
\ create an application that runs in the console
create-turnkey? [IF]

\ and create the application
&forthdir count &appdir place   \ in the Forth-directory
' www-server SAVE WebServer.exe
1 pause-seconds bye

[else]

www-server

[then]

