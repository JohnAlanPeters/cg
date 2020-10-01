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
: xbk { \ fbk curfn -- }
  edit-changed? not ?exit
  128 localalloc: fbk   128 localalloc: curfn
  cur-filename count fbk place
  s" .xbk" fbk +place
  1 +to bkindx bkindx 0 (d.) fbk +place
  fbk count "OPEN 0=  \ check if .bak file exists
  if close-file drop
     fbk count DELETE-FILE drop  \ delete old backup
  else drop then
  cur-filename count curfn place
  fbk count cur-filename place    \ save file as backup
  do-save-text true to edit-changed? curfn count cur-filename place reedit ;

: _xunbk { \ fbk curfn -- }
  128 localalloc: fbk  128 localalloc: curfn
  cur-filename count fbk place
  s" .xbk" fbk +place
  bkindx 0 (d.) fbk +place drop
  fbk count "OPEN 0=  \ check if bakcup file exists
  if close-file drop
     cur-filename count curfn place
     fbk count cur-filename place
     cursor-line cursor-col
     revert-text  curfn count cur-filename place
     to cursor-col to cursor-line
  else drop then reedit ;

: xunbk ( -- )
  bkindx 1- 0 max dup to bkindx if _xunbk else revert-text reedit then ;

: xrebk ( -- )
  bkindx 1+ dup 100 < if to bkindx _xunbk else drop then ;

: xdelbks { \ fbk -- }
  128 localalloc: fbk
  s" del " fbk place
  cur-filename count fbk +place
  s" .xbk*" fbk +place
  fbk $shell ;


