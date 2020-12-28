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

2variable CURRENT-RATE             \ what is this for?
2variable LABOR-RATE               \ a double number variable
: PER-HOUR  Labor-Rate 2! ;        \ The rate is set just below here.
  180.00 per-hour                  \ Raised for remote bidding with Miro. 
\ 150.00 per-hour                  \ Raised by JP since I have plenty of work.
\  99.00 per-hour                  \ BV raised on Boris exit July 14, 2013
: Rate? Labor-Rate 2@ 2 9 d.nr ;   \ initalization, no colon or semicolon.
Labor-rate 2@  Current-rate 2!     \ initalize   jappjapp

: Residental-Rate-BV 149.00 labor-rate 2! ;
: Commercial-Rate-BV 189.00 labor-rate 2! ;           
: Commercial-rate    180.00 labor-rate 2! ; \ immediate words for changing the
: Bid-rate           236.00 labor-rate 2! ; \ Don't be lower than BV
: Commercial-labor-rate   commercial-rate ;
: Residential-rate   150.00 labor-rate 2! ; \ labor rate in an estimate.
: Residential-labor-rate residential-rate ;

Defer UNIT  ( this is ok )   \ Example: Wire is per 1000 ft
2variable WHOLESALE-SUB
2variable PARTS-SUB   \ is in use by interpret-lines++
2variable TIME-SUB   \ The time-sub may be no longer in use.
2variable LABOR-SUB
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
2variable gparts-total
2variable gtime-total
2variable glabor-total
2variable gsell-total

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 3     THE CONSTANTS ======

1000 constant THOUSAND
 100 constant HUNDRED
   1 constant ONE-ONLY

24 value m-in

: set-exts ( n <name> -- )
  create , does> @ m-in + ;

32  set-exts parts-col    \ changing virtual sub total in WinEd
41  set-exts time-col
53  set-exts sell-col
32  set-exts vparts-col
41  set-exts vtime-col
53  set-exts vtot-col
68 set-exts discount-col

true  value timecolshow      \ set false to not show time column
false value partscolshow     \ set false to not show parts column
false value partswholesaleshow
false value unitcolshow      \ true -> show cost and time for a single unit
false value laborcolshow
false value cons-1col        \ true=> only show 1 column in console/web
0 value discount-rate        \ rate of discount; 100 -> no diff
999 value last>in            \ last >in pointer offset

editor
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
  sell-total 2@ ; \ other-total 2@ d+ permit-total 2@ d+ allowance-total 2@ d+ ;

: CALC-PARTS   ( d -- )
     2dup  parts-cost 2!  Quan 2@  d*  1.00 d/
     2dup  parts-ext 2!  2dup  parts-sub 2+!  parts-total 2+!  ;

: CALC-LABOR   ( -- )
     time-ext 2@   labor-rate 2@  D*  1.00  d/
     2dup  labor-ext 2! 2dup labor-sub 2+!  labor-total 2+!  ;

variable timejack  100 timejack !  \ 110 -> no jack  5-26-2013 inc 10%

: TIME-FACTOR  ( n - ) \ Used to increase the estimated time
                timejack ! ;  \ You can reduce the labor rate at same time

: calc-unit-time ( d -- )
   100 0 d* unit s>d d/ timejack @ s>d d* 100. d/ time-unit 2! ;

: CALC-TIME   ( d -- )  \ cost per unit
     2dup calc-unit-time
     quan 2@  d*  unit s>d   d/ timejack @ s>d d* 100. d/
     2dup time-ext 2! 2dup time-sub 2+!  time-total 2+!  ;

: CALC-OTHER ( n -- )
    100 * s>d 2dup other-sub 2+! other-total 2+! ;

: CALC-PERMIT ( n d -- )
     swap s>d d* 2dup permit-sub 2! permit-total 2+! ;

: CALC-ALLOWANCE ( n -- )
    100 * s>d 2dup allowance-sub 2! allowance-total 2+! ;

: CALC-SELL  ( -- )
     parts-ext 2@  labor-ext 2@  d+
     \ other-total 2@ d+ permit-total 2@ d+ allowance-total 2@ d+  ( jappjapp )
     other-sub 2@ d+ permit-sub 2@ d+ allowance-sub 2@ d+
     2dup sell-ext 2! 2dup sell-sub 2+! sell-total 2+!  ;

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 5     SHOW THE RESULTS ======

