anew ttt  \ we need a better name

: ?digit ( ascii -- true|false)  \ is character a digit 0-9
  dup ascii 0 >= swap ascii 9 <= and ;

: index$ ( n -- addr len )  \ index# as a string plus a space
  s>d <# #S #> ;
editor
: vindex#s ( -- )       \ maintain indexes for each virtual page
  cursor-line
  17 to cursor-line     \ start after header of a bid file
  1
  begin  +vscr          \ down 1 vscreen
    cursor-line file-lines 1- <     \ don't go off the end of the file
  while
    get-cursor-line
    cur-buf cell+ c@ ?digit 0=
    if cur-buf lcount over 3 + swap move   \ make room for 3 characters at start
     3 cur-buf +! s"    " cur-buf cell+ swap cmove
     dup index$ cur-buf cell+ swap cmove
     put-cursor-line
    then 1+              \ next vscreen index#
  repeat  drop to cursor-line ;

