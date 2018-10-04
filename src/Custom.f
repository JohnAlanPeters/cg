\ Aug 18. 2001

variable hop
\ Causes the interpreter to HOP over  n  characters of each line.

: +INTERPRET    ( -- )
                hop @ >in !   \ s/b ok now
                BEGIN   BL
                WORD DUP C@
                WHILE   SAVE-SRC FIND ?DUP
                        IF      STATE @ =
                                IF      COMPILE,
                                ELSE    EXECUTE ?STACK
                                THEN
                        ELSE    NUMBER NUMBER,
                        THEN    ?UNSAVE-SRC
                REPEAT DROP ;

 ' +INTERPRET IS INTERPRET

 : Hop-on   16 hop ! ;
 : Hop-off   hop off ;
