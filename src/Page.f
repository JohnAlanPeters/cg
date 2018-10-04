\ PAGE-DOWN and PAGE-UP goe to the first set of double blank lines.
\ RDA for JAP on October 10, 2001

: +SCR ( -- ) \ down 1 screen ending with 2 or more empty lines
    0 \ count of empty lines
    BEGIN dup -1 > cursor-line file-lines 1- < and \ ?end of file
    WHILE
    cursor-line 1+ to cursor-line \ inc line
    get-cursor-line cur-buf @ 0=  \ inc count if empty line
    if 1+ else dup 1 > if drop -1 else drop 0 then then
    REPEAT -1 =
    if cursor-line to line-cur refresh-screen
    else line-cur to cursor-line then ;


: -SCR ( -- ) \ up 1 screen ending with 2 or more empty lines
    cursor-line 2 >                   \ at least 2 lines above
    if cursor-line 1- to cursor-line  \ up one line
       get-cursor-line cur-buf @ 0=      \ line is empty
       if cursor-line 1- to cursor-line  \ up a line
          get-cursor-line cur-buf @ 0=   \ true->2 empty lines
          if begin cur-buf @ 0= cursor-line 0> and \ until top or non-empty
             while cursor-line 1- to cursor-line
                   get-cursor-line
             repeat
          then
       then
    then 0
    BEGIN dup 2 < cursor-line 0> and
    WHILE
    cursor-line 1- to cursor-line
    get-cursor-line cur-buf @ 0=
    if 1+ else drop 0 then
    REPEAT
    cursor-line + dup to line-cur to cursor-line refresh-screen ; 


\ It is loaded via an include in the file WinView.f