: .W/S    ( d -- d ) 2dup  6 d.xx  space ;

: sub<>0  ( -- fl )   \ if sub is not zero
  sell-sub 2@ + other-sub 2@ + or permit-sub 2@ + or allowance-sub 2@ + or ;
  \ quan 2@ -1 -1 d<> ;

: vtotal<>0 ( -- fl )
  EX-TOTAL + ;

: SHOW2PARTS
  parts-col 1- TAB-in wholesale-sub 2@ bucks
  time-col TAB-in parts-sub 2@ bucks ;
: SHOW-UNIT-PARTS ( -- )
  parts-col TAB-in parts-cost 2@ bucks ;  
: SHOW-PARTS ( -- )
  parts-col TAB-in  parts-sub 2@ bucks ;
: SHOW-UNIT-TIME ( -- )
  time-col TAB-in time-unit 2@ 2 8 d.nr ;
: SHOW-TIME ( -- )
  time-col TAB-in  time-sub 2@ 2 8 d.nr ;
: SHOW-SELL ( -- )
  sell-col TAB-in  sell-sub 2@ bucks
  discount-rate
  if sell-sub 2@ discount-rate 0 d* 1.00 d/
     discount-col TAB-in bucks
  then ;

: CONS-SHOW-PARTS ( -- )
  in-web?
  if
    17 >ccol quan 2@  1.00 d/ 3 d.r ." @"
    27 >ccol parts-cost 2@ bucks ."  ="
    39 >ccol parts-ext 2@ bucks
  else
    17 >ccol quan 2@  1.00 d/ 3 d.r ." @"
    27 >ccol parts-cost 2@ bucks ."  ="
    39 >ccol parts-ext 2@ bucks
  then ;

: CONS-SHOW-TIME ( -- )
  in-web?
  if  49  else 49
  then  >ccol time-ext 2@ bucks ."  hr" ;

: CONS-SHOW-SELL ( -- )
  in-web?
  if
    cons-1col not if 60 >ccol labor-ext 2@ bucks
    else webindent dup  conscol ! 0 vbuf w! then
    72 >ccol sell-ext  2@ bucks
    discount-rate
    if sell-ext 2@ discount-rate 0 d* 1.00 d/
       84 >ccol bucks
    then
  else  \ console
    cons-1col not if 60 >ccol labor-ext 2@ bucks then
    72 >ccol sell-ext  2@ bucks
    discount-rate
    if
      sell-ext 2@ discount-rate 0 d* 1.00 d/
      84 >ccol bucks
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
  parts-ext 2off labor-ext 2off
  parts-sub 2off labor-sub 2off wholesale-sub 2off
  other-sub 2off permit-sub 2off allowance-sub 2off
  time-ext 2off time-sub 2off sell-sub 2off sell-ext 2off  ;

: CLEAR-TOTALS  ( -- )
  -1 to dp-location   \ so display items from console works
  clear-sub  wholesale-total 2off
  other-total 2off  permit-total 2off  allowance-total 2off
  parts-total 2@ gparts-total 2+! labor-total 2@ glabor-total 2+!
  time-total 2@ gtime-total 2+! sell-total 2@ gsell-total 2+!
  parts-total 2off  labor-total  2off
  time-total  2off  sell-total   2off  ;

: Clear         Clear-totals ;
: CLR           clear-totals ;

: SHOW-ALL   ( -- )
  unitcolshow  if show-unit-parts else
  PartsWholeSaleShow if show2parts else
  partscolshow  if show-parts else
  then then then
  unitcolshow  if show-unit-time else     
  timecolshow  if show-time   then then
  show-sell ;

: remvoc ( -- )  \ remember vocab we are in for later display
  context @ voc>vcfa , ;

: CONS-SHOW-ALL   ( -- )   \ output on current console line
  cons-1col not
  if cons-show-parts cons-show-time then
  cons-show-sell cr ;

0. 2value markup

: small-parts   ( -- )     2.00 2to markup ; \ 200% or double
: Parts+2.00               2.00 2to markup ;
small-parts  \ default

