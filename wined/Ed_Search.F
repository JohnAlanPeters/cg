\ $Id: Ed_Search.F,v 1.1 2011/03/19 23:26:04 rdack Exp $
\    File: Ed_Search.f
\  Author: Andrew Stephenson
\ Created: Sunday, January 30 2005 - 16:45 aws
\
\ 

: never         ( flag - false ) drop false ;
: -dup  ( n1 n2    - n1 n1 n2 )    >r dup r>  ;

\ October 15th, 2002, "Lcc Wizard" Gave me a 2nip in assembler
\ April 7th, 2005, Move into fkernel.f aws
\ code 2nip       ( n1 n2 n3 n4 -- n3 n4 ) \ 2swap 2drop
\               pop     eax
\               mov     4 [esp], eax
\               pop     eax
\               next    c;

\ May 22nd, 2002 - 18:50
\ s-exchange to prevent roll when posible

code s-exchange ( ... n[k]..0 k -- ... 0..n[k] )
                mov  eax, ebx               \ save k
                mov  ecx, [esp]             \ save nos
                mov  ebx,  0 [esp] [eax*4]  \ duplicate n[k] in tos
                mov  0 [esp] [eax*4] , ecx  \ put nos where n[k] was
                pop eax           \ discard second item on data stack
                next    c;

\ Usage:
\ 10 20 30 40   3  cr .s  s-exchange    cr .s
\ result:
\ [5] 10 20 30 40 3
\ [4] 40 20 30 10   ok....
\
\ Initial Made by Ron Aharon.
\ COMPAREI is the same as COMPARE , but case-insensitive
\ Modifications to get a better shell-sort:
\ 1. The version leaves the chars from 0 to 2F unchanged.
\    The effect is that in a sort the non-alphanumeric characters will not be
\    between the alphanumeric characters.
\ 2. It uses jnb instead of jns which makes sure that the character FF is at
\    the end of a sorted list.
\ 3. Changed the name to COMPAREIA to avoid future conflicts.


code compareia    ( adr1 len1 adr2 len2 -- n )
                sub     ebp, # 8
                mov     0 [ebp], edi
                mov     4 [ebp], esi
                pop     eax                     \ eax = adr2
                pop     ecx                     \ ecx = len1
                pop     esi                     \ esi = adr1
                add     esi, edi                \ absolute address
                add     edi, eax                \ edi = adr2 (abs)
                sub     eax, eax                \ default is 0 (strings match)
                cmp     ecx, ebx                \ compare lengths
                je      short @@2
                ja      short @@1
                dec     eax                     \ if len1 < len2, default is -1
                jmp     short @@2
@@1:
                inc     eax                     \ if len1 > len2, default is 1
                mov     ecx, ebx                \ and use shorter length
@@2:
                mov     bl, BYTE [esi]
                mov     bh, BYTE [edi]
                inc     esi
                inc     edi
                cmp     bx, # $2F2F            \ skip chars beteen 0 and 2F ( now lower case )
                jle     short @@7
                or      bx, # $2020            \ May 21st, 2003 or is better then xor
@@7:
                cmp     bh, bl
                loopz   @@2

                je      short @@4               \ if equal, return default
                jnb     short @@3               \ ** jnb for an unsigned test ( was jns )
                mov     eax, # 1                \ if str1 > str2, return 1
                jmp     short @@4
@@3:
                mov     eax, # -1               \ if str1 < str2, return -1
@@4:
                mov     ebx, eax
                mov     edi, 0 [ebp]
                mov     esi, 4 [ebp]
                add     ebp, # 8
                next    c;

\ Searchai str1 for substring str2 in a case-insenitive manner.
\ If found, return the address of the start of the
\ string, the characters remaining in str1 and a true flag.
\ Otherwise return the original str1 and a false flag.

\ ESI = pointer to source string (str2)
\ EBX = length  of source string
\ EDI = pointer to destination string (str1)
\ ECX = length  of destination string
\ EDX = pointer for compare

