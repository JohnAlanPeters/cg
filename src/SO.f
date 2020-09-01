\ A version of Screen-Output Prior to November 17th, 2002
\ Dependencies: The file Wined.f must be in memory

Variable keyboard
         keyboard on \ turns both console and screen display on/off in show-all
                     \ does not seem to be the right thing
variable screen-output
variable #out

: OS-CHAR  ( c -- )  \ Overstrike a character at cursor location
    [ editor ]  Overstrike-character  ;
: OS-TYPE  ( addr count -- )
    [ editor ] overstrike @   >r
    1 Overstrike !  insert-string
    r> overstrike ! ;
: ED-CR   \ carriage return that works in the editor
         do-cr 0 #OUT ! ;

: _c_cr  [ hidden ] c_Cr  0 #out !  ; \ zero the count of #out characters
: _c_key? [ hidden ] c_key? ;
: _c_key [ hidden ] c_key ;

: SO    ( -- )  \ output at the cursor position
        keyboard off
        screen-output on
        ['] OS-CHAR is emit
        ['] OS-TYPE is type
        ['] ED-CR   is cr ;

: S-O   ( -- )  SO ; \ screen output

:  _emit_  1 #out +!  [ hidden ] c_emit ;
: _type [ hidden ] c_type ;

: _RO   ( -- ) ( Regular Output )  \ restore to regular
        keyboard on
        screen-output off
        ['] _c_CR    is CR
        ['] _emit_   is emit
        ['] _type   is type ;
' _ro is ro

: R-O    ( -- ) RO ;

0 value ext-err
create errword 20 allot
: EVALUATE-ext      ( addr len -- fl ) \ interpret string addr,len
                 SOURCE 2>R
                 >IN @ >R
                 SOURCE-ID >R
                 (SOURCE) 2!
                 >IN OFF
                 -1 TO SOURCE-ID
                 ['] INTERPRET CATCH
                 R> TO SOURCE-ID
                 R> >IN !
                 2R> (SOURCE) 2!
                 dup if beep r-o focus-console pocket count errword place dup message true to ext-err
                      err-vocab-show if cr context @ current ! words then
                     then 0= ;   \ 'throw' causes app to quit


: my-eval ['] evaluate catch dup -13 <>
           if cr ." Everything went OK..." drop
           else cr ." Oh dear, you got an error..."
                 throw
           then ;





.( SO.f is loaded )


