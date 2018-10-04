.( This one needs conversiont to 16 bit system )
\ : ` comnoop ; \ this one is a plce holder for viewing until Dudley fixes it.
: `  s" ;"       "comment ; immediate          \ comment till ;

\s



Comment: ------------------
DO-EXTEND has a 2,  (Two comma) on the 3rd line in it's definition.
It is aproximatly at line 36 in this file.  I will try to define it.
Comment; ( It seems to compile now on 4-23-01 )

: 2,  , , ;

: PARTS/HUNDRED-TIME/HUNDRED   ( n -- )  ( ? )
  >r  r@     2@   w/c
      r@  4 + @   c
      r> drop ;

: PARTS/ONEONLY-TIME/HUNDRED
  >r  r@     2@   w/e
      r@  4 + @   c
      r> drop ;
\  Not moved to improve.scr in prices    NO!             88-10-29AEC
Defer (EXTEND)  \ Resolved below
: GET-IT   bl word number? drop ;
: DO-EXTEND   ( d n n n n -- )
   Create           \ Name-of-part )
   get-it      2,   \ Cost
   '  drop          \ W/C
   get-it drop  ,   \ Hours per unit
   '  drop          \ ( E C M )
   '  drop          \ The semicolon
  Does>
  (extend)  ;
: `    ['] parts/hundred-time/hundred  is (extend)  Do-extend ;
\ : ~    ['] parts/hundred-time/thousand is (extend)  Do-extend ;
: &    ['] parts/oneonly-time/hundred  is (extend)  Do-extend ;

 