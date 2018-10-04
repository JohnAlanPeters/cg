\ $Id: HyperLink.f,v 1.1 2011/03/19 23:26:04 rdack Exp $
\    File: HyperLink.f
\  Author: Dirk Busch
\ Created: Sonntag, Juni 20 2004 - 12:38 dbu
\ Updated: Sonntag, Juni 20 2004 - 12:38 dbu

named-new$ hyper-buf
named-new$ hyper-string
named-new$ prev-hyper-string
0 value hyper-start
map-handle hyper-hndl

\ Look in the dictionary for the Word adr/len
\ return Line and Filename if found
: "hyper-dict   ( adr len -- #line adr1 len1 true )
                ( adr len -- false )
                TURNKEYED? NOT
\IN-SYSTEM-OK   if  "anyfind
                    if    dup  [ also classes ] ['] DO_MESSAGE [ previous ] <>
\IN-SYSTEM-OK             if   get-viewfile
                               if   count "path-file not
                               else 2drop false
                               then
                          else drop false
                          then
                     else drop false
                     then
                else 2drop false
                then ;

\ Look in the Index-File adr/len for the Word adr1/len1
\ return Line and Filename if found
: "hyper-index  ( adr len adr1 len1 -- #line adr2 len2 true )
                (                   -- false )
                2swap 254 min 0max hyper-buf place
                s"  " hyper-buf +place \ add a space
                hyper-buf count upper  \ for uniqueness

                hyper-hndl open-map-file 0=
                IF   hyper-hndl >hfileAddress @
                     hyper-hndl >hfileLength  @
                     hyper-start
                     IF   prev-hyper-string count hyper-string place
                     THEN
                     hyper-start /string     \ skip first part of file
                     BEGIN                   \ does word match?
                            2dup >r hyper-buf count tuck compare
                            r> 0<> and      \ & there's file left
                     WHILE  over c@ k_TAB = \ file lines marked with TAB
                            IF   2dup
                                 2dup 0x0D scan nip - 1 /string
                                 hyper-string place \ save filename
                            THEN
                            0x0D scan 2 /string     \ skip a line
                     REPEAT dup

                     IF   \ we found the word in the index

                          \ get line
                          2dup 0x0D scan          \ move to line end
                                                  \ len, skip next time
                          over 2 + hyper-hndl >hfileAddress @ -
                          to hyper-start          \ save for reentry
                          nip -                   \ parse line
                          bl scan bl skip number? \ get line#
                          2drop

                          \ get filename
                          hyper-string count

                          true
                     ELSE \ didn't find word in index
                          2drop false
                     THEN
                     hyper-hndl close-map-file drop
                ELSE \ can't open index file
                     false
                THEN ;

: "hyper        { adr len adr1 len1 -- #line adr2 len2 true }
                (                   -- false )
                \ adr  len  => the Word
                \ adr1 len1 => the Index-File

                \ first try to find the word in the dictionary
                adr len "hyper-dict
                if   true
                else \ than try to find it in the index-file
                     adr len adr1 len1 "hyper-index
                then ;

