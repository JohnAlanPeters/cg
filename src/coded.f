\ $Id:

: TIME            ( -- addr len ) get-local-time >time" ;

      2variable ~~FIXTURE-MARKUP     \ Not in use??
 1.17 2constant   FIXTURE-MARKUP=    \ Tax and 10% only
fixture-markup= ~~FIXTURE-MARKUP  2! \ Not in use?

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 05
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

: (UN-ADD)  ( line# -- )   \ LINE is not known in Win32
  line $COLUMN +   c/l $COLUMN  -  blank  update  ;
: UN-ADD-COLUMN   ( -- )  \ Uses current SCR
  1 15 Do-thru  I  (un-add)  loop  ;

: UN-SUMMARY  ( -- )
  0 line  24 +  [ 64 24 - ] literal  blank  update ;  ( 48 17 )
    ( Just after the comments, till the percent )

: UN-ADD  ( -- )  \ Uses SCR
  scr @ 0= if abort" Scr zero" then
  un-summary  un-add-column  ;

: UN-TIME  $column @   35 $column !   un-add   $column !  ;


\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 14    SO-xx   In use by MEN to print the time
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
variable ~field-width

: SO-xx   ( d -- ) \ print double number 2 decimal places in a field of three
  2dup d0= 0=
  if  2 places  5 ~field-width !  prt#
  ~target @  14 -  swap  cmove update   else 2drop
            \ s-o  ." hr"  r-o
           then ;


\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 15 16  SOURCE-LINE
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

  Variable JUMPED
  Variable ~LastColumnToCompile  46 ~LastColumnToCompile !
  : JUMP  jumped ! ;
  Variable CURRENT-LINE

(( \ not needed ------------------- see 8 lines below
        \ missing word -> BLK   \ block number to interpret
         : SOURCE-LINE  ( -- adr len )  \ V: blk
          blk @  ?dup if   block  CURRENT-LINE @  c/l *   +
          Jumped @  +  ~LastColumnToCompile @  \ First & last to compil
          else tib #tib @ then ;
)) \ not needed ------------------------ see right below

: SOURCE-LINE   line ;  \  block number to interpret


\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 20    IF-SO-DOLLARS                                              AEC
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

: IF-SO-DOLLARS  ( d -- )
   2dup d0= 0=
   if drop-cents  0 places  d.j-move
   else 2drop then ;
   
: IF-SO-CENTS  ( Uses ~target to print double number )
               ( Don't print if zero )
   2dup d0= 0=
   if   2 places  d.j-move
   else 2drop then ;
defer amount>screen  \ see IF-SO-CENTS  5 lines above, this is correct
defer defered-sub    \ s/b 2 r s
: WITH-CENTS
   ['] IF-SO-CENTS   is  amount>screen ;  WITH-CENTS
 ' Sell-sub is Defered-sub


\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 21    Added in here
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

 Variable ~TEMP
 : ANY?   ( n1, n2, n3, etc count -- ) \ See YES? below
   dup 1+ roll ~temp !  0 swap 0 do swap ~temp @
   = or loop ;


\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 22    Use FIG to price items to the screen             89-01-14 AL
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

: NOOP-SLASH-PAREN  ( n f -- n f )
   >r dup  [ ' noop ] literal [ ' \ ] literal   [ ' ( ] literal
   3  any?    if r>  drop false else  r>  then ;
: DEFINED+   ( -- here 0 | cfa [ -1 | 1 ] )   ( ID the word )
  bl word  ?uppercase  find  2dup
  noop-slash-paren
  if  >name .id else drop then ;


\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 23    Summary               Started before 12-30-90     10-17-02 bec
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
2variable temp
: SUMMARY  ( -- )  \ Put the sums on top of the screen
                           [ editor ]  top  17 cc ( 2  cc )
    2 places WholeSale-Sub 2@   2dup temp 2!    100. d/
    WholeSale-Sub 2off         ( ^^^Test^^^^ )
     100. d/  ( ?? )      S-O     10 d.j         r-o
                          S-O     ." +1/3 "      r-o
 2 places  Time-total 2@  S-O      8 d.j         r-o
                          S-O     ." hrs "       r-o
\ ( For the Auto Module)  S-O     ." c ; \"      r-o
           Sell-total 2@  S-O      11 d.j        r-o  update  ;


\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 25    WHOLESALEa Can't be moved to markup.blk           06-13-93 AEC
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

\ : WholeSaleSub   2dup  quan 2@  d*  WholeSale-Sub 2+! ;
: Double-     IncWholeSaleSub  2.00 ;
\ MARKUP-     IncWholeSaleSub  1.35 ;
: (No-Markup) IncWholeSaleSub  1.00 ;
: No-Parts-   IncWholeSaleSub  0.00 ;
\ Yes-Parts  [']  Markup-   is markup# ;  Yes-parts ( default )
: NO-PARTS    ['] No-parts- is markup#  ;


\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 26    WHOLESALE  Can't be moved to markup.blk           11-10-96 AEC
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

: DELIVERED  with-cents  [']   DOUBLE-  is markup# \ added -
   rate 2@  current-rate 2!  0.00 rate 2!
   1.00 ~~fixture-markup 2!
   5 spaces        ." Add Tax etc. & installation time."  ;
: WHOLESALE  with-cents  ['] (NO-MARKUP) is markup# \ added -
   rate 2@  current-rate 2!  0.00 rate 2!
   1.00 ~~fixture-markup 2!
   5 spaces        ." Add Tax etc. & installation time."  ;


\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 27
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

: NO-LABOR  .00 rate 2!  ;
: LABOR-ON  Labor-rate? rate 2! ;
: No-markup  ['] (no-markup) is markup# ;


\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 28    MEN   Time-sub is a 2variable           02-24-89
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

: TIME>SCREEN
  time-sub 2@  SO-XX  if-so-cents  ;
: MEN-ON  ( -- )
  ['] time>screen    is amount>screen  ;
: MEN-OFF
  ['] if-so-dollars  is amount>screen   with-cents ;

((
        : (MEN) keyboard off  men-on  (FIG)  men-off  keyboard on ;
        : MEN   16 jump (men) [ editor ] bot fl ;
        : MEN-THRU  ( from thru -- )
          do-thru i  dup .  men  loop ( save-buffers  beep ) ;
        : EXTENDS  men-thru ;  \ Does not work
))


\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 29    TIME is fak-d at top
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

: TIME-STAMP   time 3 - type ;

: T-STAMP   [ editor ] top ( 46) 52 cc  s-o time-stamp r-o ;


\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\       Some words that we may not need and will not load yet
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

(( \ later for these
        fa-e copy--bid  \ Sunday, June 27 2004 - 21:34 
        fa-e same        \ Sunday, June 27 2004 - 21:34
        : CAB-n  ( first last n-blocks -- ) ( Give it a name )
             ."  Creating A Bid file"  [ editor ] \ wrap off
             ( n ) create-file  ( n n ) copy--bid  same   r# off
             0 scr !  T-STAMP  top 0 v ;
        : Name-check  >in @ bl word C@ 0= abort" No file name" >in ! ;
           \ Prevents over writing a file of the same name.
        : \E            " \ELE\BIDS"   n$set-path ; )
        : CABb name-check \E  0 23  24 cab-n  ; \ 9-13-00


: COD      0  0   3 cab-n ." Setup Charge!"  beep  ;
   \ Copy only the Name template.  Reminds upon ESC key
)) \ --------------------- later for these


\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 31    TOT & Totalize                 rda 11-15-02       12-21-03 AL
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

: TOTALIZE ( line# -- d )  \ Can't switch to single precision
  1 ?enough   \ JP          \ Used by TOTS
  0 0 rot line 0
  c/l 0
  do if dup c@ bl -
     else dup c@ dup 47 > swap 59 < and
       if dup get-number
          4 roll 4 roll d+ rot 1   \ -- d addr fl
       else 0 then
     then swap 1+ swap
  loop 2drop  ;
\ : Bucks  ( d -- ) 8 d.j ;
: GET-TOTAL  ( line  -- )  \ used by TOTS
   1 ?enough  line 54 + get-number ;

.( Coded.f loaded ) cr

