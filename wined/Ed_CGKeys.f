
: UPDATE+ ( -- ) [ editor ] put-cursor-line file-has-changed refresh-line ;

: insert-bid-line ( adr len -- )  \ insert string into line
  get-cursor-line cur-buf lcount drop tab-size + swap over 30 blank cmove     
  80 cur-buf ! UPDATE+
  1 +to cursor-line 0 to cursor-col ;

: BL2end ( -- )  \ blank to end of line
  [ editor ]
  get-cursor-line cursor-col cur-buf !  \ truncate line to cursor column
  UPDATE+  ;

defer line2clip

: in-fish ( -- )
  s" Fish-in-Walls inc" insert-bid-line ;

: in-emt ( -- )
  s" Neat-EMT" insert-bid-line ;

: in-TS ( - )
   s" Trouble-shoot Easy" insert-bid-line ;

: in-fixit ( -- )
   tab-size 0 to tab-size
   s" Fix it          ( Use Contingency Fund )" insert-bid-line
   to tab-size  ;

: in-closet ( -- )
   tab-size 0 to tab-size
   s" Neat-EMT"                         insert-bid-line
   s" Light outlet    LT"               insert-bid-line
   s" Wall switch     SW-Easy"          insert-bid-line
   s" Flourescent     Inch-Light 33-in" insert-bid-line
   to tab-size ;

: dup-line ( -- )   \ duplicate line above cursor line
  cursor-line 1- #line"
  cur-buf ! cur-buf lcount cmove put-cursor-line UPDATE+  ;

: paste-special  ( -- )  \ split line and insert text
  [ editor ] cursor-col  \ remember current column
  split-line   overstrike @
  if 1 +to cursor-line then  \ text to right of cursor put on next line
  get-cursor-line cur-buf lcount over 16 + swap cmove>
  cur-buf lcount drop 16 blank  16 cur-buf +!
  put-cursor-line   -1 +to cursor-line dup to cursor-col
  Paste-text to cursor-col ;

: in-D&P ( -- )
   s" Device&Plate" insert-bid-line  ;

\ ---------------------------------------------
: Quick-keys ; \ Make it easy to VIEW this ^Q commands
: Control-Q ;
\ ---------------------------------------------

: cg-special ( -- )  \ ctrl-q - do special cg operations
   key upc                        case
  'A' +k_control of in-fish       endof \ A Fish-in-walls
\ 'B' +k_control of in-fish       endof \ B
  'C' +k_control of line2clip     endof \ C
  'D' +k_control of in-D&P        endof \ D Device&Plate Same as P 
  'E' +k_control of grand-total   endof \ E s/b Extend
  'F' +k_control of in-fixit      endof \ F Use contingency fund
  'G' +k_control of bl2end        endof \ G Clear to end of line
\ 'H' +k_control of               endof \ H
\ 'I' +k_control of               endof \ I
\ 'J' +k_control of               endof \ J
\ 'K' +k_control of dup-line      endof \ K Duplicate the line
\ 'L' +k_control of               endof \ L
\ 'M' +k_control of               endof \ M
\ 'N' +k_control of in-NES        endof \ N NES with all the line items 
\ 'O' +k_control of               endof \ O
  'P' +k_control of in-D&P        endof \ P Device&Plate  Same as D
\ 'Q' +k_control of               endof \ Q
\ 'R' +k_control of               endof \ R
  'S' +k_control of in-emt        endof \ S Neat-EMT
  'T' +k_control of in-TS         endof \ T Trouble-Shoot
  'V' +k_control of paste-special endof \ U split line and insert text at cursor
\ 'W' +k_control of in-fish       endof \ V
\ 'X' +k_control of in-fish       endof \ W
\ 'Y' +k_control of in-fish       endof \ X
  'Z' +k_control of in-closet     endof \ Closet LT  SW  Flo 33-inch
                                  endcase ;

\s  ( Can't use parens inside a case statement?   )

  A (               Fish-in-walls                 )
  C ( copy current line to clipboard              )
  S (               Neat-EMT                      )
  T (               Trouble-shoot easy            )
  F ( Fix it        ( Use contingency fund )      )
  Z ( Closet Light   LT  SW-easy  Inch-light 33-in )
  G ( blank the end of the line                   )
  E ( Does this make ^Q E the same as ^E or what? )
  V ( split line and paste at cursor              )











