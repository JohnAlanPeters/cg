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
: setbkindx { fbase fcnt \ fnm -- }   \ set bkindx to highest # that exists
  128 localalloc: fnm
  1 begin  fbase fcnt fnm place dup 0 (d.) fnm +place
           fnm count "OPEN 0= if close-file drop 1+ 0 else drop 1 then
    until 1- to bkindx ;

: xbk { \ fbk curfn -- }
  edit-changed? not ?exit
  128 localalloc: fbk   128 localalloc: curfn
  cur-filename count fbk place
  s" .xbk" fbk +place
  fbk count setbkindx bkindx 99 <
  if 1 +to bkindx bkindx 0 (d.) fbk +place
   fbk count "OPEN 0=  \ check if .bak file exists
   if close-file drop
     fbk count DELETE-FILE drop  \ delete old backup
   else drop then
   cur-filename count curfn place
   fbk count cur-filename place    \ save file as backup
   do-save-text true to edit-changed? curfn count cur-filename place reedit
  then ;

: xunbk { \ fbk curfn -- }
  128 localalloc: fbk  128 localalloc: curfn
  cur-filename count fbk place
  s" .xbk" fbk +place
  fbk count setbkindx xcurbk 0= if bkindx else xcurbk 1- 0 max then to xcurbk
  xcurbk dup bkindx 1+ < and
  if xcurbk 0 (d.) fbk +place
     cur-filename count delete-file drop
     fbk count cur-filename count  xcopyfile
     revert-text
  else xcurbk 1- 0 max bkindx min to xcurbk revert-text then reedit ;

: xrebk ( -- )
  2 +to xcurbk xunbk ;

: xdelbks { \ fbk -- }
  128 localalloc: fbk
  s" del " fbk place
  cur-filename count fbk +place
  s" .xbk*" fbk +place
  fbk $shell ;