CODE searchia     ( adr1 len1 adr2 len2 -- adr3 len3 flag )
                test    ebx, ebx
                jne     short @@1
                pop     eax
                dec     ebx             \ zero length matches
                jmp     short @@6
@@1:            sub     ebp, # 12
                mov     0 [ebp], edx    \ save UP
                mov     4 [ebp], edi
                mov     8 [ebp], esi
                pop     esi
                add     esi, edi
                mov     ecx, 0 [esp]
                add     edi, 4 [esp]
                jmp     short @@2

@@4:            inc     edi             \ go to next    c; char in destination
                dec     ecx
@@2:            cmp     ecx, ebx        \ enough room for match?
                jb      short @@5
                sub     edx, edx        \ starting index

@@3:            mov     al, 0 [edx] [esi]
                mov     ah, 0 [edx] [edi]
                or      ax, # $2020        \ make it lowercase
                cmp     al, ah
                jne     short @@4
                inc     edx

                cmp     edx, ebx
                jne     short @@3

                mov     eax, edi        \ found
                mov     edx, 0 [ebp]
                mov     edi, 4 [ebp]
                mov     esi, 8 [ebp]
                add     ebp, # 12
                sub     eax, edi        \ relative address
                mov     4 [esp], eax
                mov     0 [esp], ecx
                mov     ebx, # -1       \ true flag
                jmp     short @@6
@@5:            sub     ebx, ebx        \ not found
                mov     edx, 0 [ebp]    \ restore UP
                mov     edi, 4 [ebp]
                mov     esi, 8 [ebp]
                add     ebp, # 12
@@6:            next    c;


0 value last-cnt
0 value CaseSensitive?

: starting-with? ( adres-spec /spec  adr-search /search - next-adr /next flag )
   locals| /spec adr-search |
   dup -rot adr-search over CaseSensitive?
      if    compare
      else  compareia
      then
   not dup
      if    >r 2dup +to last-cnt adr-search + /spec rot - r>  \ First
      else  nip adr-search /spec rot
      then
 ;

: containing? ( adres-spec /spec adr-search /search -- next-adr /next flag )
    drop dup>r  2swap  CaseSensitive?
        if   search
        else searchia
        then
    dup
       if     r>  2 pick - +to last-cnt
       else  r>drop
       then
  ;

ascii * value wildcard-char

: continue-w-search? ( /search /spec result - /search flag )
   swap 0> and over 0> and ;

: scan-for-wildcard   ( adr-spec /spec - adr len flag )
   wildcard-char scan dup 0= ;

: target-search ( >adr-spec max-spec adr-spec /spec adr-search /search - >adr-spec1 max-spec1 adr-spec /spec adr-search /search )
   2over scan-for-wildcard
       if   2drop
       else  dup 7 s-exchange swap - 4 s-exchange drop 6 s-exchange drop
       then
 ;

: next-search ( >adr-spec max-spec adr-spec /spec adr-search /search - >adr-spec max-spec adr-spec1 /spec2 adr-search /search  )
   2>r 2drop 2dup 2r>  ;

: wildcard ( >adr-spec max-spec adr-spec /spec adr-search /search - >adr-spec max-spec adr-spec1 /spec2 adr-search /search  )
   2>r 2drop 1- swap 1+ swap    \ in spec$
   2dup scan-for-wildcard
      if    2drop  >r 0 over r>
      else  2swap  2 pick -
      then
   2r>
 ;


\ adr and len are invalid when the flag returns 0 in w-search
\ w-search is might be case sensitive
\ CaseSensitive? 0= stands for case insensitive.
\ A * in the specification string skips 0 or more characters until
\ the next substring is found. A duplicate substring might be confusing.

