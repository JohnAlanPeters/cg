\ $Id: fkernel.f,v 1.1 2011/03/19 23:26:09 rdack Exp $
\ WIN32FORTH KERNEL
\ Andrew McKewan
\ March 1994
\ Given to Tom Zimmer 05/13/94, assemblable with TASM32
\ Metacompiler version 11/95 Andrew McKewan

\ For history, see VERSION.F

DECIMAL

\        sp     equ     <esp>   \ Stack Pointer for Forth, the hardware stack
\        rp     equ     <ebp>   \ Return Pointer, Forth's subroutine stack
\        ip     equ     <esi>   \ Instruction Pointer for Forth
\        up     equ     <edx>   \ USER pointer
\        tos    equ     <ebx>   \ Top of stack is in EBX
\                       <edi>   \ CONSTANT ZERO

\ -------------------- Inner Interpreter ------------------------------------

((      SEE META.F AND FKERNEXT.F
MACRO EXEC      ( -- )                  \ execute RELATIVE cfa in eax
MACRO NEXT      ( -- )                  \ Inner interpreter
))


\ -------------------- Runtime Routines -------------------------------------

CFA-CODE DOCOL  ( -- )                  \ runtime for colon definitions
                mov     -4 [ebp], esi   \ rpush return addr
                lea     esi, 8 [eax]
                mov     eax, 4 [eax]
                sub     ebp, # 4
                exec    c;

CFA-CODE DODOES ( -- a1 )               \ runtime for DOES>
                push    ebx
                mov     -4 [ebp], esi   \ rpush esi
                mov     esi, ecx        \ new esi
                lea     ebx, 4 [eax]
                mov     eax, -4 [esi]
                sub     ebp, # 4
                exec    c;

CFA-CODE DOVAR  ( -- a1 )               \ runtime for CREATE and VARIABLE
                push    ebx
                lea     ebx, 4 [eax]
                next    c;

CFA-CODE DOUSER ( -- a1 )               \ runtime for USER variables
                push    ebx
                mov     ebx, 4 [eax]            \ get offset
                add     ebx, edx                \ add absolute user base
                next    c;

CFA-CODE DOCON  ( -- n1 )               \ runtime for constants
                push    ebx
                mov     ebx, 4 [eax]
                next    c;

CFA-CODE DODEFER ( -- )                 \ runtime for DEFER
                mov     eax, 4 [eax]
                exec    c;

CFA-CODE DOVALUE ( -- n1 )              \ runtime for VALUE fetch
                push    ebx
                mov     ebx, 4 [eax]
                next    c;

CFA-CODE DOVALUE! ( n1 -- )               \ runtime for VALUE store
                mov     -4 [eax], ebx
                pop     ebx
                next    c;

CFA-CODE DOVALUE+! ( n1 -- )               \ runtime for VALUE increment
                add     -8 [eax], ebx
                pop     ebx
                next    c;

CFA-CODE DO2VALUE ( d1 -- )               \ runtime for 2VALUE fetch
                push    ebx
                mov     ecx, 4 [eax]
                push    4 [ecx]
                mov     ebx, 0 [ecx]
                next    c;

CFA-CODE DOOFF     ( n -- )                \ run-time for OFFSET and FIELD+
                add     ebx, 4 [eax]
                next    c;

\ Define pointer constants for the basic Forth "runtime" routines.  A pointer
\ to one of these small assembly language routines is installed at the start
\ of every Forth definitions created.  They can actually be thought of as the
\ only form of Forth data "type"ing.  That is it is possible to look at the
\ contents of the CFA of any Forth definition, evaluate what is there, and
\ determine what type of definition it is.

ASSEMBLER DOCOL         META CONSTANT DOCOL
ASSEMBLER DOCON         META CONSTANT DOCON
ASSEMBLER DODOES        META CONSTANT DODOES
ASSEMBLER DOVAR         META CONSTANT DOVAR
ASSEMBLER DODEFER       META CONSTANT DODEFER
ASSEMBLER DO2VALUE      META CONSTANT DO2VALUE
ASSEMBLER DOVALUE       META CONSTANT DOVALUE
ASSEMBLER DOVALUE!      META CONSTANT DOVALUE!
ASSEMBLER DOVALUE+!     META CONSTANT DOVALUE+!
ASSEMBLER DOUSER        META CONSTANT DOUSER
ASSEMBLER DOOFF         META CONSTANT DOOFF


\ -------------------- Primitives -------------------------------------------

NCODE UNNEST    ( -- )          \ exit the current Forth definition
                mov     esi, 0 [ebp]
                add     ebp, # 4
                next    c;

NCODE LIT       ( -- n )        \ push the literal value following LIT in the
                                \ dictionary onto the data stack
                push    ebx
                mov     eax, 4 [esi]
                mov     ebx, 0 [esi]
                add     esi, # 8
                exec    c;

NCODE EXECUTE   ( cfa -- )       \ execute a Forth word, given its cfa
                mov     eax, ebx
                pop     ebx
                exec    c;

NCODE PERFORM   ( addr -- )      \ execute a Forth word whose cfa is stored at addr
                mov     eax, 0 [ebx]
                pop     ebx
                exec    c;

CODE NOOP       ( -- )          \ the Forth no-operation word (does nothing)
                next    c;

\ -------------------- Constants --------------------------------------------

-1  CONSTANT -1
 0  CONSTANT 0
 1  CONSTANT 1
 2  CONSTANT 2

 4  CONSTANT CELL
-4  CONSTANT -CELL
 32 CONSTANT BL
-1  CONSTANT TRUE
 0  CONSTANT FALSE
 0  CONSTANT NULL
CREATE PTRNULL NULL ,       \ pointer to a null

32       CONSTANT #VOCS     \ Maximum number of vocabularies in search order

260      EQU MAXBUFFER      \ Size of any string buffer, MUST match the
                            \ size of a windows maximum path string,
                            \ which is 260 bytes. ** DON'T CHANGE THIS **
MAXBUFFER CONSTANT MAX-HANDLE   \ maximum length of filename
MAXBUFFER CONSTANT MAXSTRING    \ maximum length of a counted string
MAXBUFFER CONSTANT MAX-PATH     \ maximum length of a filename buffer

255      EQU MAXCSTRING     \ max counted string
MAXCSTRING CONSTANT MAXCOUNTED  \ maximum length of contents of a counted string

\ -------------------- System WIde Constants --------------------------------

CREATE CRLF$ 2 C, 13 C, 10 C,   \ counted CRLF string

\ NEXT-SEQ returns the address of a counted string that is the code
\ compiled by NEXT. Used by the disassembler. Depends on META

CFA-CODE NEXT-SEQ
                tcode-here 0 tcode-c,                 \ length
                next    A;                     \ stop assembler
                tcode-here OVER - 1- SWAP tcode-c!     \ fix length
                C;
ASSEMBLER NEXT-SEQ META CONSTANT NEXT-SEQ      \ create constant

\ EXEC-SEQ returns the address of a counted string that is the code
\ compiled by EXEC. Used by the disassembler. Depends on META

CFA-CODE EXEC-SEQ
                tcode-here 0 tcode-c,                 \ length
                exec    A;                     \ stop assembler
                tcode-here OVER - 1- SWAP tcode-c!     \ fix length
                C;
ASSEMBLER EXEC-SEQ META CONSTANT EXEC-SEQ      \ create constant

\ -------------------- Call from Forth word ---------------------------------

NCODE RETURNF   ( -- )                         \ internal ITC word for return
                tcode-here cell+ tcode-,                \ make an ITC
                xchg    esp, ebp
                pop     esi
                ret     c;

CFA-CODE CALLF  ( -- )                         \ call forth from assembler
                push    esi
                xchg    esp, ebp
                mov     esi, # ' RETURNF       \ new esi is the return
                exec    c;                     \ jump to whatever is in eax

ASSEMBLER CALLF META CONSTANT CALLF            \ create constant

\ Also see FCALL, defined as
\        macro: fcall ( a macro to assemble a call to callf )
\               xchg    esp, ebp
\               mov     eax, # '                \ set eax to word
\               call    callf                   \ and call forth
\               xchg    esp, ebp
\        endm

\ -------------------- Branching & Looping ----------------------------------

NCODE BRANCH    ( -- )                    \ "runtime" for branch always
                br-next c;

NCODE ?BRANCH   ( f1 -- )                 \ "runtime" for branch on f1=FALSE
                test    ebx, ebx
                pop     ebx
                je      short @@1        \ yes, do branch
                mov     eax, 4 [esi]      \ optimised next
                add     esi, # 8
                exec
@@1:            br-next c;

NCODE -?BRANCH  ( f1 -- fl )             \ non-destructive "runtime" for branch on f1=FALSE
                test    ebx, ebx
                je      short @@1        \ yes, do branch
                mov     eax, 4 [esi]      \ optimised next
                add     esi, # 8
                exec
@@1:            br-next c;

NCODE _BEGIN    ( -- )          \ "runtime" marker for the decompiler, a noop
                next    c;

NCODE _THEN     ( -- )          \ "runtime" marker for the decompiler, a noop
                next    c;

NCODE _AGAIN    ( -- )          \ "runtime" branch back to after BEGIN
                br-next c;

NCODE _REPEAT   ( -- )          \ "runtime" branch back to after BEGIN
                br-next c;

NCODE _UNTIL    ( f1 -- )       \ "runtime" if f1=FALSE branch to after BEGIN
                test    ebx, ebx
                pop     ebx
                je      short @@1
                mov     eax, 4 [esi]
                add     esi, # 8
                exec
@@1:            br-next c;

NCODE _WHILE    ( f1 -- )       \ "runtime" if f1=FALSE branch to after REPEAT
                test    ebx, ebx
                pop     ebx
                je      short @@1
                mov     eax, 4 [esi]
                add     esi, # 8
                exec
@@1:            br-next c;

NCODE (DO)      ( n1 n2 -- )    \ "runtime" setup loop using n1,n2
                pop     ecx
LABEL pdo1      mov     eax, 0 [esi]
                add     ecx, # 0x80000000
                sub     ebx, ecx
                mov     -4 [ebp], eax
                mov     -8 [ebp], ecx
                mov     -12 [ebp], ebx
                sub     ebp, # 12
                pop     ebx
                mov     eax, 4 [esi]
                add     esi, # 8
                exec    c;

NCODE (?DO)     ( n1 n2 -- )    \ "runtime" setup loop using n1,n2, if n1=n2
                                \ then discard n1,n2 and branch to after DO
                pop     ecx
                cmp     ecx, ebx
                jne     short pdo1
                pop     ebx
@@1:            br-next c;

CODE I          ( -- n1 )       \ push n1, the value of the current loop index
                push    ebx
                mov     ebx, 0 CELLS [ebp]
                add     ebx, 1 CELLS [ebp]
                next    c;

CODE J          ( -- n1 )       \ push n1, the value of the outer loop index
                push    ebx
                mov     ebx, 3 CELLS [ebp]
                add     ebx, 4 CELLS [ebp]
                next    c;

CODE K          ( -- n1 )       \ push n1, value of the second outer loop index
                push    ebx
                mov     ebx, 6 CELLS [ebp]
                add     ebx, 7 CELLS [ebp]
                next    c;

NCODE LEAVE     ( -- )          \ unconditionnaly exit the current DO LOOP
                mov     esi, 2 CELLS [ebp]
                add     ebp, # 3 CELLS
                mov     eax, -4 [esi]
                exec    c;

NCODE ?LEAVE    ( f1 -- )       \ exit the current DO LOOP if f1=TRUE
                test    ebx, ebx
                pop     ebx
                jne     short @@1
                next
@@1:            mov     esi, 2 CELLS [ebp]
                add     ebp, # 3 CELLS
                mov     eax, -4 [esi]
                exec    c;

NCODE (LOOP)    ( -- )          \ "runtime" bump count and branch to after
                                \ DO if loop count not complete
                add     dword ptr 0 [ebp], # 1
                jo      short @@1
                br-next
@@1:            mov     eax, 4 [esi]
                add     esi, # 8
                add     ebp, # 12
                exec    c;

NCODE (+LOOP)   ( n1 -- )       \ "runtime" bump count by n1 and branch to
                                \ after DO if loop count not complete
                add     0 [ebp], ebx
                pop     ebx
                jo      short @@1
                br-next
@@1:            mov     eax, 4 [esi]
                add     esi, # 8
                add     ebp, # 12
                exec    c;

NCODE UNLOOP    ( -- )          \ discard LOOP parameters from return stack
                add     ebp, # 12
                next    c;

CODE BOUNDS     ( adr len -- lim first ) \ calculate loop bounds from adr,len
                mov     eax, 0 [esp]
                add     0 [esp], ebx
                mov     ebx, eax
                next    c;

NCODE _CASE     ( -- )          \ "runtime" marker for the decompiler, a noop
                next    c;

NCODE _OF       ( n1 n2 -- [n1] ) \ "runtime"
                                  \ if n1<>n2 branch to after ENDOF, return n1
                                  \ else continue and don't return n1
                pop     eax
                cmp     ebx, eax
                jne     short @@1
                mov     eax, 4 [esi]
                pop     ebx
                add     esi, # 8
                exec
@@1:            mov     ebx, eax
                br-next c;

NCODE _ENDOF    ( -- )          \ "runtime" branch to after ENDCASE
                br-next c;

NCODE _ENDCASE  ( n1 -- )       \ "runtime" discard n1 and continue
                pop     ebx
                next    c;


\ -------------------- Stack Operators --------------------------------------

CODE DROP       ( n -- )        \ discard top entry on data stack
                pop     ebx
                next    c;

CODE DUP        ( n -- n n )    \ duplicate top entry on data stack
                push    ebx
                next    c;

CODE SWAP       ( n1 n2 -- n2 n1 ) \ exchange first and second items on data stack
                mov     eax, 0 [esp]
                mov     0 [esp], ebx
                mov     ebx, eax
                next    c;

CODE OVER       ( n1 n2 -- n1 n2 n1 ) \ copy second item to top of data stack
                push    ebx
                mov     ebx, 4 [esp]
                next    c;

CODE ROT        ( n1 n2 n3 -- n2 n3 n1 ) \ rotate third item to top of data stack
                mov     ecx, 0 [esp]
                mov     eax, 4 [esp]
                mov     0 [esp], ebx
                mov     4 [esp], ecx
                mov     ebx, eax
                next    c;

CODE -ROT       ( n1 n2 n3 -- n3 n1 n2 ) \ rotate top of data stack to third item
                mov     ecx, 4 [esp]
                mov     eax, 0 [esp]
                mov     4 [esp], ebx
                mov     0 [esp], ecx
                mov     ebx, eax
                next    c;

CODE ?DUP       ( n -- n [n] )  \ duplicate top of data stack if non-zero
                test    ebx, ebx
                je      short @@1
                push    ebx
@@1:            next    c;

CODE NIP        ( n1 n2 -- n2 ) \ discard second item on data stack
                add     esp, # 4
                next    c;

CODE TUCK       ( n1 n2 -- n2 n1 n2 ) \ copy top data stack to under second item
                push    0 [esp]
                mov     4 [esp], ebx
                next    c;

CODE PICK       ( ...  k -- ... n[k] )
                mov     ebx, 0 [esp] [ebx*4]      \ just like that!
                next    c;

CODE S-REVERSE ( n[k]..2 1 0 k -- 0 1 2..n[k] ) \ w32f
\ *G Reverse n items on stack   \n
\ ** Usage: 1 2 3 4 5 5 S_REVERSE ==> 5 4 3 2 1
                lea     ecx, -4 [esp]     \ ecx points 4 under top of stack
                lea     ebx, 4 [ecx] [ebx*4] \ ebx points 4 over stack
\ bump pointers, if they overlap, stop
@@1:            sub     ebx, # 4          \ adjust top
                add     ecx, # 4          \ adjust bottom
                cmp     ecx, ebx          \ compare
                jae     short @@2         \ ecx passing ebx, so exit
\ rotate a pair
\ xor a,b xor b,a xor a,b swaps a and b
                mov     eax, 0 [ebx]      \ bottom to eax
                xor     0 [ecx], eax      \ exchange top and eax
                xor     eax,  0 [ecx]
                xor     0 [ecx], eax
                mov     0 [ebx], eax      \ eax to bottom
                jmp     short @@1         \ next pair
@@2:            pop     ebx               \ tos
                next    c;

CODE 3REVERSE   ( n1 n2 n3 -- n3 n2 n1 ) \ exchange first and third items on data stack
                mov     ecx, 4 [esp]
                mov     4 [esp], ebx
                mov     ebx, ecx
                next    c;

CODE 4REVERSE   ( n1 n2 n3 n4 -- n4 n3 n2 n1 ) \ exchange first and fourth plus second and
                                               \ third items on the data stack
                mov     ecx, 8 [esp]
                mov     8 [esp], ebx
                mov     ebx, ecx
                mov     eax, 0 [esp]
                mov     ecx, 4 [esp]
                mov     4 [esp], eax
                mov     0 [esp], ecx
                next    c;

\ -------------------- Stack Operations -------------------------------------

CODE SP@        ( -- addr ) \ get addr, the pointer to the top item on data stack
                push    ebx
                mov     ebx, esp
                next    c;

CODE SP!        ( addr -- )     \ set the data stack to point to addr
                mov     esp, ebx
                pop     ebx
                next    c;

CODE RP@        ( -- a1 )       \ get a1 the address of the return stack
                push    ebx
                mov     ebx, ebp
                next    c;

CODE RP!        ( a1 -- )       \ set the address of the return stack
                mov     ebp, ebx
                pop     ebx
                next    c;

CODE >R         ( n1 -- ) ( R: -- n1 )   \ push n1 onto the return stack
                mov     -4 [ebp], ebx
                sub     ebp, # 4
                pop     ebx
                next    c;

CODE R>         ( -- n1 ) ( R: n1 -- )   \ pop n1 off the return stack
                push    ebx
                mov     ebx, 0 [ebp]
                add     ebp, # 4
                next    c;

CODE R@         ( -- n1 ) ( R: n1 -- n1 )  \ get a copy of the top of the return stack
                push    ebx
                mov     ebx, 0 [ebp]
                next    c;

CODE DUP>R      ( n1 -- n1 ) ( R: -- n1 )   \ push a copy of n1 onto the return stack
                mov     -4 [ebp], ebx
                sub     ebp, # 4
                next    c;

CODE R>DROP     ( -- ) ( R: n1 -- )  \ discard one item off of the return stack
                add     ebp, # 4
                next    c;

\ ' r>drop alias rdrop        \ made a code def - [cdo-2008May13]
CODE RDROP      ( -- ) ( R: n1 -- )  \ discard one item off of the return stack
                add     ebp, # 4
                next    c;

CODE 2>R        ( n1 n2 -- ) ( R: -- n1 n2 ) \ push two items onto the returnstack
                mov     -2 CELLS [ebp], ebx
                pop     -1 CELLS [ebp]
                sub     ebp, # 8
                pop     ebx
                next    c;

CODE 2R>        ( -- n1 n2 ) ( R: n1 n2 -- ) \ pop two items off the return stack
                push    ebx
                mov     ebx, 0 CELLS [ebp]
                push    1 CELLS [ebp]
                add     ebp, # 8
                next    c;

CODE 2R@        ( -- n1 n2 )    \ get a copy of the top two items on the return stack
                push    ebx
                mov     ebx, 0 CELLS [ebp]
                push    1 CELLS [ebp]
                next    c;


\ -------------------- Memory Operators -------------------------------------

CODE @          ( a1 -- n1 )    \ get the cell n1 from address a1
                mov     ebx, 0 [ebx]
                next    c;

CODE !          ( n1 a1 -- )    \ store cell n1 into address a1
                pop     [ebx]
                pop     ebx
                next    c;

CODE +!         ( n1 a1 -- )    \ add cell n1 to the contents of address a1
                pop     eax
                add     0 [ebx], eax
                pop     ebx
                next    c;

CODE C@         ( a1 -- c1 )    \ fetch the character c1 from address a1
                movzx   ebx, byte ptr 0 [ebx]
                next    c;

CODE C!         ( c1 a1 -- )    \ store character c1 into address a1
                pop     eax
                mov     0 [ebx], al
                pop     ebx
                next    c;

CODE C+!        ( c1 a1 -- )    \ add character c1 to the contents of address a1
                pop     eax
                add     0 [ebx], al
                pop     ebx
                next    c;

CODE W@         ( a1 -- w1 )    \ fetch the word (16bit) w1 from address a1
                movzx   ebx, word ptr 0 [ebx]
                next    c;

CODE SW@        ( a1 -- w1 )    \ fetch and sign extend the word (16bit) w1 from address a1
                movsx   ebx, word ptr 0 [ebx]
                next    c;

CODE W!         ( w1 a1 -- )    \ store word (16bit) w1 into address a1
                pop     eax
                mov     0 [ebx], ax
                pop     ebx
                next    c;

CODE W+!        ( w1 a1 -- )    \ add word (16bit) w1 to the contents of address a1
                pop     eax
                add     0 [ebx], ax
                pop     ebx
                next    c;


\ -------------------- Cell Operators ---------------------------------------

CODE CELLS      ( n1 -- n1*cell )       \ multiply n1 by the cell size
                shl     ebx, # 2
                next    c;

CODE CELLS+     ( a1 n1 -- a1+n1*cell ) \ multiply n1 by the cell size and add
                                        \ the result to address a1
                pop     eax
                lea     ebx, 0 [ebx*4] [eax]
                next    c;

CODE CELLS-     ( a1 n1 -- a1-n1*cell ) \ multiply n1 by the cell size and subtract
                                        \ the result from address a1
                lea     eax, 0 [ebx*4]
                pop     ebx
                sub     ebx, eax
                next    c;

CODE CELL+      ( a1 -- a1+cell )       \ add a cell to a1
                add     ebx, # 4
                next    c;

CODE CELL-      ( a1 -- a1-cell )       \ subtract a cell from a1
                sub     ebx, # 4
                next    c;

CODE +CELLS     ( n1 a1 -- n1*cell+a1 ) \ multiply n1 by the cell size and add
                                        \ the result to address a1
                pop     eax
                lea     ebx, 0 [eax*4] [ebx]
                next    c;

CODE -CELLS     ( n1 a1 -- a1-n1*cell ) \ multiply n1 by the cell size and
                                        \ subtract the result from address a1
                pop     eax
                shl     eax, # 2
                sub     ebx, eax
                next    c;


\ -------------------- Char Operators ---------------------------------------

CODE CHARS      ( n1 -- n1*char )       \ multiply n1 by the character size (1)
                next    c;

CODE CHAR+      ( a1 -- a1+char )       \ add the characters size in bytes to a1
                add     ebx, # 1
                next    c;

\ -------------------- Block Memory Operators -------------------------------

NCODE CMOVE     (  from to count -- )   \ move "count" bytes from address "from" to
                \ address "to" - start with the first byte of "from"
                mov     ecx, ebx
                mov     eax, esi
                pop     edi
                pop     esi
                repnz   movsb
                mov     esi, eax
                xor     edi, edi
                pop     ebx
                next    c;

NCODE CMOVE>    ( from to count -- )    \ move "count" bytes from address "from" to
                \ address "to" - start with the last byte of "from"
                mov     ecx, ebx
                mov     eax, esi
                pop     edi
                pop     esi
                add     edi, ecx        \ CMOVE> case (dull)
                add     esi, ecx
                dec     edi
                dec     esi
                std
                repnz   movsb
                cld
                mov     esi, eax
                xor     edi, edi
                pop     ebx
                next    c;

NCODE MOVE      ( source dest len -- )  \ move len bytes from source address to dest address
                mov     ecx, ebx
                mov     eax, esi
                pop     edi
                pop     esi
                mov     ebx, edi        \ check for overlap
                sub     ebx, esi
                cmp     ebx, ecx
                jb      short @@1
                mov     ebx, ecx        \ CMOVE case (optimized)
                shr     ecx, # 2
                rep     movsd
                mov     ecx, ebx
                and     ecx, # 3
                rep     movsb
                jmp     short @@2
@@1:            add     edi, ecx        \ CMOVE> case (dull)
                add     esi, ecx
                dec     edi
                dec     esi
                std
                rep     movsb
                cld
@@2:            mov     esi, eax
                xor     edi, edi
                pop     ebx
                next    c;


NCODE FILL      ( addr len char -- )    \ fill addr with char for len bytes
                mov     bh, bl          \ bh & bl = char
                shl     ebx, # 16
                mov     eax, ebx
                shr     eax, # 16
                or      eax, ebx
LABEL FILLJ     mov     ebx, edi        \ ebx = base
                pop     ecx             \ ecx = len
                pop     edi             \ edi = addr
                push    ecx             \ optimize
                shr     ecx, # 2
                rep     stosd
                pop     ecx
                and     ecx, # 3
                rep     stosb
                mov     edi, ebx        \ restore
                pop     ebx
                next    c;

NCODE ERASE     ( addr u -- )           \ ANSI        Core Ext
\ *G If u is greater than zero, clear all bits in each of u consecutive address
\ ** units of memory beginning at addr .
                push    ebx
                xor     eax, eax
                jmp     short fillj
                c;

NCODE BLANK     ( c-addr u -- )         \ ANSI         String
\ *G If u is greater than zero, store the character value for space in u consecutive
\ ** character positions beginning at c-addr.

                push    ebx
                mov     eax, # 0x20202020 \ all blanks
                jmp     short fillj
                c;


\ -------------------- Logical Operators ------------------------------------

CODE AND        ( n1 n2 -- n3 ) \ perform bitwise AND of n1,n2, return result n3
                pop     ecx
                and     ebx, ecx
                next    c;

CODE OR         ( n1 n2 -- n3 ) \ perform bitwise OR of n1,n2, return result n3
                pop     ecx
                or      ebx, ecx
                next    c;

CODE XOR        ( n1 n2 -- n3 ) \ perform bitwise XOR of n1,n2, return result n3
                pop     ecx
                xor     ebx, ecx
                next    c;

CODE INVERT     ( n1 -- n2 )    \ perform a bitwise -1 XOR on n1, return result n2
                not     ebx
                next    c;

CODE LSHIFT     ( u1 n -- u2 )  \ shift u1 left by n bits (multiply)
                mov     ecx, ebx
                pop     ebx
                shl     ebx, cl
                next    c;

CODE RSHIFT     ( u1 n -- u2 )  \ shift u1 right by n bits (divide)
                mov     ecx, ebx
                pop     ebx
                shr     ebx, cl
                next    c;

CODE INCR       ( addr -- )     \ increment the contents of addr
                add     dword ptr 0 [ebx], # 1
                pop     ebx
                next    c;

CODE DECR       ( addr -- )     \ decrement the contents of addr
                sub     dword ptr 0 [ebx], # 1
                pop     ebx
                next    c;

CODE CINCR      ( addr -- )     \ increment the BYTE contents of addr
                add     byte 0 [ebx], # 1
                pop     ebx
                next    c;

CODE CDECR      ( addr -- )     \ decrement the BYTE contents of addr
                sub     byte 0 [ebx], # 1
                pop     ebx
                next    c;

CODE ON         ( addr -- )     \ set the contents of addr to ON (-1)
                mov     dword ptr 0 [ebx], # -1
                pop     ebx
                next    c;

CODE OFF        ( addr -- )     \ set the contents of addr of OFF (0)
                mov     dword ptr 0 [ebx], # 0
                pop     ebx
                next    c;

CODE TOGGLE     ( addr byte -- ) \ XOR the byte contents of "addr" with "byte"
                pop     eax
                xor     0 [eax], bl
                pop     ebx
                next    c;

CODE BIT-POP    ( n -- bits-in-n )                  \ population count of bits in ebx
                mov     eax, ebx
                shr     eax, # 1
                and     eax, # 0x055555555          \ (n >> 1) & 0x55555555
                sub     ebx, eax                    \ n - ((n >> 1) & 0x55555555)
                mov     eax, ebx
                shr     eax, # 2                    \ n >> 2
                and     ebx, # 0x033333333          \ n & 0x33333333
                and     eax, # 0x033333333          \ (n >> 2)  & 0x33333333
                add     ebx, eax                    \ n = (n & 0x33333333) + ((n >> 2) & 0x33333333)
                mov     eax, ebx
                shr     eax, # 4                    \ n >> 4
                add     eax, ebx                    \ n + (n >> 4)
                and     eax, # 0x00F0F0F0F          \ n = (n + (n >> 4) & 0x0F0F0F0F)
                mov     ebx, eax
                shr     ebx, # 8                    \ n >> 8
                add     eax, ebx                    \ n = n + (n >> 8)
                mov     ebx, eax
                shr     ebx, # 16                   \ n >> 16
                add     eax, ebx                    \ n = n + (n >> 16)
                and     eax, # 0x00000003F          \ popcount
                mov     ebx, eax
                next    c;

CODE BIT-MSB    ( n -- msb )                        \ most significant bit in n
                or      ebx, ebx                    \ if zero
                jz      short @@1                   \ no, do bit scan
                bsr     ebx, ebx
                add     ebx, # 1
@@1:            next    c;


\ -------------------- Arithmetic Operators ---------------------------------

CODE +          ( n1 n2 -- n3 ) \ add n1 to n2, return sum n3
                pop     eax
                add     ebx, eax
                next    c;

CODE -          ( n1 n2 -- n3 ) \ subtract n2 from n1, return difference n3
                pop     eax
                sub     eax, ebx
                mov     ebx, eax
                next    c;

