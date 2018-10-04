\ Tools
\ $Id: Tools.f
\ File is TOOLS.F  by John A. Petes and Robert D. Ackerman (hard stuff)
\ Created January 28, 1991  Revised December 12, 2010

 2variable Sales-Amount
 2variable TAXes
 2variable O-H
 2variable PROFITs

: SELL ( d -- )   2 ?enough                              cr  cr
 Sales-Amount 2!   Sales-Amount 2@  ."   Whole sale " 11 d.j  cr
 Sales-Amount 2@   .0875  d* 1.0000 d/  2dup TAXes 2!
                                    ." 8.75% Tax is " 11 d.j  cr
 Sales-Amount 2@  TAXes 2@  d+  .15  d* 1.00 d/  2dup  O-H 2!
                                    ." Over head is " 11 d.j  cr
 Sales-Amount 2@  TAXes 2@  d+ O-H 2@ d+
                      .10  d* 1.00 d/  2dup profits 2!
                                    ."    Profit is " 11 d.j  cr
                                 ."              ===========" cr
 Sales-Amount 2@  TAXes 2@  d+  O-H 2@  d+  profits 2@ d+
                                    ."     Total is " 11 d.j  cr ;

: GG  ( -- )     [ editor ] swap2lines ; 
: GGG ( n n -- ) [ editor ] swaplines ;


