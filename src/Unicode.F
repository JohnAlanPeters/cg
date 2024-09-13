\ Unicode Words
\ Tom Dixon

\ *D doc
\ *! Unicode
\ *T Unicode Wordset
\ *Q Tom Dixon - August 2006
\ ** Unicode wordset for working with Unicode APIs

anew -Unicode.f


winlibrary OLE32.DLL

6 proc MultiByteToWideChar
8 proc WideCharToMultiByte
1 proc SysStringByteLen
2 proc SysAllocStringLen
1 proc SysFreeString

: Unew$         ( -- addr )
\ *G Allocate 2X MAXSTRING bytes from the dynamic string buffer and return the address. This is
\ ** designed for 16bit Unicode strings which are twice as long as Ascii.
                MAXSTRING 2* DynAlloc ;

: UniPlace ( addr len destaddr -- )
\ *G Store a unicode string to an address
  2dup ! 4 + 2dup + 0 swap w! swap cmove ;

: +UniPlace ( addr len destaddr -- )
\ *G Append a string to the end of an address
  2dup @ + >r dup >r dup @ + 4 + 2dup + 0 swap ! swap cmove r> r> swap ! ;

: +UniNull  ( destaddr -- )
\ *G Append a null to the unicode string at address.
  dup @ 2* + 0 swap w! ;

: UniCount ( addr -- addr len )
\ *G Fetch a unicode string from an address (stored with uniplace)
  dup 4 + swap @ ;

: ZUniCount ( addr -- addr len )
\ *G Fetch a null-terminated unicode string from an address (null is 16-bit)
  dup 0 begin over w@ while 2 2 d+ repeat nip ;

: UniType ( addr len -- )
\ *G Type a unicode string to the console
  2/ 0 ?do dup i 2* + c@ emit loop drop ;

: (U") r> UniCount 2dup + 2 + aligned >r ;

: Ustr, ( addr n -- )
\ *G Store a unicode string to the dictionary at HERE
  HERE over 6 + allot uniplace ALIGN ;

: Asc>Uni ( str len -- str len ) \ !!! MUST FREE STRING AFTER !!!
\ *G Convert a ascii string to unicode.\n
\ ** must free unicode string with 'free' when no longer needed.
  dup 2* dup allocate abort" Unable to Allocate Unicode String!"
  dup >r 2swap swap MB_PRECOMPOSED 0 MultiByteToWideChar r> swap 2* ;

: Uni>Asc ( str len -- str len ) \ !!! MUST FREE STRING AFTER !!!
\ *G Convert a unicode string to ascii\n
\ ** must free ascii string afterwards when no longer needed.
  0 0 2over 0 here 2swap swap 0 0 WideCharToMultiByte 2/ >r
  0 0 2swap r@ dup Allocate abort" Unable to Allocate String!"
  dup >r 2swap swap 0 0 WideCharToMultiByte drop r> r> ;

: >Unicode ( str len -- str len )
\ *G Convert ascii string to unicode (uses Unew$)
  asc>uni 2dup Unew$ dup >r uniplace drop free drop r> dup +UniNull unicount ;

: >ascii ( str len -- str len )
\ *G Convert unicode string to ascii (uses new$)
  uni>asc 2dup new$ dup >r place drop free drop r> count ;

: U" ( ... " -- str len )
\ *G Unicode string - same as s"
  STATE @ IF COMPILE (U") ascii " PARSE
     asc>uni 2dup ustr, drop free drop EXIT THEN
  ascii " PARSE >unicode ; IMMEDIATE


\ Some APIs require more specific conditions to their unicode strings.
\ (ie: distributed and network apis)
\ bstr has more constraints applied to it.  These words are to convert
\ to bstrs and back again.

: Asc>bstr ( str len -- bstr )
\ *G Convert ascii string to unicode bstr.  bstr must be freed later with 'bstrfree'.
  dup dup 0 SysAllocStringLen dup >r
  2swap swap
  MB_PRECOMPOSED
  CP_ACP
  MultiByteToWideChar drop r> ;

: bstrFree ( bstr -- )
\ *G Free a bstr.
  SysFreeString drop ;
: bstrlen ( ustr -- len )
\ *G Returns the length of the bstr.  From this the bstr can be used with all the
\ ** other unicode functions.
  cell- @ ;

\ *Z