CODE UNDER+     ( a x b -- a+b x ) \ add top of stack to third stack item
                add     4 [esp], ebx
                pop     ebx
                next    c;

CODE NEGATE     ( n1 -- n2 ) \ negate n1, returning 2's complement n2
                neg     ebx
                next    c;

CODE ABS        ( n -- |n| ) \ return the absolute value of n1 as n2
                mov     ecx, ebx      \ save value
                sar     ecx, 31       \ x < 0 ? 0xffffffff : 0
                xor     ebx, ecx      \ x < 0 ? ~x : x
                sub     ebx, ecx      \ x < 0 ? (~x)+1 : x
                next    c;

CODE 2*         ( n1 -- n2 ) \ multiply n1 by two
                add     ebx, ebx
                next    c;

CODE 2/         ( n1 -- n2 ) \ signed divide n1 by two
                sar     ebx, # 1
                next    c;

CODE U2/        ( n1 -- n2 ) \ unsigned divide n1 by two
                shr     ebx, # 1
                next    c;

CODE 1+         ( n1 -- n2 ) \ add one to n1
                add     ebx, # 1
                next    c;

CODE 1-         ( n1 -- n2 ) \ subtract one from n1
                sub     ebx, # 1
                next    c;

CODE D2*        ( d1 -- d2 ) \ multiply the double number d1 by two
                pop     eax
                shl     eax, # 1
                rcl     ebx, # 1
                push    eax
                next    c;

CODE D2/        ( d1 -- d2 ) \ divide the double number d1 by two
                pop     eax
                sar     ebx, # 1
                rcr     eax, # 1
                push    eax
                next    c;


\ -------------------- Unsigned Multiply & Divide ---------------------------

CODE UM*        ( u1 u2 -- ud1 ) \ multiply unsigned u1 by unsigned u2
                mov     ecx, edx        \ save UP
                pop     eax
                mul     ebx
                push    eax
                mov     ebx, edx
                mov     edx, ecx        \ restore UP
                next    c;

CODE UM/MOD     ( ud1 u1 -- rem quot ) \ divide unsigned double ud1 by the
                                       \ unsigned number u1
                mov     ecx, edx        \ save UP
                pop     edx
                pop     eax
                div     ebx
                push    edx
                mov     ebx, eax
                mov     edx, ecx        \ restore UP
                next    c;

CODE WORD-SPLIT ( u1 -- low high ) \ split the unsigned 32bit u1 into its high
                                   \ and low 16bit quantities.
                xor     eax, eax
                mov     ax, bx
                push    eax
                shr     ebx, # 16
                next    c;

CODE WORD-JOIN  ( low high -- n1 ) \ join the high and low 16bit quantities
                                   \ into a single 32bit n1
                shl     ebx, # 16
                pop     eax
                mov     bx, ax
                next    c;


\ -------------------- Comparison Operators ---------------------------------

CODE 0=         ( n1 -- f1 )    \ return true if n1 equals zero
                sub     ebx, # 1
                sbb     ebx, ebx
                next    c;

CODE 0<>        ( n1 -- f1 )    \ return true if n1 is not equal to zero
                sub     ebx, # 1
                sbb     ebx, ebx
                not     ebx
                next    c;

CODE 0<         ( n1 -- f1 )    \ return true if n1 is less than zero
                sar     ebx, # 31
                next    c;

CODE 0>         ( n1 -- f1 )    \ return true if n1 is greater than zero
                dec     ebx
                cmp     ebx, # 0x7fffffff
                sbb     ebx, ebx
                next    c;

CODE =          ( n1 n2 -- f1 ) \ return true if n1 is equal to n2
                pop     eax
                sub     ebx, eax
                sub     ebx, # 1
                sbb     ebx, ebx
                next    c;

CODE <>         ( n1 n2 -- f1 ) \ return true if n1 is not equal to n2
                pop     eax
                sub     eax, ebx
                neg     eax
                sbb     ebx, ebx
                next    c;

CODE <          ( n1 n2 -- f1 ) \ return true if n1 is less than n2
                pop     eax
                cmp     eax, ebx
                jl      short @@1
                xor     ebx, ebx
                next
@@1:            mov     ebx, # -1
                next    c;

CODE >          ( n1 n2 -- f1 ) \ return true if n1 is greater than n2
                pop     eax
                cmp     eax, ebx
                jg      short @@1
                xor     ebx, ebx
                next
@@1:            mov     ebx, # -1
                next    c;

CODE <=         ( n1 n2 -- f1 ) \ return true if n1 is less than n2
                pop     eax
                cmp     eax, ebx
                jle     short @@1
                xor     ebx, ebx
                next
@@1:            mov     ebx, # -1
                next    c;

CODE >=         ( n1 n2 -- f1 ) \ return true if n1 is greater than n2
                pop     eax
                cmp     eax, ebx
                jge     short @@1
                xor     ebx, ebx
                next
@@1:            mov     ebx, # -1
                next    c;

CODE U<         ( u1 u2 -- f1 ) \ return true if unsigned u1 is less than
                                \ unsigned u2
                pop     eax
                cmp     eax, ebx
                sbb     ebx, ebx
                next    c;

CODE U>         ( u1 u2 -- f1 ) \ return true if unsigned u1 is greater than
                                \ unsigned n2
                pop     eax
                cmp     ebx, eax
                sbb     ebx, ebx
                next    c;

CODE DU<        ( ud1 ud2 -- f1 ) \ return true if unsigned double ud1 is
                                  \ less than unsigned double ud2
                pop     eax
                pop     ecx
                xchg    edx, 0 [esp]    \ save UP
                sub     edx, eax
                sbb     ecx, ebx
                sbb     ebx, ebx
                pop     edx             \ restore UP
                next    c;

CODE UMIN       ( u1 u2 -- n3 ) \ return the lesser of unsigned u1 and
                                \ unsigned u2
                pop     eax
                cmp     ebx, eax
                jb      short @@1
                mov     ebx, eax
@@1:            next    c;

CODE MIN        ( n1 n2 -- n3 ) \ return the lesser of n1 and n2
                pop     eax
                cmp     ebx, eax
                jl      short @@1
                mov     ebx, eax
@@1:            next    c;

CODE UMAX       ( u1 u2 -- n3 ) \ return the greater of unsigned u1 and
                                \ unsigned u2
                pop     eax
                cmp     ebx, eax
                ja      short @@1
                mov     ebx, eax
@@1:            next    c;

CODE MAX        ( n1 n2 -- n3 ) \ return the greater of n1 and n2
                pop     eax
                cmp     ebx, eax
                jg      short @@1
                mov     ebx, eax
@@1:            next    c;

CODE 0MAX       ( n1 -- n2 ) \ return n2 the greater of n1 and zero
                cmp     ebx, # 0
                jg      short @@1
                xor     ebx, ebx
@@1:            next    c;

CODE WITHIN     ( n1 low high -- f1 ) \ f1=true if ( (n1 >= low) and (n1 < high) )
                pop     eax
                pop     ecx
                sub     ebx, eax
                sub     ecx, eax
                sub     ecx, ebx
                sbb     ebx, ebx
                next    c;

CODE BETWEEN    ( n1 low high -- f1 ) \ f1=true if ( (n1 >= low) and (n1 <= high) )
                add     ebx, # 1      \ bump high
                pop     eax
                pop     ecx
                sub     ebx, eax
                sub     ecx, eax
                sub     ecx, ebx
                sbb     ebx, ebx
                next    c;


\ -------------------- Double memory Operators ------------------------------

CODE 2@         ( a1 -- d1 ) \ fetch the double number d1 from address a1
                push    4 [ebx]
                mov     ebx, 0 [ebx]
                next    c;

CODE 2!         ( d1 a1 -- ) \ store the double number d1 into address a1
                pop     0 [ebx]
                pop     4 [ebx]
                pop     ebx
                next    c;


\ -------------------- Double Stack Operators -------------------------------

CODE 2DROP      ( n1 n2 -- ) \ discard two single items - one double - from the data stack
                add     esp, # 4
                pop     ebx
                next    c;

CODE 2NIP       ( n1 n2 n3 n4 -- n3 n4 ) \ discard third and fourth items from data stack
                pop     eax
                mov     4 [esp], eax
                pop     eax
                next    c;

CODE 2DUP       ( n1 n2 -- n1 n2 n1 n2 ) \ duplicate the top two single items
                                         \ on the data stack
                push    ebx
                push    4 [esp]
                next    c;

CODE 2SWAP      ( n1 n2 n3 n4 -- n3 n4 n1 n2 ) \ exchange the two topmost doubles
                mov     eax, 4 [esp]      \ eax=n2
                mov     ecx, 8 [esp]      \ ecx=n1
                mov     4 [esp], ebx      \ n1 n4 n3 eax=n2 ecx=n1 ebx=n4
                mov     ebx, 0 [esp]      \ ebx=3
                mov     0 [esp], ecx      \ n3 n4 n1
                mov     8 [esp], ebx      \ n3 n4 n3
                mov     ebx, eax          \ n3 n4 n1 n2
                next    c;

CODE 2OVER      ( n1 n2 n3 n4 -- n1 n2 n3 n4 n1 n2 ) \ copy second double on top
                mov     eax, 8 [esp]
                push    ebx
                push    eax
                mov     ebx, 12 [esp]
                next    c;

CODE 2ROT       ( n1 n2 n3 n4 n5 n6 -- n3 n4 n5 n6 n1 n2 )   \ rotate 3 double
                pop     eax
                xchg    ebx, 0 [esp]
                xchg    eax, 4 [esp]
                xchg    ebx, 8 [esp]
                xchg    eax, 12 [esp]
                push    eax
                next    c;

CODE 3DROP      ( n1 n2 n3 -- ) \ discard three items from the data stack
                add     esp, # 8
                pop     ebx
                next    c;

CODE 4DROP      ( n1 n2 n3 n4 -- ) \ discard four items from the data stack
                add     esp, # 12
                pop     ebx
                next    c;

CODE 3DUP       ( n1 n2 n3 -- n1 n2 n3 n1 n2 n3 ) \ duplicate 3 topmost cells
                mov     eax, 0 [esp]      \ n2
                mov     ecx, 4 [esp]      \ n1
                push    ebx               \ n3
                push    ecx               \ n1
                push    eax               \ n2
                next    c;

CODE 4DUP       ( a b c d -- a b c d a b c d ) \ duplicate 4 topmost cells
                mov     eax, 8 [esp]
                push    ebx
                push    eax
                mov     ebx, 12 [esp]
                mov     eax, 8 [esp]
                push    ebx
                push    eax
                mov     ebx, 12 [esp]
                next    c;


\ -------------------- Signed Multiply & Divide -----------------------------

CODE M*         ( n1 n2 -- d1 ) \ multiply n1 by n2, return double result d1
                mov     ecx, edx        \ save UP
                pop     eax
                imul    ebx
                push    eax
                mov     ebx, edx
                mov     edx, ecx        \ restore UP
                next    c;

CODE *          ( n1 n2 -- n3 ) \ multiply n1 by n2, return single result n3
                mov     ecx, edx        \ save UP
                pop     eax
                mul     ebx
                mov     ebx, eax
                mov     edx, ecx        \ restore UP
                next    c;

CODE SM/REM     ( d n -- rem quot )
                mov     ecx, edx        \ save UP
                pop     edx
                pop     eax
                idiv    ebx
                push    edx
                mov     ebx, eax
                mov     edx, ecx        \ restore UP
                next    c;

CODE FM/MOD     ( d n -- rem quot )
                pop     ecx             \ high numerator
                mov     eax, ecx        \ copy for testing
                xor     eax, ebx        \ test against denominator
                jns     short @@1       \ if signs differ jump

                xchg    ecx, edx        \ save UP
                pop     eax
                idiv    ebx
                test    edx, edx        \ set zero flag
                je      short @@2
                add     edx, ebx        \ add divisor to remainder
                sub     eax, # 1             \ decrement quotient
                jmp     short @@2

@@1:            xchg    ecx, edx        \ preserve DX in CX, DX=high num
                pop     eax             \ EAX=low numerator
                idiv    ebx             \ perform the division

@@2:            push    edx             \ push remainder
                mov     ebx, eax        \ quotient to EBX
                mov     edx, ecx        \ restore UP
                next    c;

CODE /MOD       ( n1 n2 -- rem quot ) \ integer signed single divide with remainder & quotient
                pop     ecx
                mov     eax, ecx
                xor     eax, ebx
                jns     short @@1

                mov     eax, ecx        \ low order part to eax
                mov     ecx, edx        \ save UP
                cdq
                idiv    ebx
                test    edx, edx        \ set zero flag
                je      short @@2

                add     edx, ebx        \ add divisor to remainder
                sub     eax, # 1             \ decrement quotient
                jmp     short @@2

@@1:            mov     eax, ecx        \ low order part to eax
                mov     ecx, edx
                cdq
                idiv    ebx
@@2:            push    edx
                mov     ebx, eax
                mov     edx, ecx        \ restore UP
                next    c;

: /             ( n1 n2 -- quot ) \ integer single divide : quotient
                /MOD NIP ;

: MOD           ( n1 n2 -- rem ) \ integer single divide : remainder
                /MOD DROP ;

CODE */MOD      ( n1 n2 n3 -- remainder quotient ) \ integer single multiply and divide:
                \ give remainder and quotient of [n1*n2]/n3. Intermediate result n1*n2
                \ is a double, so there is no overflow.
                pop     ecx
                pop     eax
                push    edx             \ save UP
                imul    ecx
                mov     ecx, edx
                xor     ecx, ebx
                jns     short @@1

                idiv    ebx
                test    edx, edx        \ set zero flag
                je      short @@2
                add     edx, ebx        \ add divisor to remainder
                sub     eax, # 1             \ decrement quotient
                jmp     short @@2

@@1:            idiv    ebx
@@2:            mov     ebx, eax
                pop     ecx
                push    edx
                mov     edx, ecx        \ restore UP
                next    c;

: */            ( n1 n2 n3 -- quotient ) \ same as */MOD but gives only quotient
                */MOD NIP ;

\ ------------------------ String counting -----------------------

CODE COUNT      ( str -- addr len ) \ byte counted strings
                add     ebx, # 1
                push    ebx
                movzx   ebx, byte ptr -1 [ebx]
                next    c;

CODE WCOUNT     ( str -- addr len )  \ word (2 bytes) counted strings
                add     ebx, # 2
                push    ebx
                movzx   ebx, word ptr -2 [ebx]
                next    c;

CODE LCOUNT     ( str -- addr len )  \ long (4 bytes) counted strings
                add     ebx, # 4
                push    ebx
                mov     ebx, -4 [ebx]
                next    c;

CODE ZCOUNT     ( str -- addr len )  \ null terminated string, whose 1rst char is at addr
                mov     ecx, # -1               \ scan way on up there... it had better stop!
                xor     eax, eax                \ look for null
                push    ebx                     \ add on stack
                mov     edi, ebx                \ edi = absolute address of string
                repnz   scasb
                add     ecx, # 2
                neg     ecx
                mov     ebx, ecx
                xor     edi, edi                \ edi is zero
                next    c;

\ ------------------------ Character translation tables -----------------------

CREATE UCASETAB                         \ uppercase a thru z to A thru Z
               $00 C, $01 C, $02 C, $03 C, $04 C, $05 C, $06 C, $07 C,
               $08 C, $09 C, $0A C, $0B C, $0C C, $0D C, $0E C, $0F C,
               $10 C, $11 C, $12 C, $13 C, $14 C, $15 C, $16 C, $17 C,
               $18 C, $19 C, $1A C, $1B C, $1C C, $1D C, $1E C, $1F C,
               $20 C, $21 C, $22 C, $23 C, $24 C, $25 C, $26 C, $27 C, \ | !"#$%&'|
               $28 C, $29 C, $2A C, $2B C, $2C C, $2D C, $2E C, $2F C, \ |()*+,-./|
               $30 C, $31 C, $32 C, $33 C, $34 C, $35 C, $36 C, $37 C, \ |01234567|
               $38 C, $39 C, $3A C, $3B C, $3C C, $3D C, $3E C, $3F C, \ |89:;<=>?|
               $40 C, $41 C, $42 C, $43 C, $44 C, $45 C, $46 C, $47 C, \ |@ABCDEFG|
               $48 C, $49 C, $4A C, $4B C, $4C C, $4D C, $4E C, $4F C, \ |HIJKLMNO|
               $50 C, $51 C, $52 C, $53 C, $54 C, $55 C, $56 C, $57 C, \ |PQRSTUVW|
               $58 C, $59 C, $5A C, $5B C, $5C C, $5D C, $5E C, $5F C, \ |XYZ[\]^_|
               $60 C, $41 C, $42 C, $43 C, $44 C, $45 C, $46 C, $47 C, \ |`ABCDEFG|
               $48 C, $49 C, $4A C, $4B C, $4C C, $4D C, $4E C, $4F C, \ |HIJKLMNO|
               $50 C, $51 C, $52 C, $53 C, $54 C, $55 C, $56 C, $57 C, \ |PQRSTUVW|
               $58 C, $59 C, $5A C, $7B C, $7C C, $7D C, $7E C, $7F C, \ |XYZ{|}~|
               $80 C, $81 C, $82 C, $83 C, $84 C, $85 C, $86 C, $87 C,
               $88 C, $89 C, $8A C, $8B C, $8C C, $8D C, $8E C, $8F C,
               $90 C, $91 C, $92 C, $93 C, $94 C, $95 C, $96 C, $97 C,
               $98 C, $99 C, $9A C, $9B C, $9C C, $9D C, $9E C, $9F C,
               $A0 C, $A1 C, $A2 C, $A3 C, $A4 C, $A5 C, $A6 C, $A7 C,
               $A8 C, $A9 C, $AA C, $AB C, $AC C, $AD C, $AE C, $AF C,
               $B0 C, $B1 C, $B2 C, $B3 C, $B4 C, $B5 C, $B6 C, $B7 C,
               $B8 C, $B9 C, $BA C, $BB C, $BC C, $BD C, $BE C, $BF C,
               $C0 C, $C1 C, $C2 C, $C3 C, $C4 C, $C5 C, $C6 C, $C7 C,
               $C8 C, $C9 C, $CA C, $CB C, $CC C, $CD C, $CE C, $CF C,
               $D0 C, $D1 C, $D2 C, $D3 C, $D4 C, $D5 C, $D6 C, $D7 C,
               $D8 C, $D9 C, $DA C, $DB C, $DC C, $DD C, $DE C, $DF C,
               $E0 C, $E1 C, $E2 C, $E3 C, $E4 C, $E5 C, $E6 C, $E7 C,
               $E8 C, $E9 C, $EA C, $EB C, $EC C, $ED C, $EE C, $EF C,
               $F0 C, $F1 C, $F2 C, $F3 C, $F4 C, $F5 C, $F6 C, $F7 C,
               $F8 C, $F9 C, $FA C, $FB C, $FC C, $FD C, $FE C, $FF C,

CREATE LCASETAB                         \ LOWERcase a thru z to A thru Z
               $00 C, $01 C, $02 C, $03 C, $04 C, $05 C, $06 C, $07 C,
               $08 C, $09 C, $0A C, $0B C, $0C C, $0D C, $0E C, $0F C,
               $10 C, $11 C, $12 C, $13 C, $14 C, $15 C, $16 C, $17 C,
               $18 C, $19 C, $1A C, $1B C, $1C C, $1D C, $1E C, $1F C,
               $20 C, $21 C, $22 C, $23 C, $24 C, $25 C, $26 C, $27 C, \ | !"#$%&'|
               $28 C, $29 C, $2A C, $2B C, $2C C, $2D C, $2E C, $2F C, \ |()*+,-./|
               $30 C, $31 C, $32 C, $33 C, $34 C, $35 C, $36 C, $37 C, \ |01234567|
               $38 C, $39 C, $3A C, $3B C, $3C C, $3D C, $3E C, $3F C, \ |89:;<=>?|
               $40 C, $61 C, $62 C, $63 C, $64 C, $65 C, $66 C, $67 C, \ |@abcdefg|
               $68 C, $69 C, $6A C, $6B C, $6C C, $6D C, $6E C, $6F C, \ |hijklmno|
               $70 C, $71 C, $72 C, $73 C, $74 C, $75 C, $76 C, $77 C, \ |pqrstuvw|
               $78 C, $79 C, $7A C, $5B C, $5C C, $5D C, $5E C, $5F C, \ |xyz[\]^_|
               $60 C, $61 C, $62 C, $63 C, $64 C, $65 C, $66 C, $67 C, \ |`abcdefg|
               $68 C, $69 C, $6A C, $6B C, $6C C, $6D C, $6E C, $6F C, \ |hijklmno|
               $70 C, $71 C, $72 C, $73 C, $74 C, $75 C, $76 C, $77 C, \ |pqrstuvw|
               $78 C, $79 C, $7A C, $7B C, $7C C, $7D C, $7E C, $7F C, \ |xyz{|}~|
               $80 C, $81 C, $82 C, $83 C, $84 C, $85 C, $86 C, $87 C,
               $88 C, $89 C, $8A C, $8B C, $8C C, $8D C, $8E C, $8F C,
               $90 C, $91 C, $92 C, $93 C, $94 C, $95 C, $96 C, $97 C,
               $98 C, $99 C, $9A C, $9B C, $9C C, $9D C, $9E C, $9F C,
               $A0 C, $A1 C, $A2 C, $A3 C, $A4 C, $A5 C, $A6 C, $A7 C,
               $A8 C, $A9 C, $AA C, $AB C, $AC C, $AD C, $AE C, $AF C,
               $B0 C, $B1 C, $B2 C, $B3 C, $B4 C, $B5 C, $B6 C, $B7 C,
               $B8 C, $B9 C, $BA C, $BB C, $BC C, $BD C, $BE C, $BF C,
               $C0 C, $C1 C, $C2 C, $C3 C, $C4 C, $C5 C, $C6 C, $C7 C,
               $C8 C, $C9 C, $CA C, $CB C, $CC C, $CD C, $CE C, $CF C,
               $D0 C, $D1 C, $D2 C, $D3 C, $D4 C, $D5 C, $D6 C, $D7 C,
               $D8 C, $D9 C, $DA C, $DB C, $DC C, $DD C, $DE C, $DF C,
               $E0 C, $E1 C, $E2 C, $E3 C, $E4 C, $E5 C, $E6 C, $E7 C,
               $E8 C, $E9 C, $EA C, $EB C, $EC C, $ED C, $EE C, $EF C,
               $F0 C, $F1 C, $F2 C, $F3 C, $F4 C, $F5 C, $F6 C, $F7 C,
               $F8 C, $F9 C, $FA C, $FB C, $FC C, $FD C, $FE C, $FF C,

\ -------------------- String Primitives ------------------------------------


CODE COMPARE    ( adr1 len1 adr2 len2 -- n )
                \ COMPARE compares two strings. The return value is:
                \        0 = string1 = string2
                \       -1 = string1 < string2
                \        1 = string1 > string2
                mov     -4 [ebp], esi
                pop     eax                     \ eax = adr2
                pop     ecx                     \ ecx = len1
                pop     esi                     \ esi = adr1
                mov     edi, eax                \ edi = adr2 (abs)
                xor     eax, eax                \ default is 0 (strings match)
                cmp     ecx, ebx                \ compare lengths
                je      short @@2
                ja      short @@1
                sub     eax, # 1                \ if len1 < len2, default is -1
                jmp     short @@2
@@1:            add     eax, # 1                \ if len1 > len2, default is 1
                mov     ecx, ebx                \ and use shorter length
@@2:            repz    cmpsb                   \ compare the strings
                je      short @@4               \ if equal, return default
                jnc     short @@3               \ corrected; reported by Ed Beroset
                mov     eax, # -1               \ if str1 < str2, return -1
                jmp     short @@4
@@3:            mov     eax, # 1                \ if str1 > str2, return 1
@@4:            mov     ebx, eax
                mov     esi, -4 [ebp]
                xor     edi, edi                \ edi is zero
                next    c;

CODE STR=       ( adr1 len1 adr2 len2 -- flag ) \ compares two strings, case sensitive, same as COMPARE 0=
                pop     edi                     \ edi=adr2
                pop     ecx                     \ ecx=len1
                mov     eax, esi                \ save esi
                pop     esi                     \ esi=adr1
                cmp     ecx, ebx                \ if equal lengths
                mov     ebx, # 0                \ zero ebx
                jne     short @@8               \ carry on
                repz    cmpsb                   \ equal?
                jne     short @@8               \ no, exit false
                dec     ebx                     \ ebx=true
@@8:            mov     esi, eax                \ restore esi
                xor     edi, edi                \ zero edi
                next    c;

CODE ISTR=      ( adr1 len1 adr2 len2 -- flag ) \ compares two strings, case insensitive, true if equal
                mov     -4 [ebp], esi           \ save esi
                pop     edi                     \ edi=adr2
                pop     ecx                     \ ecx=len1
                pop     esi                     \ esi=adr1
                cmp     ebx, ecx                \ lengths equal?
                jne     short @@7               \ no, leave now=false

                add     ecx, esi                \ point to end of source
                xor     eax, eax                \ zero eax
                xor     ebx, ebx                \ and ebx
                jmp     short @@2               \ start checking

@@1:            mov     bl, 0 [edi]             \ get first byte
                mov     al, 0 [esi]             \ of each string
                mov     bl, ucasetab [ebx]      \ uppercase
                inc     edi
                inc     esi
                cmp     bl, ucasetab [eax]      \ equal?
                jne     short @@7               \ no, exit
@@2:            cmp     esi, ecx                \ past end of buffer?
                jb      short @@1               \ no, back round

                mov     ebx, # -1               \ ebx=true
                jmp     short @@9               \ leave

@@7:            xor     ebx, ebx                \ zero ebx
@@9:            mov     esi, -4 [ebp]           \ restore esi
                xor     edi, edi                \ zero edi
                next    c;

\ Search str1 for substring str2 :
\ ESI = pointer to source string (str2)
\ EBX = length  of source string
\ EDI = pointer to destination string (str1)
\ ECX = length  of destination string
\ EDX = pointer for compare

CODE SEARCH     ( c-addr1 u1 c-addr2 u2 -- c-addr3 u3 flag )
\ *G Search the string specified by c-addr1 u1 for the (sub)string specified by c-addr2 u2.
\ ** If flag is true, a match was found at c-addr3 with u3 characters remaining.
\ ** If flag is false there was no match and c-addr3 is c-addr1 and u3 is u1.
                test    ebx, ebx
                jne     short @@1
                add     esp, # 4
                sub     ebx, # 1             \ zero length matches
                jmp     short @@9

@@1:            mov     -4 [ebp], edx    \ save UP
                mov     -8 [ebp], esi
                pop     esi
                mov     ecx, 0 [esp]
                mov     edi, 4 [esp]
                jmp     short @@2
@@4:            add     edi, # 1        \ go to next    c; char in destination
                sub     ecx, # 1
@@2:            cmp     ecx, ebx        \ enough room for match?
                jb      short @@5
                sub     edx, edx        \ starting index
@@3:            mov     al, 0 [edx] [esi]
                cmp     al, 0 [edx] [edi]
                jne     short @@4
                add     edx, # 1
                cmp     edx, ebx
                jne     short @@3
                mov     4 [esp], edi
                mov     0 [esp], ecx
                mov     ebx, # -1       \ true flag
                jmp     short @@6
@@5:            sub     ebx, ebx        \ not found
@@6:            mov     edx, -4 [ebp]
                mov     esi, -8 [ebp]
                xor     edi, edi                \ edi is zero

@@9:            next    c;

CODE SKIP       ( adr len char -- adr' len' ) \ skip leading chars "char" in string
                pop     ecx
                jecxz   short @@2
                mov     eax, ebx                \ eax = character
                pop     edi
                repz    scasb
                je      short @@1
                add     ecx, # 1
                sub     edi, # 1
@@1:            push    edi
                xor     edi, edi                \ edi is zero
@@2:            mov     ebx, ecx
                next    c;

CODE SCAN       ( adr len char -- adr' len' ) \ search first occurence of char "char" in string
                pop     ecx
                jecxz   short @@2
                mov     eax, ebx                \ eax = character
                pop     edi
                repnz   scasb
                jne     short @@1
                add     ecx, # 1
                sub     edi, # 1
@@1:            push    edi
                xor     edi, edi                \ edi is zero
@@2:            mov     ebx, ecx
                next    c;

CODE WSKIP      ( adr len word -- adr' len' ) \ skip leading words "word" in string
                pop     ecx
                jecxz   short @@2
                mov     eax, ebx                \ eax = character
                pop     edi
                repz    scasw
                je      short @@1
                add     ecx, # 1
                sub     edi, # 2
@@1:            push    edi
                xor     edi, edi                \ edi is zero
@@2:            mov     ebx, ecx
                next    c;

CODE WSCAN      ( adr len word -- adr' len' ) \ search first occurence of word "word" in string
                pop     ecx
                jecxz   short @@2
                mov     eax, ebx                \ eax = character
                pop     edi
                repnz   scasw
                jne     short @@1
                add     ecx, # 1
                sub     edi, # 2
@@1:            push    edi
                xor     edi, edi                \ edi is zero
@@2:            mov     ebx, ecx
                next    c;

