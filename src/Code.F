\ $Id

\ CODE.F
 cr .( Loading CODE.F )
\ This is the double number verson.

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
COMMENT: \ ROLL THE CREDITS -----

Take the given quantitys parts prices and labor time
units, extend them, calculate the sub totals and totals.
Put the sell prices in to the contract ready to print

  (c) John A. Peters    1985, 1986, 1987, 1988, 1989, 1990
  (c) 1991  1992, 1993, 1994, 1995, 1996, 1997, 1998, 1999
  (c) 2000 2001 2002 2003 2004 2005 2006 2007 2008 2018 2019

        E L E C T R I C   M O D U L E   P R I C E S

     BROOKLINE AREIS ELECTRIC COMPANY SINCE 1972.
     121 Santa Rosa Ave.      Text is best 415-239-5393
     San Francisco, CA 94112  Not attended 415-509-3599
                  john@BrooklineElectric.com
     Conversion from FPC to Win32Forth via Robert Ackerman

COMMENT;


\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 2     THE VARIABLES =====

2variable QUAN              \ Also in MARKUP.BLK 10 as needed early ?
2variable NPS-W/S           \ Whole sale cost of material not used
2variable PARTS-COST        \ Cost of the part
2variable PARTS-WHOLESALE   \ wholesale cost of parts
2variable FLUF-COST         \ Permits that do not use parts or men's time.
2variable TIME-UNIT         \ Time per unit ( EMT is per 100 ft )

 ( 1993  94  95  96  97  98  99  00  01 02 03 04 2005 2006 2007 2008 2009 )
 (   55  56  55  60  60  65  70  87.50  92.00 92  125  135  145  159  159 )
 (                                      Nich               Slow, Recssion )
 ( 2010          Oct 2010    May 2011 Fire alarms etc                     )
 ( 110, 90, 115, 99 various   90.00                                       )
 ( July 14, 2013 BV raised to 99.00                                       )

2variable CURRENT-RATE
2variable LABOR-RATE
: PER-HOUR  Labor-Rate 2! ;        \ The rate is set just below here.
  150.00 per-hour                  \ Raised for remote bidding  with Miro.                                                            
\ 150.00 per-hour                  \ Raided by JP since I have plenty of work.
\  99.00 per-hour                  \ BV raised on Boris exit July 14, 2013
: Rate? Labor-Rate 2@ 2 9 d.nr ;   \ initalization, no colon or semicolon.
Labor-rate 2@  Current-rate 2!     \ initalize

Defer UNIT  ( this is ok )   \ Example: Wire is per 1000 ft
2variable WHOLESALE-SUB
2variable PARTS-SUB   \ is in use by interpret-lines++
2variable TIME-SUB   \ The time-sub may be no longer in use.
2variable LABOR-SUB   \ currently not in use but keep?
2variable SELL-SUB
2variable OTHER-SUB
2variable PERMIT-SUB
2variable ALLOWANCE-SUB
2variable WHOLESALE-TOTAL
2variable PARTS-TOTAL \ The sum of all parts in the current Vscreen
2variable TIME-TOTAL
2variable LABOR-TOTAL
2variable SELL-TOTAL
2variable OTHER-TOTAL
2variable PERMIT-TOTAL
2variable ALLOWANCE-TOTAL
2variable PARTS-EXT   \ The extend price of just one line
2variable WHOLESALE-EXT
2variable TIME-EXT    \ The time to install ordered quanity
2variable LABOR-EXT   \ The labor to install the quality
2variable SELL-EXT    \ The extended labor + materials


\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 3     THE CONSTANTS ======

1000 constant THOUSAND
 100 constant HUNDRED
   1 constant ONE-ONLY

16 value m-in

: set-exts ( n <name> -- )
  create , does> @ m-in + ;

35 ( 35 ) set-exts parts-col    \ changing messed up virtual sub total in WinEd
44 ( 44 ) set-exts time-col
56 ( 56 ) set-exts sell-col
35 ( 35 ) set-exts vparts-col   \ 29
44 ( 44 ) set-exts vtime-col    \ Virtual scr sub time is now ok was 37
56 ( 56 ) set-exts vtot-col     \ Virtual scr sub price is now ok was 48
                         \ decimal point columm before bolding