: Regular-markup           1.33 2to markup ;
: Fair-markup              1.33 2to markup ;
: parts+1/3                1.33 2to markup ;
: Good-markup              1.33 2To markup ; \ <<<<<<
: w/s+tax+15%+10%          1.33 2To markup ; \ <<<<<<
: Parts+1.33               1.33 2to markup ;
: large-parts     1.20 2to markup ; ( -- )
: Parts+10%       1.20 2to markup ;  \ Whole sale +tax, +10% profit, no OH
: Parts-ten       1.20 2to markup ;
: Parts-20        1.20 2to markup ;
: Low-markup      1.20 2to markup ;
: w/s+tax+10%     1.20 2to markup ; \ <<<<
: Parts+1.20      1.20 2to markup ;
: Wholesale-parts 1.09 2to markup ; \ Whole sale plus tax only, no profit
: Inc-tax         1.09 2to markup ; \ actually 8.50 or 1.085
: w/s+tax-only    1.09 2To markup ; \ <<<<
: Parts+8.5       1.09 2to markup ;
: Parts+30%       1.30 2to markup ;
: No-markup       1.00 2to markup ; \ Wholesale price only beforee sales tax
: Pretax-parts    1.00 2to markup ; \ before sales tax. no tax, no profit, no OH
: w/s-parts       1.00 2to markup ;
: w/s-pre-tax     1.00 2to markup ; \ <<<<
: Parts+00        1.00 2to markup ;
: Parts+1.00      1.00 2to markup ;
: Wholesale       1.00 2to markup ;

: IncWholeSaleSub  ( d -- )
   2dup quan 2@ d* 100.00 d/
   partswholesaleshow
   if 2dup WholeSale-Sub 2+!  then
   wholesale-total 2+!  ;

: MARK-IT-UP  ( w/s -- r/t )  \ 'w\s' is the double# wholesale price
   \ 2dup 100.00 d< if small-parts else large-parts then
   IncWholeSaleSub
   markup  d*  100.00  d/ ;   \ 'r/t' is retail after markup

Vocabulary Dollars
           Dollars Definitions
: T&M  ." a marker" ;

: _t&m ( n % -- )   \ stack: amount (single precision), percent for materials
  >r 0 100. d* 2dup 2dup sell-sub 2! sell-total 2+!
  2dup 100 r@ - 0 d* 100. d/ 2dup 2dup labor-sub 2! labor-total 2+!
  100. d* labor-rate 2@ d/ 2dup time-sub 2! time-total 2+!
  r> 0 d* 100. d/ 2dup parts-sub 2! parts-total 2+! ;

: T&M15  ( n -- )   \ divide an amount 15% materials, 85% labor
  15 _t&m ;

: T&M25  ( n -- )   \ divide an amount 25% materials,785% labor
  25 _t&m ;

: T&M30  ( n -- )   \ divide an amount 30% materials, 70% labor
  30 _t&m ;

: T&M40  ( n -- )   \ divide an amount 40% materials, 60% labor
  40 _t&m ;

: T&M45  ( n -- )   \ divide an amount 45% materials, 55% labor
  45 _t&m ;

: T&M50  ( n -- )   \ divide an amount 50% materials, 50% labor
  50 _t&m ;

only forth also editor also electric also definitions
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\      UNITS AND QUANTITIES ===========

: isDOUBLE? dp-location  1+ 0<> ;
: ?>d ( ?? -- d )  \ assumes a single or double on stack
   isdouble?  0=  if  s>d  100.  d*  then ;

: chkLast>in ( -- )
   >in @ last>in < if time-ext 2off parts-ext 2off labor-ext 2off sell-ext 2off
    1 else 0 then >in @ + to last>in ;

: kclr keyboard @ if clear-sub 0 to saved-depth -1 to dp-location
         then ;  \ clear subtotal for console line

        ( quantity with cost on top )
: W/E   ( n-quan d -- ) chkLast>in >r >r     n-one-only  ?>d  quan 2!  r> r>
            100. d*   mark-it-up   calc-parts ;
: W/C   ( n-quan d -- ) chkLast>in >r >r     n-one-only  ?>d  quan 2!  r> r>
                      mark-it-up   calc-parts ;
: W/M   ( n-quan d -- ) chkLast>in >r >r     n-one-only  ?>d  quan 2!  r> r>
             10. d/   mark-it-up   calc-parts ;
: EX    ( n-quan n -- )  \ Single precision extend, used for fluf and fixts
        chkLast>in
         >R  n-one-only  ?>d quan 2! R> S>D mark-it-up calc-parts  ;

: E2  ( n -- )  \ E2 is executed by evaluate
   s>d calc-time  calc-labor  calc-sell
   keyboard @ if cons-show-all then ;