CODE LSKIP      ( adr len long -- adr' len' ) \ skip leading cells "long" in string
                pop     ecx
                jecxz   short @@2
                mov     eax, ebx                \ eax = character
                pop     edi
                repz    scasd
                je      short @@1
                add     ecx, # 1
                sub     edi, # 4
@@1:            push    edi
                xor     edi, edi                \ edi is zero
@@2:            mov     ebx, ecx
                next    c;

CODE LSCAN      ( adr len long -- adr' len' ) \ search first occurence of cell "long" in string
                pop     ecx
                jecxz   short @@2
                mov     eax, ebx                \ eax = character
                pop     edi
                repnz   scasd
                jne     short @@1
                add     ecx, # 1
                sub     edi, # 4
@@1:            push    edi
                xor     edi, edi                \ edi is zero
@@2:            mov     ebx, ecx
                next    c;

CODE -SCAN      ( addr len char -- addr' len' ) \ Scan for char BACKWARDS starting
                \ at addr, the end of the string, back through len bytes before addr,
                \ returning addr' and len' of char.
                mov     eax, ebx
                pop     ecx
                jecxz   short @@1
                pop     edi
                std
                repnz   scasb
                cld
                jne     short @@2
                add     ecx, # 1
                add     edi, # 1
@@2:            push    edi
                xor     edi, edi                \ edi is zero
@@1:            mov     ebx, ecx
                next    c;

CODE -SKIP      ( addr len char -- addr' len' ) \ Skip occurances of char BACKWARDS
                \ starting at addr, the end of the string, back through len bytes
                \ before addr, returning addr' and len' of char.
                mov     eax, ebx
                pop     ecx
                jecxz   short @@1
                pop     edi
                std
                repz    scasb
                cld
                je      short @@2
                add     ecx, # 1
                add     edi, # 1
@@2:            push    edi
                xor     edi, edi                \ edi is zero
@@1:            mov     ebx, ecx
                next    c;

\ -------------------- Strings ----------------------------------------------

: "CLIP"        ( c-addr1 len1 -- c-addr2 len2 )    \ W32F           String Extra
\ *G Clip string c-addr1,len1 to c-addr2,len2 where c-addr2=c-addr1 and
\ ** len2 is between 0 and MAXCOUNTED.
                MAXCSTRING MIN 0MAX ;

CODE PLACE      ( c-addr1 len1 c-addr2 -- )         \ W32F           String Extra
\ *G Place string c-addr1,len1 at c-addr2 as a counted string.
                pop     ecx                     \ get length
                pop     eax                     \ source in eax
                test    ecx, ecx                \ check there's something to move
                jg      short @@1               \ < 0, make zero
                mov     byte [ebx], # 0         \ zero the length
                jmp     short @@9               \ and leave

@@1:            and     ecx, # MAXCOUNTED       \ make sure not too long
                mov     byte [ebx], cl          \ store the length in dest
                mov     -4 [ebp], esi           \ save esi
                mov     esi, eax                \ point at source
                lea     edi, 1 [ebx]            \ point at dest+1
                rep     movsb                   \ move it
                mov     esi, -4 [ebp]           \ restore esi
                xor     edi, edi                \ edi is zero

@@9:            pop     ebx
                next    c;

CODE +PLACE     ( c-addr1 len1 c-addr2 -- )            \ W32F    String Extra
\ *G Append string addr1,len1 to the counted string at addr2.
                pop     ecx                     \ get length
                pop     eax                     \ source in eax
                test    ecx, ecx                \ check there's something to move
                jle     short @@9               \ <= 0, just leave

                mov     -4 [ebp], esi           \ save esi
                mov     -8 [ebp], edx           \ save edx

                mov     esi, # MAXCOUNTED       \ max length
                movzx   edx, byte [ebx]         \ get current length
                sub     esi, edx                \ subtract original length
                cmp     ecx, esi                \ get min of ecx, esi in ecx
                jle     short @@3               \ ecx is ok
                mov     ecx, esi                \ esi is len to move

@@3:            add     byte [ebx], cl          \ save the new length
                mov     esi, eax                \ point at source
                lea     edi, 1 [ebx] [edx]      \ point at dest+1 + len
                rep     movsb                   \ move it
                mov     esi, -4 [ebp]           \ restore esi
                mov     edx, -8 [ebp]           \ restore edx
                xor     edi, edi                \ edi is zero

@@9:            pop     ebx
                next    c;

CODE +NULL      ( c-addr -- )                     \ W32F        String Extra
\ *G Append a NULL to the counted string.
                movzx   ecx, byte [ebx]         \ length
                lea     ebx, 1 [ebx] [ecx]      \ point at char
                mov     byte [ebx], # 0         \ zero the char
                pop     ebx
                next    c;

CODE -TRAILCHARS ( c-addr u1 char -- c-addr u2 )  \ W32F          String Extra
\ *G If u1 is greater than zero, u2 is equal to u1 less the number of chars at
\ ** the end of the character string specified by c-addr u1. If u1 is zero or the
\ ** entire string consists of chars, u2 is zero.
                mov     eax, ebx
                pop     ecx
                jecxz   short @@2
                mov     ebx, 0 [esp]
                add     ebx, ecx
@@1:            sub     ebx, # 1
                cmp     0 [ebx], al
                jne     short @@2
                sub     ecx, # 1
                jnz     short @@1
@@2:            mov     ebx, ecx
                next    c;

: -TRAILING     ( c-addr u1 -- c-addr u2 )  \ ANSI          String
\ *G If u1 is greater than zero, u2 is equal to u1 less the number of spaces at
\ ** the end of the character string specified by c-addr u1. If u1 is zero or the
\ ** entire string consists of spaces, u2 is zero.
                BL -TRAILCHARS ;

: -NULLS        ( c-addr u1 -- c-addr u2 )  \ W32F          String Extra
\ *G If u1 is greater than zero, u2 is equal to u1 less the number of nulls at
\ ** the end of the character string specified by c-addr u1. If u1 is zero or the
\ ** entire string consists of nulls, u2 is zero.
                0 -TRAILCHARS ;

CODE /STRING    ( c-addr1 u1 n -- c-addr2 u2 ) \ ANSI   String
\ *G Adjust the character string at c-addr1 by n characters. The resulting character
\ ** string, specified by c-addr2 u2, begins at c-addr1 plus n characters and is u1
\ ** minus n characters long. \n
\ ** If n1 greater than len1, then returned len2 will be zero. \n
\ ** For early (pre Nov 2000) versions of W32F, if n1 less than zero,
\ ** then returned length u2 was zero.
\ *P /STRING is used to remove or add characters relative to the left end of the
\ ** character string. Positive values of n will exclude characters from the string
\ ** while negative values of n will include characters to the left of the string.
                pop     eax
                test    ebx, ebx       \ November 27th, 2000 - 11:58 tjz. Added two
                jle     short @@1      \ lines to allow a negative argument to be
                cmp     ebx, eax       \ passed to /STRING, such that the string will
                jbe     short @@1      \ be expanded.
                mov     ebx, eax
@@1:            add     0 [esp], ebx
                sub     eax, ebx
                mov     ebx, eax
                next    c;

CODE LARGEST    ( a1 n1 --- a2 n2 )
                mov     ecx, ebx          \ count of array to search
                pop     ebx               \ starting address of array
                push    edx               \ save UP
                xor     eax, eax          \ starting highest value = 0
                mov     edx, ebx          \ highest value addr = start address
@@1:            cmp     0 [ebx], eax      \ compare 32bit words
                jle     short @@2         \ branch if not greater
                mov     edx, ebx          \ if greater, save offset in EDX
                mov     eax, 0 [ebx]      \ and contents in EAX
@@2:            add     ebx, # 4          \ bump to next element
                sub     ecx, # 1
                jnz     short @@1
                mov     ecx, edx
                pop     edx               \ restore UP
                push    ecx
                mov     ebx, eax
                next    c;

CODE CELL-SORT  ( a1 n1 -- )      \ perform in place sort buffer a1 of n1 cells
                push    ebx
                cmp     ebx, # 2        \ don't sort if less than 2 elements
                jnl     short @@2
                jmp     short @@3
@@1:            mov     eax,   0 [ebx]
                xchg    eax,   4 [ebx]
                xchg    eax,   0 [ebx]
                cmp     eax,   0 [ebx]
                jl      short @@1
                add     ebx, # 4
                loop    @@1
@@2:            pop     ecx
                pop     ebx
                push    ebx
                sub     ecx, # 1
                push    ecx
                jg      short @@1
@@3:            add     esp, # 8
                pop     ebx
                next    c;

CODE BYTE-SORT  ( a1 n1 -- )      \ perform in place sort buffer a1 of n1 bytes
                push    ebx
                cmp     ebx, # 2        \ don't sort if less than 2 elements
                jnl     short @@2
                jmp     short @@3
@@1:            mov     al,   0 [ebx]
                xchg    al, 1 [ebx]
                xchg    al,   0 [ebx]
                cmp     al,   0 [ebx]
                jl      short @@1
                add     ebx, # 1
                loop    @@1
@@2:            pop     ecx
                pop     ebx
                push    ebx
                sub     ecx, # 1
                push    ecx
                jg      short @@1
@@3:            add     esp, # 8
                pop     ebx
                next    c;

\ -------------------- Double Arithmetic Operators --------------------------

CODE D+         ( d1 d2 -- d3 ) \ add 2 doubles - no overflow check
                pop     eax
                pop     ecx
                add     0 [esp], eax
                adc     ebx, ecx
                next    c;

CODE D-         ( d1 d2 -- d3 ) \ substract 2 doubles
                pop     eax
                pop     ecx
                sub     0 [esp], eax
                sbb     ecx, ebx
                mov     ebx, ecx
                next    c;

CODE DNEGATE    ( d1 -- d2 )    \ negate d1, returning 2's complement d2
                pop     eax
                neg     ebx
                neg     eax
                sbb     ebx, # 0
                push    eax
                next    c;

CODE DABS       ( d1 -- d2 )    \ return the absolute value of d1 as d2
                test    ebx, ebx
                jns     short @@1
                pop     eax
                neg     ebx
                neg     eax
                sbb     ebx, # 0
                push    eax
@@1:            next    c;

CODE S>D        ( n1 -- d1 ) \ convert single signed single n1 to a signed
                             \ double d1
                push    ebx
                shl     ebx, 1          \ put sign bit into carry
                sbb     ebx, ebx
                next    c;

: D>S           ( d -- s )   \ convert double to single
                drop ;

: D=            ( d1 d2 -- f1 ) \ f1=true if double d1 is equal to double d2
                D- OR 0= ;

CODE D0<        ( d1 -- f1 )   \ Signed compare d1 double number with zero.
                sar     ebx, # 31
                pop     ecx
                next    c;

: D0=           ( d -- f) \ double compare to 0
                or 0= ;

CODE D<         ( d1 d2 -- f ) \ Signed compare two double numbers.
                pop     eax
                pop     ecx
                cmp     0 [esp], eax
                pop     eax
                sbb     ecx, ebx
                mov     ebx, # 0
                jge     short @@1
                sub     ebx, # 1
@@1:            next    c;

: D>            ( d1 d2 -- f ) \ Signed compare two double numbers.
                2SWAP D<   ;

: D<>           ( d1 d2 -- d ) \ Signed compare two double numbers.
                D= 0= ;

: DMIN          ( d1 d2 -- d3 ) \  Replace with the smaller of the two (signed).
                4DUP D> IF  2SWAP  THEN 2DROP ;

: DMAX          ( d1 d2 -- d3 ) \  Replace with the larger of the two (signed).
                4DUP D< IF  2SWAP  THEN  2DROP ;        \ 05/25/90 tjz

\ -------------------- Early procedure support ------------------------------

CODE CALL-PROC  ( [ n ] ep -- r )               \ call ep on top of stack
                xchg    ebx, edx                \ save UP
                call    edx                     \ ep now in edx
                mov     edx, ebx                \ restore UP
                mov     ebx, eax
                next    c;

CFA-CODE DOCALL ( [ n ] -- r )                  \ runtime for a DLL call
                push    ebx
                mov     ebx, edx                \ save UP
                call    4 [eax]                 \ call address is absolute!!!
                mov     edx, ebx                \ restore UP
                mov     ebx, eax
                next    c;

CFA-CODE DOCALL-MULTI ( -- )                    \ called to resolve from DOCALL
                mov      ebx, eax               \ top of stack is proc-cfa
                mov      0 [esp], ebx           \ drop the return address, & dup
                mov      eax, # 1234            \ get constant (patched, see res-multi-libs)
LABEL RES-MULTI-X                               \ cell beyond patch address
                xchg     esp, ebp               \ swap regs for call
                call     callf                  \ resolve with forth call
                xchg     esp, ebp               \ swap regs for call
                mov      eax, ebx               \ get address
                pop      ebx                    \ correct the stack
                exec     c;                     \ go do it

CFA-CODE DOCALL-SINGLE ( -- )                   \ called to resolve from DOCALL
                mov      ebx, eax               \ top of stack is proc-cfa
                mov      0 [esp], ebx           \ drop the return address, & dup
                mov      eax, # 1234            \ get constant (patched, see res-single-lib)
LABEL RES-SINGLE-X                              \ cell beyond patch address
                xchg     esp, ebp               \ swap regs for call
                call     callf                  \ resolve with forth call
                xchg     esp, ebp               \ swap regs for call
                mov      eax, ebx               \ get address
                pop      ebx                    \ correct the stack
                exec     c;                     \ go do it

CFA-CODE DOEXTERN ( -- r )                      \ runtime for a DLL extern
                push    ebx
                mov     ebx, 4 [eax]            \ get address
                next    c;

ASSEMBLER DOCALL        META CONSTANT DOCALL
ASSEMBLER DOEXTERN      META CONSTANT DOEXTERN
ASSEMBLER DOCALL-MULTI  META CONSTANT DOCALL-MULTI
ASSEMBLER DOCALL-SINGLE META CONSTANT DOCALL-SINGLE

\ -------------------- User Variables ---------------------------------------

\ *P Task based variables are here. Each task has its own local copy of an uninitialised
\ ** variable. All other VARIABLEs and VALUEs are global the the entire process, and must
\ ** not be changed in a task unless locked or you know what you're doing.

VARIABLE NEXT-USER        \ offset of next defineable user variable

CODE UP@        ( -- addr )                     \ get the pointer to the user area
                push    ebx
                mov     ebx, fs: 0x14           \ TIB pvArbitrary is user base
                next    c;

CODE UP!        ( addr -- )                     \ set the pointer to the user area
                mov     edx, ebx                \ make absolute user base
                mov     fs: 0x14 , edx          \ save in TIB pvArbitrary
                pop     ebx
                next    c;

-2 CELLS ( init offset so TCB is 0 ) ( order IS important )
  DUP USER RP0        CELL+ ( initial return stack pointer )
  DUP USER SP0        CELL+ ( initial data stack pointer )
  DUP USER TCB        CELL+ ( task control block )
  DUP ( *1 )                ( absolute min user area )
  DUP USER &EXREC     CELL+ ( for exception handling )
  DUP USER &EXCEPT    CELL+ ( for exception handling )
  DUP USER HANDLER    CELL+ ( throw frame )
  DUP USER LP         CELL+ ( local variable pointer )
  DUP USER OP         CELL+ ( object pointer )
  DUP USER BASE       CELL+ ( numeric radix )
  DUP | USER RLLEN    CELL+ ( read line length, used in file i/o see read-line )
  DUP | USER RLNEOF   CELL+ ( read line not eof, used in file i/o see read-line )
  DUP USER HLD        CELL+ ( numeric output pointer )
         80 CHARS ALIGNED + ( numeric output formatting buffer )
  DUP USER PAD        CELL+ ( extra )
  MAXSTRING CHARS ALIGNED + ( user string buffer )
  DUP NEXT-USER !           ( save top user variable offset in NEXT-USER )
( *2 )    OVER - CONSTANT USEREXTRA ( add to USERMIN if you are going to do I/O )
( *1 ) 3 CELLS + CONSTANT USERMIN   ( absolute min user area )
       TCB RP0 - CONSTANT USEROFFS  ( user offset, 2 cells )

\ -------------------- System Variables -------------------------------------

\ ANS defined
-1    EQU THROW_ABORT                \ no message
-2    EQU THROW_ABORTQ               \ message from ABORT"
-4    EQU THROW_STACKUNDER           \ " stack underflow"
-13   EQU THROW_UNDEFINED            \ " is undefined"
-14   EQU THROW_COMPONLY             \ " is compilation only"
-16   EQU THROW_NAMEREQD             \ " requires a name"
-22   EQU THROW_MISMATCH             \ " control structure mismatch"
-38   EQU THROW_FILENOTFOUND         \ " file not found"

\ System extended
-260  EQU THROW_NOTDEFER             \ " is not a DEFER"
-262  EQU THROW_NOTVALUE             \ " is not a VALUE"
-270  EQU THROW_OUTOFMEM             \ " out of memory"
-271  EQU THROW_MEMALLOCFAIL         \ " memory allocation failed"
-272  EQU THROW_MEMRELFAIL           \ " memory release failed"
-280  EQU THROW_FILECREATEFAIL       \ " create-file failed"
-281  EQU THROW_FILEREADFAIL         \ " read-file failed"
-282  EQU THROW_FILEWRITEFAIL        \ " write-file failed"
-290  EQU THROW_INTERPONLY           \ " is interpretation only"
-300  EQU THROW_LOCALSTWICE          \ " locals defined twice"
-301  EQU THROW_LOCALSTOOMANY        \ " too many locals"
-302  EQU THROW_LOCALSNO}            \ " missing }"
-310  EQU THROW_PROCNOTFOUND         \ " procedure not found"
-311  EQU THROW_WINERR               \ " Windows DLL error"
-320  EQU THROW_STACKCHG             \ " stack changed"
-330  EQU THROW_METHEXIT             \ " can't use EXIT in a method"
-331  EQU THROW_METHDOES>            \ " can't use DOES> in a method"
-332  EQU THROW_METH;M               \ " method must end with ;M"

\ Warnings
-4100 EQU WARN_NOTUNIQUE             \ " is already defined"
-4101 EQU WARN_SYSWORD               \ " is a system word in an application definition"
-4102 EQU WARN_SYSWORD2              \ " is an application word set to a system word"
-4103 EQU WARN_STACK                 \ " stack depth increased"
-4104 EQU WARN_DEPRECATEDWORD        \ " is a deprecated word"
-4106 EQU WARN_SYSWORD3              \ " is an application word whose runtime is in a system word"

VARIABLE THROW_MSGS 0 THROW_MSGS !        \ list header

\ ANS defined
  THROW_MSGS LINK, THROW_STACKUNDER          , ," stack underflow"
  THROW_MSGS LINK, THROW_UNDEFINED           , ," is undefined"
  THROW_MSGS LINK, THROW_COMPONLY            , ," is compilation only"
  THROW_MSGS LINK, THROW_NAMEREQD            , ," requires a name"
  THROW_MSGS LINK, THROW_MISMATCH            , ," control structure mismatch"
  THROW_MSGS LINK, THROW_FILENOTFOUND        , ," file not found"

\ System extended
  THROW_MSGS LINK, THROW_NOTDEFER            , ," is not a DEFER"
  THROW_MSGS LINK, THROW_NOTVALUE            , ," is not a VALUE"
  THROW_MSGS LINK, THROW_OUTOFMEM            , ," out of memory"
  THROW_MSGS LINK, THROW_MEMALLOCFAIL        , ," memory allocation failed"
  THROW_MSGS LINK, THROW_MEMRELFAIL          , ," memory release failed"
  THROW_MSGS LINK, THROW_FILECREATEFAIL      , ," create-file failed"
  THROW_MSGS LINK, THROW_FILEREADFAIL        , ," read-file failed"
  THROW_MSGS LINK, THROW_FILEWRITEFAIL       , ," write-file failed"
  THROW_MSGS LINK, THROW_INTERPONLY          , ," is interpretation only"
  THROW_MSGS LINK, THROW_LOCALSTWICE         , ," locals defined twice"
  THROW_MSGS LINK, THROW_LOCALSTOOMANY       , ," too many locals"
  THROW_MSGS LINK, THROW_LOCALSNO}           , ," missing }"
  THROW_MSGS LINK, THROW_PROCNOTFOUND        , ," procedure not found"
  THROW_MSGS LINK, THROW_WINERR              , ," Windows DLL error"
  THROW_MSGS LINK, THROW_STACKCHG            , ," stack changed"
  THROW_MSGS LINK, THROW_METHEXIT            , ," can't be used in a method"
  THROW_MSGS LINK, THROW_METHDOES>           , ," can't use DOES> in a method"
  THROW_MSGS LINK, THROW_METH;M              , ," method must end with ;M"

\ Warnings
  THROW_MSGS LINK, WARN_NOTUNIQUE            , ," is redefined"
  THROW_MSGS LINK, WARN_SYSWORD              , ," is a system word in an application word"
  THROW_MSGS LINK, WARN_SYSWORD2             , ," is an application word set to a system word"
  THROW_MSGS LINK, WARN_DEPRECATEDWORD       , ," is a *** deprecated *** word (see src\compat\evolve.f)"
  THROW_MSGS LINK, WARN_SYSWORD3             , ," is an application word whose runtime is in a system word"

| CREATE NULLMSG ," "                        \ no message text
VARIABLE MSG     NULLMSG MSG !               \ message pointer
0 VALUE LAST-ERROR                           \ last forth error reported
VARIABLE STATE
VARIABLE WARNING TRUE WARNING !

\ *P CAPS OFF tells the compiler to store the name with the case specified and
\ ** CAPS ON reverts to normal. To find words defined while CAPS is OFF you need
\ ** to set CAPS OFF before interpreting/compiling the word ( unless all the
\ ** alphabetic chars are uppercase ) otherwise FIND converts to uppercase
\ ** before searching.  By George Hubert c/o JP
\ VARIABLE CAPS    TRUE CAPS    !

0 VALUE POCKET                  \ ptr to POCKET allocated in MAIN
0 VALUE CUR-FILE                \ ptr to CUR-FILE
0 VALUE TEMP$                   \ ptr to TEMP$
0 VALUE FIND-BUFFER             \ ptr to FIND-BUFFER

VARIABLE LOADLINE
VARIABLE >IN                    \ offset in to input stream
0 VALUE SOURCE-ID
0 VALUE SOURCE-POSITION \ readded for cf32 port (Samstag, August 13 2005 dbu)

\ Renamed ?LOADING to LOADING? because ?LOADING was defined as a variable
\ in older w32f versions (Dienstag, Oktober 03 2006 dbu).
: LOADING?      ( -- flag )     \ are we loading?
                source-id -1 0 between 0= ;

MAXSTRING 2 + ALIGNED EQU TIBLEN

CREATE (SOURCE)                 \ input stream pointer
        0 ,                     \ length of input stream
        0 ,                     \ address of input stream, adjusted in : MAIN

: TIB           ( -- addr )       [ (SOURCE) CELL+ ] LITERAL  @ ;
: SOURCE        ( -- addr len )     (SOURCE)                 2@ ;

(SOURCE) CONSTANT #TIB          \ address of terminal input buffer length

(SOURCE)     EQU S_LEN          \ source address & length for the assembler
(SOURCE) 4 + EQU S_ADR

CREATE .SMAX   8 ,              \ max number of stack entries to show


\ -------------------- Deferred I/O -----------------------------------------

\ Dummy actions for defered i/o words. They are used (eg in GeneralBoot), to test
\ if and when the i/o defered words are on or off, so don't change them.
: K_NOOP0 2DROP 0 ;
: K_NOOP1 0 ;             \ *** DON'T CHANGE AND NEVER REDEFINE THIS WORD ***
: K_NOOP2 0 DUP ;

DEFER CONSOLE      ( -- ) ( stdout: switch I/O to console)        ' NOOP    IS CONSOLE

DEFER INIT-CONSOLE     ' K_NOOP1 IS INIT-CONSOLE
DEFER INIT-SCREEN      ' NOOP    IS INIT-SCREEN

DEFER KEY          ( -- k ) ( stdin: get a key )                  ' K_NOOP1 IS KEY
DEFER KEY?         ( -- flag ) ( stdin: is a key pending ?)       ' K_NOOP1 IS KEY?
DEFER ACCEPT       ( addr nbmax -- nb ) ( stdin: input line)      ' K_NOOP0 IS ACCEPT
DEFER PUSHKEY                                                     ' DROP    IS PUSHKEY
DEFER "PUSHKEYS                                                   ' 2DROP   IS "PUSHKEYS

DEFER CLS          ( -- ) ( stdout: clear screen)                 ' NOOP    IS CLS
DEFER EMIT         ( char -- ) ( stdout: display char)            ' DROP    IS EMIT
DEFER TYPE         ( addr len -- ) ( stdout: display string)      ' 2DROP   IS TYPE
DEFER CR           ( -- ) ( stdout: emit carriage return)         ' NOOP    IS CR
DEFER ?CR          ( n -- ) ( stdout: CR if not room for n chars) ' DROP    IS ?CR
DEFER GOTOXY       ( x y -- ) ( stdout: set cursor to x,y)        ' 2DROP   IS GOTOXY
DEFER GETXY        ( -- x y ) ( stdout: get cursor position)      ' K_NOOP2 IS GETXY
DEFER FGBG!        ( f b -- ) ( stdout: set back and fore colors) ' 2DROP   IS FGBG!
DEFER FG@          ( -- f ) ( stdout: get foregroung color)       ' K_NOOP1 IS FG@
DEFER BG@          ( f b -- ) ( stdout: get background color)     ' K_NOOP1 IS BG@
DEFER SETCHARWH                                                   ' 2DROP   IS SETCHARWH
DEFER CHARWH                                                      ' K_NOOP2 IS CHARWH
DEFER SET-CURSOR                                                  ' DROP    IS SET-CURSOR
DEFER GET-CURSOR                                                  ' K_NOOP1 IS GET-CURSOR
DEFER GETCOLROW                                                   ' K_NOOP2 IS GETCOLROW
DEFER GETROWOFF    ( -- n ) ( first visible row in new console)   ' K_NOOP1 IS GETROWOFF
DEFER &THE-SCREEN                                                 ' K_NOOP1 IS &THE-SCREEN
DEFER SCROLLTOVIEW                                                ' NOOP    IS SCROLLTOVIEW

\ Note : the number of defered i/o words must be minimized so that switching
\        from a device to another doesn't need reseting useless defered, useless
\        meaning that this defer may be expressed in terms of other ones.
\        eg: : COL  ( n -- ) GETCOLROW DROP 1- MIN GETXY DROP - SPACES ;

\ DEFER SETCOLROW                                                   ' 2DROP   IS SETCOLROW
\ DEFER SETROWOFF                                                   ' DROP    IS SETROWOFF
\ DEFER GETMAXCOLROW                                                ' K_NOOP2 IS GETMAXCOLROW
\ DEFER SETMAXCOLROW                                                ' 2DROP   IS SETMAXCOLROW
\ DEFER SIZESTATE                                                   ' K_NOOP1 IS SIZESTATE
\ DEFER MARKCONSOLE                                                 ' 4DROP   IS MARKCONSOLE
\ DEFER CURSORINVIEW                                                ' NOOP    IS CURSORINVIEW
\ DEFER INIT-CONSOLE-REG ' NOOP    IS INIT-CONSOLE-REG


\ -------------------- DOS Console I/O -----------------------------------------
\                 d_ prefix stands for "DOS"

0 VALUE appInst     \ the application instance (origin of code), set in MAIN
0 VALUE _conHndl    \ window handle for the original console handle


WinLibrary KERNEL32.DLL
0 PROC AllocConsole              \ kernel's console (APIs from KERNEL32.DLL)
2 PROC SetConsoleMode
1 PROC GetStdHandle
5 PROC WriteConsoleA
4 PROC PeekConsoleInputA
0 PROC FreeConsole
2 Proc GetNumberOfConsoleInputEvents
4 Proc ReadConsoleInputA

0 VALUE INH                     \ console input handle
0 VALUE OUTH                    \ console output handle
CREATE INP_REC  10 cells ALLOT  \ input_record for PeekConsoleInput
VARIABLE DOSCHAR -1 DOSCHAR !   \ current char buffer


: d_INIT-CONSOLE ( -- flg ) \ init kernel's DOS console, ff if already inited
                INH if 0 exit then
                Call AllocConsole drop          \ alloc the character mode cons.
                STD_OUTPUT_HANDLE
                Call GetStdHandle to OUTH       \ get output handle
                STD_INPUT_HANDLE
                Call GetStdHandle to INH        \ get input handle
                0                               \ mode: char/char ; no echo
                INH
                Call SetConsoleMode drop
                -1 ;                            \ true flag : ok

: d_UNINIT-CONSOLE ( -- ) \ free the character-mode console
                INH 0<>
                if   Call FreeConsole drop
                     0 to INH 0 to OUTH
                then ;

: d_TYPE        ( addr cnt -- ) \ type a string
                0                               \ reserved : null
                0 >r RP@                        \ pointer to addr # chars read
                2swap swap                      \ count and addr
                OUTH                            \ handle of console output
                Call WriteConsoleA drop
                r>drop ;

: d_EMIT        ( char -- ) \ emit a character
                SP@ 1 d_TYPE drop ;

: d_CR          ( -- ) \ emit a carriage return
                13 d_EMIT 10 d_EMIT ;