: w-search ( adr-spec /spec adr-search /search flag - adr len flag )
   to CaseSensitive?
   0  0 locals| /last adr  |
   dup 0> 3 pick 0> and
   if  2>r 2dup 2r>   true >r
       2 pick r@ continue-w-search? 0 to last-cnt
           if
                begin  2 pick r@ continue-w-search?
                while  3 pick c@ wildcard-char  =
                        if    wildcard 4dup
                               adr containing?   adr 0=  \ *
                                  if  0 to last-cnt
                                  then
                        else  target-search  4dup adr 0=
                                  if    over to adr
                                  then
                               starting-with?
                        then
                     r> and dup>r adr 0= and
                        if    over to adr
                        then
                     2nip 2 pick to /last next-search
                repeat
                4drop 2drop last-cnt /last +
             else drop
             then
        adr swap r@ 0<> and r>
     else   2nip false   \ July 21st, 2003 Solves the zero buffer problem
     then
 ;

: +trailing ( adr count char - adr2 count2 )
    -rot dup>r over + swap dup>r
        ?do   i c@ over <>
                if   i leave
                then
        loop
     nip r> -dup - r> swap -
 ;

: #number-line> ( adr count which seperator - n flag )
    locals| seperator |   dup 0>
       if    >r seperator  +trailing r> 0
                do    seperator scan seperator +trailing
                loop
       else  drop seperator  +trailing
       then
    -dup seperator scan drop over -
     number? -rot d>s swap
 ;

: search-window ( adr cnt - hndl )
   2>r call GetActiveWindow dup
    begin
       GW_HWNDNEXT swap call GetWindow dup 0<>
          if  dup  MAXSTRING pad rot call GetWindowText pad swap
              2r@ 2swap w-search nip never
          else never 0 true
          then
      or
     until nip 2r> 2drop
 ;

create *buffer maxstring allot
\ *search puts a * before the specification string.
\ Then it performs a w-search

: *search ( adr-spec /spec adr-search /search flag - adr len flag )
  >r 1 *buffer c!  wildcard-char *buffer 1+ c!
  2swap  *buffer +place
  *buffer count 2swap  r> w-search
 ;


\ ----------------------------------------------------------------------------
\ Findtext dialog
\ ----------------------------------------------------------------------------

NewEditDialog FindTextDlg "Find Text" "Search for:" "Find" "" "Case Sensitive Search"

create find-buf MAXSTRING allot
       find-buf off

0     value busy?           \ flag to prevent reentrancy
FALSE value find-label?     \ are we searching for a label?
0     value found_len       \ length of the string we found (new July 6th, 2003 - dbu)
0     value srch_len
0     value startcol