68 set-exts discount-col

: (totline?) ( -- fl )   \ if an extended line and next one isn't
  displayingLine #line" vtot-col >
  if vtot-col + dup c@ ascii . =
     if begin 1- dup c@ bl =
        until 1+ c@ ascii $ =
     else drop false then
  else drop false then ;
' (totline?) is totline?

0 value afterTot     \ hold total line in a bid file
: afterTot? ( -- fl )
  afterTot dup displayingLine < and if true else
   displayingLine #line" drop s" total est" tuck istr= dup
   if displayingLine to afterTot then
  then ;

: (vtop?) ( -- fl )     \ if on top line of a virtual screen
   noext? 0=   displayingLine 25 <  or  afterTot? or
   if 0 else   \ is source or before line #25 or after 'total' line
   displayingLine #line" -trailing nip 0= if 0 else  \ blank line isn't a vscr
   displayingLine 1 - #line" -trailing nip 0=  \ line above is blank
   then then ;
' (vtop?) is vtop?

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 4     THE CALCULATIONS ======
: EX-TOTAL ( -- d )  \ add the 3 'total' variables
  sell-total 2@ other-total 2@ d+ permit-total 2@ d+ ;

: CALC-PARTS   ( d -- )
     2dup  parts-cost 2!  Quan 2@  d*  1.00 d/
     2dup  parts-ext  2!  2dup  parts-sub 2+!  parts-total 2+!  ;

: CALC-LABOR   ( -- )
     time-ext 2@   labor-rate 2@  D*  1.00  d/
     2dup  labor-ext  2!  2dup labor-sub 2+!  labor-total 2+!  ;

variable timejack  100 timejack !  \ 110 -> no jack  5-26-2013 inc 10%
: CALC-TIME   ( d -- )              \ back to 100 July 2013
     quan 2@  d*  unit s>d   d/ timejack @ s>d d* 100. d/
     2dup  time-ext   2!  2dup time-sub 2+!   time-total 2+!  ;

: CALC-SELL  ( -- )
     parts-ext 2@  labor-ext 2@  d+
     2dup sell-ext 2! 2dup sell-sub 2+! sell-total 2+!  ;

: CALC-OTHER ( n -- )
    100 * s>d 2dup other-sub 2+! other-total 2+! ;

: CALC-PERMIT ( n d -- )
     swap s>d d* 2dup permit-sub 2+! permit-total 2+! ;

: CALC-ALLOWANCE ( n -- )
    100 * s>d 2dup allowance-sub 2+! allowance-total 2+! ;


\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 5     SHOW THE RESULTS ======

: .W/S    ( d -- d ) 2dup  2-6-d.nr  space ;

true  value timecolshow      \ set false to not show time column
false value partscolshow     \ set false to not show parts column
false value partswholesaleshow
0 value discount         \ rate of discount; 100 -> no diff

: sub<>0  ( -- fl )   \ if sub is not zero
  sell-sub 2@ + other-sub 2@ + or permit-sub 2@ + or allowance-sub 2@ + or ;

: vtotal<>0 ( -- fl )
  EX-TOTAL + ;

: SHOW2PARTS
  parts-col 1- TAB-in wholesale-sub 2@ bucks
  time-col TAB-in parts-sub 2@ bucks ;
: SHOW-PARTS ( -- )
  parts-col TAB-in  parts-sub 2@ bucks ;
: SHOW-TIME ( -- )
  time-col TAB-in  time-sub 2@ 2 8 d.nr ;
: SHOW-SELL ( -- )
  sell-col TAB-in  sell-sub 2@ other-sub 2@ d+
  permit-sub 2@ d+ allowance-sub 2@ d+ bucks
  discount
  if sell-sub 2@ discount 0 d* 1.00 d/
     discount-col TAB-in bucks
  then ;
                                                \ JP start of factoring