: d_EKEY	( -- u ) \ get extended char
		0 >r RP@
                2
                INP_REC
                INH
                Call ReadConsoleInputA drop
                r>drop
                INP_REC w@ KEY_EVENT <> if FALSE exit then
                [ INP_REC 14 + ] LITERAL w@                  \ AsciiChar
                [ INP_REC 12 + ] LITERAL w@  16 lshift or    \ wVirtualScanCode
                [ INP_REC 04 + ] LITERAL c@  24 lshift or ;  \ bKeyDown

: d_EKEY>CHAR   ( u -- u false | char true ) \ is char ?
		dup 0xFF000000 AND 0=  if FALSE    exit then
		dup 0x000000FF AND dup if nip TRUE exit then
		drop FALSE ;

: d_KEY? 	( -- flag ) \ is a char (ie key pressed) available ?
                DOSCHAR @ 0 > IF TRUE exit then
                begin 0 >r RP@
                      INH
                      Call GetNumberOfConsoleInputEvents drop
                      r>
                      while                          \ loop while events present
                      d_EKEY d_EKEY>CHAR             \ exit if event is a valid char
                      if DOSCHAR ! TRUE exit then
		      drop
                repeat FALSE ;

: d_KEY 	( -- char ) \ get key from keyboard
		DOSCHAR @ 0>
		if DOSCHAR @ -1 DOSCHAR ! exit then
		begin d_EKEY d_EKEY>CHAR
                      0= while
		      drop
		repeat ;

: d_ACCEPT      ( c-addr nbmax -- nbread ) \ accept a string
                >r 0                                 \ current char count
                begin
                  d_KEY dup 13 <> while
                  dup 8 =
                  if   drop dup 0>
                       if   1- 8 d_EMIT BL d_EMIT 8 d_EMIT
                       else 7 d_EMIT
                       then
                  else over r@ < over 32 >= and
                       if   dup d_EMIT 2 pick 2 pick + c! 1+
                       else drop 7 d_EMIT
                       then
                  then
                repeat
                drop swap r> 2drop ;

' d_Init-Console       IS INIT-CONSOLE
' d_KEY                IS KEY         \ init defered
' d_KEY?               IS KEY?
' d_ACCEPT             IS ACCEPT
' d_EMIT               IS EMIT
' d_TYPE               IS TYPE
' d_CR                 IS CR


\ -------------------- basic I/O ------------------------------------------

: SPACE         ( -- ) \ emit a space
                BL EMIT ;

256 CONSTANT SPCS-MAX  ( optimization for SPACES )
0 VALUE SPCS

: SPACES        ( n -- ) \ emit n spaces
                BEGIN   DUP 0>
                WHILE   DUP SPCS-MAX MIN
                        SPCS OVER TYPE
                        -
                REPEAT  DROP ;

: COL		( n -- ) \ goto nth column
                GETCOLROW DROP 1- MIN GETXY DROP - SPACES ;

: #TAB          ( n1 -- )
                GETXY DROP OVER / 1+ * COL ;


\ -------------------- Deferred I/O  Part II --------------------------------

defer unload-forth ' noop is unload-forth         \ things to do at end

1 PROC ExitProcess

WinLibrary USER32.DLL
0 PROC IsWindow
1 PROC DestroyWindow

: k_BYE         ( -- )          \ Exit Forth
                d_uninit-console                     \ close Dos console if any
                _conHndl Call IsWindow               \ close console window if any
                IF _conHndl call DestroyWindow drop THEN
                unload-forth                         \ cleanup
                0 Call ExitProcess ;                 \ and exit Forth

\ NOTE: BYE shouldn't be redefered in an application.
\       Use the unload-chain instead.
DEFER BYE ' k_BYE IS BYE
DEFER MS  ' DROP  IS MS


\ -------------------- Windows Error functions ------------------------------

align HERE: K32GLE                          \ loaded in init-k32
1 PROC GetLastError
6 PROC FormatMessage

variable WinErrMsg 0 WinErrMsg !            \ win error flag

: GetLastWinErrMsg ( n -- addr )            \ build string for error message
                >R
                0 MAXCOUNTED 1-             \ buff len
                temp$ CHAR+                 \ buffer
                0 R> 0                      \ langid error null
                [ FORMAT_MESSAGE_FROM_SYSTEM FORMAT_MESSAGE_MAX_WIDTH_MASK OR ] literal
                call FormatMessage temp$ C! \ save length in buffer
                temp$ ;                     \ return buff

: GetLastWinErr ( -- n )              \ get windows error code
                call GetLastError     \ get error number
                dup GetLastWinErrMsg  \ create error message
                WinErrMsg @
                if  THROW_WINERR NABORT!
                else drop             \ remove error message
                then ;                \ return error code

CODE TRTNZ      ( addr len table -- addr' len' code ) \ translate & test a buffer, stop at ~0
                pop     ecx                           \ buffer length
                pop     eax                           \ buff address
                push    edx                           \ save UP
                xor     edx, edx                      \ zero edx
                test    ecx, ecx                      \ test ecx
                jmp     short @@3                     \ start
@@2:            movzx   edx, byte ptr 0 [eax]         \ get the char from the buffer
                movzx   edx, byte ptr 0 [ebx] [edx]   \ get the code from the table
                test    edx, edx                      \ if it's non zero
                jnz     short @@4                     \ found a char
                add     eax, # 1                      \ up one char in buffer
                sub     ecx, # 1                      \ one less char to scan
@@3:            jg      short @@2                     \ not end, so next char
                xor     ecx, ecx                      \ otherwise zero ecx
@@4:            mov     ebx, edx                      \ save the code found
                pop     edx                           \ restore UP
                push    eax                           \ save the address we got to
                push    ecx                           \ and the length
                next    c;

CODE TRTZ       ( addr len table -- addr' len' )      \ translate & test a buffer, stop at =0
                pop     ecx                           \ buffer length
                pop     eax                           \ buff address
                push    edx                           \ save UP
                xor     edx, edx                      \ zero edx
                test    ecx, ecx                      \ test ecx
                jmp     short @@3                     \ start
@@2:            movzx   edx, byte ptr 0 [eax]         \ get the char from the buffer
                movzx   edx, byte ptr 0 [ebx] [edx]   \ get the code from the table
                test    edx, edx                      \ if it's zero
                jz      short @@4                     \ found a char
                add     eax, # 1                      \ up one char in buffer
                sub     ecx, # 1                      \ one less char to scan
@@3:            jg      short @@2                     \ not end, so next char
                xor     ecx, ecx                      \ otherwise zero ecx
@@4:            pop     edx                           \ restore UP
                push    eax                           \ save the address we got to
                mov     ebx, ecx                      \ and the length
                next    c;

CODE TR         ( addr len table -- )                 \ translate a buffer
                pop     ecx                           \ length to translate
                pop     edi                           \ address of string
                push    edx                           \ save edx
                add     ecx, edi                      \ point ecx at last char
                xor     eax, eax                      \ zero eax
                jmp     short @@2                     \ start
@@1:            mov     al, 0 [edi]                   \ get the char
                mov     dl, [ebx] [eax]               \ translate it
                mov     0 [edi], dl                   \ and store it back
                inc     edi                           \ point at next character
@@2:            cmp     edi, ecx                      \ past end of string?
                jb      short @@1                     \ no, back round
                xor     edi, edi                      \ zero edi
                pop     edx                           \ restore edx
                pop     ebx                           \ adjust stack
@@9:            next    c;

\ -------------------- UPPER/lower functions ------------------------

CODE UPC        ( char -- char )                 \ convert char to uppercase
                cmp     ebx, # 256
                jae     short @@9                \ don't convert if too big
                mov     bl, ucasetab [ebx]       \ translate
@@9:            next    c;

: UPPER         ( addr len -- )                  \ translate string to uppercase
                ucasetab tr ;                    \ use tr to do the work

: LOWER         ( addr len -- )                  \ translate string to lowercase
                lcasetab tr ;                    \ use tr to do the work

NCODE UPPERCASE ( str -- str )                   \ translate to uppercase, but not '.' or '.
                mov     eax, 0 [ebx]             \ get characters
                movzx   ecx, al                  \ length in ecx
                and     eax, # 0xFF00FFFF        \ mask all but single quotes
                cmp     eax, # 0x27002703        \ is it '.' ?
                je      short @@5                \ yes, so leave
