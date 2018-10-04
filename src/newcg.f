

s" src" cgbase" "CHDIR

needs xwinver


variable qcg7 128 allot
variable qcg 128 allot
variable qruncg 128 allot

: qqq  ( qadr -<str>-  )
  ascii ' word count rot place ;

qcg7 qqq '"\Program Files (x86)\Win32Forth\win32for.exe" fload cg'
qcg qqq '"Win32Forth\win32for.exe" fload cg'
qruncg qqq 'cg.exe 0 editor hyper-compile bye'

: newcg ( -- )
  xwinver-init
  s" newcg.bat" w/o create-file
  abort" Couldn't create NEWCG.BAT"
  >r    \ save file handle
  s" chdir src" r@ write-file drop crlf$ count r@ write-file drop
  winver win7 =
  if qcg7 else qcg then
  count r@ write-file drop   crlf$ count r@ write-file drop
  s" chdir \cg" r@ write-file drop crlf$ count r@ write-file drop
  qruncg count r@ write-file drop  r> close-file drop bye ;

chdir ..
' newcg turnkey newcg



