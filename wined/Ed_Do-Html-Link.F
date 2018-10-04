\ $Id: Ed_Do-Html-Link.F,v 1.1 2011/03/19 23:26:04 rdack Exp $
\
\
\ is string a2,n2 at the start of string a1,n1?  If it is, then remove n2
\ leading characters from a1,n1 returning the result as a3,n3 and a TRUE flag.
\ else return a1,n1 unmodified as a3,n3 and return a FALSE flag.

: HTML?         ( a1 n1 a2 n2 -- a3 n3 f1 )
                2>r over 2r@ tuck caps-compare 0=       \ a2,n2 starts a1,n1?
                IF      2r@ nip /string                 \ then remove n2 chars
                        TRUE                            \ return true
                ELSE    FALSE                           \ else return false
                THEN    2r> 2drop ;                     \ cleanup return stack


: do-html-link  { \ html$ -- }
     MAXCOUNTED LocalAlloc: html$
     mousey CharHeight: DocWindow / line-cur + file-lines 1- min
     #line" html-link? 1- 0MAX /string s" <A HREF" caps-search
     IF  7 /string                         \ remove "<A HREF"
         bl skip '=' skip bl skip
         2dup '>' scan nip -               \ discard after '>'
         -trailing
         2dup  '"' scan nip                \ if link is quoted
         IF    '"' scan 1 /string 2dup
               '"' scan nip -              \ remove the quotes
         THEN
         over c@ '#' =                     \ searching in this document?
         IF  1 /string                     \ then remove leading '#'
             "clip" html$ place        \ save text to find, in case file changes
             cur-filename count "+open-text \ open another copy of same document
             browse? 0=
             IF      browse-toggle
             THEN
             html$ count "find-label
         ELSE                    \ open a file
             s" FILE:" HTML?
             IF  2dup s" .EXE" caps-search nip nip   \ check for executable
                 IF  "CLIP" html$ PLACE
                     html$ +NULL
                     html$ $EXEC
                     IF      beep
                     THEN
                 ELSE
                     2dup '#' scan               \ scan for string search marker
                     2dup 1 /string html$ place  \ save string to search for
                     nip -  "+open-text          \ parse out and open the file
                     browse? 0=
                     IF      browse-toggle
                     THEN
                     html$ c@
                     IF      html$ count "find-label
                     THEN
                 THEN
             ELSE
                 s" HTTP:" HTML?
                 IF  5 + swap 5 - swap                   \ add "HTTP:" back in
                     "ViewWeb-Link
                 ELSE
                     s" NEWS:" HTML?
                     IF  5 + swap 5 - swap               \ add "NEWS:" back in
                         GetHandle: FrameWindow "Web-Link
                     ELSE
                         s" FTP:" HTML?
                         IF  4 + swap 4 - swap           \ add "FTP:" back in
                             GetHandle: FrameWindow "Web-Link
                         ELSE
                             s" MAILTO:" HTML?
                             IF  7 + swap 7 - swap       \ add "MAILTO:" back in
                                 GetHandle: FrameWindow "Web-Link
                             ELSE                \ just a file, or sub web page
                                                 \ of current page
                                 2dup '#' scan   \ scan for string search marker
                                 2dup 1 /string html$ place
                                                 \ save string to search for
                                 nip -           \ -- adr len ;of file to open
                                 from-web?               \ if this is a web file
                                 IF  "build-URL" "HTML   \ then open as web file
                                 ELSE
                                     "+open-text   \ parse out and open the file
                                     browse? 0=
                                     IF      browse-toggle
                                     THEN
                                 THEN
                                 html$ c@
                                 IF  html$ count "find-label
                                 THEN
                             THEN
                         THEN
                     THEN
                 THEN
             THEN
         THEN
     ELSE
         2drop beep
     THEN    ;

