\ $id.  Saturday, May 22 2004v - 12:33

Editor  \ This is required

2variable FIRST-CFA  2variable SECOND-CFA
: (SAVE-OLD)  \ cfa --
    >body  >r     r@ dup      @  swap first-cfa  2!
    r> cell+ dup   @  swap second-cfa 2! ;
: PATCH   ( New Old -- )
    '  '  dup  >name
    cr ." WARNING: if you forget " .id ." you will crash!" cr
    ." I hope you did a PATCH NEW OLD " cr
    dup  (save-old)  >body dup >r ! ['] exit r> cell+ ! ;
: UNPATCH  ( -- )
    first-cfa  2@ !     second-cfa 2@ !   ;

( Note ) .(  UNPATCH will restore the latest word that you patched! ) cr

\ ====================

: Test  dup swap ;

: slow-msg-infile    ( -- )
                LOADING? IF
                  ." ; in file " LOADFILE COUNT TYPE
                  BASE @ DECIMAL
                  ."  at line " LOADLINE @ .
    900 ms        BASE !
                THEN
                ;

\s

: slow_HEADER-WARN ( addr len -- addr len ) \ check if a duplicate
                WARNING @ IF
                  2DUP CURRENT @ (SEARCH-SELF) IF
                    DROP
                    CR ." Warning: Word " 2DUP TYPE ."  isn't unique "
                    msg-infile
                  THEN
                THEN ;
\ patch slow_header-warn  _header-warn