: web-show
    10 ( 16 ) >ccol quan 2@  1.00 d/ 3 d.r ." @"
    21 ( 21 ) >ccol parts-cost 2@ bucks ."  ="
    33 ( 33 ) >ccol parts-ext 2@ bucks  ;

: console-show
    16 ( 16 ) >ccol quan 2@  1.00 d/ 3 d.r ." @"
    31 ( 27 ) >ccol parts-cost 2@ bucks ."  ="
    43 ( 39 ) >ccol parts-ext 2@ bucks ;

: CONS-SHOW-PARTS ( -- )
  in-web?
  if  web-show
  else console-show
  then ;
                                                 \ JP end of factoring
: CONS-SHOW-TIME ( -- )
  in-web?
  if  40  else 51
  then  >ccol time-ext 2@ bucks ."  hr" ;

: CONS-SHOW-SELL ( -- )
  in-web?
  if  \ which one?
    52 ( 77 ) >ccol labor-ext 2@ bucks
    62 ( 87 ) >ccol sell-ext  2@ bucks
    discount
    if  \ the other one
     sell-ext 2@ discount 0 d* 1.00 d/
     72 ( 97 ) >ccol bucks
    then
  else  \ wich one?
    61 ( 77 ) >ccol labor-ext 2@ bucks
    71 ( 87 ) >ccol sell-ext  2@ bucks
    discount
    if  \ wich one?
      sell-ext 2@ discount 0 d* 1.00 d/
      81 ( 97 ) >ccol bucks
    then
  then ;


\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 6   DISPLAY THE PARTS, LABOR AND SELL PRICES =====

: d-ONE-ONLY  ( 0-quan -- 1-quan )
   depth saved-depth - 2 <
   if depth 1 = if drop then 1.00
   then ; \ No # means one

: N/A  ( ?? -- d ) \ if no dbl# on stack, put a dbl zero on
   depth saved-depth - 2 <
   if depth 1 = if drop then .00
   then ;    \ No # means zero

: n-ONE-ONLY   ( ?? -- 1-quan ) \ no depth then 1 on stack
   depth saved-depth - 1 <
   IF 1 THEN  ;

: CLEAR-SUB \ used by interpret-lines++
  parts-sub 2off labor-sub 2off wholesale-sub 2off
  other-sub 2off permit-sub 2off allowance-sub 2off
  time-sub 2off sell-sub 2off  ;

: CLEAR-TOTALS  ( -- )
  -1 to dp-location   \ so display items from console works
  clear-sub  wholesale-total 2off
  other-total 2off  permit-total 2off  allowance-total 2off
  parts-total 2off  labor-total  2off
  time-total  2off  sell-total   2off  ;

: Clear         Clear-totals ;
: CLR           clear-totals ;

: SHOW-ALL   ( -- )
  PartsWholeSaleShow
  if   show2parts
  else partscolshow
    if   show-parts
  then
       timecolshow
     if   show-time
    then
   then show-sell ;

: remvoc ( -- )  \ remember vocab we are in for later display
  context @ voc>vcfa , ;

: CONS-SHOW-ALL   ( -- )   \ output on current console line
   ( context @ voc>vcfa .name )
  cons-show-parts \ leaves off the last didget to the right of the decimal
  cons-show-time
  cons-show-sell ;

: IncWholeSaleSub  ( d -- )
   2dup quan 2@ d* 100.00 d/
   partswholesaleshow
   if 2dup WholeSale-Sub 2+!  then
   wholesale-total 2+!  ;

: MARK-IT-UP  ( w/s -- r/t )
   IncWholeSaleSub
   1.35  d*  100.00  d/ ; \ Was 1.35 till I talked wiwth Mario,  Big parts?                      
                          \ back to 1.35 after Ez Navar kit LED conversion
: MMM    ; \ For use with view        

\ MARK-IT-UP  ( w/s -- r/t )
\  IncWholeSaleSub
\  1.35  d*  100.00  d/ ;
                         