\ search for sa2,sn2 within string sa1,sn1.
\ (Allow ALT 0160 followed by a space as a pseudo leading space )
: (xsearch)     { sa1 sn1 sa2 sn2 \ pspf ldsp1 ldsp2 trsp2 n4 -- a3 n3 flg } \ search for sa2,sn2 within string sa1,sn1.
                \ case sensitive selectable
                \ sa1   target starting address
                \ sn1   target initial count
                \ sa2   search buffer starting address
                \ sn2   search buffer count
                \ pspf  pseudo-space flag
                \ ldsp1 count of leading spaces in target
                \ ldsp2 count of leading spaces in search buffer
                \ trsp2 count of trailing spaces in search buffer
                \ a3    starting address of possible matched string in target
                \ n3    remaining count in target
                \ n4    length of string matched, possibly excluding some leading or trailing spaces
                \ flg   is truth value of search
        sn2 to found_len \ save the length of the string we found
        0 to srch_len
        false to pspf
        0 to ldsp2
        0 to trsp2
        0 to n4
        sa1 sn1 bl skip drop
        sa1 - to ldsp1
        sa2 w@ 0x20A0 =                 \ a pseudo-space flag?
        IF      sa2 sn2 1 /string
                to sn2  to sa2
                sa2 sn2 bl skip drop
                sa2 - to ldsp2
                startcol 0=
                ldsp2 ldsp1 > and
                IF
                        true to pspf    \ only if we are at the line start
                THEN
        ELSE    sa2 sn2 bl skip drop
                sa2 - to ldsp2
        THEN
        sa2 sn2 -trailing
        sn2 over - to trsp2             \ count trailing spaces
        dup to sn2                      \ modify sn2 to exclude trailing spaces
        bl skip sn2 swap -
        to ldsp2 drop                   \ count leading spaces
        pspf                            \ possible pseudo space case
        IF      sa1 sa2 sn2
                ldsp2 ldsp1 - /string   \ advance search buffer pointer
                dup to n4 swap n4       \ ( sa1 n4 sa2 n4 )
                CaseSensitive? 0=
                IF      caps-compare
                ELSE    compare
                THEN
                0=      \ if result is 0, string is matched to start
                IF      \ of trailing spaces
                        sa1 sn1 2dup
                        n4 /string              \ look for trailing spaces
                        2dup bl skip dup 0=
                        IF      \ We have reached the end of the target buffer
                                2drop nip trsp2 min n4 + dup to srch_len
                                0<> EXIT
                        ELSE    \ We have NOT reached the end of the target
                                nip - nip trsp2 >=
                                IF      \ Enough trailing spaces
                                        trsp2 n4 + dup to srch_len 0<> EXIT
                                THEN
                        THEN
                THEN
                2drop \ clean up stack
        THEN
        sn2 to n4
        BEGIN
                CaseSensitive? 0= \ search
                IF      sa1 sn1 sa2 sn2 caps-search
                ELSE    sa1 sn1 sa2 sn2      search
                THEN
                IF      \ String is matched to start of trailing spaces
                        2dup n4 /string         \ look for trailing spaces
                        2dup bl skip dup 0=
                        IF      \ We have reached the end of the target buffer
                                2drop nip trsp2 min n4 + dup to srch_len
                                0<> EXIT
                        ELSE    \ We have NOT reached the end of the target
                                nip - nip trsp2 >=
                                IF      \ Enough trailing spaces
                                        trsp2 n4 + dup to srch_len 0<> EXIT
                                THEN
                        THEN
                        1 /string dup n4 <
                        IF      \ Not enough characters left for a match
                                0 to srch_len 0 EXIT
                        THEN
                        to sn1
                        dup sa1 - +to startcol
                        to sa1
                ELSE    \ No match possible
                        0 to srch_len 0 EXIT
                THEN
        AGAIN
;

\ Rewritten to allow wildcard text search ( July 6th, 2003 - dbu )
\ Changed to use Jos new Version of w_search.f ( July 8th, 2003 - 18:43 - dbu )
: xsearch  { sa1 sn1 sa2 sn2 \ buff$ -- a3 n3 flg }
           \ search for sa2,sn2 within string sa1,sn1.
           \ sa1   target starting address
           \ sn1   target initial count
           \ sa2   search buffer starting address
           \ sn2   search buffer count
           \ a3    starting address of possible matched string in target
           \ n3    remaining count in target

        sn1 1 < sn2 1 < or
        if      \ there is not text to search in or no text to search for
                sa1 sn1 false
        else
                sa2 sn2 wildcard-char scan nip sn2 1 > and
                if
                        \ there is a bug in w-search if the search string dosn't
                        \ start with a wildcard char no text will be found

\ J.v.d.Ven explaind to me that this isn't bug. So I removed the "bugfix"
\ July 28th, 2003 - 17:22 dbu
\                       sn2 2+ LocalAlloc: buff$
\                       sa2 c@ wildcard-char <>
\                       if      1 buff$ c! wildcard-char buff$ 1+ c! \ store wildcard char into the buffer
\                               sa2 sn2 buff$ +place \ and append the search string
\                       else
\                               sa2 sn2 buff$ place \ only put the search string into the buffer
\                       then
\                       buff$ count sa1 sn1 CaseSensitive? w-search 0= \ perform wildcard search
                        sa2 sn2 sa1 sn1 CaseSensitive? w-search 0= \ perform wildcard search

                        if      \ we didn't find the text
                                2drop sa1 sn1 false
                        else    \ we found it
                                to found_len \ save the length of the string we found
                                sa1 over - sn1 + \ calc the remaining count in target
                                true
                        then
                else    sa1 sn1 sa2 sn2 (xsearch) \ perform normal search
                then
        then
