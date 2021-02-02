editor
variable lastbakfile max-path allot
: copy-file      ( sadr slen dadr dlen -- fl )  \ 0 -> success
\ *G Copy a file. The 'from' and 'to' string is the path
\  and the file name.
  { | from$ to$ }
  max-path localAlloc: from$
  max-path localAlloc: to$
  to$   place
  from$ place
  from$ +NULL
  to$   +NULL
  false
  to$    1+
  from$  1+
  Call CopyFile 0= ;

create upath 128 allot

: setupath ( -- )   \ path to users dir
  s" \Users\j*"  find-first-file if drop s" \Users\User" find-first-file drop then 
  dir->file-name rot drop 
  s" \Users\" upath place upath +place s" \" upath +place ;

: onedrivebids ( addr len -- uaddr ulen)  \ full path to filename in onedrive
  setupath s" OneDrive\bids\" upath +place upath +place upath count ;

: xsave ( -- )     \ save original as xx.bak, before writing to disk
  edit-changed? 0= ?exit  \ only backup if file has changed
  cur-filename count find-first-file nip 0=
  if s" xx.bak" cgbase" DELETE-FILE drop \ delete backup
     cur-filename count s" xx.bak" cgbase" COPY-FILE 0=  \ move current file to .bak
     if cur-filename count lastbakfile place then
  then
  do-save-text ;

: xundo ( -- )    \ replace original with .bak file and reopen
  cur-filename count lastbakfile count istr=   \ only if same file was backed up
  if s" xx.bak" cgbase" "OPEN 0=  \ check if .bak file exists
     if close-file drop
        cur-filename count DELETE-FILE drop \ delete original
        s" xx.bak" cgbase" cur-filename count COPY-FILE 0=  \ copy .bak file to current file
        if  revert-text   \ reload current file
        then
     else drop then
  then ;

0 value bkindx
0 value xcurbk
0 0 2value bktime
: file-mod-time ( adr len -- dwmodtime )
  "open 0=
   if >r
     file-time-buf 2 cells erase     \ pre-clear buffer
     file-time-buf                   \ address of where to put the file's
                                     \ last written time and date
     0                               \ last access time not needed
     0                               \ creation time not needed
     r@ call GetFileTime drop r> close-file drop
     file-time-buf 2@ swap
   else drop 0 0
   then ;

: setbkindx { fbase fcnt \ fnm  -- }   \ set bkindx to highest # that exists
  128 localalloc: fnm   1 0 to bktime
  1 begin fbase fcnt fnm place dup 0 (d.) fnm +place
      fnm count file-mod-time ?dup
      if 2dup bktime d>
        if to bktime 1+ 0 else 2drop 1 then
      else 0= then
    until 1- to bkindx ;

: xbk { \ fbk curfn -- }
  edit-changed? not ?exit
  128 localalloc: fbk   128 localalloc: curfn
  cur-filename count fbk place
  s" .xbk" fbk +place
  fbk count setbkindx bkindx 9 > if 0 to bkindx then
  1 +to bkindx bkindx 0 (d.) fbk +place
  fbk count "OPEN 0=  \ check if .xbk file exists
  if close-file drop
     fbk count DELETE-FILE drop  \ delete old backup
  else drop then save-text
  cur-filename count fbk count xcopyfile bkindx to xcurbk ;

: xunbk { \ fbk curfn  textlen -- }
  128 localalloc: fbk  128 localalloc: curfn
  cur-filename count fbk place
  s" .xbk" fbk +place
  fbk count setbkindx xcurbk ?dup 0= if bkindx then
  1- dup bkindx <> over bkindx 1+ <> and
  if ?dup 0= if 10 else dup 10 > if drop 1 then then dup to xcurbk
    0 (d.) fbk +place
    fbk count r/o open-file 0=
    if >r                              \ save the file handle
      text-ptr ?dup IF release THEN
      r@ file-size 2drop to textlen
      textlen start-text-size +  to text-blen
      text-blen malloc to text-ptr
      cursor-line
      text-ptr textlen r@ read-file drop
      r> close-file drop
      set-line-pointers
      to cursor-line
      set-longest-line refresh-screen  reedit
    else drop then
  else drop then ;

: xrebk ( -- )
  2 +to xcurbk xunbk ;

: xdelbks { \ fbk -- }
  128 localalloc: fbk
  s" del " fbk place
  cur-filename count fbk +place
  s" .xbk*" fbk +place
  fbk $shell ;