\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 7     UNITS AND QUANTITIES ===========

: isDOUBLE? dp-location  1+ 0<> ; \ also defined in the kernel
: ?>d ( ?? -- d )  \ assumes a single or double on stack
   isdouble?  0=  if  s>d  100.  d*  then ;

: kclr   keyboard @ if clear-sub 0 to saved-depth -1 to dp-location
         then ;  \ clear subtotal for console line

        ( quanity with cost on top )
: W/E   ( n-quan d -- ) ( kclr ) >r >r     n-one-only  ?>d  quan 2!  r> r>
            100. d*   mark-it-up   calc-parts ;
: W/C   ( n-quan d -- ) ( kclr ) >r >r     n-one-only  ?>d  quan 2!  r> r>
                      mark-it-up   calc-parts ;
: W/M   ( n-quan d -- ) ( kclr ) >r >r     n-one-only  ?>d  quan 2!  r> r>
             10. d/   mark-it-up   calc-parts ;
: EX    ( n-quan n -- )  \ Single precision extend, used for fluf and fixts
         >R  n-one-only  ?>d quan 2! R> S>D  calc-parts  ;

: E2  ( n -- )  \ E2 is executed by evaluate
   s>d  calc-time  calc-labor  calc-sell
   keyboard @ if cons-show-all then ;

