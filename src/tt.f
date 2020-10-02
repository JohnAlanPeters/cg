anew ttt

editor
: setbkindx { fbase fcnt \ fnm -- }
  128 localalloc: fnm
  1 begin  fbase fcnt fnm place dup 0 (d.) fnm +place
           fnm count "OPEN 0= if close-file drop 0 else drop 1+ 1 then
    until to bkindx ;

\ s" \cg\src\tt.f.xbk" setbkindx bkindx .