;

\ selectably case sensitive search backwards
\ rls mods January 6th, 2002 - 20:35
: -xsearch      { sadr slen fadr flen \ ffnd srch_lenz -- a3 n3 n4 }
                0 to ffnd
                sadr slen
                BEGIN   fadr flen xsearch
                WHILE   dup +to startcol
                        srch_len to srch_lenz
                        2dup to slen to sadr
                        1 /string
                        true to ffnd
                REPEAT
                srch_lenz to srch_len
                2drop sadr slen ffnd ;

0 value search-till

: .searching    ( n1 -- )
        dup 0=
        IF      0 to search-till
                FALSE to search-aborted?
        THEN
        search-till 4000 >=
        IF      search-till 4000 =
                IF      s" Searching:             \n\nPress ESC to abort"
                        "message
                THEN
                dup 1000 mod 0=
                IF      s" Searching:             \n\nPress ESC to abort" 2>r
                        0 (ud,.)
                        2r@ bl scan drop 1+ swap 11 min move
                        2r> MessageText: msg-window
                        Refresh: msg-window
                        key?
                        IF     key k_esc = to search-aborted?
                        THEN
                ELSE    drop
                THEN
        ELSE    drop
        THEN    1 +to search-till ;

\ Changed to allow wildcard text search ( July 6th, 2003 - dbu )

: to-find-line  ( col row -- ) \ set cursor position to the line with the text we found
                file-lines 1- min 0max
                to cursor-line
                to cursor-col
                0 HPosition: DocWindow
                \ cursor-on-screen   \ next line to center cursor line
                cursor-line screen-rows 2 / - VPosition: DocWindow
                cursor-col found_len + screen-cols 3 - - HPosition: DocWindow
                cursor-line dup to hlst to hled
                cursor-col to hcst
                hcst found_len + to hced ;