: M [']  Thousand is Unit  E2 ;
: C [']  Hundred  is UNIT  E2 ;
: E [']  One-only is UNIT  E2 ;


\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 8     ACCUMULATE THE TOTALS AND SUBTOTALS =====

\ NOT IN USE
\ : SUB-TOTAL ( -- )  \ display sub-totals
\ conscol @ -1 >
\ if
\   34 ( 33 ) >ccol parts-total 2@ bucks  \ web server
\   43 ( 42 ) >ccol time-total  2@ bucks ."  hr"
\   55 ( 54 ) >ccol labor-total 2@ bucks
\   64 ( 63 ) >ccol sell-total  2@ bucks
\ else
\   39 ( 39 ) >ccol parts-total 2@ bucks  \ surface
\   49 ( 49 ) >ccol time-total  2@ bucks ."  hr"
\   61 ( 61 ) >ccol labor-total 2@ bucks
\   71 ( 71 ) >ccol sell-total  2@ bucks
\ then ;
\
\ sub  sub-total ; \ an alias

   \ I wonder if these are affecting the next one?
: Total-WEB ( -- ) \ display sub-totals on web
  24 ( 44 ) >ccol parts-total 2@ bucks
  33 ( 53 ) >ccol time-total  2@ bucks ."  hr"
  41 ( 61 ) >ccol labor-total 2@ bucks
  51 ( 71 ) >ccol sell-total  2@ bucks ;    
       \ changing these #s does not change anything

: Total-CON ( -- ) \ display sub-totals in console   sub?
  43  ( 44 ) >ccol parts-total 2@ bucks  \ jppjpp
  51  ( 53 ) >ccol time-total  2@ bucks ."  hr" 
  61  ( 61 ) >ccol labor-total 2@ bucks
  71  ( 71 ) >ccol sell-total  2@ bucks ;

: Headline-WEB ( -- )
     conscol @ 40 > if cr then
     05 spaces ." Only            Part       Parts     Time       Labor     Sell " ;  

: Headline-CON ( -- ) \ names of the columns  THESE ARE GOOD
18 ( 16 ) >ccol  ." Quan"
30 ( 30 ) >ccol  ." Part"
40 ( 45 ) >ccol  ." Parts"
50 ( 50 ) >ccol  ." Time"
59 ( 59 ) >ccol  ." Labor"
70 ( 67 ) >ccol  ." Sell" ;

: HEADLINE        \ maybe shold be HEADLINE-W/C  I think HEADLINE is redefined
  in-web?
  if   headline-WEB
  else headline-CON   
  then ;

: TOTAL      \ name it total-w/c     ?-?
  Headline   \ use headline-w/c   ?-?
  in-web? cr
  if   total-WEB
  else total-CON
  then  clear-totals ;

: TT total ;  \ development shortcut  call total-w/c ?-?

: TOTAL-VSCR   ( Print totals at bottom of each section )
     [  editor   ] get-cursor-line buf-blank
  partswholesaleshow
  if
    vparts-col 1- tab-in wholesale-total 2@ $.r
    vtime-col tab-in  parts-total 2@ $.r
  else
     partscolshow
     if vparts-col tab-in parts-total 2@ $.r
     then timecolshow
     if vtime-col tab-in  time-total 2@  2 8 d.nr
     then
  then
     vtot-col  tab-in EX-TOTAL $.r
     update+ ;

: T&M  ( n -- )   \ divide an amount 15% materials, 85% labor
  dup 0 100 0 d* 2dup sell-sub 2! sell-total 2+!
  dup 0
    85 0 d* 2dup 2dup labor-sub 2! labor-total 2+!
  100 0 d* labor-rate 2@ d/ 2dup time-sub 2! time-total 2+!
  0
    15 0 d* 2dup parts-sub 2! parts-total 2+!
 ;
\ See also a T&M in HOURS and in DOLLARS


\ templates
: bid-show  ( <title> -- )  \ show vscr in -bids
  s" bids\-bids" cgbase" /parse-s$ count vfind ;
: bid-copy ( vadr vlen -- )  \ copy vscr from -bids
  s" bids\-bids" cgbase" 2swap vcopy ;
: NES ( -- ) \ See line 657 of -bids
   s" NES" bid-copy ;
: UG-NES ( -- )
   s" UG" bid-copy ;
: Commercial-NES ( -- )
  s" Commercial-NES" bid-copy ;
: DBI ( -- )
  s" DBI" bid-copy ;
: Kit ( -- )
  s" KITCHEN LIGHTING" bid-copy
  s" KITCHEN POWER" bid-copy ;

\ copy template to new file or open old file
: CAB { \ to$ -- <fname> }   \ copies bids\template to a new file
  max-path localAlloc: to$   \ Does not save the file  japp 
  /parse-s$ count to$ place
  to$ $open     \ don't copy if already exists
  if drop s" bids " cgbase" 2dup + 1- 0 swap c!  "chdir
     to$ +NULL false to$ 1+ 
     s" template " over + 1- 0 swap c!
    Call CopyFile 0= abort" The COPY Failed!"
  else close-file then to$ count "+open-text
      9 to cursor-line reEdit ;

: to-bids ( -- )  \ open -bids in editor
  s" bids\-bids" cgbase" "open-text REEDIT  ;

: >bids ( line# -- )             \ open -bids to line# given
  s" bids\-bids" cgbase" "open-text 
  find-buf off
  0 swap to-find-line  refresh-line ;

: TO-Bids  ( n -- )
  >r  >bids r> ;

: (un-add) ( -- )  \ remove extensions and vtotals
  noext? 0= ?exit
  [ editor ] 17 to cursor-line
  begin cursor-line file-lines <
        cursor-line 1- #line" drop s" Total Estimate" tuck istr= 0= and
  while get-cursor-line
        cur-buf @ 56 min cur-buf !
        put-cursor-line
        1 +to cursor-line
  repeat refresh-screen ;

' (un-add) is un-add

\s

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 9     THE DOCUMENTATION -----

                This revision is for Win32Forth.
                Conversion started in March of 2000
                Working version Thursday, July 01 2004
                files1line will help look through the old bids

ELECTRIC        A vocabulary
ELECT           Set the search order to a clean safe state.
ELECTRIC-WORDS  A correctly spelled version
DONE            Save all the buffers and set the vocabularys to a clean
                state with Electric as the first vocabulary to be searched
QUAN            The quanity ordered.
NPS-W/S         The price of one unit wholesale
PARTS-COST      The cost of the parts
TIME-UNIT       Per each, hundred or thousand
RATE        >>  This is where the default labor rate is set...
UNIT            Defered to either C  M  E
PARTS-EXT       The total of the unit price times the quanity.
TIME-EXT        The time for the number of units.
LABOR-EXT       The labor to extend
SELL-EXT        The parts and labor added.  Asking price.
PARTS-SUB       The sub total of parts.
TIME-SUB        Sub total of time.
LABOR-SUB       Sub total of the labor price.
SELL-SUB        Sub total of the asking price.
CALC-PARTS      Multiply the cost by the quantity and store in three variables
                Parts-ext  Parts-sub  and Parts-total
CALC-TIME       Calculate the time
.W/S            Print whole sale
SHOW-PARTS      Show the quanity, the parts price and the extended cost.
SHOW-LABOR      Show the time it will take and the asking price for it.
SHOW-SELL       Show the asking price for the line.
W/E             Wholesale each
W/C             Wholesale per hundred
W/M             Wholesale per thousand
EX              Single precision extend used for fluf and fixts
E2              Calc the time labor and the sell price
EXdd            Double number quanity, double number price
EXd             Single percision quanitity  double number price
M               Thousand
C               Hundred
E               Each
CLEAR-SUB       Zero out the double variables named
                parts-sub, labor-sub and sell-sub.
(SUB)           print the sub total of the parts, labor and sell
SUB
CLEAR-GRAND     Don't clear-totals, do zero out the grand totals
HEAD-LINE       Put a header on top of the columns like this.
                PARTS       TIME      LABOR       SELL
                and unsupress if necessary.
GRAND           Show the headaers and the grand totals of all
                and clear the grand total variables.
                Actually not used very much by me.
CLEAR
INTERPRET-A-BLOCK
                This was known as  RUN in F82 version 1.0.0
                I use it as it does what I need in the old way when it treats
                the in-file and the from-file.  Something like that.  JP
SO-xx
                If there is a double number on the stack, print it with 2
                places to the right of the decimal and in a field of 3
INTERPRET-LINE
JUMPED
JUMP
CURRENT-LINE    is a variable
SOURCE-LINE     Take the BLK and convert it to the address of
                the current-line, unless BLK is zero.
                Restore the tect input buffer??
IF-SO-DOLLARS   Drop the cents and move the double number to
                the address on the stack.
NO-CENTS        Vector  if-so-dollars in to amount>screen
IF-SO-CENTS     Test for a double nunber, output it to the
                screen with two decimal places.
WITH-CENTS      Vector if-so-CENTS in to amount>screen
NOOP-SLASH-PAREN   Disabale the action of back-slash and the
                   left parenithes.
DEFINED+        The same as  DEFINED  with the addition of
                disabeling the words back-slash and the left paren.
REPORT          Give name of the word you are interpreting.  This is
                usefull when you want to see what items are being extended
                on screen while executing the command EXTEND.
SUMMARY         Put the prices on top of the screen
                Price up the items on the screen, enter the
                editor, go to the top and print the various
                totals for the parts, tate, hours, and sell
                prices.  Put the user in to the editor so he can
                use the work ADD to add up the extentions at the
                cursor location.  Needs a beter name.
FIG             Price out the screen but skip anything on the
                first three columns.  ( Room name etc.)
FIGG            Take the screen number and price it out.  Put
                the totals on the top line of the screen.
(EXTEND)        Tab over, figure the prices with totals then add the
                colums and print the results
EXTEND          Price up all the parts listed on the current screen.
                Usually executed by  CTRL E  from the visual editor.
FIG             Extend the prices as above but stop and wait for a key so
                you can look at the on screen audit trail before going on.
LEFT-EXTEND     Extend prices for parts listed on the left border.
FIGG            An old name now better known as Left-Extend
EXTENDS         Extend a series of screens
FIG-THRU        an old name for Extends
PRICE-IT        extend the whole file from screen one to the end
LEFT-EXTENDS    Extends parts that start on left border of screen
mmmm            Show the times for each line as well as the sell price
MEN-ON          Turn on the times feature
MEN-OFF         Put it back to not showing the times on each line
(MEN)           Times on  extend each line  Times off
MEN             Add a column showing the time required for each item
