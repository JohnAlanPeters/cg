anew ttt

: (rename-file) ( <filename> <newname> -- )
  { \ RenameFrom$ RenameTo$ -- }
  MAXSTRING LocalAlloc: RenameFrom$
  MAXSTRING LocalAlloc: RenameTo$
  /parse-s$ count RenameFrom$  place
  /parse-s$ count RenameTo$ place cr
  ."  From: " RenameFrom$  count type
  ."   To: " RenameTo$ count type
  RenameFrom$ count RenameTo$ count rename-file
  if ."  Failed" then ;