: M [']  Thousand is Unit  E2 ;
: C [']  Hundred  is UNIT  E2 ;
: E [']  One-only is UNIT  E2 ;


\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 8     ACCUMULATE THE TOTALS AND SUBTOTALS =====
: Total-WEB ( -- ) \ display sub-totals on web
  cons-1col not
  if 39 >ccol parts-total 2@ bucks
     49 >ccol time-total  2@ bucks ."  hr"
     60 >ccol labor-total 2@ bucks
  then
  72 >ccol sell-total  2@ bucks ;


: Total-CON ( -- ) \ display sub-totals in console
  cons-1col not
  if 39  >ccol parts-total 2@ bucks
     49  >ccol time-total  2@ bucks ."  hr"
     60  >ccol labor-total 2@ bucks
  then
  72  >ccol sell-total  2@ bucks ;

: Headline-WEB ( -- )
     conscol @ 40 > if cr then
     16 >ccol ." Count"
     33 >ccol ." Part" \ Need to show on small cell screen or think it is dead
     44 >ccol ." Parts"
     55 >ccol ." Time"
     67 >ccol ." Labor"
     78 >ccol ." Sell" ;

: Headline-CON ( -- ) \ names of the columns
  16 >ccol  ." Count"
  26 >ccol  ." Part"
  38 >ccol  ." Parts"
  48 >ccol  ." Time"
  58 >ccol  ." Labor"
  70 >ccol  ." Sell" ;

: TOTAL  ( -- )
  in-web?
  if  headline-WEB  cr total-WEB
  else headline-CON cr total-CON
  then  clear-totals cr ;

: TOT total ; \ another attemampt as a shortcut

: TT reset-stacks  total ; \ shortcut. The spell checker changed TT into "To"

: clear-grand-total ( -- )
  gparts-total 2off gtime-total 2off
  glabor-total 2off gsell-total 2off ;

: alltotal ( -- )  \ grand-total for web
  gparts-total 2@ parts-total 2+!
  gtime-total 2@ time-total 2+!
  glabor-total 2@ labor-total 2+!
  gsell-total 2@ sell-total 2+!
  total clear-grand-total ;

: HEADLINE cr headline-con ;

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

\ See T&M in DOLLARS

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
: CAB-mini { \ to$ -- <fname> }   \ copies bids\template to a new file
  max-path localAlloc: to$ 
  /parse-s$ count to$ place
  to$ $open     \ don't copy if already exists
  if drop s" bids " cgbase" 2dup + 1- 0 swap c!  "chdir
     to$ +NULL false to$ 1+ 
     s" template " over + 1- 0 swap c!
    Call CopyFile 0= abort" The COPY Failed!"
  else close-file then to$ count "+open-text
      9 to cursor-line reEdit ;

editor
: cab { \ to$ -- } ( <fname> -- )  \ create a bid
  s" " onedrivebids "chdir
  max-path localAlloc: to$
  bl word count to$ place  \ path to 1drive bids file
  to$ $open         \ do nothing if it exists
  if s" \cg\bids\template-mini" to$ count xcopyfile
  then drop
  to$ count onedrivebids "+open-text 9 to cursor-line bookmark ;

: to-bids ( -- )  \ open -bids in editor
  s" -bids" onedrivebids "open-text ;

: >bids ( line# -- )             \ open -bids to line# given
  s" -bids" onedrivebids "open-text
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
        cur-buf @ 48 min cur-buf !
        put-cursor-line
        1 +to cursor-line
  repeat refresh-screen ;

' (un-add) is un-add

: replace-ch ( <ch1 ch2> -- )  \ replace all instances of ch1 in col 0 with ch2
  bl word 1+ c@ bl word 1+ c@
  cursor-line >r file-lines 0
  do i to cursor-line get-cursor-line cur-buf dup c@
     if cell+ dup c@ 3 pick =
     if over swap c!  put-cursor-line 0 then then drop
  loop 2drop file-has-changed save-text r> to cursor-line refresh-screen ;

\s

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 9     THE DOCUMENTATION -----

                This revision is for Win32Forth.
                Conversion started in March of 2000
                Working version Thursday, July 01 2004
                files1line will help look through the old bids
                Stoped using it in 2008 due to realestate downt
                Finished conversion November 2019
                Web version is progressing in December 2019

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
