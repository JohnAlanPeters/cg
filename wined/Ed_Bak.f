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
     cur-filename count s" xx.bak" cgbase" RENAME-FILE 0=  \ move current file to .bak
     if cur-filename count lastbakfile place then
  then
  do-save-text ;

: xundo ( -- )    \ replace original with .bak file and reopen
  cur-filename count lastbakfile count istr=   \ only if same file was backed up
  if s" bids\xx.bak" cgbase" "OPEN 0=  \ check if .bak file exists
     if close-file drop
        cur-filename count DELETE-FILE drop \ delete original
        s" bids\xx.bak" cgbase" cur-filename count COPY-FILE 0=  \ copy .bak file to current file
        if  revert-text   \ reload current file
        then
     else drop then
  then ;



