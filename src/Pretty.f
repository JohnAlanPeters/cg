\ $Id: Pretty.f,v 1.1 2011/03/19 23:26:09 rdack Exp $
Anew -pretty

((
 From Forth Dimensions Vol 7 #5 Pg 7 by  Mike Ham.   87-01-01 jap
 I started this file on June 3, 1987.
   IT IS IN USE BY THE CONTRACT GENERATOR TO PRINT MONEY AND $
 Mike Ham wrote a pretty printer.  Typos got into it when it was
 printed in Forth Dimensions.  I called him and we got it working
 It uses about 530 bytes.
 .
 The fixes for the typos in the article are in the last screen.
 I have modified and extended his code for use with my
 electrical estimating program.
 .
 The improvements alter the code to extend it to create the word
  D.J  which is short for DOUBLE number JUSTIFIED on the decimal

)) 


0 Constant      US>D
Variable        ~Digit-Count
Variable        ~Decimals  \ P: Number of decimal places wanted

: PLACES        ( n - ) ~decimals ! ;                                         ( 6 )
                2 Places  \  My default  J.P.
: 2,            ( d -- )  , , ;
                Create NINES
                9. 2,  99. 2,  999. 2,  9999. 2,  99999. 2,
                999999. 2,  9999999. 2,  99999999. 2,  999999999. 2,

: #DIGITS       ( d -- ) \ P: leaves count in variable ~digit-count
                dabs 1 ~digit-count !
                begin 2dup ~digit-count @
                1- 2 cell * * nines + 2@ d>                                    ( 7 )
                while 1 ~digit-count +!  repeat
                2drop ;

: #,s           ( -- # )
                ~digit-count @  ~decimals @
                - 3 /mod swap 0= +  0 max ;

: safe-spaces   ( addr count width -- addr count )
                >r >r pad r@ cmove pad
                r> r>  over - spaces ;

Variable  ~field-width
          8 ~field-width !       \ 8 is the default

: WHOLE-NUMBERS
   ~digit-count @  #,s +  ;

: HOLD-DECIMAL
  ~decimals @ 0 ?DO # LOOP ascii . hold ;

: PLACE-COMMAS
  #,s 0 ?DO # # # ascii , hold  Loop ;

false value $out        \ true=>leading dollar sign
: PRT#          ( d -- adr cnt )        \ V: ~field-width  V: Places
                dup >r dabs     \ change to absolute number
                2dup #digits    \ Store in ~digit-count, used by  #,s
                <#              \ Initalize the number conversion process
                Hold-decimal    \ If any decimals hold space and put in a .
                Place-Commas    \ Place a comma betwen every three numbers.
                #s              \ Convert until finished
                $out if ascii $ hold then
                r> sign         \ Add the sign if negative
                #>   ;          \ Terminate conversion process ( addr len -- )

: BUF-BLANK ( -- )                       \ blank fill line
    [ editor ] cur-buf lcount dup 46 >
    If drop 46
    Then dup >r + 90 r> - blank
    90 cur-buf ! ;            \ set length

: bufpos ( -- addr )
   cur-buf lcount drop cursor-col + ;
: bufspaces ( n -- )
  bufpos over bl fill +to cursor-col ;

\ outputs to cursor buffer or console with cursor set at decimal point
: D.NR          ( d n r -- ) \ print double-num n=decimal-points r=field width
  2dup  ~field-width !  ~decimals !
  keyboard @
  if  - 1+ getxy >r + r> gotoxy
      prt#
       ~field-width @ over - spaces
      type
  else
      - 1+ +to cursor-col \ cursor to field start
      prt#             \ -- addr count
       ~field-width @ over - 0 max bufspaces
       >r bufpos r@ cmove r> +to cursor-col
  then ;

: d.xx    ( d n -- )  \ print double# as $.cents in a given field width
  2 swap d.nr ;

: BUCKS   ( d -- ) 10 d.xx ; \  field used by EXTND-  999,999.99

: $.r           ( d -- )   \ leading '$' Used by TOTAL
  true to $out 10 d.xx false to $out ;

: ?ENOUGH       ( n -- )  \  thanks to Robert Paton
                >R DEPTH R@ U<
                IF ( INTERACTIVE ) CR R> .
                ( TRUE ABORT" ) ." parameter(s) required." ABORT THEN
                R> DROP ;
                ( If enough numbers are on the stack then it passes them on, )
                ( if not, abort with a warning and tell how many are needed. )

Variable ~TARGET    \ Address where we want to emit the decimal point

: D.J           ( double-number field-width -- )
                3 ?enough
                >r  prt# r> safe-spaces  type ;

: D.J-MOVE      ( double-number -- ) \ Justified on the decimal
                prt#  dup   negate  3 +  ~target @ +   swap
                move ;

\ : D.R-Move    ( D -- ) \ Justify without commas
\                prt#- dup negate 3 +  ~target @ + swap move ( update ) ; ))

: D.J-CURSOR    ( d -- )
                [ editor ]  'cursor 1+ [ forth ]  ~target !   D.J-move  ;

: D.R-CURSOR    D.J-Cursor ; \ Used by ADD-THRU

: DROP-CENTS    ( d -- )  1.00 d/ ;
                ( s/b Round cents to the nearest dollar... )
: SO-MONEY      ( d -- )    0 places   D.J-move   ;
                ( 40.00 = 4,000 )
: SO-DOLLARS    drop-cents  0 places   D.J-move ;
                ( 40.00 =    40 )
                ( s/b Type-Dollars ? )
: SO-CENTS      ( d -- )    2 places   D.J-move  ;
                ( 40.00 =    40.00 )
((
: AT-TARGET     ( line col -- addr )
                swap  64 *  +  [ editor ] 'start  +  1- ~target !  ;
: DROP-CENTS-AT ( d line col -- )
                ~decimals @ >r   at-target   0 places drop-cents
                D.J-move   r> places ;
: AT-DOLLARS    drop-cents-at ;

: 2-PLACES-AT   ( d line col -- )
                ~decimals @ >r   at-target   2 places
                D.J-move   r> places ;
))
: OUT-CENTS     ( d -- )     \ setup buffer, output number, save buffer
  get-cursor-line  80 cur-buf !
  s-o 2 9 d.nr r-o  \ JP 4-4-09 was 2 9 
  update+ ;

: AT-CENTS      ( d l# col# -- )  \ set col+line, output number
  to cursor-col to cursor-line
  out-cents ;


: Dollars       ( d - )  ." $" bucks ;

: D?            ( d -- )    2@  6 d.j ; 

: 2OFF          ( addr -- )  0 0 2 roll 2! ;


.( Pretty.f is loaded )


 
