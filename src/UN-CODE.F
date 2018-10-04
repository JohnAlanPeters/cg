\ UN-CODE 1
Comment:
\ CAB                                               04-05-00 BEC
: TIME-STAMP   time 3 - type ;
: T-STAMP   [ editor ] top 46 CC  s-o time-stamp r-o ;
: COPY--BID  ( first last -- )
   file @  " \ELE\BIDS\-BIDS" $open drop file !
     0 hop  convey-  ;
: CAB-n  ( first last n-blocks -- ) ( Give it a name )
            ."  Creating A Bid file"  [ editor ] wrap off
   ( n ) create-file  ( n n ) copy--bid  same   r# off
   0 scr !  T-STAMP  top 0 v ;
: Name-check  >in @ bl word C@ 0= abort" No file name" >in ! ;
   \ Prevents over writing a file of the same name.
: CAB  name-check \E ( 0 20 ) 0 23 ( 21)  24 cab-n  ; \ 9-13-00
: COD      0  0   3 cab-n ." Setup Charge!"  beep  ;
   \ Copy only the Name template.  Reminds upon ESC key
comment;


\ UN-CODE 2
Comment:
\ Un-add a column                                   88-11-05 0.0
: (UN-ADD)  ( line# -- )
  line $COLUMN +   c/l $COLUMN  -  blank  update  ;
: UN-ADD-COLUMN   ( -- )  \ Uses current SCR
  1 15 Do-thru  I  (un-add)  loop  ;
: UN-SUMMARY  ( -- )
  0 line  24 +  [ 64 24 - ] literal  blank  update ;  ( 48 17 )
    ( Just after the comments, till the percent )
: UN-ADD  ( -- )  \ Uses SCR
  scr @ 0= if abort" Scr zero" then
  un-summary  un-add-column  ;
: UN-TIME  $column @   35 is $column  un-add   $column !  ;
comment;


