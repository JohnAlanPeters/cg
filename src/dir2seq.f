0 value rh
0 value wh
variable newnm 32 allot

: read-line-CRLF ( buff len -- flag )
  dup >r 13 scan dup r> <>              \ got cr
  if + 1+ c@ 10 =
  else 2drop 0 then ;

: f2seq ( fadr flen -- )     \ convert blk file to sequential file
  r/o OPEN-FILE 0=
  if to rh  pad 80 blank 2573 pad 80 + !
     s" tmp.f" delete-file drop
     newnm count w/o create-file drop to wh
     begin pad 64 blank
           pad 64 rh read-file 0= swap 64 = and
     while pad 82 wh write-file drop
     repeat rh close-file  wh close-file 2drop
  then ;

: isblkfile ( addr cnt --  flag)    \
     \ read 200 chars: if no 0d0a => true
     r/o OPEN-FILE 0=
     if to rh pad 200 blank
        pad 200 rh read-file 0=
        rh close-file drop
        if pad swap read-line-CRLF 0=
        else drop 0 then
     else drop 0
     then ;

: do2seq ( wd -- )
  dup @ 16 <>   \ not a dir
  if 44 + zcount
     2dup isblkfile
     if 2dup s" .\" newnm place newnm +place s" .seq" newnm +place
        newnm count type f2seq
     else 2drop then
  else drop then ;

\ loop through files in current dir
: dir2seq ( -- )
  s" *" find-first-file 0=
  if do2seq
  then
  begin find-next-file 0=
  while do2seq
  repeat find-close drop ;

: vwfile ( wd -- ok)
  dup @ 16 <>   \ not a dir
  if 44 + zcount
     [ editor ] _"+open-text     \ open in editor
     key close-text 27 <>
  else drop 1
  then ;

: seefiles ( -- )   \ open each file in a dir, one at a time
  s" *" find-first-file 0=
  if vwfile 0= if exit then else exit then
  begin find-next-file 0=
  while vwfile 0= if exit then
  repeat drop find-close drop ;

