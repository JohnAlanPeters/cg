\ console-paste
\ hidden also     \ doesn't work with this line in
: console-paste { \ phdl pptr -- }
  conHndl call OpenClipboard 0= ?exit
  1 call GetClipboardData ?dup
  if dup to phdl
     call GlobalLock dup
     to pptr       \ lock memory
     if pptr zcount  \ -- addr len
        [ hidden ] c_"pushkeys
        phdl Call GlobalUnlock drop
     then
  then Call CloseClipboard ?win-error ;

' console-paste is paste-load


