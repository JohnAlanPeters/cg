\ rent

0 value starttimechk    \ gets set to minute-1 of current time

: time-min ( -- n )
   time-buf 10 + w@ ;

: chktimeout ( fl -- fl )
  dup 0= if get-local-time time-min starttimechk =
  if k_bye then then ;

: rentkey ( -- n )  get-local-time time-min 1- to starttimechk  \ wait 59 minutes
  BEGIN _c_key? chktimeout UNTIL [ also hidden ] key ;

: menu-rentkey ( -- )
               ['] rentkey is key ;

\ FORTH-IO-CHAIN CHAIN-ADD menu-rentkey
\ menu-rentkey

: JULIAN  ( year mo day -- d )
  3 ?enough
  >r 1-  31 *   r>  +   >r
  365  M*  ( d )
  r>  s>d   d+   ;

: .PLEASE-PAY
   cr ." Please continue renting this program."
   cr ." Make your check payable to: "
cr cr ."       John A. Peters"
   cr ."     121 Santa Rosa Ave."
   cr ."   San Francisco, CA 94112"
   cr ."            or  "
   cr ."     Call (415) 239-5393"
cr cr ."    Rent is $40 per month."
   cr ."  Site licenses, discounts, rent free demos"
   cr ."  and updates are available"
   cr ."  >>>> SORRY YOUR RENT IS USED UP OR..."
   cr ." If you already paid your rent, give me a call.. " ;

: NOTIFY ( days -- )
   dup  0 400 within
   if   dup 371 400 within
        if cr ." <<< LESS THAN 30 DAYS LEFT >>>" then
        cr .  ." Days used."  cr
              ." Rent is $40.00/Mo. Please" cr
   else  drop .please-pay  beep key k_bye
   then ;

: rtrtrtrt    \ Rent-time   ( Today's date )
   2013 1 10 \ START date: <year> <month> <day>
   Julian
   get-local-time time-buf w@ time-buf 2 + w@ time-buf 6 + w@
   julian  2swap d-  drop  NOTIFY ;

