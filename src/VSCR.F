\  vscr.f  - virtual screens are blocks of lines in a file separated by 2 crlfs
\ code to index vscreens, goto a vscrn
\ Verson 0.2  August 17th, 2003 - 21:56

: strim ( adr len -- adr' len' )  \ strip leading and trailing spaces
  bl skip -trailing ;

editor
: IND ( -- )       \ display first line of each virtual page
  cursor-line
  cr                  \ start at top
  0 to cursor-line    \ absolute line in current file
  0
  begin  dup space .
    cursor-line #line" strim type cr    \ type the line from the buffer
    +vscr                     \ down 1 screen ending with 1 or more empty lines
    cursor-line file-lines 1- <      \ don't go off the end of the file
  while 1+  slow       \ set slfactor to slow it down
  repeat  drop to cursor-line ;

: INDL ( -- )       \ display first line of each virtual page with line#
  cursor-line
  cr                  \ start at top
  0 to cursor-line    \ absolute line in current file
  0
  begin space cursor-line .
    cursor-line #line" strim type cr    \ type the line from the buffer
    +vscr                     \ down 1 screen ending with 1 or more empty lines
    cursor-line file-lines 1- <      \ don't go off the end of the file
  while 1+  slow       \ set slfactor to slow it down
  repeat  drop to cursor-line ;

: INDX ( -- )       \ display first line of each virtual page
  cursor-line
  cr                  \ start at line 23
  23 to cursor-line    \ absolute line in current file
  0
  begin  dup space .
    cursor-line #line" strim type    \ type the line from the buffer
    1 true skiplines                 \ skip non-empty lines
    cursor-line #line" dup 58 >
    if 58 getxy drop - spaces strim type
    else 2drop then cr
    1 0 skiplines
    cursor-line file-lines 1- <      \ don't go off the end of the file
  while 1+  slow       \ set slfactor to slow it down
  repeat  drop to cursor-line ;

: vPAGE  ( n -- )   \ goto virtual page 'n'
  0 to cursor-line
  begin dup 0<>
  while 1- +vscr
  repeat drop refresh-screen ;

: >vscr  ( n -- )  vpage ;
: Screen ( n -- )  vpage ;

16 constant vl#
: vnew ( -- )   \ create a new vscr of blank lines
  vl# insert-lines ;
                                                                        
: vpad ( -- )   \ add blank lines to get to a full vscr of blank lines
  0 begin dup vl# < over cursor-line + #line" -trailing nip 0= and
    while 1+
    repeat vl# swap -
  0 begin 2dup > cursor-line 2 pick 1+ - #line" -trailing nip 0= and
    while 1+
    repeat - dup 0 >
    if insert-lines else drop then ;

: vunpad ( -- )  \ reduce multiple blank lines to 2  (same as 'settle'?)
  begin cursor-line #line" -trailing nip 0=
  while -1 +to cursor-line repeat 1 +to cursor-line
  cursor-line    #line" -trailing nip 0=
  cursor-line 1+ #line" -trailing nip 0= and
  if  2 begin dup cursor-line + #line" -trailing nip 0=
        while 1+ repeat
      2 - delete-lines
  then ;

: blow-up ( -- )  \ insert 5 blank lines between vscreens
  26 to cursor-line    \ absolute line in current file
  begin
    +vscr                     \ down 1 screen ending with 1 or more empty lines
    5 insert-lines 5 +to cursor-line
    cursor-line file-lines 6 - >   \ don't go off the end of the file
  until ;


