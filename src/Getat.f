\ $Id: Getat.f,v 1.1 2011/03/19 23:26:09 rdack Exp $                                                         1 0
(( GETAT.F  Coded on August 3rd, 2003 - 18:25 RDA for JAP      2 1
1234567890           22        32                              3 2
 123.00 Test numbers. This is line #3 zero based or 4          4 3
  321                456.78                                    5 4
  123.45                       $123.45                         6 5
7                                                              7 6
8                                                              8 7
9                                                              9 8
10                                                               9

By Robert D. Ackerman - July 15th, 2003  Version 1.01 first cut.

Given the line# of the current file and column# GET-AT returns a double number.
It allows leading '$', leading spaces, commas, leading minus sign, and decimal
point. Keep parsing til a non-digit. ))

\ Anew xxgetat-test  \ Anew has a problem, it forgets too far down  jap
editor
0 value atflag   \ maxfldlen (31max), |0x40 -> '$', |0x80 ->'-'
9 value atmax   \ set to max fldlen desired

: ATADDR ( line# col# -- coladdr )
  over #line.bytes 1- over atmax + >
  if swap #line.addr + else 2drop 0 then ;

: GETNUMCUR  ( -- d1) \ get a double number at current position
  cursor-line cursor-col ataddr
  ?dup 0= if 0 0 exit then  \ col is gt linelen
  atmax to atflag  \  -- addr
  -1 to dp-location
  \  get leading chars up to first digit
  atflag 0
  do dup c@ dup ascii $ =
    if drop atflag 64 or to atflag    \ got a dollar sign
    else dup ascii - =
     if drop atflag 128 or to atflag  \ negative#
     else bl <> ?leave then           \ hopefully got a digit (or dp)
    then atflag 1- to atflag     \ decrement max
    1+                           \ increment address
  loop      \ (S addr )
  0 0  rot atflag 31 and \ -- ud addr
  begin >number over c@ dup ascii , =
        swap ascii . = or over 0> and
  while 1 -1 d+          \ inc addr, dec len
  repeat 2drop           \ ud
  atflag 128 and         \ is negative
  if dnegate then ;

: get-number  ( line# col# -- d1)  \ get a double number
  to cursor-col to cursor-line
  GETNUMCUR ;

: PUT-AT ( saddr slen #line #col -- ) \ put a string at the line and col #
  \ do a s" with the text in it " line# col# 
  to cursor-col to cursor-line
  get-cursor-line
  cur-buf lcount
  2 pick cursor-col + max cur-buf !  \ (S saddr slen curbuf )
  cursor-col + dup atmax blank       \ (S saddr slen curcol)
  swap cmove
  put-cursor-line
  file-has-changed
  refresh-line ;

Synonym getat GET-NUMBER   ( line# col# -- d1)
Synonym putat PUT-AT   ( saddr slen #line #col -- )

.( getat.f is loaded )

Comment:
It might be nice to have a word to change from a double number to a string if one exists
in the system. Here it is

<# #s #>

Comment;
