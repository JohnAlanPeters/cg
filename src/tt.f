
anew tt

editor
: xset  ( -- )  \ eliminate extra blank lines  see also settle below
  17 to cursor-line   0  \ initial value for #blank lines read \ was 24  JPPP
  begin cursor-line 1+ file-lines <
  while cursor-line #line" -trailing nip 0=
        if 1+ dup 2 >  \ 1 is one line 2 is two lines between  \ JP 3-24-11
           if  1 delete-lines
           else 1 +to cursor-line then
        else 1 = if 1 insert-lines then
           0  1 +to cursor-line   \ non-blank, so reset count
        then    \  dup . cursor-line .  cr   ( for debugging )
   repeat drop ;



