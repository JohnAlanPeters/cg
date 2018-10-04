\ logger.scr

create logfile ," wcglog.txt" cgbase"      \ default logfile name

: logdatetime ( handle -- )
   >r get-local-time
   time-buf >month,day,year" r@ write-file drop
   s"  " r@ write-file drop
   time-buf >time" r@ write-file drop
   s"  - " r> write-file drop ;

: logmsg ( adr len -- )       \ string to log
  logfile count w/o OPEN-FILE dup
  if 2drop logfile count w/o create-file then 0=
  if dup >r file-append drop
      r@ logdatetime                  \ enter date time
      r@ write-file drop              \ write message to file
      crlf$ count r@ write-file drop  \ newline at end
      r> close-file drop 
  else 2drop drop then ;

: dologfile ( -- )  \ assumes file name in cur-file
  cur-file count logmsg ;

\ ' dologfile is logit

: getuser ( -- )
  begin cr cr s" Please enter name & email:" type cr pad 64 expect
    span @ 4 >
  until pad span @ logmsg ;