@@4:            push    ebx                      \ ( str
                inc     ebx
                push    ebx                      \ ( str str+1
                push    ecx                      \ ( str str+1 len
                mov     ebx, # ucasetab          \ ( str str+1 len table )
                mov     eax, # ' TR              \ translate ( -- str )
                exec
@@5:            next    c;                       \ leave now


\ -------------------- Number Input --------------------

CODE DIGIT      ( char base -- n flag )
                mov     eax, 0 [esp]
                sub     al, # 48
                jb      short @@1
                cmp     al, # 9
                jbe     short @@2
                sub     al, # 7
                cmp     al, # 10
                jb      short @@1
@@2:            cmp     al, bl
                jae     short @@1
                mov     0 [esp], eax
                mov     ebx, # -1
                jmp     short @@3
@@1:            sub     ebx, ebx
@@3:            next    c;

CODE >NUMBER    ( ud addr len -- ud addr len )
                test    ebx, ebx                \ check if anything to convert
                je      short @@4               \ zero, so skip
                mov     -4 [ebp], esi
                mov     -8 [ebp], edx           \ save UP
                mov     esi, 0 [esp]            \ esi = address
                mov     edi, BASE [UP]          \ get the number base
@@1:            movzx   eax, byte 0 [esi]       \ get next digit
                cmp     al, # '0'
                jb      short @@3               \ if below '0' branch to done
                cmp     al, # '9'
                jbe     short @@2               \ go convert it
                and     al, # 0xDF              \ convert to uppercase
                cmp     al, # 'A'               \ if below 'A'
                jb      short @@3               \ then branch to done
                sub     al, # 7
@@2:            sub     al, # '0'
                cmp     eax, edi
                jae     short @@3               \ out of base range
                xchg    eax, 1 CELLS [esp]      \ high word * base
                mul     edi
                xchg    eax, 2 CELLS [esp]      \ low word * base
                mul     edi
                add     eax, 1 CELLS [esp]      \ add
                adc     edx, 2 CELLS [esp]
                mov     2 CELLS [esp], eax      \ store result
                mov     1 CELLS [esp], edx
                add     esi, # 1
                sub     ebx, # 1
                jnz     short @@1
@@3:            mov     0 CELLS [esp], esi      \ address of unconvertable digit
                mov     esi, -4 [ebp]
                mov     edx, -8 [ebp]           \ save UP
                xor     edi, edi                \ edi is zero
@@4:            next    c;

0  VALUE DOUBLE?                                \ double value
-1 VALUE DP-LOCATION                            \ decimal point location
0  value -ve-num?                               \ negate value flag

: num-init      ( -- )                          \ initialise number values
                false to double?
                -1 to dp-location
                false to -ve-num?
                ;

\ simple version of number

: (NUMBER?)     ( addr len -- d1 f1 )
                num-init
                OVER C@ [CHAR] - =
                dup to -ve-num? negate /string
                0 0 2swap >number nip
                if false exit then             \ leave if not all converted
                -ve-num? if dnegate then true ;

: ?MISSING      ( f -- )
                0= THROW_UNDEFINED AND THROW ;

|: (NUMBER)     ( str -- d )
                UPPERCASE COUNT (NUMBER?) ?MISSING ;

DEFER NUMBER   ' (NUMBER) IS NUMBER


\ -------------------- Number Output ----------------------------------------

: DECIMAL       10 BASE ! ;
: HEX           16 BASE ! ;
: BINARY         2 BASE ! ;
: OCTAL          8 BASE ! ;

CODE HOLD       ( char -- ) \ insert char in number output picture - see <#
                mov     eax, HLD [UP]
                sub     eax, # 1
                mov     0 [eax], bl
                mov     HLD [UP], eax
                pop     ebx
                next    c;

: <#            ( ud -- ) \ begin a pictured number output. Full example :
                \ : test dup 0< if negate -1 else 0 then >r
                \        s>d <# [char] $ hold # # [char] . hold # # # [char] , hold #S r> sign #>
                \        cr type ;
                \  1234599 test    displays    12,345.99$
                \ -1234599 test    displays   -12,345.99$
                PAD HLD ! ;

: #>            ( d1 -- addr len ) \ ends a pictured number output - see <#
                2DROP  HLD @ PAD OVER - ;

: SIGN          ( f1 -- ) \ insert a sign in pictured number output - see <#
                0< IF  [CHAR] - HOLD  THEN ;

CODE #          ( d1 -- d2 ) \ convert a digit in pictured number output - see <#
                push    edx                     \ save UP
                mov     ecx, BASE [UP]
                sub     edx, edx
                mov     eax, ebx
                div     ecx
                mov     ebx, eax
                mov     eax, 4 [esp]
                div     ecx
                mov     4 [esp], eax
                mov     eax, edx
                pop     edx                     \ restore UP
                cmp     al, # 9
                jbe     short @@1
                add     al, # 7
@@1:            add     al, # CHAR 0
                mov     ecx, HLD [UP]
                sub     ecx, # 1
                mov     0 [ecx], al
                mov     HLD [UP]  , ecx
                next    c;

: #S            ( d1 -- d2 ) \ consume last digits in a pictured number output - see <#
                BEGIN  #  2DUP OR 0= UNTIL ;

: (D.)          ( d -- addr len ) \ convert as signed double to ascii string
                TUCK DABS  <# #S ROT SIGN #> ;
: D.            ( d -- ) \ display as signed double
                (D.) TYPE SPACE ;
: D.R           ( d w -- ) \ display as signed double right justified in w wide field
                >R (D.) R> OVER - SPACES TYPE ;
: .             ( n -- ) \ display as signed single
                S>D  D. ;
: .R            ( n w -- ) \ display as signed single right justified in w wide field
                >R  S>D  R>  D.R ;
: U.            ( u -- ) \ display as unsigned single
                0 D. ;
: U.R           ( u w -- ) \ display as unsigned single right justified in w wide field
                0 SWAP D.R ;
: H.            ( u -- ) \ display as signed single in hexadecimal whatever BASE is
                BASE @ SWAP  HEX U.  BASE ! ;
: ?             ( addr -- ) \ display single stored at address
                @ . ;

in-system

: .ID           ( nfa -- ) \ display header's name
                COUNT TYPE SPACE ;

in-application

\ -------------------- Parse Input Stream --------------------

\ WORD doesn't met the ANS-Standard in Win32Forth.
\ The standrad reqires that a space, not included in the length, must follow
\ the string. In Win32Forth a NULL follow's the string.
CODE WORD       ( char "<chars>ccc<char>" -- c-addr ) \ parse the input stream
                \ for a string delimited by char. Skip all leading char. Give a
                \ counted string (the string is ended with a null, not included
                \ in count). Use only inside colon definition.
                push    esi
                mov     al, bl                  \ al = delimiter
                mov     edi, S_ADR              \ edi = input pointer
                add     edi, >IN                \ add >in
                mov     ecx, S_LEN              \ ecx = input length
                sub     ecx, >IN                \ subtract >in
                ja      short @@9
                xor     ecx, ecx                \ at end of input
                jmp     short @@8
@@9:            cmp     al, # 32
                jne     short @@5
        \ Delimiter is a blank, treat all chars <= 32 as the delimiter
@@1:            cmp     0 [edi], al             \ leading delimiter?
                ja      short @@2
                add     edi, # 1                \ go to next character
                sub     ecx, # 1
                jnz     short @@1
                mov     esi, edi                \ esi = start of word
                mov     ecx, edi                \ ecx = end of word
                jmp     short @@7
@@2:            mov     esi, edi                \ esi = start of word
@@3:            cmp     0 [edi], al             \ end of word?
                jbe     short @@4
                add     edi, # 1
                sub     ecx, # 1
                jnz     short @@3
                mov     ecx, edi                \ ecx = end of word
                jmp     short @@7
@@4:            mov     ecx, edi                \ ecx = end of word
                add     edi, # 1                \ skip over ending delimiter
                jmp     short @@7
        \ delimiter is not a blank
@@5:            repz    scasb
                jne     short @@6
                mov     esi, edi                \ end of input
                mov     ecx, edi
                jmp     short @@7
@@6:            sub     edi, # 1                \ backup
                add     ecx, # 1
                mov     esi, edi                \ esi = start of word
                repnz   scasb
                mov     ecx, edi                \ ecx = end of word
                jne     short @@7
                sub     ecx, # 1                \ account for ending delimiter
        \ Update >IN pointer and get word length
@@7:            sub     edi, S_ADR              \ offset from start
                mov     >IN , edi               \ update >IN
                sub     ecx, esi                \ length of word
                cmp     ecx, # MAXCOUNTED       \ max at MAXCOUNTED
                jbe     short @@8
                mov     ecx, # MAXCOUNTED       \ clip to MAXCOUNTED
        \ Move string to pocket
@@8:            mov     edi, ' POCKET >BODY     \ edi = pocket
                mov     0 [edi], cl             \ store count byte
                add     edi, # 1
                rep     movsb                   \ move rest of word
                xor     eax, eax                \ clear EAX
                stosb                           \ append a NULL to pocket
                xor     edi, edi                \ edi is zero
                pop     esi
                mov     ebx, ' pocket >BODY  \ return pocket
                next    c;

CODE PARSE-WORD ( "<spaces>name" -- c-addr u ) \ parse the input stream
                \ for a string delimited by spaces. Skip all leading spaces.
                \ Give the string as address and count.
                push    ebx
                mov     eax, S_ADR              \ edi = input pointer
                add     eax, >IN                \ add >in
                push    eax                     \ address of output eax = input char
                mov     ecx, S_LEN              \ ecx = input length
                sub     ecx, >IN                \ subtract >in
                ja      short @@1
                xor     ecx, ecx                \ at end of input
                jmp     short @@8

@@1:            cmp     byte 0 [eax], # 32      \ leading delimiter?
                ja      short @@2
                add     eax, # 1                \ go to next character
                sub     ecx, # 1
                jnz     short @@1

                mov     ebx, eax                \ ebx = start of word
                mov     ecx, ebx                \ ecx = end of word
                jmp     short @@7

@@2:            mov     ebx, eax                \ ebx = start of word
@@3:            cmp     byte 0 [eax], # 32      \ end of word?
                jbe     short @@4
                add     eax, # 1
                sub     ecx, # 1
                jnz     short @@3
                mov     ecx, eax                \ ecx = end of word
                jmp     short @@7

@@4:            mov     ecx, eax                \ ecx = end of word
                add     eax, # 1                \ skip over ending delimiter
                                                \ update >IN pointer and get word length
@@7:            sub     eax, S_ADR              \ offset from start
                mov     >IN , eax               \ update >IN
                sub     ecx, ebx                \ length of word
                mov     0 [esp], ebx            \ save on stack
@@8:            mov     ebx, ecx                \ and length
                next    c;

CODE PARSE      ( char "ccc<char>" -- c-addr u ) \ parse the input stream
                \ for a string delimited by char. Skip ONLY ONE leading char.
                \ Give the string as address and count.
                mov     eax, S_ADR              \ edi = input pointer
                add     eax, >IN                \ add >in
                push    eax                     \ address of output
                push    edx
                mov     dl, bl                  \ char to scan for eax = input char
                mov     ecx, S_LEN              \ ecx = input length
                sub     ecx, >IN                \ subtract >in
                ja      short @@1
                xor     ecx, ecx                \ at end of input
                jmp     short @@8

@@1:            mov     ebx, eax                \ ebx = start of word
@@3:            cmp     byte 0 [eax], dl        \ end of word?
                je      short @@4
                add     eax, # 1
                sub     ecx, # 1
                jnz     short @@3
                mov     ecx, eax                \ ecx = end of word
                jmp     short @@7

@@4:            mov     ecx, eax                \ ecx = end of word
                add     eax, # 1                \ skip over ending delimiter
                                                \ update >IN pointer and get word length
@@7:            sub     eax, S_ADR              \ offset from start
                mov     >IN , eax               \ update >IN
                sub     ecx, ebx                \ length of word
                mov     4 [esp], ebx            \ save on stack
@@8:            mov     ebx, ecx                \ and length
                pop     edx
                next    c;

: .(            ( -- ) \ - interpretation only -  ( see also  ."  and  S" )
\ *G parses the input stream until it finds the next ) and
\ ** prints the text beetween .( and ) in the console window
                [CHAR] ) PARSE TYPE ; IMMEDIATE


\ -------------------- Header structure as of May 2003 ----------------------

\       [ link field       ] -4  +0       LFA
\   +-  [ cfa ptr field    ] +0   4       CFA-PTR
\   |   [ byte flag        ]  4   8       BFA
\   |   [ count byte       ]  5   9       NFA
\   |   [ the name letters ]  6  10
\   |   [ alignment bytes  ]  0 to 3 bytes for name alignment
\   |   [ view field       ]  n+0         VFA <- head-fields, all are optional
\   |   [ file field       ]  n+4         FFA
\   |   [ optimize field   ]  n+8         OFA
\   |
\   v
\       [ cfa  field       ] +0           CFA
\       [ body field       ] +4           PFA
\
\ BFA: MSB 8  128  IMMEDIATE flag
\          7   64  DEPRECATED flag
\          6   32  unused
\          5   16  unused
\          4    8  unused
\          3    4  OFA set if OFA is present
\          2    2  FFA set if FFA is present
\      LSB 1    1  VFA set if VFA is present

128 constant BFA_IMMEDIATE    \ bit of header's field BFA : true if word is immediate
 64 constant BFA_DEPRECATED   \ bit of header's field BFA : true if word is deprecated
 32 constant BFA_UNUSED3
 16 constant BFA_UNUSED2
  8 constant BFA_UNUSED1
  4 constant BFA_OFA_PRESENT  \ bit of header's field BFA : true if optimize field present
  2 constant BFA_FFA_PRESENT  \ bit of header's field BFA : true if file field present
  1 constant BFA_VFA_PRESENT  \ bit of header's field BFA : true if view field present

CODE >BODY      ( cfa -- pfa ) \ convert code field address to parameter field address
                add     ebx, # 4
                next    c;

CODE BODY>      ( pfa -- cfa ) \ convert parameter field address to code field address
                sub     ebx, # 4
                next    c;

9  offset  L>NAME   ( lfa -- nfa )
\ *G Convert link address to name address.
-9 offset  N>LINK   ( nfa -- lfa )
\ *G Convert name address to link address.
-5 offset  N>CFAPTR ( nfa -- cfa-ptr )
\ *G Convert name address to the address of the CFA pointer address.
-1 offset  N>BFA    ( nfa -- bfa )
\ *G Convert neme address to the address of the bit fields.

CODE LINK>      ( link -- cfa )
\ *G Convert the link address to the CFA (xt).
                mov     ebx, 4 [ebx]
                next    c;

CODE NAME>      ( nfa -- cfa )
\ *G Convert the name address to the CFA (xt).
                mov     ebx, -5 [ebx]
                next    c;

\ ' COUNT ALIAS NFA-COUNT            \ made a colon def - [cdo-2008May13]
: NFA-COUNT     ( nfa -- addr count )
                COUNT ;

\ -------------------- Vocabulary support ----------------------------------

VARIABLE CONTEXT #VOCS CELLS ALLOT     \ make context array of #VOCS+1 cells
VARIABLE CURRENT
VARIABLE LAST                   \ NFA of last header created
VARIABLE LAST-LINK              \ address of last link for last header created
VARIABLE VOC-LINK               \ linked list of vocabularies

\ Vocabularies; currently, these MUST be defined as specified

        1 #VOCABULARY ROOT              \ root vocab
           VOCABULARY FORTH             \ main vocabulary
\ #PTHREADS #LEXICON    PROCS             \ procs vocabulary; there's only 1
        1 #VOCABULARY LOCALS            \ locals vocab
#FTHREADS #VOCABULARY FILES             \ files vocab
#HTHREADS #VOCABULARY HIDDEN            \ hidden words

\ -------------------- Vocabulary dictionary structure ----------------------

\       [ cfa field        ] +0           VCFA = vocabulary cfa -> DOES> code
\       [ num voc threads  ] +4           #THREADS
\       [ voc link         ] +8           VLINK
\       [ voc header       ] +12          VHEAD
\       [ voc search       ] +16          VSRCH
\       [ voc iterate      ] +20          VITER
\       [ voc thread 0     ] +24          VOC thread 0 = voc-address
\       [ voc thread 1     ] +28          VOC thread 1
\       [ voc thread 2     ] +32          VOC thread 2
\       [ voc thread ...   ] +n*4+24      VOC thread n

0           EQU VCFA
VCFA  CELL+ EQU VTHRD
VTHRD CELL+ EQU VHEAD
VHEAD CELL+ EQU VSRCH
VSRCH CELL+ EQU VITER
VITER CELL+ EQU VLINK
VLINK CELL+ EQU VOC#0

DEFER VOC-ALSO
      ' NOOP IS VOC-ALSO                \ possibly for lookaside use

VOC#0 VLINK - OFFSET VLINK>VOC  ( voc-link-field -- voc-address )

VLINK VOC#0 - OFFSET VOC>VLINK  ( voc-address -- voc-link-field )

: VOC#THREADS ( voc-address -- #threads )       [ VTHRD VOC#0 - ] literal + @ ;

VOC#0 VCFA - OFFSET VCFA>VOC   ( vocabulary-cfa -- voc-address )

VCFA VOC#0 - OFFSET VOC>VCFA   ( voc-address -- vocabulary-cfa )

CFA-CODE DOVOC  ( -- )                  \ "runtime" for VOCABULARY
                add     eax, # 0 VCFA>VOC \ set CONTEXT to VOC address
                mov     context , eax
                next    c;

ASSEMBLER DOVOC META CONSTANT DOVOC

VARIABLE [UNKNOWN]                                      \ also used to store last cfa found

in-system

CODE >NAME      ( CFA -- NFA  )                         \ search vocabs for cfa, return nfa
\ Follows the VOC-LINK pointer to all of the vocabularies, searches threads for CFA
\ EBX is CFA to search for. On exit, EBX is NFA
\ Uses: EAX is voc link field, ECX is voc thread fields, EDX is thread link entry
\ If entry is not found, returns NFA of [UNKNOWN]
                push    edx                             \ save edx for now
                jmp     short @@1                       \ jump to start

@@8:            mov     ebx, # ' [unknown]              \ search for [unknown]

@@1:            mov     eax, # voc-link                 \ get vocab link

@@2:            mov     eax, 0 [eax]                    \ fetch next vocab in link
                or      eax, eax                        \ if it's zero, bail out
                jz      short @@8                       \ and search for [unknown] instead
                mov     ecx, VTHRD VLINK - [eax]        \ get vocab thread count
                lea     ecx, 0 VLINK>VOC [ecx*4] [eax]  \ point at last entry +1

@@3:            sub     ecx, # 4                        \ back one thread entry
                cmp     ecx, eax                        \ check the entry
                je      short @@2                       \ we're done, next vocab
                mov     edx, ecx                        \ point edx at thread link ptr

@@4:            mov     edx, 0 [edx]                    \ get contents of thread from thread link
                or      edx, edx                        \ ? no more thread ?
                jz      short @@3                       \ next thread if zero
                cmp     ebx, 4 [edx]                    \ does CFA match?
                jne     short @@4                       \ if they don't match, next entry

                lea     ebx, 0 L>NAME [edx]             \ ebx is the l>name (nfa)

                pop     edx                             \ restore edx
                next    c;

in-application

: N>HEAD        ( nfa -- head-fields )
                COUNT + 1+ ALIGNED ;

: >HEAD-FIELD   ( cfa mask -- addr  )           \ get the optional field's address
                [UNKNOWN] OFF                   \ set [unknown] to 0, just in case set
                >R >NAME DUP N>BFA C@           \ get byte field address value
                DUP R@ AND                      \ is our bit set?
                IF                              \ yes, so
                  R> DUP 1- + AND               \ get rid of all bits to the left
                  BIT-POP 1- CELLS              \ BIT-POP count cells offset (zero based)
                  SWAP N>HEAD +                 \ go to head, add in offset
                ELSE R>DROP 2drop [UNKNOWN] THEN  \ else no such field in header, point at [unknown]
                ;

: >VIEW         ( cfa -- vfa )
                BFA_VFA_PRESENT >HEAD-FIELD ;

: >VIEW@        ( cfa -- ffa )                  \ get the View Field Address
                >VIEW @ ;                       \ VFA is bit 1

: >FFA@         ( cfa -- ffa )                  \ get the File Field Address
                BFA_FFA_PRESENT >HEAD-FIELD @ ; \ FFA is bit 2

: >OFA@         ( cfa -- ofa@ )                 \ get the Optimization Field Address value
                BFA_OFA_PRESENT >HEAD-FIELD @ ; \ OFA is bit 3

: OFA-LAST      ( -- addr )                     \ address of last OFA
                LAST @ BFA_OFA_PRESENT >HEAD-FIELD ; \ return address


\ -------------------- Dictionary Search ------------------------------------

VARIABLE LATEST-NFA

CODE "#HASH     ( a1 n1 #threads -- n2 )
                pop     eax                     \ pop count into EAX
                mov     -4 [ebp], edx           \ save UP
                mov     -8 [ebp], ebx           \ save # of threads
                pop     ebx                     \ get string address into EBX
                mov     ecx, eax                \ copy count into ECX
                add     ebx, ecx
                neg     ecx
@@1:            rol     eax, # 7                \ rotate result some
                xor     al, [ebx] [ecx]
                add     ecx, # 1
                jl      short @@1               \ +ve, keep going
                xor     edx, edx                \ clear high part of dividend
                div     dword -8 [ebp]          \ perform modulus by #threads
                mov     ebx, edx                \ move result into EBX
                mov     edx, -4 [ebp]           \ restore UP
                lea     ebx, 0 [ebx*4]          \ multiply by cell size
                next    c;

CODE (SEARCH-WID) ( addr len voc -- 0 | cfa bfa ) \ this is the standard vocab vsrch
                                                  \ returns bfa = 1 for immediate words, and
                                                  \ bfa = -1 for "normal" words
                mov     -4 [ebp], esi           \ save esi
                mov     -8 [ebp], edi           \ and edi
                mov     -12 [ebp], edx          \ and edx
                mov     -16 [ebp], ebx          \ >r the wid
                sub     ebp, # 16               \ adjust ebp
                push    4 [esp]                 \ 2dup
                push    4 [esp]                 \ ( addr len addr len voc)
                mov     ebx, VTHRD VOC#0 - [ebx] \ ( addr len addr len #threads)
                fcall   "#hash                  \ ( addr len thread-offset)
                add     ebx, 0 [ebp]            \ ( addr len thread-entry)
                pop     eax                     \ eax = length
                mov     edx, 0 [esp]            \ str address

@@2:            mov     ebx, 0 [ebx]            \ follow link
                or      ebx, ebx                \ if top of stack = zero
                jz      short @@6               \ branch to exit, ebx=0=false

                movzx   ecx, byte 0 L>NAME [ebx] \ count byte
                cmp     ecx, eax                \ counts equal?
                jne     short @@2               \ next, follow through link

                mov     esi, 0 [esp]            \ esi = string address
                lea     edi, 1 L>NAME [ebx]     \ edi = name field after count
                repz    cmpsb
                jne     short @@2

                mov     eax, 0 >BODY [ebx]      \ cfa
                lea     ecx, 0 L>NAME [ebx]     \ ecx = name field
                mov     0 [esp], eax            \ this is the cfa
                mov     LATEST-NFA , ecx        \ save nfa for other use

                test    byte 0 L>NAME N>BFA [ebx], # BFA_IMMEDIATE \ get BFA field, test immediate
                mov     ebx, # -1                \ assume word is not immediate
                je      short @@9
                neg     ebx                     \ immediate, 1
                jmp     short @@9               \ leave

@@6:            add     esp, # 4                \ discard string address
@@9:            mov     esi, 12 [ebp]           \ restore esi edi edx
                mov     edi, 8 [ebp]
                mov     edx, 4 [ebp]
                add     ebp, # 16
                next    c;

NCODE (SEARCH-SELF) ( addr len wid -- 0 | cfa flag ) \ uses VSRCH to search this wordlist
                mov     eax, VSRCH VOC#0 - [ebx] \ fetch header word to execute
                exec    c;

: SEARCH-WORDLIST ( addr len wid -- 0 | cfa flag )
                  \ SEARCH-WORDLIST is case insensitive
                >R FIND-BUFFER PLACE
                FIND-BUFFER UPPERCASE COUNT
                R>
                (SEARCH-SELF) ;

\ changed to 0xff because filenames are compiled in the dictionary by
\ LINKFILE, and they can be up to 260 char's long. So this doesn't fix our
\ problem with LINKFILE completely but 255 char's are more close to 260 than 63.
\ September 9th, 2003 - 15:23 dbu
0xff VALUE NAME-MAX-CHARS                 \ function names can be this long


|: (FIND)       ( str -- str FALSE | cfa flag )
\ WARNING: (FIND) is a case sensitive find.  If you need to be able to find
\ words in the dictionary that have not already been passed through UPPERCASE,
\ then you should use CAPS-FIND which will uppercase the string before trying
\ to find it in the dictionary.
                DUP C@
                IF
                  CONTEXT
                  BEGIN   DUP @                   \ while not at end of list
                  WHILE   DUP 2@ <>               \ and not the same vocabulary as NEXT time
                    IF OVER COUNT NAME-MAX-CHARS MIN
                      2 PICK @ (SEARCH-SELF) ?DUP
                      IF 2NIP                     \ found it, so
                        exit                     \ we're done searching
                      THEN
                    THEN CELL+                    \ step to next vocabulary
                  REPEAT DROP
                THEN FALSE ;

\ CAPS-FIND readded, which was lost sometime in the past, but it can be used
\ in real application's (e.g. Brad Eckert is useing it in his "Firmware Studio").
\ Samstag, Mai 15 2004 - dbu
: CAPS-FIND     ( str -- str FALSE | cfa flag )
                UPPERCASE (FIND) ;

DEFER FIND      ( str -- str 0 | cfa flag )

: DEFINED       ( -- str 0 | cfa flag )
                BL WORD PARMFIND ;    \ parmfind defined in locals section

\ -------------------- Vector Variables --------------------

\ Define the Forth base image pointer constants. These constants contain
\ information about the current size (x-SIZE),
\ and the offset to the next section (x-OFFS). They are set by
\ META compile, or adjusted when an image is FSAVEd.
\

0 CONSTANT CODE-SIZE                 \ values set in meta compile
0 CONSTANT CODE-OFFS
0 CONSTANT APP-SIZE
0 CONSTANT APP-OFFS
0 CONSTANT SYS-SIZE
0 CONSTANT SYS-OFFS
0 CONSTANT IMG-ENTRY

\ -------------------- Compiling words ----------------------------

\  DP is the current data pointer, DP @ is the equivalent of HERE
\
\  Each set of pointers to a data ("dictionary") space is a structure.
\  These structures MUST RESIDE IN THE APPLICATION SPACE if they are linked
\
\  CELL OFFSET  FUNCTION
\  ---- ------  --------
\   0     0     Current pointer to area
\   1     4     Address of the area (origin)
\   2     8     Highest address of area (origin + length)
\   4    16     Link of all the xDP areas; set in DP-LINK
\   5    20     Counted name of the area
\
\  3 defined by default; APP -- std area, SYS -- system area, not saved on
\  TURNKEY and CODE -- area for executable x86 code.
\
\  Actual values for these 3 are filled in by the meta compiler.
\  See also PDP and LDP (procs and locals data respectively)

VARIABLE DP-LINK                 \ list of xDP structures
         0 DP-LINK !

CREATE SDP  0 , 0 , 0 , DP-LINK LINK, ," SYS"  \ system
CREATE ADP  0 , 0 , 0 , DP-LINK LINK, ," APP"  \ application
CREATE CDP  0 , 0 , 0 , DP-LINK LINK, ," CODE" \ code

ADP VALUE  DP                    \ data pointer defaults to app space
ADP VALUE ODP                    \ data pointer defaults to app space

\ ----------------- Switching dictionary words ---------------

\ To switch between data areas, >DP saves and resets the data pointer.
\ NOTE: >DP does a "double UNNEST", so >DP must be the last word in
\       any definition that uses it.
\
\ IN-xxxx is used in open code to switch HERE ALLOT , W, etc to point
\ to the specific data area; the current DP is saved in ODP, so
\ it can be reseted using IN-PREVIOUS.
\
\ >XXXX and XXXX> move to and from a specific data area, and save the
\ current DP. Should only be used in code, as the return stack is used
\ to save/restore the current value, and must be used in matching pairs.
\

: IN-APPLICATION ( -- )         \ w32f
\ *G Activate the application data area.
        DP TO ODP ADP TO DP ;

: IN-SYSTEM      ( -- )         \ w32f
\ *G Activate the system data area.
        DP TO ODP SDP TO DP ;

: IN-CODE        ( -- )         \ w32f
\ *G Activate the code data area.
        DP TO ODP CDP TO DP ;

: IN-PREVIOUS    ( -- )         \ w32f
\ *G Restore the data area after a call to IN-APPLICATION IN-SYSTEM or IN-CODE.
        ODP TO DP ;

: >DP           ( dp -- ) \ save the current DP, set new
                R>DROP DP R> 2>R TO DP ;
: >APPLICATION  ( -- ) \ select app dict, save prev dict
                ADP >DP ;
: >SYSTEM       ( -- ) \ select sys dict, save prev dict
                SDP >DP ;
: >CODE         ( -- ) \ select code dict, save prev dict
                CDP >DP ;

: DP>           ( -- ) \ back to previous DP
                2R> >R TO DP ;
\ ' DP> ALIAS SYSTEM>             \ made a colon def - [cdo-2008May13]
\ ' DP> ALIAS APPLICATION>        \ made a colon def - [cdo-2008May13]
\ ' DP> ALIAS CODE>               \ made a colon def - [cdo-2008May13]
: SYSTEM>       ( -- ) \ back to previous DP  (synonym of DP>)
                2R> >R TO DP ;
: APPLICATION>  ( -- ) \ back to previous DP  (synonym of DP>)
                2R> >R TO DP ;
: CODE>         ( -- ) \ back to previous DP  (synonym of DP>)
                2R> >R TO DP ;

: APP-ORIGIN    ( -- a1 ) ADP CELL+ @ ;
: SYS-ORIGIN    ( -- a1 ) SDP CELL+ @ ;
: CODE-ORIGIN   ( -- a1 ) CDP CELL+ @ ;

: HERE          ( -- a1 ) ( current dictionary pointer, points to next free space)
                DP @ ;
: ,             ( n -- )  ( compile cell at HERE, increment DP)
                HERE  ! CELL DP +!  ;
: W,            ( n -- )  ( compile word at HERE, increment DP)
                HERE W! 2    DP +!  ;
: C,            ( n -- )  ( compile byte at HERE, increment DP)
                HERE C!      DP INCR ;

|: MEM-FREE     ( -- N1 ) DP 2 CELLS+ @ HERE - ;

: ?MEMCHK       ( n1 -- ) \ test to see if we have enough memory
                MEM-FREE > if
                  dp 4 cells+ count temp$ place
                  temp$ THROW_OUTOFMEM NABORT!
                then
                ;

: ALLOT         ( n -- ) \ allocate n bytes at HERE, increment DP
                DUP 1000 + ?MEMCHK DP +! ;

: SYS-ADDR?     ( a -- f )                \ is it a system address?
                SYS-ORIGIN [ SDP 2 CELLS+ ] LITERAL @ WITHIN ;

: IN-SYS?       ( -- f ) DP SDP = ;       \ true flag if the DP is set to SDP
\ : IN-CODE?      ( -- f ) DP CDP = ;       \ true flag if the DP is set to CDP
\ : IN-APP?       ( -- f ) DP ADP = ;       \ true flag if the DP is set to ADP

TRUE VALUE DUP-WARNING?
: DUP-WARNING-OFF ( -- ) \ disable warning for redefinitions
                FALSE TO DUP-WARNING? ;

: DUP-WARNING-ON  ( -- ) \ enable warning for redefinitions
                TRUE  TO DUP-WARNING? ;

TRUE VALUE SYS-WARNING?

: SYS-WARNING-OFF ( -- ) \ disable warning for use of system words in application
                FALSE TO SYS-WARNING? ;

: SYS-WARNING-ON  ( -- ) \ enable warning for use of system words in application
                TRUE  TO SYS-WARNING? ;

|: (syswarn)	( xt -- xt ) \ warn if system word in app word
                DUP SYS-ADDR?                   \ address in system space
                IN-SYS? 0= AND                  \ not currently system pointer
                IF WARN_SYSWORD WARNMSG THEN ;

: COMPILE,      ( xt -- ) \ compile (same as , but with warning)
		SYS-WARNING? if (syswarn) then \ warn if system word in app word
		, ;

CODE COMPILE    ( -- )                          \ compile xt following
                push    ebx
                mov     ebx, [esi]
                add     esi, # 4
                mov     eax, # ' COMPILE,
                exec    c;

CODE ALIGNED    ( addr1 -- addr2 ) \ addr2 is the next cell aligned address following addr1
                add     ebx, # 3
                and     ebx, # -4
                next    c;

: ALIGN         ( -- ) \ align DP & pad
                DP CDP = IF 0x90 ELSE 0 THEN    \ pad is nop for code area
                HERE DUP ALIGNED SWAP - 0 ?DO DUP C, LOOP DROP ;

CODE -ALIGNED   ( addr1 -- addr2 )
                and     ebx, # -4
                next    c;

CODE NALIGNED   ( addr n -- addr2 )
                mov     eax, ebx         \ n
                sub     eax, # 1         \ n-1
                neg     ebx              \ -n
                pop     ecx              \ addr
                add     eax, ecx         \ addr+n-1
                and     ebx, eax         \ addr+n-1 and -n
                next    c;

: TURNKEYED?    ( -- f )      \ return true if running as a Turnkey application
                SYS-SIZE 0= ;

: APP-FREE      ( -- n1 ) >APPLICATION  MEM-FREE   APPLICATION> ;
: APP-HERE      ( -- a ) ADP @ ;
: APP-ALLOT     ( n1 -- ) >APPLICATION  ALLOT      APPLICATION> ;
: APP-ALIGN     ( -- )    >APPLICATION  ALIGN      APPLICATION> ;

: SYS-FREE      ( -- n1 ) >SYSTEM       MEM-FREE   SYSTEM>      ;
: SYS-HERE      ( -- a ) SDP @ ;
: SYS-ALLOT     ( n1 -- ) >SYSTEM       ALLOT      SYSTEM>      ;
: SYS-,         ( n -- )  >SYSTEM       ,          SYSTEM>      ;
: SYS-W,        ( n -- )  >SYSTEM       W,         SYSTEM>      ;
: SYS-C,        ( n -- )  >SYSTEM       C,         SYSTEM>      ;
: SYS-COMPILE,  ( xt -- ) >SYSTEM       COMPILE,   SYSTEM>      ;
: SYS-COMPILE   ( -- )    >SYSTEM       COMPILE    SYSTEM>      ;
: SYS-ALIGN     ( -- )    >SYSTEM       ALIGN      SYSTEM>      ;

: CODE-FREE     ( -- n1 ) >CODE         MEM-FREE   CODE>        ;
: CODE-HERE     ( -- a ) CDP @ ;
: CODE-ALLOT    ( n1 -- ) >CODE         ALLOT      CODE>        ;
: CODE-,        ( n -- )  >CODE         ,          CODE>        ;
: CODE-W,       ( n -- )  >CODE         W,         CODE>        ;
: CODE-C,       ( n -- )  >CODE         C,         CODE>        ;
: CODE-ALIGN    ( -- )    >CODE         ALIGN      CODE>        ;

: IMMEDIATE     ( -- )  \ mark the last header created as an immediate word
                LAST @ N>BFA BFA_IMMEDIATE TOGGLE ;

\ Deprecated words will be removed from Win32Forth some time in the
\ future. When a deprecated word is used a warning message will be showen.
: DEPRECATED    ( -- )  \ mark the last header created as a deprecated word
                LAST @ N>BFA BFA_DEPRECATED TOGGLE ;

: HIDE          ( -- ) LAST @ N>LINK @ LAST-LINK @ ! ;

: REVEAL        ( -- ) LAST @ N>LINK LAST-LINK @ ! ;

\ in-system

: LITERAL       ( n -- )
                COMPILE LIT , ; IMMEDIATE \ moved to application space to avoid messages.

\ in-application

: CHAR          ( <c> -- char ) \ parse char from input stream and put its ascii
                \ code on stack. If <c> is longer than a char, takes its first char.
                BL WORD 1+ C@ ;

: '             ( <name> -- cfa ) \ get cfa of parsed word
                DEFINED ?MISSING ;
in-system

: [COMPILE]     ( -<name>- ) \ compile the xt of word <name>
                ' COMPILE, ; IMMEDIATE

: [CHAR]        ( <c> -- char ) \ parse char from input stream and compile its
                \ ASCII value as a literal
                CHAR [COMPILE] LITERAL ; IMMEDIATE

: [']           ( -<name>- ) \ compile xt of <name> as a literal
                ' [COMPILE] LITERAL ; IMMEDIATE

: POSTPONE      ( -<name>- ) \ compilation only - compile xt of word
                DEFINED DUP ?MISSING
                0< IF COMPILE COMPILE THEN
                COMPILE, ; IMMEDIATE
in-application

\ -------------------- Link Operations (Single Linked)  --------------------



\ *P Single linked lists have a cell which points to the first element (or contains 0 for
\ ** an empty list. The cell can be a variable or element of an array. Do not use VALUES
\ ** for this as they don't work correctly.

: DO-LINK       ( i*x xt list -- j*x ) \ W32F        List
\ *G Apply input function, xt to each element of the list in turn. i*x and j*x are the
\ ** input(s) to and output(s) of xt (normally the number of inputs=number of outputs).
\ *P Usage: [parms] ' x link do-link \n
\ ** Follows link, for each link executes x. x must have a stack picture
\ ** ( [parms ...] link -- [parms ...] ).
\ ** Safe to use even if x destroys next link and can be used recursively.
                swap >r @ >r                      \ save cfa, next link address
                begin r>  ?dup                    \ check the address
                while dup @ r@ swap >r            \ get link, get cfa, & save next pointer
                      execute                     \ execute the cfa
                repeat r>drop ;                   \ drop saved cfa

CODE ADD-LINK   ( addr list -- )      \ W32F         List
\ *G Add a link to the head of a list.
                pop    eax                        \ fetch addr
                mov    ecx , 0 [ebx]              \ fetch address pointed to by link
                mov    0 [eax], ecx               \ point addr at pointed to
                mov    0 [ebx], eax               \ point link at addr
                pop    ebx                        \ clear stack
                next   c;

CODE APPEND-LINK ( addr list -- )     \ W32F         List
\ *G Append a link to the end of a list.
@@1:            mov     ecx, 0 [ebx]              \ get next link
                test    ecx, ecx                  \ is next link zero?
                jz      short @@2                 \ yes, found last entry
                mov     ebx, ecx                  \ get next link
                jmp     short @@1                 \ and back
@@2:            pop     eax                       \ get address to add in eax
                mov     0 [ebx], eax              \ save in link field
                mov     0 [eax], ecx              \ zero the link in added entry
                pop     ebx                       \ clear stack
                next    c;

CODE UN-LINK    ( addr link -- f1 )    \ W32F        List
\ *G Unlink addr from list. f1 is 0 if addr was removed from list or non-zero if addr
\ ** wasn't in the list.
                pop     eax                       \ ebx=link, eax=addr
@@1:            mov     ecx, 0 [ebx]              \ link @
                or      ecx, ecx                  \ if zero
                jz      short @@8                 \ failed to find
                cmp     eax, ecx                  \ my link?
                je      short @@2                 \ yes, go unlink
                mov     ebx, ecx                  \ next link
                jmp     short @@1                 \ back round

@@2:            mov     ecx, 0 [eax]              \ fetch me
                mov     0 [ebx], ecx              \ prev=me
                xor     ebx, ebx                  \ tos=0
                jmp     short @@9                 \ exit

@@8:            mov     ebx, # -1                 \ tos=-1
@@9:            next    c;

: LINK,         ( list -- )      \ W32F           List
\ *G Add a link in the dictionary (i.e. at here) to the head of the list.
                HERE OVER @ , SWAP ! ;


\ -------------------- String Literals --------------------------------------

\ Convert occurances of \N within string a1,n1 to the CRLF pairs.
\ Useful mostly for strings that will get passed to the operating system.

DEFER \N->CRLF  ( a1 n1 -- )    ' 2DROP IS \N->CRLF

: ",            ( a1 n1 -- )    \ compile string a1,n1 as a counted string at here
                HERE OVER C, OVER ALLOT 1+ SWAP CMOVE
                ;

: ,"            ( -<string">- ) \ compile string delimited by " as a counted string at here
                HERE [CHAR] " PARSE ", 0 C, ALIGN COUNT \N->CRLF
                ;

: Z",           ( addr len -- )            \ W32F     String Extra
\ *G compile the string, addr len as uncounted chars at here
                HERE OVER ALLOT swap cmove ;

: Z,"           ( -<string">- )  \ compile string delimited by " as uncounted
                \ chars null-terminated chars at here
                HERE [CHAR] " PARSE Z", 0 C, ALIGN ZCOUNT \N->CRLF
                ;

DEFER NEW$    ' TEMP$ IS NEW$           ( -- addr )

|: ((P"))       ( -- addr len buff buff )    \ internal for ((x")) words
                [CHAR] " PARSE NEW$ DUP ;

|: ((S"))       ( -<string>- -- add len )    \ for state = not compiling
                ((P")) >R SWAP DUP>R MOVE 2R> ;

|: ((C"))       ( -<string>- -- addr )       \ for state = not compiling
                ((P")) >R PLACE R> ;

NCODE (C")      ( -- addr )                    \ for c" type strings
                push    ebx
                movzx   ecx, byte ptr [esi]    \ length of string
                mov     ebx, esi               \ start of the string in TOS
                lea     esi, 9 [ecx] [ebx]     \ optimised next, account for len & null at end
                and     esi, # -4              \ align
                mov     eax, -4 [esi]          \ next word
                exec    c;                     \ go do it

NCODE (S")      ( -- addr len )                \ for s" type strings
                push    ebx
                lea     ecx, 1 [esi]           \ start of string
                movzx   ebx, byte ptr [esi]    \ length of string in TOS
                push    ecx                    \ save addr of string
                lea     esi, 8 [ecx] [ebx]     \ optimised next, account for len & null at end
                and     esi, # -4              \ align
                mov     eax, -4 [esi]          \ next word
                exec    c;                     \ go do it

NCODE (Z")      ( -- addr )                    \ for z" type strings
                push    ebx
                lea     ebx, 1 [esi]           \ start of string in TOS
                movzx   ecx, byte ptr [esi]    \ length of string
                lea     esi, 8 [ecx] [ebx]     \ optimised next, account for len & null at end
                and     esi, # -4              \ align
                mov     eax, -4 [esi]          \ next word
                exec    c;                     \ go do it

NCODE (.")      ( -- addr len )                \ for ."
                push    ebx
                lea     ecx, 1 [esi]           \ start of string
                movzx   ebx, byte ptr [esi]    \ length of string in TOS
                push    ecx                    \ save addr of string
                lea     esi, 4 [ecx] [ebx]     \ optimised next, account for len & null at end
                and     esi, # -4              \ align
                mov     eax, # ' TYPE          \ next word
                exec    c;                     \ go do it

in-system

: C"            \ comp: ( -<string">- ) run: \ ( -- addr )
                \ compile a string, delimiteb by " , from input stream. When
                \ run, give the string as the address of its count byte
                STATE @
                IF      COMPILE (C")  ,"
                ELSE    ((C"))
                THEN ; IMMEDIATE

: S"            \ comp: ( -<string">- ) run: ( -- addr len )
\ *G Compiletime: s" parses the input stream until it finds the next " and
\ ** compiles it into the current definition. Runtime: s" leaves the address
\ ** and the length of the compiled string on the stack.
                STATE @
                IF      COMPILE (S")  ,"       \ see  also ."  and  .(
                ELSE    ((S"))
                THEN ; IMMEDIATE

: Z"            ( -<string">- )  \ If compiling puts string in the dictionary
                STATE @          \ or else it puts the address and length n the stack
                IF   COMPILE (Z")  ,"
                ELSE ((C")) dup dup c@ + 1+ 0 swap c! 1+
                THEN ; IMMEDIATE

: ."            \ comp: ( -<string">- ) run: ( -- ) \ See also  s"  and  .(
\ *G Compiletime: Parses the input stream until it finds the next " and
\ ** compiles it into the current definition.
\ ** Runtime: Prints the compiled text to the console window
                COMPILE (.") ," ; IMMEDIATE

in-application

: SLITERAL      ( a1 n1 -- )                    \ compile string as literal
                COMPILE (S")
                HERE >R ", 0 C, ALIGN R> COUNT \N->CRLF ; IMMEDIATE

\ tjz, as posted from Bernd Paysan Thu, 05 Jul 2001  Thanks Bernd

: /parse        ( -- addr u )
                >in @ char swap >in ! dup '"' = over ''' =
                or IF  dup parse 2drop  ELSE  drop bl  THEN  parse ;

: /parse-word   ( -- a1 )
                /parse pocket place     \ word may start with ' or " into pocket
                pocket +null            \ make sure it is null terminated
                pocket ;

: /parse-s$     ( -- a1 )               \ parse possibly quoted string
                source >in @ /string    \ addr len of where we are
                bl skip nip             \ skip blanks
                source rot - >in ! drop \ adjust >in
                /parse-word
                ;

\ -------------------- LIB and PROC structures -----------------------

\ LIB structure as of Aug 12 2003
\
\       [ link field       ]  0         LFA  LIB link field
\       [ libhandle        ]  4         HANDLE of the library after load
\       [ name             ]  8         NAME counted string
\
\
\ PROC structure as of Oct 2003
\
\       [ link field       ]  0         LFA  PROC link field
\       [ cfa ptr field    ]  4         CFA  DOCALL
\       [ entry point      ]  8         EP   entry point
\       [ lib struct ptr   ]  12        LIB  ptr to lib entry
\       [ parm&flags       ]  16        PCNT Parm counter & flags
\       [ name             ]  17        NAME counted string
\
\ PCNT: MSB 8  128  UNKNOWN#; we don't know the number of parms
\           7   64  off=MULTI, on=SINGLE
\                   MULTI -- ignore the library field if loading the proc, and
\                   search all the libraries defined for the name
\                   SINGLE -- search only the library specified in the lib pointer
\           6   32  EXTERN -- don't call, an external variable that's fetched
\           5   16  unused
\       LSB 4-1     COUNT of # of parms (0 to 15)

\ --------------------- Support for PROC memory -----------------------

CREATE PDP  0 , 0 , 0 , DP-LINK LINK, ," *PROCS"  \ locals pointer, free check

|: >PROCS        ( -- ) PDP >DP ;   \ select app dict, save prev dict

\ -------------------- Pointers for procs & libs ----------------------

DLL kernel32.dll k32dll

variable winlib-link                 \ linkage for libraries
variable winlib-last                 \ last library found/defined

variable winproc-link                \ linkage for procedures
variable winproc-last                \ last proc found/defined

0 value ignore-missing-procs?   \ used to ignore entry point missing, default is load now


\ -------------------- Required PROCs ---------------------------------------

align HERE: K32LLI
1 proc LoadLibrary
align HERE: K32GPA
1 proc GetProcAddress
1 proc FreeLibrary


\ -------------------- Proc link offset routines ----------------------------

cell     offset lib>handle ( addr -- addr )        \ offset from link to pfa

2 cells  offset lib>name   ( addr -- addr )        \ offset to lib name

-1 cells offset cfa>proc   ( addr -- addr )        \ offset to proc from cfa

cell     offset proc>cfa   ( addr -- addr )        \ offset to proc cfa

2 cells  offset proc>ep    ( addr -- addr )        \ offset to proc ep

3 cells  offset proc>lib   ( addr -- addr )        \ offset to lib pointer

4 cells  offset proc>pcnt  ( addr -- addr )        \ offset to proc count

17       offset proc>name  ( addr -- addr )        \ offset to proc name

\ -------------------- Resolving Procedures ---------------------------------

: _proc-error ( addr -- )
         THROW_PROCNOTFOUND THROW ;

defer proc-error ' _proc-error is proc-error

\ in assembler, as used at run time by wined (for some obtruse reason...)

CODE "find-proc  ( addr len -- proccfa -1 | 0 ) \ find windows proc by name **WINED**
                pop     eax                     \ eax is addr, ebx is len
                push    esi                     \ save esi
                push    edx                     \ save edx
                lea     edx, ' winproc-link >body \ get ptr to first proc
@@1:            mov     edx, 0 [edx]            \ get the proc ptr
                or      edx, edx                \ check if zero
                jz      short @@9               \ yes, so not found exit
                movzx   ecx, byte ptr 0 proc>name [edx] \ get the count of the name in ecx
                cmp     ebx, ecx                \ compare lengths
                jne     short @@1               \ no, so next proc
                lea     esi, 0 proc>name char+ [edx] \ point esi at name string
                mov     edi, eax                \ edi is address
                rep     cmpsb                   \ check if equal
                jne     short @@1               \ no, so next
                add     edx, # 0 proc>cfa       \ point at cfa
                mov     ebx, # -1               \ exit code
                pop     ecx                     \ pop old edx
                xchg    edx, ecx                \ restore edx
                pop     esi
                push    ecx                     \ proccfa
                next                            \ out
@@9:            xor     ebx, ebx                \ zero
                pop     edx                     \ old edx
                pop     esi
                xor     edi, edi                \ edi is zero
                next    c;

: res-loadproc ( procname lib -- proc-ep | 0 )   \ helper to get proc address
               lib>handle @ over char+ over      \ name, lib handle
               call GetProcAddress
               -if
                 nip nip                         \ found, so leave EP
               else
                 drop swap count                 \ get procname len
                 MAXCOUNTED _LOCALALLOC dup>r place \ allocate local buffer, copy the string
                 S" A" char+ r@ +place           \ add an "A<null>" after last char
                 r> char+                        \ point at it and lib
                 swap call GetProcAddress
                 _LOCALFREE                      \ free off buffer
               then
               ;

: res-single-lib ( proc-cfa -- )                \ resolve proc address, search the specified lib
                cfa>proc                        \ now point at link, not cfa
                dup proc>lib @ dup load-dll     \ point at lib and load the DLL
                if                              \ ok, loaded
                  over proc>name                \ name of proc
                  swap res-loadproc             \ load it
                  -if                           \ loaded?
                    swap proc>ep !              \ save the EP
                    exit                       \ and leave
                  then
                then
                proc-error                      \ it's an error
                ;

\ KLUDGE -- needed to backpatch because code forward refs not allowed
' res-single-lib ALSO ASSEMBLER res-single-x PREVIOUS CELL- tcode-!  \ backpatch for assembler

: res-multi-libs ( proc-cfa -- )                \ resolve proc address, search all libs
                cfa>proc                        \ now point at link, not cfa
                dup proc>pcnt c@ 0x20 and if    \ is it an extern?
                   DOEXTERN over proc>cfa !     \ cfa is an extern
                then
                ['] proc-error over proc>lib !  \ in case we recurse through here
                winlib-link
                begin @ ?dup                    \ loop through libraries
                while                           \ ( proc lib )
                  over proc>name                \ get proc, point at name
                  over load-DLL                 \ attempt load of library
                  if                            \ did it load?
                    over res-loadproc           \ now load the proc
                    -if                         \ ( proc lib ep )
                      >r                        \ save entry point
                      over proc>lib !           \ store lib ptr in proc
                      r> swap proc>ep !         \ store the ep in the proc address
                      exit                     \ and exit
                    then
                  then
                  drop                          \ drop name
                repeat
                proc-error                      \ it's an error, couldn't load the proc
                ;

\ KLUDGE -- needed to backpatch because code forward refs not allowed
' res-multi-libs ALSO ASSEMBLER res-multi-x PREVIOUS CELL- tcode-!  \ backpatch for assembler

\ -------------------- Defining Procedures --------------------

|: 0winproc     ( proc-addr -- )                 \ init proc at proc-addr
                docall over proc>cfa !           \ set docall
                dup proc>pcnt c@ 0x40 and        \ single?
                if
                  DOCALL-SINGLE                  \ DOCALL-SINGLE
                else
                  0 over proc>lib !              \ zero the library
                  DOCALL-MULTI                   \ DOCALL-MULTI
                then swap proc>ep !
                ;

in-system

|: #"proc ( n a1 n1 -- cfa )                  \ define a procedure from string a1,n1
        2dup "find-proc                       \ find procedure
        if
           cfa>proc winproc-last !            \ save in last (find-proc returns cfa addr)
           3drop                              \ ok, drop excess
        else
          state @ if >PROCS else >APPLICATION then \ build in procs area if compiling
          48 ?MEMCHK                            \ check mem available
          rot
          align here dup>r                      \ get aligned pointer, allot to parm count
          winproc-link link,                    \ link address
          0winproc 12 allot                     \ build proc at addr
          c,                                    \ # of parms ( n )
          ", 0 c,                               \ move in name null terminated
          r> winproc-last !                     \ last created
          DP>                                   \ out of whatever section we're in
        then
        winproc-last @ proc>cfa                 \ return cfa
        ;

: proc          ( #params -<name>- )            \ #arguments proc MessageBeep
                bl word count #"proc drop
                ;

: extern        ( -<name>- )                    \ extern var
                0x20 proc ;


\ -------------------- Calling Procedures -----------------------------------

: call          ( [args..] -<proc>- result )    \ compile or execute a windows procedure
                0x80 bl word count #"proc       \ build the proc (0x80 = unknown # parms)
                state @
                if                              \ compiling
                  dup compile,                  \ compile it
                  ignore-missing-procs? if      \ should we ignore missing?
                    drop                        \ yes, just drop
                  else
                    res-multi-libs              \ else resolve call now!
                  then
                else                            \ interpreting
                  execute                       \ execute it
                then
                ; IMMEDIATE

\ ****************** Library Routines ****************************

|: find-winlib   ( addr len -- lib -1 | 0 )     \ find windows library by name
        2>r                                     \ save string
        winlib-link                             \ loop through windows procs
        begin @ dup
        while   dup lib>name count
                2r@ str=                        \ compare called to entry
                if  TRUE                        \ ok, then leave
                    r>drop r>drop
                    exit
                then
        repeat
        r>drop r>drop                           \ otherwise leave with 0 at end
        ;

: "winlibrary   ( adr len -- )
        2dup
        find-winlib                             \ find the library
        if
          winlib-last !                         \ save last lib
          2drop                                 \ drop unused
        else
          align
          here winlib-last !                    \ point last at here
          winlib-link link,                     \ the link of all libraries
          0 ,                                   \ the library handlehandle
          ", 0 c,                               \ counted string
        then
        ;

in-application

: load-DLL ( lib-entry -- f1 )                  \ f1=TRUE if all is ok
        dup lib>handle @                        \ is library address not null
        if      drop TRUE                       \ if not null retun true
        else    dup lib>name char+              \ to null terminated library name
                call LoadLibrary
                -if  swap lib>handle ! TRUE     \ store address
                else nip                        \ discard leave null
                then
        then
        ;

: free-DLL ( lib-entry -- )                     \ free a lib entry
          lib>handle dup @                      \ it's got a handle...
          -if
            call FreeLibrary drop               \ free it
            off exit                           \ zero it & leave
          then 2drop
        ;


\ -------------------- Library Procedures -----------------------------------

in-system

: winlibrary   ( 'name.DLL' -- )        \ usage: WINLIBRARY user32.dll
        bl word uppercase count "winlibrary
        ;

: dll          ( 'name.DLL' <-name-> )  \ usage: DLL "USER32.DLL" USER32
        winlibrary winlib-last @ constant ;

in-application

|: init-proc ( -- )                          \ initialize all procedure libraries

        ['] 0winproc winproc-link do-link       \ zero the procs
                                                \ NOTE! run-time rather than compile-time
        init-k32

        ['] free-DLL winlib-link do-link \ zero out app libraries
        ;


\ -------------------- Memory Management functions --------------------------
\
\ Malloc data structure in dynamically allocated memory
\ 06/09/2002 21:54:51 arm major modifications

\ [malloc_next][heapaddress][mem_type][ 0 ] [malloced_memory][extra_cells]
\                                           |
\                                           * returns this address on allocate *
\                                           this is the "address"
\ Changes:
\   All memory calls are now to Windows heap functions
\   Length field has been discarded
\   Heap address is included
\   Currently, only the process heap is used. Only
\     ALLOCATE and REALLOC need to be modified to work against
\     another heap.
\   mem_type is currently unused, will be for pe header
\ Windows function calls

0 PROC GetProcessHeap            \ Heap functions
3 PROC HeapAlloc
3 PROC HeapFree
4 PROC HeapReAlloc
3 PROC HeapSize

0 constant malloc-hflag                          \ heap flags
variable malloc-haddr                            \ heap address
variable malloc-link                             \ head of single linked list
         0 malloc-link !

cell offset link>haddr   ( addr -- addr' )       \ from link to heap address

| 2 cells offset link>memtype ( addr -- addr' )  \ from link to memtype

4 cells offset link>mem     ( addr -- addr' )    \ from link to mem pointer

| -4 cells offset mem>link     ( addr' -- addr ) \ from mem to link

8 CELLS CONSTANT malloc-adjlen                   \ adjustment for headers + extra cells

|: mHeapAlloc   ( n -- rel-addr fl )              \ allocate n bytes, return rel address
               malloc-hflag malloc-haddr @       \ flags, heapaddress
               call HeapAlloc dup 0= ;

|: mHeapParm    ( rel-addr -- abs-addr 0 abs-heap-addr ) \ set up parms
               dup                               \ abs rel
               link>haddr @ malloc-hflag swap    \ abs 0 heap-addr
               ;

|: mHeapFree    ( rel-addr -- f )                 \ free rel-addr bytes
               mHeapParm
               call HeapFree 0= ;                \ flags, heapaddress

|: mHeapReAlloc ( n rel-addr -- rel-addr' fl )    \ realloc n rel-addr bytes
               mHeapParm
               call HeapReAlloc dup 0= ;          \ flags, heapaddress

: mHeapSize    ( rel-addr -- n )                 \ size of rel-addr bytes
               mHeapParm
               call HeapSize ;                   \ flags, heapaddress

defer (memlock)   ' noop is (memlock)             \ memory lock and unlock, see task.f
defer (memunlock) ' noop is (memunlock)           \ used to serialise requests for tasks

|: malloc-add-link ( addr -- )                    \ link memory into list
                malloc-haddr @ over link>haddr !  \ save heap address
                (memlock)                         \ lock
                malloc-link add-link              \ link into malloc_next
                (memunlock)                       \ unlock
                ;

|: malloc-unlink ( addr -- f1 )                   \ unlink from list
                 >r malloc-link                   \ f1=FALSE=ok
                (memlock)                         \ lock
                begin dup @ ?dup                  \ prev and next
                while                             \ if it points somewhere...
                  dup r@ =                        \ is it me?
                  if
                    @ swap !                      \ yes, so unlink me
                    (memunlock) r>drop FALSE exit
                  then
                nip                               \ drop prev
                repeat
                (memunlock)                       \ unlock
                drop r>drop TRUE ;                \ didn't find it...

: allocate      ( n -- addr fl )                \ ansi version of malloc
                malloc-adjlen +
                dup malloc-adjlen u<            \ less than malloc-adjlen ?
                if      drop 0 TRUE             \ error, the size wrapped
                        exit
                then
                mHeapAlloc                      \ modified to use Windows call
                if      drop 0 TRUE             \ error, fl=true
                else    dup malloc-add-link     \ link in
                        link>mem FALSE          \ point at real mem
                then    ;                       \ -- f1 = true on error

: malloc        ( n -- addr )                   \ allocate dynamic memory
                allocate THROW_MEMALLOCFAIL ?THROW ;

|: (free)       ( link-addr -- f1 )             \ free memory (addr points link)
                dup malloc-unlink               \ first, delete from malloc list
                if      drop TRUE               \ if it failed, return failure
                else    mHeapFree               \ then actually release the mem
                then    ;

: free          ( addr -- f1 )                  \ release the memory pointer
                                                \ f1=TRUE=failed, f1=FALSE=ok
                mem>link (free) ;               \ point at true address

|: (release)     ( link-addr -- )                \ release block
                (free) THROW_MEMRELFAIL ?THROW ;

: release       ( addr -- )
                mem>link (release) ;

: realloc       ( n addr -- addr' fl )
                mem>link dup malloc-unlink      \ remove from list
                if      nip TRUE                \ if not in list
                        exit                   \ then fail the function
                then
                malloc-adjlen under+
                over malloc-adjlen u<           \ less than malloc-adjlen ?
                if      nip 0 TRUE              \ if so the size wrapped, error
                else    tuck mHeapReAlloc       \ else make longer
                then                            \ actually it can be longer or
                                                \ shorter
\ At this point the stack is either ( a-addr1 a-addr2 0 )
\                                or ( a-addr1 0 -1 )

                if      swap                    \ ( 0 a-addr1 )
                then
                dup malloc-add-link link>mem    \ add in to list
                swap 0= ;                       \ put flag on top and set it
                                                \ -- a-addr f1 = true on error
\ At the conclusion of realloc if a-addr1 was a valid address, the stack is
\ ( a-addr2 0 ) if successful or
\ ( a-addr1 -1 ) if the allocated memory could not be resized.


: resize        ( a1 n1 -- a2 f1 )              \ ansi version of realloc
                swap realloc ;                  \ -- f1 = true on error

|: init-malloc  ( -- )
\ NOTE the two deferred words MUST BE reset to Noop's before any mallocs
               ['] noop is (memlock)                  \ turn off lock until inited
               ['] noop is (memunlock)                \ turn off unlock until inited
               0 malloc-link !
               call GetProcessHeap malloc-haddr ! ; \ heap address save in var

((
|: term-malloc   ( -- )                         \ release all allocated memory
                ['] (release) malloc-link do-link
                ;
))

\ -------------------- ANS File Functions --------------------

7 PROC CreateFile
1 PROC CloseHandle
4 PROC ReadFile
4 PROC WriteFile
1 PROC DeleteFile
2 PROC MoveFile
4 PROC SetFilePointer
1 PROC FlushFileBuffers
2 PROC SetEndOfFile

                     : bin ;                   \ BIN
GENERIC_READ  constant r/o                     \ GENERIC_READ
GENERIC_WRITE constant w/o                     \ GENERIC_WRITE
r/o w/o +     constant r/w                     \ READ/WRITE

: ascii-z     ( addr len buff -- buff-z )      \ W32F      String Extra
\ *G Make a null-terminated copy of string addr len in buff and return the address of the
\ ** first character.
   dup>r place r> dup +null 1+ ;

: open-file ( adr slen fmode -- fileid ior )
   -rot MAXSTRING _LOCALALLOC ascii-z              \ fmode adrstr - & convert to zstring
   2>r                                             \ ( r: adrstr fmode  )
   0                                               \ hTemplateFile
   FILE_FLAG_SEQUENTIAL_SCAN                       \ fdwAttrsAndFlag
   OPEN_EXISTING                                   \ fdwCreate
   0                                               \ lpsa
   [ FILE_SHARE_READ FILE_SHARE_WRITE or ] literal \ fdwShareMode
   2r>                                             \ fdwAcess(fmode) lpszName(adr)
   call CreateFile
   dup INVALID_HANDLE_VALUE =                      \ fileid ior = 0 = success
   _LOCALFREE ;                                    \ release buffer

: create-file ( adr slen fmode -- fileid ior )
   -rot MAXSTRING _LOCALALLOC ascii-z              \ fmode adrstr - & convert to zstring
   2>r                                             \ ( r: adrstr fmode  )
   0                                               \ hTemplateFile
   FILE_FLAG_SEQUENTIAL_SCAN                       \ fdwAttrsAndFlag
   CREATE_ALWAYS                                   \ fdwCreate
   0                                               \ lpsa
   [ FILE_SHARE_READ FILE_SHARE_WRITE or ] literal \ fdwShareMode
   2r>                                             \ fdwAcess(fmode) lpszName(adr)
   call CreateFile
   dup INVALID_HANDLE_VALUE =                      \ fileid ior - 0 = success
   _LOCALFREE ;                                    \ release buffer

: close-file ( fileid -- ior )
   call CloseHandle 0= ;                           \ hObject 0 = success

| CODE FPARMS-RW  ( addr len fileid -- 0 0 ptr len addr fileid ) \ parms for read/write
\ ptr points here:                     ^
                xor     ecx, ecx                \ zero ecx
                lea     eax, 4 [esp]            \ get esp, ebx is fileid
                push    eax                     \ addr len ptr
                push    4 [esp]                 \ addr len ptr len
                push    12 [esp]                \ addr len ptr len addr
                mov     16 [esp], ecx           \ 0 len ptr len addr
                mov     12 [esp], ecx           \ 0 0 ptr len addr
                next    c;

: read-file     ( b-adr b-len fileid -- len ior ) \ ior = 0 = success
   fparms-rw
   call ReadFile 0= ;

: write-file    ( adr slen fileid -- ior ) \ ior = 0 = success
   fparms-rw
   call WriteFile nip 0= ;

: delete-file ( adr len -- ior ) \ ior - 0 = success
   MAXSTRING _LOCALALLOC ascii-z             \ lpszFileName
   call DeleteFile 0=
   _LOCALFREE ;                              \ free buffer

: rename-file ( adr1 len adr2 len -- ior )
   MAXSTRING MAXSTRING + _LOCALALLOC DUP>R     \ get 2 buffers
   ascii-z -rot                                \ addr2
   r> MAXSTRING + ascii-z                      \ addr1
   call MoveFile 0=                            \ adr1a adr2a
   _LOCALFREE ;

CODE FPARMS-FP  ( len-ud fileid move --  \ parms for file-position words using SetFilePointer
\                -- MoveHigh move ptrMoveHigh MoveLow fileid ) \ results
\ ptr points here:   ^
                mov     -4 [ebp], edx     \ save edx
                pop     eax               \ fileid
                pop     ecx               \ movehigh
                pop     edx               \ movelow
                push    ecx               \ ( movehigh )
                mov     ecx, esp
                push    ebx               \ ( movehigh move )
                push    ecx               \ ( movehigh move ptrmovehigh )
                push    edx               \ ( movehigh move ptrmovehigh movelow )
                mov     ebx, eax          \ ( movehigh move ptrmovehigh movelow fileid )
                mov     edx, -4 [ebp]     \ restore edx
                next    c;

|: SetFP        ( parms -- len-ud 0 | len-ud err )
   FPARMS-FP Call SetFilePointer dup -1 ( INVALID_SET_FILE_POINTER ) =
   IF Call GetLastError DUP NO_ERROR =
     IF   DROP SWAP 0                         \ return len-ud 0=success
     else NIP 0 SWAP then                     \ return 0 0 ior=err
   else
     SWAP 0                                   \ return len-ud 0=success
   then ;

: file-position ( fileid -- len-ud ior )
   0 0 rot FILE_CURRENT SETFP ;

: advance-file ( len-ud fileid -- ior ) \ RELATIVE position file, not ANS \ ior - 0 = success
   FILE_CURRENT SetFP nip nip ;

: reposition-file ( len-ud fileid -- ior ) \ ior - 0 = success
   FILE_BEGIN SetFP nip nip ;

: file-append   ( fileid -- ior ) \ ior - 0 = success
   0 0 rot FILE_END SetFP nip nip ;

2 PROC GetFileSize
: file-size     ( fileid -- len-ud ior )
   sp@ 0 swap rot call GetFileSize
   tuck INVALID_FILE_SIZE <>
   if false
   else
     call GetLastError NO_ERROR <>
     -if
       3drop 0 0 true
     then
   then ;

: flush-file    ( fileid -- ior )
                call FlushFileBuffers 0= ;      \ ior - 0 = success

| CODE ADJ-LENS ( buff len buff' -- len len' )  \ adjust lengths: rot - tuck swap - ;
                pop     eax                     \ length of buff
                pop     ecx                     \ address of buff
                sub     ebx, ecx                \ subtract where found (buff - buff')
                push    ebx                     \ save as length of string read
                sub     ebx, eax                \ subtract from original buffer, length to move
                inc     ebx                     \ 1+
                next    c;

|: read-line-CRLF ( buff len -- len len true | false ) \ return len of string, len to move file, flag
                2dup 0x0D scan                  \ look for cr
                if
                  dup>r adj-lens r>             \ adjust length & length back
                  char+ c@ 0x0A = if 1+ then    \ check next for LF, adjust for it
                  true exit                     \ leave with found
                then                            \ cr not found, perhaps it's an LF only
                drop
                2dup 0x0A scan                  \ look for LF
                if
                  adj-lens                      \ length back
                  true exit
                then
                3drop false  ;                  \ no just a plain string

: read-line     ( adr len fileid -- len eof ior )
                >r                              \ save the fileid
                0max dup RLLEN !                \ save length requested
                1+ 2dup r@ read-file ?dup       \ read requested chars+1
                if                              \ if read not ok
                  r>drop                        \ drop fileid
                  >r 3drop 0 -1 r> exit         \ ior <> 0 = error
                then
                2dup = RLNEOF !                 \ if req=read is equal, not end of file
                min                             \ if read ANY characters
                -if
                  RLLEN @ min dup RLLEN !       \ reset length read
                  read-line-crlf                \ scan for line break characters
                  if                            \ if line break
                    RLNEOF @ if 1- 0 min then   \ if not end, need to adjust for extra char read
                    ?dup if                     \ if it's ok to positiom
                      s>d r> advance-file       \ position file for next time
                      -1 swap exit              \ len -1 ior
                    else
                      r>drop -1 0 exit          \ len -1 ior
                    then
                  then
                  RLNEOF @ if                   \ correct if not eof (Bill McCarthy fix)
                    -1 -1 r@ advance-file ?dup  \ we over-read, so step back 1 char
                    if r>drop 0 0 rot exit      \ reposition-file error
                    then
                  then
                  r>drop RLLEN @ -1 0           \ no line break, so len -1 0
                else
                  2drop r>drop 0 0 0            \ nothing read return 0=len, eof=false ior=false
                then    ;

: write-line    ( adr len fileid -- ior )
                dup>r write-file
                crlf$ count r>  write-file or ; \ ior - 0 = success

: resize-file   ( len-ud fileid -- ior )
                dup>r reposition-file drop
                r> call SetEndOfFile 0= ;    \ ior - 0 = success

: file-status   ( adr len -- x ior )
                r/o open-file
                -if     nip
                else    swap close-file drop
                then    0 swap ;         \ ior - 0 = success


\ -------------------- File I/O ---------------------------------------------

: FSAVE-FILE    ( addr len filename -- )
                count r/w create-file THROW_FILECREATEFAIL ?THROW
                dup>r write-file THROW_FILEWRITEFAIL ?THROW
                r> close-file drop ;

\ -------------------- Error Handler ----------------------------------------

: CATCH         ( cfa -- flag ) \ execute the word given by its cfa in a way that
                \ will pass control to the word just after CATCH, whatever an error
                \ occurs while cfa is executed or not - see THROW which may be
                \ used inside the word "cfa" to handle errors if any.
                \ if no error occured, flag is 0, else the flag is given by THROW
                \ Beware: if an error occurs, any parameters for the word "cfa" are
                \ still on the stack, under "flag"
                SP@ >R
                LP @ >R
                OP @ >R
                HANDLER @ >R
                RP@ HANDLER !
                EXECUTE
                R> HANDLER !
                R>DROP
                R>DROP
                R>DROP
                0 ;

: THROW         ( n -- ) \ throw an error, identified by n, while executing a word
                \ whose execution is "protected" by CATCH .
                ?DUP
                IF      HANDLER @ RP!
                        R> HANDLER !
                        R> OP !
                        R> LP !
                        R> SWAP >R
                        SP! DROP
                        R>
                THEN ;

: ABORT         ( -- )
                THROW_ABORT THROW ;

: NABORT!       ( addr n -- ) \ set message, n throw
                SWAP MSG ! THROW ;

: ABORT!        ( addr -- )  \ abort, print counted string passed
                THROW_ABORTQ NABORT! ;

NCODE ?THROW    ( f n -- )
\                SWAP IF THROW ELSE DROP THEN ;
                pop     eax
                test    eax, eax
                jz      short @@9
                mov     eax, # ' THROW         \ flag set, throw
                exec                           \ go do it
@@9:            pop     ebx                    \ correct tos
                next    c;


NCODE (("))     ( -- counted-string )
                push    ebx
                mov     ebx, 0 [ebp]
                movzx   ecx, byte ptr 0 [ebx]
                lea     eax, 5 [ebx] [ecx]  \ account for null at end
                and     eax, # -4       \ align
                mov     0 [ebp], eax
                next    c;

: (ABORT")      ( f -- )
                ((")) SWAP
                IF      ABORT!
                THEN    DROP ;

in-system

: ABORT"        ( flag -<ccc>- -- ) \ abort and display message ccc if flag is true
                COMPILE (ABORT")  ,"  ; IMMEDIATE

\ -------------------- Structured Conditionals ------------------------------

in-application

: ?PAIRS        ( n1 n2 -- )  XOR THROW_MISMATCH ?THROW ; \ Sometimes used in applications.

in-system

: ?EXEC  STATE @     THROW_INTERPONLY ?THROW  ;
: ?COMP  STATE @ 0=  THROW_COMPONLY   ?THROW  ;

: >MARK         ( -- addr )   HERE 0 , ;           \ mark a link for later resolution by
: <MARK         ( -- addr )   HERE ;
: >RESOLVE      ( addr -- )   HERE CELL+ SWAP ! ;
: <RESOLVE      ( addr -- )   , ;

: AHEAD  ?COMP  COMPILE  BRANCH  >MARK 2 ; IMMEDIATE

\ gah Modified to optimize DUP IF into -IF
: IF     ?COMP  HERE 2 CELLS - @ DUP ['] COMPILE =
                SWAP ['] LIT = OR 0=
                HERE CELL - @ ['] DUP = AND
                IF CELL NEGATE ALLOT COMPILE -?BRANCH
                ELSE COMPILE ?BRANCH
                THEN >MARK 2 ; IMMEDIATE
: -IF    ?COMP  COMPILE -?BRANCH  >MARK 2 ; IMMEDIATE
: THEN   ?COMP  2 ?PAIRS  COMPILE _THEN >RESOLVE ; IMMEDIATE
: ENDIF  [COMPILE] THEN ; IMMEDIATE
: ELSE   ?COMP  2 ?PAIRS  COMPILE BRANCH >MARK  SWAP >RESOLVE  2 ; IMMEDIATE

: BEGIN  ?COMP  COMPILE _BEGIN <MARK CELL+ 1 ; IMMEDIATE
: UNTIL  ?COMP  1 ?PAIRS  COMPILE _UNTIL  <RESOLVE ; IMMEDIATE
: AGAIN  ?COMP  1 ?PAIRS  COMPILE _AGAIN  <RESOLVE ; IMMEDIATE
: WHILE  ?COMP  COMPILE _WHILE  >MARK 2  2SWAP ; IMMEDIATE
: REPEAT ?COMP  1 ?PAIRS  COMPILE _REPEAT <RESOLVE  2 ?PAIRS >RESOLVE ; IMMEDIATE

: DO     ?COMP  COMPILE (DO)   >MARK 3 ; IMMEDIATE
: ?DO    ?COMP  COMPILE (?DO)  >MARK 3 ; IMMEDIATE
: LOOP   ?COMP  3 ?PAIRS  COMPILE (LOOP)   DUP 2 CELLS+ <RESOLVE >RESOLVE ; IMMEDIATE
: +LOOP  ?COMP  3 ?PAIRS  COMPILE (+LOOP)  DUP 2 CELLS+ <RESOLVE >RESOLVE ; IMMEDIATE


\ -------------------- Eaker CASE statement ---------------------------------

: CASE   ?COMP  COMPILE _CASE  0 ; IMMEDIATE
: OF     ?COMP  COMPILE _OF  >MARK 4 ; IMMEDIATE
: ENDOF  ?COMP  4 ?PAIRS  COMPILE _ENDOF  >MARK  SWAP >RESOLVE  5 ; IMMEDIATE

: ENDCASE  ?COMP  COMPILE _ENDCASE
           BEGIN  ?DUP WHILE  5 ?PAIRS  >RESOLVE  REPEAT ; IMMEDIATE

\ -------------------- Build Header -----------------------------------------

|: _BFA-@       ( -- bfa-addr value )
                LAST @ N>BFA DUP C@     \ get bfa address and value
                ;

|: _HEADER-BARE ( a1 n1 voc -- lfa nfa ) \ build a hashed header from a1,n1 in voc
                3dup                       \ ( a1 n1 voc a1 n1 voc )
                VOC#THREADS "#HASH +
                DUP>R LINK,                \ lfa
                0 ,                        \ cfa-ptr
\                ['] COMPILE, ,             \ for std words
                0 c,                       \ bfa
                HERE >R                    \ NFA is last
                ", 0 C, ALIGN              \ nfa
                2R> ;                      \ lfa, nfa

|: _HEADER-BUILD ( a1 n1 voc -- )    \ build a hashed header from a1,n1 in voc
                _HEADER-BARE
                LAST ! LAST-LINK !   \ set the last nfa, and the last link
                ;

in-application

CREATE CONSFILE ," (console)"

in-system

|: _HEADER-OPT ( -- )         \ optional fields
                LOADING? IF                             \ if loading...
                  LOADFILE                              \ file
                  LOADLINE @                            \ line number
                else CONSFILE -1 then                   \ from console
                _BFA-@ 2>R                              \ get bfa and value
                ?DUP IF                                 \ if not zero
                  , R> BFA_VFA_PRESENT OR >R            \ set vfa bit
                THEN
                ?DUP IF                                 \ if not zero
                  , R> BFA_FFA_PRESENT OR >R            \ set FFA bit as well
                THEN
                2R> SWAP C!                             \ set flags
                ;

: _HEADER-OFA   ( -- )          \ optional fields
                _BFA-@ BFA_OFA_PRESENT OR SWAP C!       \ set flags
                0 sys-,                                 \ ofa
                ;

: CFAPTR!       ( xt -- )                               \ set cfaptr to cfa
                LAST @ N>CFAPTR ! ;

defer class>sys
| : _class>sys drop 0 ; ' _class>sys is class>sys

: ("HEADER) ( a1 n1 -- )
            CURRENT @ DUP SYS-ADDR?           \ if the dictionary is in system space
            over class>sys or                 \ or is a class or object
            IF >SYSTEM ELSE >APPLICATION THEN \ then build the header in the same space
            2000 ?MEMCHK                      \ check avail mem
            align _HEADER-BUILD _HEADER-OPT   \ build head in current @
            DP>                           \ back to original dictionary pointer
\ the following line looks obscure, but what it does is make sure the CFA
\ follows the CFA-pointer when compiling definitions into some named space
\ (which may not be the same space as the header).
            align HERE CFAPTR!
            ;

DEFER START/STOP        ' noop is start/stop   \ has to be in systemspace

in-application



: "HEADER   ( a1 n1 -- )                    \ build header in same dict as wordlist
            DUP 0= THROW_NAMEREQD AND THROW
            "CLIP"
	    2dup UPPER                      \ bad; should really copy
            WARNING @ IF
              2DUP CURRENT @ (SEARCH-SELF) IF
                DROP DUP-WARNING? IF
                WARN_NOTUNIQUE WARNMSG
                THEN
              THEN
            THEN
            ("HEADER)
            ;

| NCODE (HEADER)  ( addr len -- )          \ standard voc header word
                mov     ecx, CURRENT       \ get current vocab
                mov     eax, VHEAD VOC#0 - [ecx] \ fetch header word to execute
                exec    c;

0 value slfactor            \ adjust this to slow down loading

: SLOW ( -- ) slfactor ms start/stop ; \ set 'slfactor' to slow down loading

: HEADER        ( -<name>- )      \ build a header
                BL WORD COUNT (HEADER) slow ; \ self-call the header word

in-system

: ALIAS         ( xt -<name>- )            \ W32F
\ *G Creates an alias of a word that is non-imediate (unless IMMEDIATE is used).
\ *P NOTE View of either name can go to the synonym instead (it depends which name
\ ** is found first in a full dictionary search).
                HEADER CFAPTR! ;

: SYNONYM       ( -<newname> <oldname>- )  \ 200X
\ *G Creates an alias of a word that will be immediate if the original word was
\ ** immediate.  The word order is the same as when making a colon definition.
\ ** <newname> is hidden during the search for <oldname> so that an alias of an
\ ** existing word in another vocabulary can be created (NOTE versions prior to
\ ** V6.10.05 and V6.11.10 incorrectly created a void definition when <newname>
\ ** was found in the search. If <oldname> is not found then <newname> remains
\ ** hidden (only since V6.10.05 and V6.11.10).
\ *P NOTE View of either name can go to the synonym instead (it depends which name
\ ** is found first in a full dictionary search).
                HEADER hide
                DEFINED DUP ?MISSING
                1 = IF IMMEDIATE THEN       \ make synonym immediate if original is
                CFAPTR! reveal ;            \ set the cfa pointer of header


\ -------------------- Colon Compiler ---------------------------------------

in-application

VARIABLE CSP    \ Current Stack Pointer variable

: !CSP          ( -- )  \ save current stack pointer for later stack depth check
                SP@ CSP ! ;

in-system

: ?CSP          ( -- )  \ check current stack pointer against saved stack pointer
                SP@ CSP @ XOR THROW_STACKCHG ?THROW ;

\ DODOES-CALL, builds code (in code-only section) that loads the
\ cfa following DOES> and jumps to DODOES
: DODOES-CALL,  ( -- ) \ compile call to does> (in code-only section)
                code-align code-here ,                       \ for (;code) to pick up
                0xC790 code-w, 0xC1 code-c, HERE cell+ code-, \ nop  mov ecx, # ? cell+ ; new esi
                0xE9 code-c, DODOES code-here CELL+ - code-, \ jmp (long) dodoes
                ;

: DOES>?        ( ip -- flag )    \ is cfa a does> section of code
                @ @ 0x00FFFFFF and 0xC1C790 = ;   \ nop  mov ecx, # ?; used in see and debugger

in-application

: (;CODE)       ( -- )
                R> @ LAST @ NAME> !  ;

: (DOES>)       ( -- )
                LAST @ NAME> R> TUCK @ OVER !
                SYS-ADDR? 0= SWAP
                SYS-ADDR? AND SYS-WARNING? AND
                IF WARN_SYSWORD3 WARNMSG THEN ;

: #(;CODE)      ( a1 -- )
                R> @ SWAP ! ;

: _]            ( -- )
                STATE ON ;

: _[            ( -- )          \ turn off compiling
                STATE OFF ;

DEFER ]           ' _] IS ]
DEFER [ IMMEDIATE ' _[ IS [     \ turn off compiling

0 VALUE ?:M
0 VALUE PARMS   \ number of parameters (locals)

in-system

: PARMS-INIT    ( -- )
                FALSE TO ?:M
                0 TO PARMS ;

|: :COLONDEF    ( -- )
                PARMS-INIT DOCOL COMPILE, !CSP ] ;

: :NONAME       ( -- xt )       \ start a headerless colon definition
                ALIGN HERE :COLONDEF ;

: :             ( -<name>- )    \ Forth's primary function defining word
                HEADER HIDE :COLONDEF ;

: RECURSE       ( -- )          \ cause current definition to execute itself
                ?COMP LAST @ NAME> COMPILE, ; IMMEDIATE


\ -------------------- Defining Words ---------------------------------------

VARIABLE DEFER-LIST             \ The head of a linked-list of deferred words

in-application

: CREATE        ( "<spaces>name" -- )  \ Create a definition for name.
                HEADER DOVAR COMPILE, ;

in-system

: CONSTANT      ( n -<name>- )  \ create a constant (unchangeable) value
                HEADER DOCON COMPILE, , ;

: VARIABLE      ( -<name>- )    \ create a variable (changeable) value
                CREATE 0 , ;

: DEFER         ( -<name>- )    \ create a deferred execution function
\ *G create a deferred execution function, defaults to a NOOP
\ ** Typical usage    ' new-action is deferred-action
\ ** -or- : new-word ['] new-action is deferred-action ;
                HEADER DODEFER COMPILE,
                COMPILE NOOP
                DEFER-LIST LINK,
                COMPILE NOOP ;

: USER          ( n -<name>- -- )  \ create a user variable (changeable) value
                HEADER DOUSER COMPILE, , ;

: NEWUSER       ( size -<name>- -- )      \ Creates a user. A user can be
                                \ a byte, cell, float, string or stack
                NEXT-USER @ SWAP OVER + NEXT-USER !
                USER ;

in-application

1 4096 *        CONSTANT USERSIZE   \ user area size for task variables

in-system

: 2CONSTANT     ( n1 n2 -- ) \ create a double constant
                CREATE , ,
                ;CODE   NO-OFA        \ disable OFA resolution
                        push    ebx
                        push         2 CELLS [eax]
                        mov     ebx, 1 CELLS [eax]
                        next    c;

: 2VARIABLE     ( -<name>- )  \ create a double variable
                VARIABLE 0 , ;

in-application

\ -------------------- Redefine DEFER-red Words -----------------------------

NCODE @(IP)     ( -- n )
                push    ebx
                mov     ecx, 0 [ebp]
                mov     ebx, 0 [ecx]
                add     ecx, # 1 CELLS  \ modifies return address! Horrible.
                mov     0 [ebp], ecx
                next    c;

: (IS)          ( xt -- )   @(IP) >BODY ! ;

: ?IS           ( xt -- xt )                    \ error if not a deferred word
                DUP @ DODEFER <> THROW_NOTDEFER ?THROW ;

in-system

: IS            ( xt -<name>- ) \ assign xt to a defer
                STATE @
                IF      COMPILE (IS)   ' ?IS COMPILE,
                ELSE    DUP SYS-ADDR?              \ if xt is system
                        ' DUP>R SYS-ADDR? 0= AND   \ and deferred word isn't
                        SYS-WARNING? AND           \ and we want warnings
                        IF WARN_SYSWORD2 WARNMSG THEN   \ warn user about problem
                        R> ?IS >BODY !       \ store new deferred func
                THEN ; IMMEDIATE


\ -------------------- Value ------------------------------------------------

: VALUE         ( n -<name>- )  \ create a self fetching changeable value
                HEADER           \ 'n TO value-name' will change a value
                DOVALUE   COMPILE,
                ( n )     ,
                DOVALUE!  COMPILE,
                DOVALUE+! COMPILE,   ;

|: ?TO_CHECK    ( xt -- xt_body )
                DUP @ >R
                >BODY DUP CELL+ @ -1 =  \ no special words
                R@ DOCON   = OR         \ no constants
                R@ DOCOL   = OR         \ no colon definitions
                R@ DODOES  = OR         \ no DOES> words
                R@ DOVAR   = OR         \ no variables
                R> DODEFER = OR         \ no deferred words
                THROW_NOTVALUE ?THROW ;

|: TOCOMPEXEC   ( -- )
                ' ?TO_CHECK + STATE @ IF COMPILE, ELSE EXECUTE THEN ;

: TO            ( n -<value_name>- ) \ store n in a value. Ex: -1 TO myvalue
                CELL
                TOCOMPEXEC ; IMMEDIATE

: +TO           ( n -<value_name>- )  \ Add to a value as in
                                      \ 10 VALUE X  then  20 +TO X  sets X to 30
                [ 2 CELLS ] LITERAL
                TOCOMPEXEC ; IMMEDIATE


\ -------------------- Chains -----------------------------------------------

variable chain-link             \ linked list of chains
         0 chain-link !

variable sys-chain-link         \ linked list of system chains
         0 sys-chain-link !

: new-chain     ( -- )
\ *G Create a new chain.
                create 0 , ['] noop compile,
                in-sys? if sys-chain-link else chain-link then
                link,
                ;

: new-sys-chain ( -- )
\ *G Create a new chain in the system space.
                >system
                new-chain
                system>
                ;

|: ?sys-chain   ( chain_address cfa -- chain_address cfa )
\ Warn the user about adding a word in system-space to a chain in application space.
                over sys-addr? 0=             \ chain NOT in system space?
                over sys-addr? and            \ and cfa in system space?
                sys-warning? and              \ and we want warnings
                if   WARN_SYSWORD WARNMSG
                then ;

|: noop-compile ( -- addr )
                here ['] noop compile, ;

: noop-chain-add ( chain_address -- addr )
\ *G Add chain item, return addr of cfa added.
\ ** For normal forward chains.
                begin   dup @
                while   @
                repeat  here swap ! 0 ,
                        noop-compile ;

: chain-add     ( chain_address -<word_to_add>- )
\ *G Add chain item.
\ ** For normal forward chains.
                ' ?sys-chain >r         \ chain_addr    | cfa_of_word_to_add
                noop-chain-add          \ addr          | cfa
                r> swap ! ;

: noop-chain-add-before ( chain_address -- addr )
\ *G Add chain item, return addr of cfa added.
\ ** For reverse chains like BYE
                here over @ ,   \ compile current head-chain-item
                swap !          \ store the addr of this chain-item in the chain-head
                noop-compile ;

: chain-add-before ( chain_address -<word_to_add>- )
\ *G Add chain item
\ ** For reverse chains like BYE
                ' ?sys-chain >r
                noop-chain-add-before
                r> swap ! ;

in-application

: do-chain      ( chain_address -- )
\ *G Execute all words in a chain.
                begin   @ ?dup
                while   dup>r           \ make sure stack is clean during
                        cell+ perform   \ execution of the chained functions
                        r>              \ so parameters can be passed through
                repeat  ;               \ the chain if items being performed

in-system

: strand      ( <-name-> -- )          \ new chain
              new-chain                \ create
              ;code
                mov      ecx, 4 [eax] \ get body of first strand
                sub      ebp, # 4
@@1:            test     ecx, ecx     \ zero?
                jz       short @@9    \ yes, finished
                mov      0 [ebp], ecx \ save ecx for next time round
                mov      eax, 4 [ecx] \ get the xt to execute
                xchg     esp, ebp     \ swap regs for call
                call     callf        \ call the forth word there
                xchg     esp, ebp     \ swap regs for call
                mov      ecx, 0 [ebp] \ restore ecx
                mov      ecx, 0 [ecx] \ get next strand
                jmp      short @@1    \ next word
@@9:            add      ebp, # 4
                next     c;           \ finished

: append-strand  ( cfa <-name-> -- )     \ add cfa to chain end
                ' swap ?sys-chain >r    \ check for system
                >body noop-chain-add r> swap ! ; \ add in to chain

: insert-strand  ( cfa <-name-> -- )     \ add cfa to chain start
                ' swap ?sys-chain >r    \ check for system
                >body here over @ , r> , swap ! ; \ add in to chain

\ ---------------------------------------------------------------------------

: offset        ( n1 <-name-> -- )        \ compiling
                ( n2 -- n3 )              \ runtime n3=n1+n2
                header dooff compile, , ;

: field+        ( n1 n2 <-name-> -- n3 )  \ compiling n3=n1+n2 stored offset=n1
                ( addr1 -- addr2 )        \ runtime addr2=addr1+n1
                over offset + ;

in-application

\ -------------------- Interpreter ------------------------------------------

CODE DEPTH      ( -- n ) \ return the current data stack depth (n excluded)
                push    ebx
                mov     ebx, SP0 [UP]
                sub     ebx, esp
                sar     ebx, # 2  \ shift right two is divide by 4
                next    c;

: ?STACK        ( -- )          \ check the data stack for stack underflow
                DEPTH 0< THROW_STACKUNDER ?THROW ;

: QUERY         ( -- )          \ accept a line of input from the user to TIB
                TIB DUP MAXSTRING ACCEPT (SOURCE) 2!
                >IN OFF
                0 TO SOURCE-ID 0 TO SOURCE-POSITION ;

: _NUMBER,      ( d -- )
                DOUBLE? 0= IF DROP THEN
                STATE @
                IF      DOUBLE? IF  SWAP  [COMPILE] LITERAL  THEN
                        [COMPILE] LITERAL
                THEN ;

DEFER NUMBER,           ' _NUMBER, IS NUMBER,

DEFER SAVE-SRC          ' NOOP     IS SAVE-SRC
DEFER ?UNSAVE-SRC       ' NOOP     IS ?UNSAVE-SRC

: _INTERPRET    ( -- )
                BEGIN   BL WORD DUP C@
                WHILE   SAVE-SRC FIND ?DUP
                        IF      STATE @ =
                                IF      COMPILE,        \ COMPILE TIME
                                ELSE    EXECUTE ?STACK  \ INTERPRET
                                THEN
                        ELSE    NUMBER NUMBER,
                        THEN    ?UNSAVE-SRC
                REPEAT  DROP ;

DEFER INTERPRET    ' _INTERPRET IS INTERPRET

1 PROC Sleep

\ 07/07/2003 21:10:55 fkernel.f  [ 745385 ] Bug in "Find Text in Files" Dialog
DEFER WINPAUSE      ( -- )  \ release control to OS for a moment, pump message loop (in wrapper)
: (WINPAUSE)    KEY? DROP ; ' (WINPAUSE) IS WINPAUSE


\ -------------------- File Loading -----------------------------------------

\ August 11th, 1997 - 9:02 tjz added to correct for performance bug
\ readded for cf32 port (Samstag, August 13 2005 dbu)
0 value len-prev

: REFILL        ( -- f )        \ refill TIB from current input stream
                SOURCE-ID ?DUP
                IF      1+  ( not from evaluate )
                        IF      LOADLINE INCR
                                LOADLINE @ 255 AND 0=   \ once each 256 lines
                                IF      WINPAUSE        \ release control to OS
                                THEN                    \ for a moment
                                TIB MAXSTRING
                                LEN-PREV +TO SOURCE-POSITION
                                SOURCE-ID READ-LINE THROW_FILEREADFAIL ?THROW
                                IF      DUP 2 + TO LEN-PREV
                                        (SOURCE) !
                                        >IN OFF
                                        .REFILL
                                        TRUE exit
                                ELSE    0 to len-prev
                                THEN
                                DROP
                        THEN
                        FALSE exit
                THEN
                CR QUERY TRUE ;

DEFER STACK-CHECK       ' NOOP   IS STACK-CHECK

FALSE VALUE INCLUDING?

|: DO-INCLUDE    ( -- ) \ Internal word for reading & interpreting a file;
                        \ used by INCLUDE and FLOAD.
                TIBLEN _LOCALALLOC
                (SOURCE) CELL+ !                \ point at new buffer
                INCLUDING?      >R TRUE TO INCLUDING?
                SOURCE-POSITION >R 0 TO SOURCE-POSITION
                LEN-PREV        >R 0 TO LEN-PREV

                BEGIN   REFILL
                        INCLUDING? AND
                WHILE   INTERPRET
                        STACK-CHECK
                REPEAT

                R> TO LEN-PREV
                R> TO SOURCE-POSITION
                R> TO INCLUDING?
                _LOCALFREE
                ;

winlibrary SHLWAPI.DLL
2 proc PathAddExtension
1 proc PathFindFileName

CREATE DEFEXT$  ( -- a1 ) \ the default extension buffer (max 8 chars)
                here ," F" 0 , here swap - 1- CONSTANT DEFEXTMAX

CREATE DEFEXTZ$ ( -- a1 )  \ copy, with . and null terminated
                DEFEXTMAX 1+ here '.' C, 'F' C, 0 C, here swap - - allot

\ VARIABLE EXT_ADDED?             \ January 17th, 2000 - 10:31 added to better
\                                 \ handle files without extensions
\    FALSE EXT_ADDED? !

VARIABLE DEFEXT_ON?             \ January 17th, 2000 - 10:31 added to better
    TRUE DEFEXT_ON? !           \ handle files without extensions

: DEFEXT        ( -<F>- )       \ make -<F>- the default extension
                BL WORD COUNT DEFEXTMAX MIN 2DUP
                DEFEXT$ PLACE
                DEFEXTZ$ PLACE DEFEXTZ$ DUP +NULL '.' SWAP C!
                ;

: "TO-PATHEND"  ( a1 n1 --- a2 n2 )     \ return a2 and count=n1 of filename
                2dup                    \ save originals
                MAX_PATH _LOCALALLOC ascii-z dup \ make zstring on the stack
                call PathFindFileName   \ find the file part
                swap - /string          \ remove the chars from caller
                _LOCALFREE
                ;

: ?DEFEXT       ( addr -- )               \ conditionally add a default extension
                dup +null                 \ make addr end in a null
                DEFEXTZ$                  \ point at dotted zstr
                over 1+ dup>r call PathAddExtension drop \ add extension
                r> zcount nip swap c! \ adjust length
                ;

: _"OPEN        ( a1 n1 -- fileid f1 )  \ open filename a1,n1
                                        \ return fileid and f1=false=ok
                MAXSTRING _LOCALALLOC DUP>R
                PLACE                              \ drop name to OPENBUF
                R@ ?DEFEXT                         \ add extension if needed
                R@ COUNT r/o OPEN-FILE             \ try to open it
                DUP 0=                             \ if we succeeded
                IF
                  R@ COUNT CUR-FILE PLACE          \ then set current file
                THEN
                R> COUNT POCKET PLACE              \ and set POCKET
                _LOCALFREE
                ;

DEFER "OPEN     ( a1 n1 -- fileid f1 )  \ open filename a1,n1  ( but not in editor )
   ' _"OPEN IS "OPEN                    \ return fileid and f1=false=ok

: $OPEN         ( addr -- fileid f1 )   \ open counted filename specified by addr
                                        \ return fileid and f1=false=ok
                COUNT "OPEN ;


\ -------------------- Get/Set current directory ----------------------------

2 PROC GetCurrentDirectory
1 PROC SetCurrentDirectory

: current-dir$  ( -- a1 )       \ get the full path to the current directory
                new$ dup 1+
                MAXCOUNTED call GetCurrentDirectory over c! ;

: $current-dir! ( a1 -- f1 )    \ a1 is a null terminated directory string
                call SetCurrentDirectory ;

\ -------------------- LOADFILE linkage -------------------------------------

HERE ," \program files\win32forth\SRC\KERNEL\FKERNEL.F" CONSTANT KERNFILE \ kernel file
CONSFILE VALUE LOADFILE                  \ pointer to loaded filename

: ISFILE        ( -- )  ;                \ do nothing for file CFAs

1 PROC PathIsRelative                    \ in SHLWAPI.DLL
: IsAbsolutePath? ( a1 n1 -- f )         \ returns true if path is absolute
                MAXCOUNTED _LOCALALLOC   \ allocate a string
                dup>r place r@ +null     \ move the string
                r> 1+                    \ for call
                call PathIsRelative 0=   \ call function
                _LOCALFREE               \ free buffer
                ;

in-system

\ Changed to store file names with full qualified paths.
\ a1 must point to a file name relative to the current directory.
\ September 23rd, 2003 - dbu
: LINKFILE      ( a1 -- ) \ link name a1 as current file IF LOADING ONLY !!
                LOADING?
                IF
                  MAXCOUNTED _LOCALALLOC      \ alloc local path buffer
                  >R                          \ save path buffer addr

                  dup count IsAbsolutePath?   \ make a full qualified path if needed
                  if   count r@ place                  \ store file name
                  else current-dir$ count r@ place     \ store current directory
                       s" \" r@ +place count r@ +place \ append file name
                  then r> UPPERCASE count 2dup         \ uppercase

                  ['] FILES VCFA>VOC (SEARCH-SELF)     \ search for file name
                  IF
                    LATEST-NFA @ TO LOADFILE  \ save last file loaded ptr
                    3DROP
                  ELSE
                    ['] FILES VCFA>VOC _HEADER-BUILD                   \ create header for this file
                    ['] ISFILE CFAPTR!        \ point cfa at this function (null)
                    LAST @ TO LOADFILE        \ last file loaded ptr
                  THEN

                  _LOCALFREE                  \ free local path buffer
                ELSE DROP
                THEN
                ;

in-application

\ -------------------- save/restore file input ------------------------------

: SAVE-INPUT    ( -- ... 7 )                  \ save input
                LOADFILE
                LOADLINE @
                >IN @
                SOURCE-POSITION
                SOURCE-ID
                SOURCE
                7 ;

: RESTORE-INPUT ( ... 7 -- flag )             \ restore input
                7 ?PAIRS
                (SOURCE) 2!
                TO SOURCE-ID
                TO SOURCE-POSITION
                >IN !
                LOADLINE !
                TO LOADFILE
                LOADING?
                IF
                  LOADFILE COUNT CUR-FILE PLACE \ make current again
                THEN
                FALSE ;

| CODE (SAVE-INPUT) ( ... 7 -- R: ... 7 )               \ save input to rstack
                mov     -8 CELLS [ebp], ebx
                pop     -7 CELLS [ebp]
                pop     -6 CELLS [ebp]
                pop     -5 CELLS [ebp]
                pop     -4 CELLS [ebp]
                pop     -3 CELLS [ebp]
                pop     -2 CELLS [ebp]
                pop     -1 CELLS [ebp]
                sub     ebp, # 32
                pop     ebx
                next    c;

| CODE (RESTORE-INPUT) ( R: ... 7 -- ... 7 )            \ save input to stack
                push    ebx
                push    7 CELLS [ebp]
                push    6 CELLS [ebp]
                push    5 CELLS [ebp]
                push    4 CELLS [ebp]
                push    3 CELLS [ebp]
                push    2 CELLS [ebp]
                push    1 CELLS [ebp]
                mov     ebx, 0 CELLS [ebp]
                add     ebp, # 32
                next    c;

\ -------------------- Evaluate ---------------------------------------------

: EVALUATE      ( addr len -- ) \ interpret string addr,len
                save-input (save-input)
                (SOURCE) 2!
                >IN OFF
                -1 TO SOURCE-ID
                ['] INTERPRET CATCH
                (restore-input) restore-input drop
                THROW ;

\ -------------------- Include file support ---------------------------------

in-system

DEFER START-INCLUDE     ' NOOP IS START-INCLUDE
DEFER   END-INCLUDE     ' NOOP IS   END-INCLUDE

: INCLUDE-FILE  ( fileid -- ) \ load file open on "fileid" to current dictionary
                SAVE-INPUT (SAVE-INPUT)         \ save source to rstack
                ( fileid ) TO SOURCE-ID
                POCKET LINKFILE                 \ create a filename link
                LOADLINE OFF                    \ clear the loadline counter
                0 TO SOURCE-POSITION            \ reset the loadfile position
                START-INCLUDE

                ['] DO-INCLUDE CATCH            \ load file and catch errors

                END-INCLUDE
                SOURCE-ID CLOSE-FILE DROP
                THROW                           \ throw load error if any
                (RESTORE-INPUT) RESTORE-INPUT DROP \ restore from rstack
                ;

: INCLUDED      ( addr len -- )   \ load file addr,len into current dictionary
                "OPEN THROW_FILENOTFOUND ?THROW INCLUDE-FILE ;

: $FLOAD        ( a1 -- )         \ a1 = counted file string
                COUNT INCLUDED ;

: FLOAD         ( -<filename>- )  \ load "filename" into application dictionary
                /PARSE-S$ $FLOAD ;

\ ' INCLUDED ALIAS "FLOAD         \ made a colon def - [cdo-2008May13]
\ ' FLOAD    ALIAS INCLUDE        \ made a colon def - [cdo-2008May13]
: "FLOAD        \ synonym of INCLUDED
                INCLUDED ;
: INCLUDE       \ synonym of FLOAD
                FLOAD ;

: SYS-FLOAD     ( -<filename>- )  \ load "filename" into system dictionary
                >SYSTEM
                FLOAD
                SYSTEM> ;

: OK            ( -- ) ;          \ to allow console code with ok prompt to be pasted
\ was:          CUR-FILE $FLOAD ;

in-application

\ -------------------- Comment words ----------------------------------------

: \             ( -- )
                (SOURCE) @ >IN ! ; IMMEDIATE

TRUE VALUE DPR-WARNING?

: DPR-WARNING-OFF ( -- ) \ disable warning for use of deprecated words
                FALSE TO DPR-WARNING? ;

: DPR-WARNING-ON  ( -- ) \ enable warning for use of deprecated words
                TRUE  TO DPR-WARNING? ;

: (dprwarn)     ( f -- f ) \ warn if deprecated word was found
                dup 0<> DPR-WARNING? and
                if   LATEST-NFA @ ?dup
                     if   n>bfa c@ BFA_DEPRECATED and
                          if   WARN_DEPRECATEDWORD WARNMSG
                          then
                     then
                then ;

\ -------------------------- Locals Support  --------------------------
\
\ Syntax is (where [ and ] represent meta-symbols for optional parameters)
\ { [a b c] [\ [d e f]] [-- comments] }
\ The following are valid examples;
\ { }   { a }   { a -- }   { \ }   { a \ d -- comment }
\
\ Local variables can have any name except -- \ or }
\ NOTE: { a -<name>- } declares two locals; it doesn't indicate a parsing word
\       { a -- -<name>- } is the only correct method
\ Added | as alternative for \, as it matches John Hayes' syntax better
\
\ Improved factoring
\
\ arm 25Apr2004 complete rewrite of locals; now uses a vocabulary
\

\ -------------------- Locals Allocation on rstack --------------------------

NCODE _LOCALFREE ( -- )                 \ release local allocation
                mov     ebp, LP [UP]    \ ebp = LP
                mov     eax , 0 [ebp]   \ LP = pop [ebp]
                mov     LP [UP] , eax
                add     ebp, # 4
                next    c;

NCODE _LOCALALLOCP ( n1 -- a1 )
                sub     ebp, ebx        \ subtract n1 from return stack
                and     ebp, # -4       \ cell align return stack
                mov     ebx, ebp        \ move to top of stack
                next    c;

NCODE _LOCALALLOC ( n1 -- a1 )
                mov     eax, LP [UP]    \ push [ebp] = LP
                mov     -4 [ebp], eax
                sub     ebp, # 4
                mov     LP [UP] , ebp   \ LP = ebp
                sub     ebp, ebx        \ subtract n1 from return stack
                and     ebp, # -4       \ cell align return stack
                mov     ebx, ebp        \ move to top of stack
                next    c;

: LOCALALLOC    ( n1 -- a1 )            \ allocate n1 bytes of return stack
                                        \ return a1 the address of the array
                PARMS                   \ if no locals, setup stack frame
                IF      COMPILE _LOCALALLOCP
                ELSE    -1 TO PARMS
                        COMPILE _LOCALALLOC
                THEN    ; IMMEDIATE

: LOCALALLOC:   ( n1 -<name>- )   \ allocate a local n1 byte buffer to local "name"
                ?COMP
                [COMPILE] LOCALALLOC [COMPILE] TO ; IMMEDIATE

\ -------------------- Local Variable Runtime -------------------------------

CFA-CODE LOCAL@ ( locm -- n1 )    \ get the cell n1 from local m
                push    ebx
                mov     ecx, LP [UP]
                mov     eax, 4 [eax]
                mov     ebx, 0 [eax] [ecx]
                next    c;

CFA-CODE LOCAL! ( n locm -- )     \ store n in local m
                mov     ecx, LP [UP]
                mov     eax, -4 [eax]
                mov     0 [eax] [ecx], ebx
                pop     ebx
                next    c;

CFA-CODE LOCAL+! ( n locm -- )    \ add n to local m
                mov     ecx, LP [UP]
                mov     eax, -8 [eax]
                add     0 [eax] [ecx], ebx
                pop     ebx
                next    c;

ASSEMBLER LOCAL@  META CONSTANT DOLOCAL
ASSEMBLER LOCAL!  META CONSTANT DOLOCAL!
ASSEMBLER LOCAL+! META CONSTANT DOLOCAL+!

NCODE UNNESTP   ( -- )                  \ exit the current Forth definition, remove parms
                mov     ebp, LP [UP]
                mov     eax, 0 [ebp]
                mov     esi, 4 [ebp]
                mov     LP [UP], eax
                add     ebp, # 8
                next    c;

' UNNESTP ALIAS EXITP    \ Note: can't be made a colon def - [cdo-2008May13]
                         \ why this synonym ?

NCODE INIT-LOCALS ( loc1 loc2 ... -- )
                mov     eax, LP [UP]            \ push [ebp] = LP
                mov     -4 [ebp], eax
                sub     ebp, # 4
                mov     LP [UP], ebp            \ LP = ebp
                mov     ecx, 0 [esi]            \ ecx=# of locals (bytes 0&1 init, bytes 2&3 uninit)
LABEL MOVE-LOCALS                               \ entry point for CLASS locals
                push    ebx                     \ save ebx on stack for pop
                movsx   eax, cx                 \ sign extend cx to eax (uninit locals)
                sar     ecx, 16                 \ sign extend ecx (init locals)
                add     eax, ecx                \ eax is -ve total # cells to adjust
                lea     ebp, [ebp] [eax*4]      \ adjust ebp, make room for cells
                lea     eax, 1234 [ecx] [ecx*2] \ calculate jump offset
  a; tcode-here cell-                               \ point at the offset in lea
                jmp     eax                     \ and leap...
  a; tcode-here 12 3 * + swap tcode-!                   \ correct the lea calculation
                pop     11 cells [ebp] \ nop   \ 12th
                pop     10 cells [ebp] \ nop
                pop      9 cells [ebp] \ nop
                pop      8 cells [ebp] \ nop
                pop      7 cells [ebp] \ nop
                pop      6 cells [ebp] \ nop
                pop      5 cells [ebp] \ nop
                pop      4 cells [ebp] \ nop
                pop      3 cells [ebp] \ nop
                pop      2 cells [ebp] \ nop
                pop      1 cells [ebp] \ nop
                pop      0 cells [ebp] \ nop   \ to 1st
                pop     ebx                     \ get ebx back
@@9:            mov     eax, 4 [esi]            \ optimised next
                add     esi, # 8
                exec    c;

ASSEMBLER MOVE-LOCALS META CONSTANT MOVE-LOCALS

 0 LOCAL LOCAL0
 1 LOCAL LOCAL1
 2 LOCAL LOCAL2
 3 LOCAL LOCAL3
 4 LOCAL LOCAL4
 5 LOCAL LOCAL5
 6 LOCAL LOCAL6
 7 LOCAL LOCAL7
 8 LOCAL LOCAL8
 9 LOCAL LOCAL9
10 LOCAL LOCAL10
11 LOCAL LOCAL11

| CREATE LOCAL-PTRS ' LOCAL0 , ' LOCAL1 , ' LOCAL2 , ' LOCAL3 , ' LOCAL4 ,
                    ' LOCAL5 , ' LOCAL6 , ' LOCAL7 , ' LOCAL8 , ' LOCAL9 ,
                    ' LOCAL10 , ' LOCAL11 ,

| CREATE LDP  0 , 0 , 0 , DP-LINK LINK, ," *LOCALS"  \ locals pointer

in-system

12 CONSTANT #-LOCALS                            \ must match code above!!!!

4096 EQU LOCALS-LEN
0 | VALUE LOCALS-AREA

0   VALUE INPARMS         \ number of input parameters (locals)
0   VALUE LOCFLG          \ 1 = compiling args, 0 = compiling locals
0 | VALUE LOCDIR          \ direction; <>0 = stack natural, 0 = reversed

|: >LOCAL        ( -- ) LDP >DP ;   \ select app dict, save prev dict
|: LOCAL>        ( -- ) 2R> >R TO DP ;

\ -------------------- Parameter Compiler -----------------------------------

|: >LOC  ( n -- ptr-cfa )
         LOCDIR IF                 \ fetch the right locals cfa
           PARMS 1+ SWAP - THEN
         1- CELLS LOCAL-PTRS + ;

|: LOCALS-VOCINIT ( -- )                        \ init the locals vocab
        LOCALS-AREA DUP DUP
        LDP !                                   \ reset data pointer
        [ LDP CELL+ ] LITERAL !                 \ and origin
        LOCALS-LEN + [ LDP 2 CELLS+ ] LITERAL ! \ and max address
        [ ' LOCALS VCFA>VOC ] LITERAL OFF       \ clean thread in vocabulary
        ;

|: LOCALS-INIT ( -- )                          \ init, check if locals validly used
\        ?csp                                   \ make sure not used inside control structures
        ?comp                                  \ must be compiling
        PARMS THROW_LOCALSTWICE ?THROW         \ and not used before in the definition
        0 TO INPARMS
        1 TO LOCFLG
        TRUE TO LOCDIR
        LOCALS-VOCINIT
        ;

|: PARMS,       ( -- )                  \ compile runtime to push parameters
        PARMS IF                        \ only if parms
          ?:M                           \ in method?
          IF      -CELL ALLOT           \ then deallocate the cell layed down
          ELSE    COMPILE INIT-LOCALS   \ else this is a normal local def
          THEN
          INPARMS PARMS OVER -
          NEGATE W,                    \ #locals, -ve )
          NEGATE W,                    \ #args, -ve )
        THEN ;

|: <LOCAL>      ( addr cnt -- )
                -IF                                   \ looks like std vocab header
                  1 +TO PARMS
                  PARMS #-LOCALS > THROW_LOCALSTOOMANY ?THROW
                  [ ' LOCALS VCFA>VOC ] LITERAL
                  >LOCAL
                  _HEADER-BARE                       \ build header struct
                  HERE SWAP N>CFAPTR ! DROP            \ point cfa here, drop link
                  DOCON , PARMS ,                      \ parm constant <local name>
                  LOCAL>
                  LOCFLG +TO INPARMS
                ELSE 2DROP PARMS,                      \ go create parms
                THEN ;

|: {LOCAL}       ( addr cnt -- )                       \ create name in LOCALS vocab
                ?comp <LOCAL> ;

: (LOCAL)       ( addr cnt -- )                       \ create name in LOCALS vocab
                ?comp
                PARMS 0= IF
                LOCALS-INIT
                FALSE TO LOCDIR                        \ reversed stack order
                THEN <LOCAL> ;


\ August 2nd, 1999 - 11:13 tjz
\ modfied versin of a word suggested by Robert Smith, to get a word from the
\ input stream, delimited by 'char', even if a line crossing is needed.

: NEXTWORD      ( char -- adr flag ) \ flag=TRUE if we got a word, else FALSE
                BEGIN   DUP WORD DUP C@ 0=
                WHILE   refill
                        IF      DROP    \ discard empty word
                        ELSE    NIP     \ discard 'char'
                                FALSE   \ can't find a word
                                exit   \ time to leave
                        THEN
                REPEAT  NIP TRUE ;

|: BLNEXTWORD   ( -- addr ln )  \ check for next word, if fails closing } is missing
                BL NEXTWORD 0= THROW_LOCALSNO} ?THROW
                UPPERCASE COUNT ;

: {     ( -- )  \ begin local variable usage in the form;
                \ { initedloc1 initedloc2 \ uninitedloc3 -- comments }
        LOCALS-INIT
        BEGIN BLNEXTWORD                       \ get next word
              2DUP S" --" STR= >R              \ as in { [...] -- ...
              2DUP S" }"  STR= R> OR INVERT    \ as in { [...] } ...
        WHILE                                  \ if neither, then not done
              2DUP S" \" STR= >R               \ is it { [...] \ ...
              2DUP S" |" STR= R> OR INVERT     \ is it { [...] | ...
              IF {LOCAL}                       \ no, it's a local
              ELSE 2DROP 0 TO LOCFLG THEN      \ onto uninited locals
        REPEAT

        BEGIN                                  \ here at ... -- or ... }
              S" }" STR= INVERT
        WHILE
              BLNEXTWORD                       \ skip until we see ... }
        REPEAT
        PARMS,                                 \ compile runtime code (equiv of 0 0 (LOCAL))
        ; IMMEDIATE

: LOCALS|       ( -- )                         \ ANS standard locals
        BEGIN BLNEXTWORD
              2DUP S" |" STR= INVERT
        WHILE
                (LOCAL)                        \ declare a local
        REPEAT  2DROP
        PARMS,                                 \ compile runtime code (equiv of 0 0 (LOCAL))
        ; IMMEDIATE

in-application

|: PFIND        ( addr -- addr FALSE | cfa -1 | cfa 1 ) \ find possible local
                PARMS                 \ there's got to be a local
                IF
                  STATE @             \ don't search locals if not compiling
                  IF
                    DUP COUNT [ ' LOCALS VCFA>VOC ] LITERAL
                    (SEARCH-WID)
                    IF NIP EXECUTE            \ execute the constant
                       >LOC @ -1 exit        \ get the correct locals CFA
                    THEN
                  THEN
                THEN FALSE
                ;

\ Search order for PARMFIND is
\   locals (case as determined by CAPS)
\   standard vocabularies (case as determined by CAPS)
\   PROCs list (case sensitive)
\     The PROCs search is currently very inefficent, and will need
\     implemented as a proper vocabulary, as it uses "find-proc
\     that does a sequential scan through the PROCs list
\   *** Note that PFIND translates the buffer in-place to uppercase

: PARMFIND      ( addr -- addr FALSE | cfa -1 | cfa 1 )
                dup count find-buffer place     \ copy for case-sensitive searches
                UPPERCASE                       \ uppercase
                PFIND ?DUP 0=
                IF (FIND) ?DUP 0=
                  IF find-buffer count "find-proc \ "find-proc is case sensitive
                    if nip -1 else false then
                  THEN
                THEN

		(dprwarn) ; \ warn if deprecated word is found

' PARMFIND IS FIND

NCODE (&OF-LOCAL) ( -- addr )          \ get address of local following
                push    ebx
                mov     eax, 4 [esi] \ optimised next
                mov     ebx, LP [UP]
                mov     ecx, 0 [esi] \ get xt of local
                add     ebx, 4 [ecx] \ add offset to locals ptr
                add     esi, # 8
                exec    c;

NCODE (&OF-VALUE) ( -- addr )          \ push the literal value following onto the data stack
                push    ebx
                mov     eax, 4 [esi]
                mov     ebx, 0 [esi]
                add     ebx, # 4
                add     esi, # 8
                exec    c;

in-system

: &OF           ( -<name>- addr )   \ get the address of a value or local
                ' DUP @
                STATE @ IF
                  DOLOCAL = IF
                    ['] (&OF-LOCAL)   \ xt of local
                  else
                    ['] (&OF-VALUE)   \ xt of value
                  THEN COMPILE, ,                  \ xt
                ELSE DROP >body
                THEN ; IMMEDIATE

in-application

\ ------------------- Forward reference resolutions.

' _LOCALALLOC   RESOLVES _LOCALALLOC
' _LOCALFREE    RESOLVES _LOCALFREE
' PARMFIND      RESOLVES PARMFIND

\ -------------------- Text Interpreter Loop --------------------------------

DEFER EDIT-ERROR   ' NOOP IS EDIT-ERROR   ( -- ) \ start editor at error

: _RESET-STACKS ( ?? -- ) \ reset the stack
                SP0 @ SP! ;

\ NOTE: RESET-STACKS shouldn't be redefined in an application.
\       Use the reset-stack-chain instead.
DEFER RESET-STACKS ' _RESET-STACKS IS RESET-STACKS ( ?? -- ) \ reset the stack

\ -------------------- Messages ----------------------------

|: ?TYPE        ( c-str -- )                             \ print message if not null
                COUNT -IF TYPE SPACE ELSE 2DROP THEN ;

|: (TYPEMSG)    ( n addr len -- )
                LOADING? IF CR SOURCE TYPE THEN          \ print source line if loading
                CR >IN @ DUP (SOURCE) @ < +              \ adjust if not at end of line
                   POCKET C@ DUP>R - SPACES              \ spaces
                   R> 1 max 0 ?DO [CHAR] ^ EMIT LOOP     \ then (at least one) ^^^ under the word
                BASE @ >R DECIMAL                        \ save base
                CR TYPE ." ("                            \ print type
                DUP TO LAST-ERROR                        \ save error #
                S>D (D.) TYPE ." ): "                    \ i.e "Error(-234): <name> "
                POCKET ?TYPE                             \ show whatever was parsed by WORD
                MSG @ ?TYPE                              \ if message already set, print it
                NULLMSG MSG !                            \ set null message
                THROW_MSGS                               \ list of message
                BEGIN @ ?DUP                             \ get pointer to next message
                WHILE DUP CELL+ @ LAST-ERROR =           \ if it matches
                  IF 2 CELLS+ ?TYPE PTRNULL THEN         \ print the message, set ptr 2 null to stop loop
                REPEAT
                LOADING? IF
                  ." in file " LOADFILE ?TYPE
                  ." at line " LOADLINE @ .
                THEN
                R> BASE !                                \ restore base
                ;

: WARNMSG       ( n -- )                                 \ prints Warning:
                S" Warning" (TYPEMSG) ;                  \ mark the source line in error, warning

: _MESSAGE      ( n -- )                                 \ prints Error:
                DUP 1+ IF                                \ only do this for real errors, not -1 throw
                  S" Error" (TYPEMSG)                    \ mark the source line in error, error
                  LOADING? IF EDIT-ERROR THEN            \ edit if loading
                else drop
                THEN ;

DEFER MESSAGE   ' _MESSAGE IS MESSAGE

: QUERY-INTERPRET   ( -- )
                QUERY SPACE INTERPRET ;

: QUIT          ( -- )
                RP0 @ RP!
                BEGIN   [COMPILE] [
                        BEGIN   CR ['] QUERY-INTERPRET CATCH  ?DUP 0=
                        WHILE   STATE @ 0=
                                IF      ."  ok"
                                        DEPTH .SMAX @ MIN 0
                                        ?DO  [CHAR] . EMIT  LOOP
                                THEN
                        REPEAT
                        CONSOLE         \ select the forth console
                        DUP 1+          \ no message on abort
                        IF      MESSAGE
                        THEN
                        RESET-STACKS    \ reset the stacks
                AGAIN ;

DEFER BOOT              ' INIT-CONSOLE   IS BOOT

0 PROC GetCommandLine
| CREATE &CMDLINE
       0 ,                              \ length
       0 ,                              \ address

|: GETCMDLINE   ( -- )                                \ prepare the command line
                call GetCommandLine zcount            \ get the commandline
                over c@ [char] " = if                 \ first char a " ?
                  1 /string                           \ skip it
                  [char] "                            \ find next " character
                else bl then                          \ else look for a blank
                scan 1 /string bl skip                \ scan for & bump past, skip blanks
                &CMDLINE 2!                           \ set command line
                ;

: CMDLINE       ( -- addr len )                       \ fetch command line
                &CMDLINE 2@ ;

\ -------------------- Task support & initialisation ------------------------

\ VARIABLE &EXCEPT
\ VARIABLE &EXREC
variable exc-guard
variable exc-access

align
here: K32VAL
4 PROC VirtualAlloc
K32VAL proc>ep constant EXCEPT-VALLOC  \ points at VirtualAlloc ep

CFA-CODE EXCEPT-HANDLER
((
 Exception code set in entry. Used by this code and tasks.f to provide
 memory commit for pages that cause an exception C0000005 (access violation)
 for writes to memory. Allows VirtualAlloc MEM_RESERVE, and the system
 will automatically turn that into MEM_COMMIT.
))
                push    ebp                               \ save regs
                mov     ebp, esp
                push    ebx
                push    edi
                push    esi
                mov     eax, 8 [ebp]                      \ get exception record
                test    4 [eax], 0x03                     \ non-continuable?
                jnz     short @@8                         \ next handler
                mov     ecx, 0 [eax]                      \ fetch exception code
                cmp     ecx, # EXCEPTION_GUARD_PAGE       \ guard violation?
                jne     short @@2                         \ no, carry on
                add     dword exc-guard , # 1             \ WIN2K+ only, increment guard count
                xor     eax, eax                          \ just carry on, all ok
                jmp     short @@9                         \ exit
@@2:            cmp     ecx, # EXCEPTION_ACCESS_VIOLATION \ is it an access violation?
                jne     short @@8                         \ no, carry on with search
                cmp     20 [eax], # 0                     \ is the violation a read?
                je      short @@8                         \ don't bother, continue
                mov     eax, 24 [eax]                     \ from exception record
                cmp     eax, # 0                          \ is address 0?
                je      short @@8                         \ don't bother, continue
                push    # PAGE_EXECUTE_READWRITE          \ read/write/execute
                push    # MEM_COMMIT                      \ commit
                push    # 1                               \ one byte will do
                push    eax                               \ address to commit
                xor     eax, eax                          \ zero eax
                call    except-valloc [eax]               \ loaded in kernel (should be call [addr])
                or      eax, eax                          \ test return address
                jz      short @@8                         \ null, continue search
                add     dword exc-access , # 1            \ increment access count
                xor     eax, eax                          \ just carry on, all ok
                jmp     short @@9                         \ and exit
@@8:            mov     eax, # 1                          \ execute next handler
@@9:            pop     esi                               \ exit
                pop     edi
                pop     ebx
                mov     esp, ebp
                pop     ebp
                ret
                c;

ASSEMBLER EXCEPT-HANDLER  META CONSTANT EXCEPT-HANDLER


\ -------------------- Main Entry Point -------------------------------------

3 PROC GetModuleFileName
1 PROC PathRemoveFileSpec

0 VALUE &PROGNAM
\ *G The program name buffer
\ ** (the name of the exe-file including the full path).

0 VALUE &FORTHDIR
\ *G The Win32Forth installation directory
\ ** (in turnkey applications it's the path of the exe-file).

maxstring 7 * tiblen + equ buffs-len

|: MAIN         ( -- )                                 \ MAIN start forth main entry point

                init-proc                              \ *** MUST BE FIRST IN MAIN ***
                init-malloc
                ['] TEMP$ IS NEW$                      \ Must be set until pointers are inited
                buffs-len malloc
                            dup to CUR-FILE
                maxstring + dup to TEMP$
                maxstring + dup to FIND-BUFFER
                maxstring + dup to POCKET
                maxstring + dup to SPCS
                maxstring + dup to &PROGNAM
                maxstring + dup to &FORTHDIR
                tiblen    +     (source) cell+ !
                sys-size if                            \ when not turnkeyed
                  sys-here locals-len sys-allot to LOCALS-AREA \ allocate buffers
                  LOCALS-VOCINIT                       \ initialise
                then

                spcs spcs-max blank                    \ fill spaces buffer

                MAXSTRING &prognam char+
                appInst call GetModuleFileName         \ and exe name
                &prognam c!

                MAXSTRING &forthdir char+              \ installation directory
                appInst call GetModuleFileName dup
                &forthdir c!
                if   &forthdir char+ dup call PathRemoveFileSpec drop
                     zcount nip &forthdir c!
                     s" \" &forthdir +place &forthdir +null
                then

                GETCMDLINE                             \ prepare the cmdline

                CONSFILE TO LOADFILE

                ['] BOOT CATCH                         \ do BOOT
                IF      BYE         ( fatal error, exit)
                THEN
                &EXCEPT @ 0= sys-size and
                IF      CMDLINE ['] EVALUATE CATCH DUP
                        IF      DUP 1+ IF MESSAGE THEN
                        THEN
                THEN
                RESET-STACKS

                QUIT ;

8 4096 *                     | CONSTANT RSTACKSIZE \ rstack size
RSTACKSIZE USERSIZE + 4096 / | CONSTANT PROBESTACK \ amount to probe the stack (pages)

CFA-CODE TASK-ENTRY  ( -- )
                pop     esi                     \ return address in esi
                                                \ esi must not be changed here
                mov     ecx, # PROBESTACK       \ number of pages to probe stack
                mov     edx, esp                \ stack address
@@2:            mov     -4092 [edx], # 0        \ probe page at [edx]
                sub     edx, # 4096             \ next page down
                loop    @@2                     \ loop

                and     esp, # -16              \ align to 16 byte boundary
                mov     eax, esp                \ rstack top in eax
                sub     esp, # RSTACKSIZE       \ room for return stack

                mov     edx, esp                \ user area is on stack
                mov     fs: 0x14 , edx          \ save in TIB at pvArbitrary
                mov     RP0 [UP] , eax          \ save RP0
                sub     esp, # USERSIZE         \ subtract usersize

                push    dword # EXCEPT-HANDLER  \ err handler address
                push    fs: 0                   \ previous error handler
                mov     fs: 0 , esp             \ our structure now in TIB
                sub     esp, # 32               \ back off 8 cells
                and     esp, # -16              \ align to 16 byte boundary

                mov     SP0 [UP] , esp          \ save SP0
                mov     BASE [UP] , dword # 10  \ default base to decimal

                xor     edi, edi                \ edi is constant 0
                pop     ebx                     \ pop for adjust
                jmp     esi  c;                 \ back to caller

ASSEMBLER TASK-ENTRY  META CONSTANT TASK-ENTRY


\ -------------------- EXEM Start Entry Point -------------------------------

CFA-CODE EXEM   ( -- )                         \ EXE entry point
                0XE8 tcode-c, 0 tcode-,                \ call next word
                pop     eax                    \ get address of me
                sub     eax, # EXEM IMAGE-ORIGIN - 5 + \ subtract to get loadpoint (length of call is 5)
\               int 3                          \ DEBUGGING ONLY
                push    ebp                    \ save regs
                push    ebx
                push    edi
                push    esi
                mov     ebp, esp
                mov     ' appInst >body , eax  \ save in appinst
                call    TASK-ENTRY             \ setup stack, error handler etc
                mov     eax, # ' main          \ main entry point
                exec    c;                     \ go do it, no return to here...

ASSEMBLER EXEM META CONSTANT EXEM              \ exe entry point


\ -------------------- Early DLL and EP initialisation, temporary -----------

| NCODE INIT-K32   ( -- )                     \ initialize for windows calls
                push    ebp                   \ save regs, these get wiped otherwise
                push    ebx
                push    edx
                push    esi
                mov     ebp, esp

                mov     eax, ' appInst >body  \ get appinst
                mov     ebx, 0x3c [eax]       \ from dos header to pe header
                add     eax, 0xd8 [eax] [ebx] \ from pe header to iat
                push    4 [eax]               \ ep of GetProcAddress from IAT, save for later
                mov     ebx, 0 [eax]          \ ep of LoadLibrary from IAT
                mov     K32LLI proc>ep , ebx  \ save in the PROC for LoadLibrary
                push    # K32DLL lib>name 1+  \ point at KERNEL32.DLL string
                call    ebx                   \ call LoadLibrary
                mov     K32DLL lib>handle , eax \ save the address in DLL
                mov     esi, eax              \ module in esi
                pop     ebx                   \ get back ep of GetProcAddress
                mov     K32GPA proc>ep , ebx  \ save in the PROC for GetProcAddress

                push    # K32GLE proc>name 1+ \ point at GetLastError
                push    esi
                call    ebx                   \ get the address
                mov     K32GLE proc>ep , eax  \ save ep

                push    # K32VAL proc>name 1+ \ point at VirtualAlloc
                push    esi
                call    ebx                   \ get the address
                mov     K32VAL proc>ep , eax  \ save ep

                mov     eax, # K32DLL      \ point at kernel DLL structure
                mov     K32GPA proc>lib , eax \ and save in GetProcAddress
                mov     K32LLI proc>lib , eax \ and save in LoadLibrary
                mov     K32GLE proc>lib , eax \ and save in GetLastError
                mov     K32VAL proc>lib , eax \ and save in VirtualAlloc

                mov     esp, ebp
                pop     esi                               \ exit
                pop     edx
                pop     ebx
                pop     ebp
                next    c;

\ -------------------- Tools --------------------

|: H.BASE>HEX   ( n1 n2 -- base n1 n2 )
                BASE @ -ROT HEX ;

: H.R           ( n1 n2 -- )    \ display n1 as a hex number right
                                \ justified in a field of n2 characters
                H.BASE>HEX
                >R 0 <# #S #> R> OVER - SPACES TYPE
                BASE ! ;

: H.N           ( n1 n2 -- )    \ display n1 as a HEX number of n2 digits
                H.BASE>HEX
                0 <# SWAP 0 ?DO # LOOP #> TYPE
                BASE ! ;

: H.2           ( n1 -- ) 2 H.N ;               \ two digit HEX number
: H.4           ( n1 -- ) 4 H.N ;               \ four digit HEX number
: H.8           ( n1 -- ) 8 H.N ;               \ eight digit HEX number

: EMIT.         ( n -- )
                DUP BL 255 BETWEEN 0= IF  DROP [CHAR] .  THEN  EMIT ;

: WAIT          ( -- )
                KEY ( k_ESC ) 27 = IF ABORT THEN ;

: .S            ( -- ) \ display current data stack contents
                ?STACK
                DEPTH .SMAX @ MIN
                -IF     ." ["
                        DEPTH 1- 1 .R
                        ." ] "
                        BEGIN   DUP PICK 1 .R
                                BASE @ 16 =
                                IF       ." h"
                                THEN
                                SPACE
                                1- DUP 0=
                        UNTIL
                ELSE    ."  empty "
                THEN    DROP ;

in-system

: .NAME         ( xt -- )       \ show name, if can't find name, show address
                DUP >NAME DUP NAME> ['] [UNKNOWN] =     \ if not found
                IF      DROP [CHAR] " EMIT ." 0x" 1 H.R [CHAR] " EMIT SPACE
                ELSE    .ID DROP
                THEN    ;

18 VALUE SCREENDELAY    \ delay value for some screen output

CREATE DELAYS     0 W,    1 W,   18 W,   25 W,   40 W,
                 60 W,   90 W,  120 W,  200 W,  500 W,

: _START/STOP   ( -- )
                KEY?
                IF KEY  10 DIGIT ( number keys select delay )
                        IF 2 * DELAYS + W@ TO SCREENDELAY
                        ELSE  ( k_ESC ) 27 = IF ABORT THEN  WAIT
                        THEN
                THEN ;

' _START/STOP IS START/STOP

VARIABLE ECHO  \ ECHO ON echos everything to the console that's included

|: ?.REFILL      ( -- )
                ECHO @
                IF      CR SOURCE TYPE
                        START/STOP
                THEN    ;

DEFER .REFILL   ' ?.REFILL IS .REFILL

: NUF?          ( -- f1 )
                ['] START/STOP CATCH ;

: KWORDS        ( -- ) \ simple version of words
                CR CONTEXT @
                DUP VOC#THREADS >R
                HERE 500 + R@ CELLS CMOVE        \ copy vocabulary up
                BEGIN   HERE 500 + R@ LARGEST DUP
                WHILE   DUP L>NAME COUNT NIP 7 + ?CR
                        DUP LINK> ." 0x" H.8 SPACE
                        DUP L>NAME .ID 23 #TAB
                        @ SWAP !
                        START/STOP
                REPEAT  2DROP  R>DROP ;

IN-APPLICATION

#version# constant version#
#build#   constant build#

: ((version))   ( version# -- addr len )
                0 <# # # '.' hold # # '.' hold #s #> ;

: .version      ( -- )
                base @ decimal
                cr ." Version: "
                version# ((version)) type
                ."  Build: " build# .
                base ! ;

\ ------------------- Forward reference resolutions.

' .REFILL       RESOLVES .REFILL

\ =================================================================
\ =================================================================
\
\       These definitions must be last so they are not used
\       during meta compilation
\
\ =================================================================
\ =================================================================

in-system

|: EXIT_A       ( -- )
                ?COMP
                ?:M THROW_METHEXIT ?THROW           \ Can't use EXIT in a Method
                FALSE TO ?:M
                ;

: EXIT          ( -- )
                EXIT_A
                PARMS
                IF      COMPILE UNNESTP
                ELSE    COMPILE UNNEST
                THEN    ; IMMEDIATE

: ?EXIT         ( F1 -- )
\                EXIT_A
                [COMPILE]  IF
                [COMPILE]  EXIT
                [COMPILE]  THEN ; IMMEDIATE

|: DOES>_A      ( -- )
                ?COMP
                ?:M     ( -- F1 )
                FALSE TO ?:M
                        ( -- f1 ) THROW_METHDOES> ?THROW \ Can't use DOES> in a Method
                PARMS
                IF      COMPILE _LOCALFREE
                        COMPILE PARMS-INIT
                THEN
                ;

|: DOES>_B      ( -- )
                DODOES-CALL,
                PARMS-INIT ;

: DOES>         ( -- )
                SYS-WARNING? SYS-WARNING-OFF
                DOES>_A
                COMPILE (DOES>)
                DOES>_B TO SYS-WARNING? ; IMMEDIATE

: #DOES>        ( -- )          \ "compile time"
                ( a1 -- )       \ "runtime" a1=cfa of word being defined
                DOES>_A
                COMPILE #(;CODE)
                DOES>_B ; IMMEDIATE

\ Semicolon ';' must be compiled after its last use in the meta compile
\ ---------------------------------------------------------------------------

DEFER DO-;CHAIN ' NOOP IS DO-;CHAIN

: ;             ( -- )
                ?COMP
                ?:M     ( -- F1 )
                FALSE TO ?:M
                        ( -- f1 ) THROW_METH;M ?THROW \ Methods must END in ;M
                ?CSP REVEAL
                PARMS
                IF      COMPILE UNNESTP
                ELSE    COMPILE UNNEST
                THEN ( EXIT_B )  [COMPILE] [ PARMS-INIT DO-;CHAIN ; IMMEDIATE


\ ------------------- The End -----------------------------------------------

\ ------------------- Forward reference resolutions.

in-application

' UNNEST        RESOLVES EXIT
' CONSTANT      RESOLVES CONSTANT
' THROW         RESOLVES THROW
' ALIGNED       RESOLVES ALIGNED
' LOAD-DLL      RESOLVES LOAD-DLL
' INIT-K32      RESOLVES INIT-K32
' LOADFILE      RESOLVES LOADFILE
' NABORT!       RESOLVES NABORT!
' ?THROW        RESOLVES ?THROW
' WARNMSG       RESOLVES WARNMSG
