\ $Id: Convert.f,v 1.1 2011/03/19 23:26:09 rdack Exp $
\ Convert source from F83s to work with Win32 Forth.   Revised 8-25-2001 rda

forth also forth definitions

: --> ;

: `  : ;  \ Back tick alias for colon - leaves original unavailable.
: ~  : ;  \ Nya alias for colon         
: |    ( -- ) [compile] \ ; immediate \ Now ok to load each blk, plenty of mem.
          \ Formerly used with GET to do LOAD on demand to save memory.
: %    ( -- ) [compile] \ ; immediate \ Now ok to load each blk, plenty of mem.
          \ Formerly used to indicate a block not commonly needed. (Ivory Plates)

: TITLE ( n -- ) CREATE DOES> DROP ;
          \ Formerly created a title in the VLIST of words.

: DO-THRU  ( from thru -- )  postpone 1+ postpone swap postpone do ; immediate

: TAB-IN    ( n -- )      \ tab to column n
  >col-cursor ;

: eof 0 ;
: thru 2drop ;
: want [compile] \ ; immediate
: Have [compile] \ ; immediate

\ Make 16 bit doubles work on a 32 bit system.
: D->S   ( d -- n )  \ Convert double number to single.
     drop ;
: D*  ( d d -- d d )    d->s >r  d->s  r>  m* ;  \ 10-13-2001
: D/  ( d d -- d d )    d->s >r  d->s  r>  /  s>d  ;  \ 10-13-2001
: dliteral swap [compile] literal [compile] literal ;  immediate
: dlit  swap [compile] literal [compile] literal ;  immediate

\S
end =vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv end

.( Convert.f loaded )

Variable R#     \ Editig cursor position
64 Constant C/L \ characters per line
1024 value      C/SCR \ c/l l/scr \ Constant C/scr
Variable SCR

: AT  at-xy ;   ( n n -- ) \ location on the screen

: TOP           ( -- ) \ top of the virtual screen
                R# OFF  ED ;

: CC ( n -- )   \ Move the cursor n spaces.  Sunday, May 02 2004 - 15:19
                [ editor ] +col-cursor ;

: CURSOR        ( -- n )  \ Returns number of chars
                R#  \ editing cursor position in the old 1024 byte screen
                @   \ get the value of the variable
                ;

: LINE#         ( -- n )  \ line nunmber
                CURSOR  C/L  /  ;

: COL#          ( -- n )
                CURSOR  C/L  MOD  ;

: block  ( line# - addr ) line ;   \ might be bad ????jap
: 'START        ( -- adr )
                SCR @ BLOCK ;

: #AFTER        ( -- n )
                C/L COL# -  ;

: #REMAINING    ( -- n ) \ characters remaining to end
                C/SCR CURSOR - ;

: #END          ( -- n )
                #REMAINING COL# +  ;

: T             ( n -- )    TOP  C/L *  CC EDITOR ;
                \ Used by GSD -> GOTO -> GG  and all-thru, copy-job-address

: CRs           ( n -- )  1+ 1 do cr loop ;

: 2NIP          ( n1 n2 n3 n4 -- n3 n4 )  2swap  2drop ;