: find-label    { line# -- flag }       \ flag=TRUE if we found the label
        line# #line" s" <A NAME" dup>r xsearch
        IF      r> /string                    \ remove leading "<A NAME" string
                bl skip                       \ skip any leading blanks
                '=' skip                      \ skip equal sign
                bl skip                       \ skip any more leading blanks
                2dup '>' scan nip -           \ trim text after '>' in line
                                              \ retain trailing '"' (quote)
                     '"' skip                 \ strip off leading '"' (quote)
                drop find-buf count tuck
                caps-compare 0=
                IF      0 line# to-find-line  \ if found, move to this line
                        TRUE                  \ mark as all done searching
                ELSE    FALSE                 \ else we continue searching
                THEN
        ELSE    2drop
                r>drop
                FALSE
        THEN    ;

\ rls mods January 6th, 2002 - 21:14
\ Changed to allow wildcard text search ( July 6th, 2003 - dbu )
: _find-text-again      ( -- f1 )  \ f1=TRUE if found
        false busy? ?EXIT \ leave if already busy
        drop \ discard the boolean, we will generate another
        true to busy? \ now we are busy

        find-buf c@
        IF      \ put the search text into the ComboBox
                find-buf count InsertString: findComboEdit

                \ if we reached the end of file,
                \ jump to start beep and exit
                cursor-line file-lines 1- >=
                IF      Home: DocWindow
                        0 >col-cursor
                        FALSE to busy?
                        false beep EXIT
                THEN

                cursor-line 1-line-flag: DocWindow \ mark current line to be updated

                \ is the text on the current line?
                cursor-line #line" \ get address and length of current line
                dup cursor-col min to cursor-col \ don't jump behind the last char in line
                cursor-col /string \ jump to cursor position
                cursor-col to startcol \ make the actual cursor position to our start position
                find-buf count xsearch
                IF      cursor-line #line" rot - nip nip \ calculate column
                        cursor-line to-find-line \ set cursor position
                        hcst found_len + to hced \ set highlight
                        TRUE \ leave flag on stack
                ELSE    2drop

                        \ if we are on the last line of the file, we jump
                        \ to the first one
                        cursor-line file-lines 1- =
                        cursor-col  cursor-line #line" nip = and
                        IF      Home: DocWindow
                                0 to cursor-col
                        THEN

                        true \ put flag on stack
                        0 .searching \ open the search progress dialog

                        \ do the search over the rest of the file
                        file-lines
                        cursor-line file-lines 1- min 1+
                        ?DO     I .searching \ set search progress dialog
                                find-label?
                                IF      I find-label
                                        IF      0=      \ invert the flag on stack
                                                LEAVE
                                        THEN
                                ELSE    0 to startcol
                                        I #line" find-buf count xsearch
                                        IF      i #line" rot - nip nip \ calculate column
                                                i to-find-line \ set cursor position
                                                hcst found_len + to hced \ set highlight
                                                0= \ invert the flag on stack
                                                LEAVE \ and exit
                                        ELSE    2drop
                                        THEN
                                THEN
                                search-aborted? ?LEAVE
                        LOOP

                        IF      \ we didn't find the text
                                FALSE
                                Home: DocWindow
                                0 to cursor-col
                        ELSE    TRUE
                        THEN
                        message-off \ colse the search progress dialog
                THEN

                refresh-line
        ELSE    FALSE
        THEN

        ReTitle: EditorWindow
        FALSE to busy?
;

defer find-text ( -- )

: find-text-again ( -- )  \ bound to F3 in WinEd
        bitImage? ?EXIT
        find-buf c@ 0=
        IF      find-text
        ELSE    1 +to cursor-col       \ skip one character
                _find-text-again 0=
                IF      _find-text-again ?beep
                THEN
        THEN    SetFocus: DocWindow ;

\ rls mods January 6th, 2002 - 21:11
\ Changed to allow wildcard text search ( July 6th, 2003 - dbu )
: _back-find-text-again ( -- f1 )        \ f1=TRUE if found
        false busy? ?EXIT \ leave if already busy
        drop \ discard the boolean, we will generate another
        true to busy? \ now we are busy

        cursor-line 0=
        cursor-col  0= and
        IF      End: DocWindow
                cursor-line #line.len to cursor-col
        THEN

        cursor-line 1-line-flag: DocWindow

        0 to startcol
        cursor-line #line" cursor-col min
        find-buf count -xsearch
        IF      cursor-line #line"
                cursor-col min rot - nip nip to cursor-col
                0 HPosition: DocWindow
                cursor-line dup to hlst to hled
                cursor-col              to hcst
                hcst found_len +        to hced
                TRUE
        ELSE    2drop true
                0 .searching
                0 cursor-line 1- 0max
                ?DO     i .searching
                        0 to startcol
                        i #line" find-buf count -xsearch
                        IF      i #line" rot - nip nip
                                i to-find-line
                                hcst found_len + to hced
                                0= LEAVE
                        ELSE    2drop
                        THEN
                        search-aborted? ?LEAVE
                -1 +LOOP
                IF      End: DocWindow
                        cursor-line #line" nip to cursor-col
                        FALSE
                ELSE    TRUE
                THEN
                message-off
        THEN
        refresh-line
        ReTitle: EditorWindow
        FALSE to busy? ;

: back-find-text-again ( -- )
        bitImage? ?EXIT
        busy? ?EXIT                     \ leave if already busy
        find-buf c@ 0=
        IF      TRUE to busy?
                find-buf EditorWindow Start: FindTextDlg
                dup 2 = to CaseSensitive?
                FALSE to busy?
                find-buf c@ 0=
                IF      drop FALSE
                        beep
                THEN
        ELSE    true
        THEN    \ -- f1
        IF      _back-find-text-again 0=
                IF      _back-find-text-again ?beep
                THEN
        THEN
        SetFocus: DocWindow ; 
 
