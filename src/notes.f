\ notes.f

vocabulary notes
   notes definitions

' 2drop is \n->crlf   \ avoid seeing '\n' as a crlf

create notepath ," bids\notes.txt"    \ file to find text in

:  notevcopy create ," does> notepath count rot count vcopy ;

\        dict  paragraph   - only 1 space allowed between name and title
\        name  title       - titles are case sensitive
notevcopy john John
notevcopy alan Alan
notevcopy NES nes





 ' _\n->crlf is \n->crlf

















