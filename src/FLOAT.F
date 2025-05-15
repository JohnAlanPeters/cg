\ $Id: FLOAT.F,v 1.66 2014/08/06 12:30:30 georgeahubert Exp $
\ float.f                                                A. McKewan
\                  Modified substantially by R. Smith

\ Floating point values are maintained on a separate stack.
\ Major changes by rls to convert to a software stack

\ ------------------- Bug Fix Log -----------------------------------------
\ rls 09-21-97  Bug fixes for FTANH and E by itself.
\ rls 09-30-97  correction to restore change by SMuB, which we don't have a
\               comment to explain
\ tjz 03-16-98  added FCALLRET, FCALL and FS>DS from Bill McCarthy.
\ 4-1-98 J.v.d.Ven. I put the stack into the user-area.
\               Note: The user-area should be extended.
\ tjz 01-11-99
\ Extended User area to 4096 bytes, added several new user words to kernel.
\ Added macros for DATA stack memory, Floating Point Stack Pointer, and
\ FLoating Point Stack Data area, so I could track changes when the stacks
\ were moved to the USER area.
\ rls 03-13-99  Correction for F>D, includes suggestions from Bill McCarthy
\ tjz 04-16-99  Added F2DROP, F2DUP and F2SWAP.
\ float.f beta 4.9C 2003/02/13 arm Remove all FWAIT/WAIT as only 386 co-processor requires
\ float.f beta 4.9D 2003/02/18 arm Added RBS code (needs stack comments)
\ dbu Samstag, Mai 14 2005 major changes to make more readable and shorter
\   also fixed a lot of wrong stack coments
\ gah Thursday, May 19 2005 optimized fdrop and f2drop for better decoding
\ gah Thursday, May 26 2005 added macro 2>FPU
\ gah Saturday, June 25 2005 modified rep-zero to correct bug in represent
\ gah Thursday, June 30 2005 modified rep-normal to correct bug in represent
\ gah Thursday, June 30 2005 made FLOOR FROUND FTRUNC thread-safe
\ gah Tuesday, July 12 2005 converted DATASTACK_MEMORY FSP_MEMORY and FSTACK_MEMORY to use macro:
\ dbu Sonntag, Juli 31 2005 changed the default display of the floating point stack in the debuger
\                           from .FDEPTH to F.S
\ gah Sunday, November 6 2005 major changes to macros to reduce code size and increase speed
\                             and make code more easy to port to STC (work in progress)
\ gah Monday, November 14 2005 corrected bug in ZF>D and further optimizations
\ -------------------------------------------------------------------------

\ *D doc
\ *! p-float W32F float
\ *T Floating point words in Win32Forth

\ *P Win32Forth implements the full ANSI floating-point and floating-point extension
\ ** wordsets as well as a number of useful extra words. It uses a separate floating-point
\ ** stack (implemented in the USER area for task safety).

\ *P The floating-point words can be compiled as 8 byte (for speed) or 10 byte (for accuracy).
\ ** The default when the system is built is 8 byte, but can be set to 10 byte (in src\extend.f) by
\ ** altering the CONSTANT B/FLOAT and re-extending the system (using setup.exe).
\ ** If the CONSTANT is not defined then the file automatically creates it and compiles
\ ** the code for 10 byte floats.

\ *P The only error that is thrown is for FP stack Underflow (error code -45);
\ ** arithmetic operations which produce values too large to be represented use infinity,
\ **  while indeterminate results produce NANs.

\ *S Glossary

\ *W <ul><li><a href="#Sec#1">Loading and saving FPU registers</a></li>
\ *W <li><a href="#Sec#2">Memory Access</a></li>
\ *W <li><a href="#Sec#3">FP Stack operations</a></li>
\ *W <li><a href="#Sec#4">FP Stack operations on pairs of entries</a></li>
\ *W <li><a href="#Sec#5">FP Constants</a></li>
\ *W <li><a href="#Sec#6">FP Variables</a></li>
\ *W <li><a href="#Sec#7">Rounding functions</a></li>
\ *W <li><a href="#Sec#8">Integer to float conversion</a></li>
\ *W <li><a href="#Sec#9">FP Comparison operators</a></li>
\ *W <li><a href="#Sec#10">Arithmetic operators</a></li>
\ *W <li><a href="#Sec#11">Trigonometric functions</a></li>
\ *W <li><a href="#Sec#12">Inverse Trigonometric functions</a></li>
\ *W <li><a href="#Sec#13">Logarithmic functions</a></li>
\ *W <li><a href="#Sec#14">Exponential functions</a></li>
\ *W <li><a href="#Sec#15">Hyperbolic functions</a></li>
\ *W <li><a href="#Sec#16">Inverse hyperbolic functions</a></li>
\ *W <li><a href="#Sec#17">Input of Floating Point numbers</a></li>
\ *W <li><a href="#Sec#18">Output conversion</a></li>
\ *W <li><a href="#Sec#19">Format FP number to a buffer</a></li>
\ *W <li><a href="#Sec#20">Display FP numbers</a></li>
\ *W <li><a href="#Sec#21">Debugging tools</a></li></ul>

cr .( Loading Floating Point...)

in-system

macro: DATASTACK_MEMORY      ( -- )
                0 [tos] endm

in-previous

\ *W <a name="Sec#1"></a>
\ *N Loading and saving FPU registers

\ *P The following words are for examining, saving, restoring and changing the state of the
\ ** x87 FPU. They are not normally needed by applications although they can be useful for
\ ** dealing with legacy code, which requires different rounding modes, precision, or
\ ** exception handling. \n
\ ** Since the default error handler resets the control word then applications that use
\ ** other settings will need to CATCH all exceptions or modify the error handler. \n
\ ** NOTE if programs unmask exceptions then they need to handle their own errors.
\ ** For information on the settings and writng exception handlers refer to the INTEL
\ ** processor documentation.
\ *P \b WARNING! \d do not alter the settings unless you know what you're doing.

code >fregs     ( addr -- )             \ W32F         Floating extra
\ *G Restore x87 FPU State.
                frstor  DATASTACK_MEMORY
                pop     tos
                next,
                end-code

code >fregs>    ( addr -- )             \ W32F        Floating extra
\ *G Save and Restore x87 FPU State.
                fsave   DATASTACK_MEMORY
                frstor  DATASTACK_MEMORY
                pop     tos
                next,
                end-code

code fpcw>      ( -- n )                \ W32F        Floating extra
\ *G Get x87 FPU Control Word.
                push    tos
                xor     tos, tos   \ avoids partial stall
                push    tos
                fstcw   word 0 [esp]
                pop     tos
                next,
                end-code

code >fpcw      ( n -- )                \ W32F        Floating extra
\ *G Set x87 FPU Control Word.
                push    tos
                fldcw   word 0 [esp]
                add     esp, # 4
                pop     tos
                next,
                end-code

code fpsw>      ( -- n )                \ W32F        Floating extra
\ *G Get x87 FPU Status Word.
                push    tos
                fstsw  ax
                mov     tos, eax
                next,
                end-code

[undefined] B/FLOAT [if]
 10 constant B/FLOAT  ( -- n )          \ W32F         Floating extra
\ *G Number of bytes in a floating-point number. Note the default is 8 bytes.
[then]

cr B/FLOAT . .( byte floating point numbers)

\ The next word is mainly for SEE.F
B/FLOAT aligned cell / checkstack
value cells/float
\ *G Number of cells in a floating-point number. If the number of bytes is not a multiple
\ ** of 4 this is rounded up.

also assembler definitions

in-system

B/FLOAT 10 =
[IF]    : FSIZE extended ;  \ synonym FSIZE extended   \ made a colon def - [cdo-2008May13]
[ELSE]  : FSIZE double ;    \ synonym FSIZE double     \ made a colon def - [cdo-2008May13]
[THEN]

in-previous

previous definitions

cell NEWUSER FLOATSP ( -- addr )                    \ W32F             Floating extra
\ *G Address of floating point stack pointer in the user area.
256 constant fstack-elements            \ 256 floating point elements in stack
next-user @ 0x10 naligned next-user !   \ align next user to quadword
fstack-elements B/FLOAT * NEWUSER FLOATSTACK

in-system

macro: FSP_MEMORY    ( -- )
                FLOATSP [up] endm

macro: FSTACK_MEMORY ( -- )
                FLOATSTACK [ecx] [up] endm

macro: +FSTACK_MEMORY ( n -- )
                FLOATSTACK + [ecx] [up] endm

in-previous

-45 Constant THROW_FLOATSTACKUNDER
THROW_MSGS LINK, THROW_FLOATSTACKUNDER  , ,"  Floating Point Stack Underflow !!! "
: FSTKUFLO      ( -- ) \ handle floating point stack underflow
                THROW_FLOATSTACKUNDER throw ;

: FDEPTH        ( -- n ) \ return floating point stack depth
                FLOATSP @ B/FLOAT / ;


\ FXAM results:
\ Class                C3 C2 C0
\ Unsupported          0  0  0
\ NaN                  0  0  1
\ Normal finite number 0  1  0
\ Infinity             0  1  1
\ Zero                 1  0  0
\ Empty                1  0  1
\ Denormal number      1  1  0
\
\ The C1 flag is set to the sign of the value in ST(0),
\ regardless of whether the register is empty or full.

0x4700 constant FPU_STATUS_CCF_MASK      \ mask for C0, C1, C2 and C3
0x0200 constant FPU_STATUS_CCF_MASK_1    \ mask for C1
0x4500 constant FPU_STATUS_CCF_MASK_023  \ mask for C0, C2 and C3

0x0000 constant FPU_STATUS_CCF_UNSUPPORTED
0x0100 constant FPU_STATUS_CCF_NAN
0x0400 constant FPU_STATUS_CCF_NORMAL
0x0500 constant FPU_STATUS_CCF_INFINITY
0x4000 constant FPU_STATUS_CCF_ZERO
0x4100 constant FPU_STATUS_CCF_EMPTY
0x4400 constant FPU_STATUS_CCF_DENORMAL

code fexam      ( fs: r -- r ; -- n ) \ Examines r and return the condition code flags C0, C2, and C3
                push    ebx
                mov     ecx, FSP_MEMORY
                sub     ecx, # B/FLOAT
                jns      short L$1
                mov     ebx, # FPU_STATUS_CCF_EMPTY
                jmp     short L$2
L$1:            fld     FSIZE FSTACK_MEMORY
                fxam
                fstsw  ax
                mov     ebx, eax
                and     ebx, # FPU_STATUS_CCF_MASK
                fstp    st(0)
L$2:            next,
                end-code

code finit      ( -- )                  \ W32F    Floating extra
\ *G Clears the floating-point stack & sets the appropriate byte mode.
\ ** It is executed by the system on start-up and by the default exception handler.
\ ** Users generally don't need to call this word in a single-task program.
\ ** Tasks in a multi-task program should execute this word before executing any
\ ** other floating-point words.
                finit
                mov     FSP_MEMORY , edi
                B/FLOAT 10 = 0=              [IF]
                fstcw   word -4 [ebp]
                and     word -4 [ebp], # 0x0eff           \ 8  byte mode
                fldcw   word -4 [ebp]        [THEN]
                next,
                end-code

initialization-chain chain-add finit
finit           \ Initialize the fpu

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

in-system

false value fsp-cached?
0 value fsp-adjust

macro:  +fsp-adjust
                b/float +to fsp-adjust
                endm

macro:  -fsp-adjust
                b/float negate +to fsp-adjust
                endm

\ macro to copy ST(0) on the separate float stack
macro:  (FPU>)
                fsp-cached? 0= if
                mov     ecx, FSP_MEMORY
                true to fsp-cached? then
                fstp    FSIZE fsp-adjust +FSTACK_MEMORY
                endm


\ macro to move ST(0) on the separate float stack
macro:  FPU>
                (FPU>)
                +fsp-adjust
                endm

\ macro to move the top of the separate float stack into st(0)
macro:  >FPU
                fsp-cached? 0= if
                mov     ecx, FSP_MEMORY
                true to fsp-cached? then
                -fsp-adjust
                fld     FSIZE fsp-adjust +FSTACK_MEMORY
                endm

\ makro to copy the top of the separate float stack into st(0)
macro:  (>FPU)
                >FPU
                +fsp-adjust
                endm

\ macro to move the top 2 values from the separate float stack into st(0) and st(1)
macro: 2>FPU
                >FPU >FPU
                endm

\ macro to end float words
macro: float;
                fsp-adjust if fsp-adjust 0< if
                sub     ecx,  # fsp-adjust negate
           else add     ecx,  # fsp-adjust then
                mov     FSP_MEMORY , ecx
                0 to fsp-adjust then
                false to fsp-cached? next ;c endm

in-previous

\ Subroutine to check the depth of the float stack for underflow errors.
\ Input: eax = number of floats we need times b/float.
subr:   fstack-check
                mov     ecx, FSP_MEMORY
                cmp     ecx, eax
                js      short L$1
                ret     \ stack is fine, return to caller
L$1:            mov     eax, # ' FSTKUFLO       \ throw underflow error
                exec                            \ doesn't return to caller !!!
                end-code

in-system

\ macro to check if there is at least one element on the floating point stack
macro:  fstack-check_1
                mov     eax, # b/float
                call    fstack-check
                true to fsp-cached?
                endm

\ macro to check if there are at least two elements on the floating point stack
macro:  fstack-check_2
                mov     eax, # b/float 2*
                call    fstack-check
                true to fsp-cached?
                endm

\ macro to check if there are at least three elements on the floating point stack
macro:  fstack-check_3
                mov     eax, # b/float 3 *
                call    fstack-check
                true to fsp-cached?
                endm

in-previous

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ memory operators
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

\ *W <a name="Sec#2"></a>
\ *N Memory Access

code F@         ( addr -- ; fs: -- r )  \ ANSI      Floating
\ *G Fetch a float.
                fld     FSIZE DATASTACK_MEMORY
                FPU>
                pop     ebx
                float;

code SF@        ( addr -- ; fs: -- r )  \ ANSI       Floating ext
\ *G Fetch a 32 bit (short) float.
                fld     float DATASTACK_MEMORY
                FPU>
                pop     ebx
                float;

code DF@        ( addr -- ; fs: -- r )  \ ANSI       Floating ext
\ *G Fetch a 64 bit (double) float.
                fld     double DATASTACK_MEMORY
                FPU>
                pop     ebx
                float;

code F!         ( addr -- ; fs: r -- )  \ ANSI        Floating
\ *G Store a float.
                fstack-check_1
                >FPU
                fstp    FSIZE DATASTACK_MEMORY
                pop     ebx
                float;

code SF!        ( addr -- ; fs: r -- )  \ ANSI        Floating ext
\ *G Store a 32 bit (short) float.
                fstack-check_1
                >FPU
                fstp    float DATASTACK_MEMORY
                pop     ebx
                float;

code DF!        ( addr -- ; fs: r -- )  \ ANSI        Floating ext
\ *G Store a 64 bit (double) float.
                fstack-check_1
                >FPU
                fstp    double DATASTACK_MEMORY
                pop     ebx
                float;

code F+!        ( addr -- ; fs: r -- )  \ W32F       Floating extra
\ *G Add the value to a float.
                fstack-check_1
                >FPU
                fld     FSIZE DATASTACK_MEMORY
                faddp   st(1), st
                fstp    fsize datastack_memory
                pop     tos
                float;

: F,            ( fs: r -- )     \ W32F        Floating extra
\ *G Compile a float into the dictionary.
                here f! B/FLOAT allot ;


\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ Floating point Variables, Values and Constants
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

internal

cfa-code dofvalue  ( fs: -- r )
    mov      ecx,  4 [eax]
    fld      fsize 0 [ecx]
    FPU>
    float;

cfa-code dofvalue!  ( fs: r -- )
    push    ebx
    mov     ebx, -4 [eax]
    fstack-check_1
    >FPU  \ to st(0)
    fstp    FSIZE datastack_memory
    pop     ebx
    float;

cfa-code dofvalue+! ( fs: r -- )
    push    tos
    mov     ebx, -8 [eax]
    fstack-check_1
    >FPU
    fld     FSIZE DATASTACK_MEMORY
    faddp   st(1), st
    fstp    fsize datastack_memory
    pop     tos
    float;

external

in-system

: FVARIABLE     ( compiling "name"  -- ; run-time -- addr) \ ANSI        Floating
\ *G Define a floating-point variable in the dictionary. The contents are undefined.
                create B/FLOAT allot ;

: FVALUE  ( compiling "name" -- ; fs: r -- ; run-time FS: -- r  ) \ W32F    Floating ext
\ *G Define a floating point value initialised from the FP stack.
                header dofvalue , here 0 , dofvalue! , dofvalue+! , here swap ! f, ;

synonym fto to                          \ W32F               Floating extra
\ *G \b Interpretation: ( -<fvalue>- -- fs: r -- ) \n
\ ** Compilation:    ( -<fvalue>- --  Run-time: FS: r -- ) \d
\ *P Store r into -<fvalue>-.

synonym +fto +to                        \ W32F               Floating extra
\ *G \b Interpretation: ( -<fvalue>- -- fs: r -- ) \n
\ ** Compilation:    ( -<fvalue>- --  Run-time: FS: r -- ) \d
\ *P Add r into -<fvalue>-.

: FCONSTANT      ( "name" -- ; fs: r -- )      \ ANSI               Floating
\ *G      \b Interpretation: ( "name" ; fs: r -- ) \d \n
\ ** Define an FP constant. \n
\ **      \b Compilation: \d \n
\ ** Append the run-time semantics given below to the current definition. \n
\ **      \b Run-time:  ( fs: -- r ) \d \n
\ ** Place r on the floating-point stack.
                create f, ;code
                fld     fsize 4 [eax]
                FPU>
                float;

in-previous

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ Floating point literals. We store the 64-bit or 80-bit floating point
\ literal inline and push to the FP stack at runtime.
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

internal

code flit       ( fs: -- r )
                fld     FSIZE 0 [esi]
                FPU>

        B/FLOAT 10 =
        [IF]    add     esi, # 12        \ to keep dword alignment !
        [ELSE]  add     esi, # 8
        [THEN]  float;

0 value &flit
' flit to &flit \ for the debugger

external

\ in-system

: FLITERAL      ( Compilation fs: r -- ; Runtime fs: -- r )  \ ANSI         Floating
\ *G         \b Interpretation: \d \n
\ ** Interpretation semantics for this word are undefined. \n
\ **         \b Compilation: ( fs: r -- ) \d \n
\ ** Append the run-time semantics given below to the current definition. \n
\ **         \b Run-time: ( fs: -- r ) \d \n
\ ** Place r on the floating-point stack.
                postpone flit
                here CELLS/FLOAT cells allot f!
                ; immediate \ moved to application space to avoid messages.

\ in-application

in-system

also assembler

: DFIELD:    ( n1 "name" -- n2 ) ( addr -- 'addr )
\ *G Skip leading space delimiters. Parse name delimited by a space. Offset is the first
\ ** double-float aligned value greater than or equal to n1. n2 = offset + 1 double-float.
\ ** Create a definition for name with the execution semantics given below.
\ ** name Execution: ( addr1 -- addr2 )
\ ** Add the offset calculated during the compile time action to addr1 giving the
\ ** double-float aligned address addr2.
double field+ ;

: FFIELD:    ( n1 "name" -- n2 ) ( addr -- 'addr )
\ *G Skip leading space delimiters. Parse name delimited by a space. Offset is the first
\ ** float aligned value greater than or equal to n1. n2 = offset + 1 float.
\ ** Create a definition for name with the execution semantics given below.
\ ** name Execution: ( addr1 -- addr2 )
\ ** Add the offset calculated during the compile time action to addr1 giving the float
\ ** aligned address addr2.
fsize field+ ;

: SFIELD:    ( n1 "name" -- n2 ) ( addr -- 'addr )
\ *G Skip leading space delimiters. Parse name delimited by a space. Offset is the first
\ ** singe-float aligned value greater than or equal to n1. n2 = offset + 1 single-float.
\ ** Create a definition for name with the execution semantics given below.
\ ** name Execution: ( addr1 -- addr2 )
\ ** Add the offset calculated during the compile time action to addr1 giving the
\ ** single-float aligned address addr2.
float field+ ;

previous

in-previous

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ Floating point stack operators
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

\ *W <a name="Sec#3"></a>
\ *N FP Stack operations

code FDROP      ( fs: r -- )                \ ANSI           Floating
\ *G Remove r from the floating-point stack.
                fstack-check_1
                -fsp-adjust
                float;

code FDUP       ( fs: r -- r r )             \ ANSI           Floating
\ *G Duplicate the top entry on the floating-point stack.
                fstack-check_1
                (>FPU)
                FPU>
                float;

code FSWAP      ( fs: r1 r2 -- r2 r1 )            \ ANSI          Floating
\ *G Exchange the top 2 FP numbers.
                fstack-check_2
                2>FPU
                +fsp-adjust
                FPU>
                -fsp-adjust -fsp-adjust
                FPU>
                +fsp-adjust
                float;

code FOVER      ( fs: r1 r2 -- r1 r2 r1 )         \ ANSI           Floating
\ *G Copy the 2nd FP stack number to the top of the FP stack.
                fstack-check_2
                fld     FSIZE b/float 2* negate +FSTACK_MEMORY
                fstp    FSIZE FSTACK_MEMORY
                +fsp-adjust
                float;

code FROT       ( fs: r1 r2 r3 -- r2 r3 r1 )       \ ANSI          Floating
\ *G Rotate the top 3 FP stack numbers.
                fstack-check_3
                -fsp-adjust
                fld     FSIZE fsp-adjust +FSTACK_MEMORY
                -fsp-adjust
                fld     FSIZE fsp-adjust +FSTACK_MEMORY
                -fsp-adjust
                fld     FSIZE fsp-adjust +FSTACK_MEMORY
                +fsp-adjust +fsp-adjust
                fstp    FSIZE fsp-adjust +FSTACK_MEMORY
                -fsp-adjust -fsp-adjust
                fstp    FSIZE fsp-adjust +FSTACK_MEMORY
                +fsp-adjust
                fstp    FSIZE fsp-adjust +FSTACK_MEMORY
                +fsp-adjust +fsp-adjust
                float;

code FPICK      ( n -- ; fs: -- r )              \ W32F         Floating extra
\ *G Copy the n'th number from the FP stack.
                mov     eax, ebx
                inc     eax
B/FLOAT 10 = [IF]
                lea eax, 0 [eax*4] [eax]
                add eax, eax
         [ELSE] shl eax, # 3
         [THEN]
                call    fstack-check
                sub     ecx, eax
                fld     FSIZE FSTACK_MEMORY
                add     ecx, eax
                pop     ebx
                fstp    FSIZE FSTACK_MEMORY
                +fsp-adjust
                float;

: FNIP          ( fs: r1 r2 -- r2 )                \ W32F          Floating extra
\ *G Remove the 2nd FP stack entry.
                FSWAP FDROP ;

\ *W <a name="Sec#4"></a>
\ *N FP Stack operations on pairs of entries

\ *P The following words can be used for pairs of FP numbers and are useful for dealing
\ ** with complex numbers or 2-dimensional vectors on the FP stack.

code F2DROP     ( fs: r1 r2 -- )                   \ W32F          Floating extra
\ *G Remove the top 2 FP stack entries.
                fstack-check_2
                -fsp-adjust
                -fsp-adjust
                float;

: F2DUP         ( fs: r1 r2 -- r1 r2 r1 r2 )       \ W32F          Floating extra
\ *G Duplicate the top 2 FP stack entries.
                fover fover ;

: F2SWAP        ( fs: r1 r2 r3 r4 -- r3 r4 r1 r2 )          \ W32F     Floating extra
\ *G Swap the top pair of floating-point numbers with the second pair.
                { \ ftemp -- }
                B/FLOAT LocalAlloc: ftemp       \ hold a floating point number
                FROT ftemp f!                   \ move out of the way into ftemp
                FROT ftemp f@ ;                 \ recover saved float

: F2NIP         ( fs: r1 r2 r3 r4 -- r3 r4 )        \ W32F          Floating extra
\ *G Remove the 2nd pair of FP stack entries.
                f2swap f2drop ;

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ Various floating point constants
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

\ *W <a name="Sec#5"></a>
\ *N FP Constants

code fpi        ( fs: -- r )      \ W32F           Floating extra
\ *G Push the value 3.141596... on to the FP stack.
                fldpi
                FPU>
                float;


code f0.0       ( fs: -- r )       \ W32F          Floating extra
\ *G Push plus zero on to the FP stack.
                fldz
                FPU>
                float;

code f1.0       ( fs: -- r )       \ W32F          Floating extra
\ *G Push the value 1.0 on to the FP stack.
                fld1
                FPU>
                float;

code fL2t       ( fs: -- r )       \ W32F          Floating extra
\ *G Push the value of log base 2 of 10.
                fldl2t
                FPU>
                float;

code fL2e       ( fs: -- r )       \ W32F          Floating extra
\ *G Push the value of log base 2 of e.
                fldL2e
                FPU>
                float;

code fLog2      ( fs: -- r )       \ W32F          Floating extra
\ *G Push the value of log base 10 of 2.
                fldLg2
                FPU>
                float;

code fLn2       ( fs: -- r )       \ W32F          Floating extra
\ *G Push the value of ln 2 (the natural logarithm).
                fldLn2
                FPU>
                float;

(( Note the following constants are defined later, after the arithmetic operators
   But are included here for documentation purposes ONLY.

f1.0 f0.0 f/
             fconstant finf  ( fs: -- r ) \ W32F             Floating extra
\ *G Push plus infinity.

2e0          fconstant f2.0  ( fs: -- r ) \ W32F             Floating extra
\ *G Push floating-point 2.0.

10e0         fconstant f10.0 ( fs: -- r ) \ W32F             Floating extra
\ *G Push floating-point 10.0.

5e-1         fconstant f0.5  ( fs: -- r ) \ W32F             Floating extra
\ *G Push floating-point 0.5.
))

B/FLOAT 10 = [IF]

        f0.0 fconstant fbig
                ' fbig >body  -1 over !         nostack
                -1 over cell+ !
                0x7ffe swap 2 cells+ w!         stack-check

        f0.0 fconstant feps             \ smallest non-zero-number
                1 ' feps >body !

        f0.0 fconstant fsmall
                0 ' fsmall >body tuck !  0x80000000 over cell+ !
                1 swap 2 cells+ w!

        fvariable a2**63
                0 a2**63 !  0x80000000 a2**63 cell+ !
                0x403e a2**63 2 cells+ w!       \ January 13th, 1998 - 9:32 tjz for RLS
                                                \ per suggestion from Pierre Abbat

        fvariable sq2m1                    \ sqrt(2) - 1
                0xe7799210 sq2m1 !
                0xd413cccf sq2m1 cell+ !
                0x3ffd sq2m1 2 cells+ w!

        fvariable sq2/2m1                  \ sqrt(2)/2 - 1
                0x0c4336f8 sq2/2m1 !
                0x95f61998 sq2/2m1 cell+ !
                0xbffd sq2/2m1 2 cells+ w!

[ELSE]  ( 8 byte mode )

       f0.0 fconstant fbig   ( fs: -- r ) \ W32F             Floating extra
\ *G Push the largest non-infinite floating-point number.
                ' fbig >body  -1 over !  0x7fefffff swap cell+ !

       f0.0 fconstant feps   ( fs: -- r ) \ W32F             Floating extra
\ *G Push the smallest non-zero floating-point number.
                1 ' feps >body !

       f1.0 fconstant fsmall ( fs: -- r ) \ W32F             Floating extra
\ *G Push the smallest non-denormalised floating-point number.
                ' fsmall >body 0 over !  0x00100000 swap cell+ !

\ *W <a name="Sec#6"></a>
\ *N FP Variables

        fvariable a2**63     ( -- addr )  \ W32F             Floating extra
\ *G Return the address of a float containing 2**63.
                0 a2**63 !  0x43e00000 a2**63 cell+ !

        fvariable sq2m1      ( -- addr )  \ W32F             Floating extra
\ *G Return the address of a float containing sqrt(2) - 1.
                0x99fcef34 sq2m1 !
                0x3fda8279 sq2m1 cell+ !

        fvariable sq2/2m1    ( -- addr )  \ W32F             Floating extra
\ *G Return the address of a float containing sqrt(2)/2 - 1.
                0x33018866 sq2/2m1 !
                0xbfd2bec3 sq2/2m1 cell+ !

[THEN]

\ *W <a name="Sec#7"></a>

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ *N Rounding functions
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

in-system

\ Macro to set the FPU rounding mode
\ input:  bx = rounding mode mask for the FPU Control Word
\ output: bx = org FPU Control Word
macro:  set-rounding-mode
                fstcw   word -4 [ebp]
                mov     ax, -4 [ebp]
                and     ax, # 0x0f3ff
                or      ax, bx
                mov     -8 [ebp], ax
                fldcw   word -8 [ebp]
                mov     bx, -4 [ebp]
                endm

\ Macro to restore the FPU rounding mode
\ input: bx = org FPU Control Word
macro:  restore-rounding-mode
                mov     -4 [ebp], bx
                fldcw   word -4 [ebp]
                endm

\ Macro to round a floating point value
\ input:  bx = rounding mode mask for the FPU Control Word
macro:  (fround)
                fstack-check_1
                >FPU
                set-rounding-mode
                frndint
                FPU>
                restore-rounding-mode
                endm

in-previous

code FLOOR      ( fs: r1 --  r2 )         \ ANSI         Floating
\ *G Round r1 to an integral value using the round toward negative infinity rule,
\ ** giving r2.
                push    ebx
                mov     bx, # 0x00400
                (fround)
                pop     ebx
                float;

code FCEIL      ( fs: r1 -- r2 )          \ W32F         Floating extra
\ *G Round r1 to an integral value using the round toward positive infinity rule,
\ ** giving r2.
                push    ebx
                mov     bx, # 0x00800
                (fround)
                pop     ebx
                float;

code FTRUNC     ( fs: r1 -- r2 )          \ W32F         Floating extra
\ *G Round r1 to an integral value using the round toward zero rule, giving r2.
                push    ebx
                mov     bx, # 0x00c00
                (fround)
                pop     ebx

                float;

code FROUND     ( fs: r1 -- r2 )          \ ANSI         Floating
\ *G Round r1 to an integral value using the round to nearest rule, giving r2.
                push    ebx
                mov     bx, # 0x00000
                (fround)
                pop     ebx
                float;


\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ Integer to float convsersion
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

\ *W <a name="Sec#8"></a>
\ *N Integer to float conversion

code D>F        ( d -- ; Fs: -- r )       \ ANSI           Floating
\ *G Convert double number to floating-point number.
                lea esp, -4 [esp]
                mov ecx, 4 [esp]
                mov 0 [esp], ecx
                mov 4 [esp], tos
                fild    qword 0 [esp]
                mov tos, 8 [esp]
                lea esp, 12 [esp]
                FPU>
                float;

\ Changed 3/13/99 rls
code F>D        ( -- d ; fs: r -- )       \ ANSI           Floating
\ *G Convert floating-point number to double number, by rounding towards zero. If the
\ **  result would be too large to fit in a double number then \n -9223372036854775808
\ ** is returned.
                fstack-check_1
                >FPU
                sub     esp, # 12
                mov     8 [esp], tos
                xor     ebx, ebx
                mov     bx, # 0x00c00           \ Set rounding to truncate
                set-rounding-mode
                fistp   qword 0 [esp]
                restore-rounding-mode
                mov     tos, 4 [esp]
                mov     eax, 0 [esp]
                mov     4 [esp], eax
                add     esp, # 4
                float;

code ZF>D       ( -- d ; fs: r -- )       \ W32F           Floating extra
\ *G Convert floating-point number to double number, using the current rounding mode
\ ** (rounding towards nearest unless changed by the user). If the result would be too
\ ** large to fit in a double number then \n -9223372036854775808 is returned.
                fstack-check_1
                >FPU
                sub     esp, # 8
                fistp   qword 0 [esp]
                mov     eax,  4 [esp]
                mov     4 [esp], tos
                mov     tos,  eax
                float;

: s>f           ( n -- ; fs: -- r )       \ W32F            Floating extra
\ *G Convert the single number n to floating point number r.
                s>d d>f ;

: f>s           ( -- n ; fs: r -- )       \ W32F           Floating extra
\ *G Convert the floating point number r to single number n.
                f>d drop ;

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ Transfering floats to the data stack (as floats) for windows
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

code FS>DS      ( -- dfloat fs: r -- )    \ W32F           Floating extra
\ *G Move floating point number bits to the data stack as a 64-bit float.
\ ** This function is for passing floats to DLLs.
                fstack-check_1
                >fpu
                push    ebx
                push    ebx
                push    ebx
                fstp    double 0 [esp]
                pop     ebx
                float;

\ from Jos v.d. Ven

code SFS>DS     ( -- float ; fs: r -- )   \ W32F           Floating extra
\ *G Push the top of the float stack onto the data stack as a 32-bit float.
\ ** This function is for passing floats to DLLs.
                fstack-check_1
                >fpu
                push    ebx
                push    ebx
                fstp    float 0 [esp]
                pop     ebx
                float;

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ Floating point comparison operators
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

internal

0x4100 constant FCOMP_MASK
0x4000 constant FCOMP_EQUAL
0x0100 constant FCOMP_LESS

in-system

macro: (fcomp)
                fstsw  ax
                push    ebx
                mov     ebx, eax
                and     ebx, # FCOMP_MASK
                endm

in-previous

code fcomppx    ( -- flags ; fs: r1 r2 -- ) \ for comparing 2 FP values
                fstack-check_2
                2>FPU
                fcompp
                (fcomp)
                float;

code ftstp      ( -- flags ; fs: r1 -- ) \ for comparison with 0.0e0
                fstack-check_1
                >FPU
                ftst
                (fcomp)
                fstp    st \ pop
                float;

external

\ *W <a name="Sec#9"></a>
\ *N FP Comparison operators

: F0=           ( -- f ; fs: r -- )       \ ANSI           Floating
\ *G Return true if r equals ±0e0. Returns false for NAN.
                ftstp FCOMP_EQUAL = ;
: F0<           ( -- f ; fs: r -- )       \ ANSI           Floating
\ *G Return true if r is less than ±0e0. Returns false for NAN.
                ftstp FCOMP_LESS  = ;
: f0>           ( -- f ; fs: r -- )       \ W32F           Floating extra
\ *G Return true if r is greater than ±0e0. Returns false for NAN.
                ftstp 0= ;

: f=            ( -- f ; fs: r1 r2 -- )   \ W32F           Floating extra
\ *G Return true if r1 equals r2. Returns false if either number is a NAN.
                fcomppx FCOMP_EQUAL = ;
: F<            ( -- f ; fs: r1 r2 -- )   \ ANSI           Floating
\ *G Return true if r1 is less than r2. Returns false if either number is a NAN.
                fcomppx FCOMP_LESS  = ;
: f>            ( -- f ; fs: r1 r2 -- )   \ W32F           Floating extra
\ *G Return true if r1 is greater than r2. Returns false if either number is a NAN.
                fcomppx 0= ;

: f<=           ( -- f ; fs: r1 r2 -- )   \ W32F           Floating extra
\ *G Return true if r1 is less than or equal to r2. Returns true if either number
\ ** is a NAN.
                f> not ;
: f>=           ( -- f ; fs: r1 r2 -- )   \ W32F           Floating extra
\ *G Return true if r1 is greater than or equal to r2. Returns true if either number
\ ** is a NAN.
                f< not ;

: FMAX          ( fs: r1 r2 -- r3 )       \ ANSI           Floating
\ *G Return r3 the maximum of r1 and r2. If r1 is a NAN then so is r3. If r2 is a NAN
\ ** then r3=r1.
                f2dup f< IF fswap THEN fdrop ;

: FMIN          ( fs: r1 r2 -- r3 )       \ ANSI           Floating
\ *G Return r3 the minimum of r1 and r2. If r1 is a NAN then so is r3. If r2 is a NAN
\ ** then r3=r1.
                f2dup f> IF fswap THEN fdrop ;

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ Simple math operators
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

\ *W <a name="Sec#10"></a>
\ *N Arithmetic operators

code F+         ( fs: r1 r2 -- r3 )       \ ANSI          Floating
\ *G Add r1 to r2.
                fstack-check_2
                2>FPU
                faddp   st(1), st
                FPU>
                float;

code F-         ( fs: r1 r2 -- r3 )       \ ANSI          Floating
\ *G Subtract r2 from r1.
                fstack-check_2
                2>FPU
                fsubrp   st(1), st
                FPU>
                float;

code F*         ( fs: r1 r2 -- r3 )       \ ANSI          Floating
\ *G Multiply r1 by r2.
                fstack-check_2
                2>FPU
                fmulp   st(1), st
                FPU>
                float;

code F/         ( fs: r1 r2 -- r3 )       \ ANSI         Floating
\ *G Divide r1 by r2.
                fstack-check_2
                2>FPU
                fdivrp   st(1), st
                FPU>
                float;

code FNEGATE    ( fs: r1 -- r2 )          \ ANSI          Floating
\ *G Reverse the sign of r1.
                fstack-check_1
                >FPU
                fchs
                FPU>
                float;

: 1/f           ( fs: r1 -- r2 )          \ W32F        Floating extra
\ *G r2 is the reciprocal of r1.
                f1.0 fswap f/ ;

code f2*        ( fs: r1 -- r2 )          \ W32F        Floating extra
\ *G Multiply by 2.
                fstack-check_1
                fld1
                >FPU
                fscale
                FPU>
                fstp    st(0)
                float;

code f2/        ( fs: r1 -- r2 )          \ W32F        Floating extra
\ *G Divide by 2.
                fstack-check_1
                fld1
                fchs
                >FPU
                fscale
                FPU>
                fstp    st(0)
                float;

code FABS       ( fs: r1 -- r2 )          \ ANSI        Floating ext
\ *G r2 is the absolute value of r1.
                fstack-check_1
                >FPU
                fabs
                FPU>
                float;

code FSQRT      ( fs: r1 -- r2 )          \ ANSI        Floating ext
\ *G r2 is the positive square root of r1. r2 is NAN for negative r1.
                fstack-check_1
                >FPU
                fsqrt
                FPU>
                float;

internal

: (F~)          ( -- f ; fs: r1 r2 r3 -- )
                frot frot f- fabs f> ;

external

\ July 29th, 1998 - 8:53 tjz
\ added '@' after FLOATSP to fix a bug reported by Pierre Abbat
: F~            ( -- flag ; fs: r1 r2 r3 -- )  \ ANSI        Floating ext
\ *G If r3 is positive, flag is true if the absolute value of (r1 minus r2) is less than
\ ** r3. If r3 is zero, flag is true if the implementation-dependent encoding of r1 and
\ ** r2 are exactly identical (positive and negative zero are unequal).
\ ** If r3 is negative, flag is true if the absolute value of (r1 minus r2) is less than the
\ ** absolute value of r3 times the sum of the absolute values of r1 and r2.
\ *P This provides the three types of floating point equality in common use -- close in
\ ** absolute terms, exact equality as represented, and relatively close.
                fdup f0<
                IF      fabs fover fabs 3 fpick fabs f+ f*      \ r1 r2 r3*(r1+r2)
                        (f~)
                ELSE    fdup f0=
                        IF      fdrop FLOATSTACK FLOATSP @ + B/FLOAT - dup B/FLOAT -
                                swap B/FLOAT swap B/FLOAT str=
                                f2drop
                        ELSE
                            (f~)
                        THEN
                THEN ;

\ The following constants are documented earlier

f1.0 f0.0 f/         fconstant finf  ( fs: -- r )

f1.0 f2*             fconstant f2.0  ( fs: -- r )

f2.0 fdup f2* f2* f+ fconstant f10.0 ( fs: -- r )

f1.0 f2/             fconstant f0.5  ( fs: -- r )

[defined] dofcon [if] ' finf @ to dofcon [then]

internal

code f**+n      ( n -- ; fs: r1 -- r2 ) \ r2 is r1 to the power n, where n is positve.
                fstack-check_1
                fld1
                or      tos, tos
                je      short L$4
                >fpu
                fxch    st(1)
L$1:            shr     tos, # 1
                jnc     short L$2
                fmul    st(0), st(1)
L$2:            jz      short L$3
                fxch    st(1)
                fmul    st(0), st(0)
                fxch    st(1)
                jmp     short L$1
L$3:            fxch    st(1)
                fstp    st(0)
L$4:            fpu>
                pop     tos
                float;

: f**n          ( n -- ; fs: r1 -- r2 )  \ r2 is r1 to the power n.
                DUP 0<
                IF   ABS F**+N 1/f
                ELSE F**+N
                THEN ;

code (fsin)     ( fs: r1 -- r2 )
                >FPU
                fsin
                FPU>
                float;

code (fcos)     ( fs: r1 -- r2 )
                >FPU
                fcos
                FPU>
                float;

code (fsincos)  ( fs: r1 -- r2 r3 )
                >FPU
                fsincos
                fxch
                FPU>
                FPU>
                float;

code frem2pi    ( fs: r1 -- r2 )
                fld1
                fldpi
                fscale
                fstp    st(1)
                >FPU
L$1:            fprem1
                fstsw  ax
                sahf
                jp      short L$1
                FPU>
                fstp    st(0)
                float;

: >a2**63_frem2pi ( fs: r1 -- r2 )
                fdup fabs a2**63 f@ f>=
                if frem2pi then ;
external

\ *W <a name="Sec#11"></a>
\ *N Trigonometric functions

: FSIN          ( fs: r1 -- r2 )          \ ANSI         Floating ext
\ *G r2 is the sine of r1 in radians.
                >a2**63_frem2pi (fsin) ;

: FCOS          ( fs: r1 -- r2 )          \ ANSI         Floating ext
\ *G r2 is the cosine of r1 in radians.
                >a2**63_frem2pi (fcos) ;

: FSINCOS       ( fs: r1 -- r2 r3 )       \ ANSI         Floating ext
\ *G r2 is the sine and r3 the cosine of r1 in radians. This function is more efficient
\ ** than calling FSIN and FCOS separately.
                >a2**63_frem2pi (fsincos) ;

: FTAN          ( fs: r1 -- r2 )          \ ANSI         Floating ext
\ *G r2 is the tangent of r1 in radians.
                fsincos f/ ;

\ *W <a name="Sec#12"></a>
\ *N Inverse Trigonometric functions

code FASIN      ( fs: r1 -- r2 )          \ ANSI         Floating ext
\ *G r2 is the radian angle whose sine is r1. The result for |x| =< 1 is between ±pi/2.
\ ** The result for |x| > 1 is NAN.
                fstack-check_1
                >FPU
                fld     st(0)
                fld     st(0)
                fmulp   st(1), st(0)
                fld1
                fsubpr  st(1), st
                fsqrt
                fpatan
                FPU>
                float;

code FACOS      ( fs: r1 -- r2 )          \ ANSI         Floating ext
\ *G r2 is the radian angle whose cosine is r1. The result for |x| =< 1 is between 0 and pi.
\ ** The result for |x| > 1 is NAN
                fstack-check_1
                >FPU
                fld     st(0)
                fld     st(0)
                fmulp   st(1), st(0)
                fld1
                fsubpr  st(1), st
                fsqrt
                fxch    st(1)
                fpatan
                FPU>
                float;

code FATAN      ( fs: r1 -- r2 )          \ ANSI          Floating ext
\ *G r2 is the radian angle whose tangent is r1. The result is between ±pi/2.
                fstack-check_1
                >FPU
                fld1
                fpatan
                FPU>
                float;

code FATAN2     ( fs: r1 r2 -- r3 )       \ ANSI         Floating ext
\ *G r3 is the radian angle whose tangent is r1/r2. The result is between ±pi
\ ** with the same sign as r2. If r1 and r2 are both zero then r3 is ±zero.
\ ** This function can be used to convert cartesian coordinates into the angle of the
\ ** polar coordinates.
                fstack-check_2
                2>FPU
                fxch
                fpatan
                FPU>
                float;

\ *W <a name="Sec#13"></a>
\ *N Logarithmic functions

code FLN        ( fs: r1 -- r2 )          \ ANSI            Floating ext
\ *G r2 is the natural logarithm of r1. If r1 is ±0 then r2 is -infinity. If r1
\ ** is infinity then r2 is infinity. If r1 is less than zero then r2 is a NAN.
                fstack-check_1
                fldln2
                >FPU
                fyl2x
                FPU>
                float;

code FLNP1      ( fs: r1 -- r2 )          \ ANSI           Floating ext
\ *G r2 is the natural logarithm of the quantity r1 plus one. If r1 is -1.0 then
\ ** r2 is -infinity. If r1 is infinity then r2 is infinity. If r1 is less than
\ ** -1.0 then r2 is a NAN.
                fstack-check_1
                fldln2
                >FPU
                fld     FSIZE sq2m1
                fcomp   st(1)
                fstsw  ax
                sahf
                jp      short L$3
                ja      short L$4
                fld     FSIZE sq2/2m1
                fcomp   st(1)
                fstsw  ax
                sahf
                jb      short L$4
                fyl2xp1
                (FPU>)                  \ Used to balance branches
                jmp     short L$2
L$4:            fld1                    \ add the "1" explicitly
                faddp   st(1), st(0)
                fabs
                fyl2x
                FPU>
                jmp     short L$2
L$3:            fcompp                  \ return arg if incomparable
L$2:            float;

code FLOG       ( fs: r1 -- r2 )          \ ANSI       Floating ext
\ *G r2 is the logarithm to base 10 of r1. If r1 is ±0 then r2 is -infinity. If r1
\ ** is infinity then r2 is infinity. If r1 is less than zero then r2 is a NAN.
                fstack-check_1
                fldlg2
                >FPU
                fyl2x
                FPU>
                float;

\ *W <a name="Sec#14"></a>
\ *N Exponential functions

code FEXP       ( fs: r1 -- r2 )          \ ANSI       Floating ext
\ *G Raise e to the power r1, giving r2.
                fstack-check_1
                >FPU                                               \ 1
                fldl2e                  \ log base 2 of e          \ 2
                fmulp   st(1), st       \ modified exponent        \ 1
                fxam
                fstsw  ax
                and     ax, # FPU_STATUS_CCF_MASK
                cmp     ax, # FPU_STATUS_CCF_INFINITY
                je      short L$2
                cmp     ax, #  0x700 \ FPU_STATUS_CCF_INFINITY FPU_STATUS_CCF_MASK_1 or
                jne     short L$1
                fstp    st(0)
                fldz
                jmp     short L$2
L$1:            fld     st(0)           \ duplicate exponent       \ 2
                frndint                 \ take integer part        \ 2
                fsub    st(1), st       \ get fractional part      \ 2
                fld1                    \ 1                        \ 3
                fscale                  \ 2**int                   \ 3
                fstp    st(1)           \ remove unneeded part     \ 2
                fxch    st(1)           \ frac                     \ 2
                f2xm1                   \ (2**frac) - 1            \ 2
                fld1                    \ 1.0                      \ 3
                faddp   st(1), st       \ 2**frac                  \ 2
                fmulp   st(1), st       \ 2**(int + frac)          \ 1
L$2:            FPU>                                               \ 0
                float;

code FEXPM1     ( fs: r1 -- r2 )          \ ANSI      Floating ext
\ *G Raise e to the power r1 and subtract one, giving r2.
\ *P This function allows accurate computation when its arguments are close to zero, and
\ **  provides a useful base for the standard exponential functions. Hyperbolic functions
\ **  such as cosh(x) can be efficiently and accurately implemented by using FEXPM1;
\ **  accuracy is lost in this function for small values of x if the word FEXP is used.
                fstack-check_1
                >fpu
                fldl2e                                             \ 2
                fmulp st(1), st(0)                                 \ 1
                fld1                                               \ 2
                fcom    st(1)                                      \ 2
                fstsw  ax                                          \ 2
                sahf                                               \ 2
                jbe     short L$1       \ arg > 1                  \ 2
                fchs                                               \ 2
                fcomp   st(1)                                      \ 1
                fstsw  ax                                          \ 1
                sahf                                               \ 1
                jnc     short L$2       \ arg <= -1                \ 1
                je      short L$4       \ is NAN                   \ 1
                f2xm1                                              \ 1
                jmp     short L$4
L$1:            fstp    st(0)                                      \ 1
L$2:            fxam
                fstsw  ax
                and     ax, # FPU_STATUS_CCF_MASK
                cmp     ax, # FPU_STATUS_CCF_INFINITY
                je      short L$4
                cmp     ax, #  0x700 \ FPU_STATUS_CCF_INFINITY FPU_STATUS_CCF_MASK_1 or
                jne     short L$3
                fstp    st(0)
                fld1
                fchs
                jmp     short L$4
L$3:            fld     st(0)           \ duplicate exponent       \ 2
                frndint                 \ take integer part        \ 2
                fsub    st(1), st       \ get fractional part      \ 2
                fld1                                               \ 3
                fscale                  \ 2**int                   \ 3
                fstp    st(1)           \ remove unneeded part     \ 2
                fxch    st(1)           \ frac                     \ 2
                f2xm1                   \ (2**frac) - 1            \ 2
                fld1                    \ 1.0                      \ 3
                faddp   st(1), st       \ 2**frac                  \ 2
                fmulp   st(1), st       \ 2**(int + frac)          \ 1
                fld1
                fsubp   st(1), st
L$4:            fpu>
                float;

: f**           ( fs: r1 r2 -- r3 )       \ ANSI            Floating ext
\ *G Raise r1 to the power r2, giving the product r3.
                FDUP FROUND FDUP F>S F- FDUP F0=
                if    FDROP F**N
                else      FOVER FLN F* FEXP FSWAP F**N F*
                THEN    ;

: FALOG         ( fs: r1 -- r2 )          \ ANSI           Floating ext
\ *G Raise ten to the power r1, giving r2.
                f10.0 fswap f** ;

internal

: (fsinh)       ( fs: r1 -- r2 )         \ hyperbolic sine, more accurate for positive.
                fexp fdup 1/f f- f2/ ;

external

\ *W <a name="Sec#15"></a>
\ *N Hyperbolic functions

: FSINH         ( fs: r1 -- r2 )          \ ANSI             Floating ext
\ *G r2 is the hyperbolic sine of r1.
                fdup f0<
                IF   fabs (fsinh) fnegate
                ELSE (fsinh)
                THEN ;

: FCOSH         ( fs: r1 -- r2 )          \ ANSI             Floating ext
\ *G r2 is the hyperbolic cosine of r1.
                fabs fexp fdup 1/f f+ f2/ ;

: FTANH         ( fs: r1 -- r2 )          \ ANSI             Floating ext
\ *G r2 is the hyperbolic tangent of r1, |r2| <= 1.
                fdup fabs f1.0 f<
                IF      f2* fexpm1 fdup f2.0 f+ f/
                ELSE    f2* fdup f0<
                        IF      fexpm1 fdup f2.0 f+ f/
                        ELSE    fnegate fexp f1.0 fover f- \ RLS Sep. 21, 1997
                                fswap f1.0 f+ f/
                        THEN
                THEN ;

\ *W <a name="Sec#16"></a>
\ *N Inverse hyperbolic functions

code FASINH     ( fs: r1 -- r2 )          \ ANSI             Floating ext
\ *G r2 is the number whose hyperbolic sine is r1.
                fstack-check_1
                fldln2
                >FPU
                fld     st(0)
                fmul    st(0), st(0)
                fld1
                faddp   st(1), st(0)
                fsqrt
                faddp   st(1), st(0)
                fyl2x
                FPU>
                float;

code FACOSH     ( fs: r1 -- r2 )          \ ANSI            Floating ext
\ *G r2 is the number whose hyperbolic cosine is r1. If r1 < 1.0 then r2 is a NAN.
                fstack-check_1
                fldln2
                >FPU
                fld     st(0)
                fmul    st(0), st(0)
                fld1
                fsubp   st(1), st(0)
                fsqrt
                faddp   st(1), st(0)
                fyl2x
                FPU>
                float;

: FATANH        ( fs: r1 -- r2 )          \ ANSI             Floating ext
\ *G r2 is the number whose hyperbolic tangent is r1. IF |r1| > 1.0 then r2 is a NAN.
                fdup f1.0 f+
                fswap f1.0  fswap f-
                f/ fln f2/ ;

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ floating point defining words and array operators
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

: FALIGN        ( -- ) ; immediate
: FALIGNED      ( addr -- addr ) ; immediate
: DFALIGN       ( -- ) ; immediate
: DFALIGNED     ( addr -- addr ) ; immediate
: SFALIGN       ( -- ) ; immediate
: SFALIGNED     ( addr -- addr ) ; immediate

b/float offset FLOAT+        ( addr1 -- addr2 )

: FLOATS        ( n1 -- n2 )
                B/FLOAT * ;

8 offset DFLOAT+       ( addr1 -- addr2 )

: DFLOATS       ( n1 -- n2 )
                8 * ;

4 offset SFLOAT+       ( addr1 -- addr2 )

: SFLOATS       ( n1 -- n2 )
                4 * ;

in-system

: float-array   ( n1 "name" -- )         \ compile time
                ( -- a1 )               \ runtime
                create floats allot ;

internal

in-previous

\ pointer to a float primitives
cfa-func ^float@  2 cells+ @ f@  ;
cfa-func ^float!    cell+  @ f!  ;
cfa-func ^float+!          @ f+! ;

\ float primitives
cfa-func float@  2 cells+ f@  ;
cfa-func float!    cell+  f!  ;
cfa-func float+!          f+! ;

\ pointer to a float array primitives
cfa-func ^#float@  2 cells+ @ swap floats + f@  ;
cfa-func ^#float!    cell+  @ swap floats + f!  ;
cfa-func ^#float+!          @ swap floats + f+! ;

\ float array primitives
cfa-func #float@  2 cells+ swap floats + f@  ;
cfa-func #float!    cell+  swap floats + f!  ;
cfa-func #float+!          swap floats + f+! ;

in-system

: floater?      ( a1 -- a1 f1 )     \ is a1 the CFA of a float? or ^float?
                dup @
                dup   float@ =
                swap ^float@ = or ;

: #float?       ( a1 -- a1 f1 )     \ is a1 the CFA of a #float? or #^float?
                dup @
                dup   #float@ =
                swap ^#float@ = or ;

: ?float        ( cfa -- cfa )          \ abort if not a FLOAT
                floater? 0= abort" is not a FLOAT or ^FLOAT" ;

: ?#float       ( cfa -- cfa )          \ abort if not a #FLOAT-ARRAY
                #float? 0= abort" is not a #FLOAT-ARRAY or #^FLOAT-ARRAY" ;

external

: ^float        ( a1 "name" -- )         \ compile time          64-bits
                ( fs: -- r )      \ runtime
                header ^float@ , ^float! , ^float+! , ( a1 ) , ;

: #^float-array ( n1 "name" -- )         \ compile time          64-bits
                ( n1 -- ; fs: -- r )   \ runtime
                header ^#float@ , ^#float! , ^#float+! , ( n1 ) , ;

: FLOAT         ( "name" -- )            \ compile time          64-bits
                ( -- ; fs: -- r )   \ runtime
                header float@ , float! , float+! ,
                1 floats here over erase allot ;

: #float-array  ( n1 "name" -- )         \ compile time          64-bits
                ( n1 -- ; fs: -- r )   \ runtime
                header #float@ , #float! , #float+! ,
                ( n1 ) 1+ floats here over erase allot ;

: f->           ( n1 "name" -- )         \ store a value into a float
                ' ?float  1 cells+ cfa-comp, ; immediate

: f+>           ( n1 "name" -- )         \ increment the value of a float
                ' ?float  2 cells+ cfa-comp, ; immediate

: f#->          ( n1 "name" -- )         \ store a value into a float
                ' ?#float  1 cells+ cfa-comp, ; immediate

: f#+>          ( n1 "name" -- )         \ increment the value of a float
                ' ?#float  2 cells+ cfa-comp, ; immediate

in-previous

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ string input number conversion
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

internal

: xsign         ( char -- char false | nflag true )
                CASE    [char] + OF false true ENDOF
                        [char] - OF true  true ENDOF
                        ( else )   false over
                ENDCASE ;

: e-char        ( char -- true | char false )
                dup upc [char] D [char] E between -if nip then ;

: 10digit       ( char -- n flag )
                10 digit ;

: digit0        ( char -- flag )
                dup [char] 0 = ;

cell newuser mantsign
cell newuser intcnt
cell newuser fracnt
cell newuser charcnt
cell newuser zerochar
cell newuser havedigits
128  newuser $fsignif
10 newuser fbcd-buf

: 10**n         ( fs: -- r )  ( n -- ) \ 10 raised to n
                f10.0 f**n ;

: 10**N-0.5     ( fs: -- r )  ( n -- ) \ (10 raised to n) - 0.5
                10**n f0.5 f- ;

: bcd-char@     ( n -- char )
                dup 1 and swap 2/ fbcd-buf + c@ swap
                IF      4 rshift
                ELSE    0x0f and
                THEN
                ascii 0 + ;

B/FLOAT 10 = [IF]
        4932 constant big-power
[ELSE]  308  constant big-power
[THEN]

: 10**n*f       ( n -- ; fs: f1 -- f2 ) \ (10 raised to n) * f1
                10**n f* ;

: f*10**n       ( n -- ; fs: f1 -- f2 )
                dup big-power >
                IF   big-power   10**n*f
                     big-power - 10**n*f
                ELSE 10**n*f
                THEN ;

: next-char     ( addr1 -- addr2 char flag ) \ flag = 0 means valid char
                count -1 charcnt +! charcnt @ 0< ;

code sig>f      ( fs: -- r ) \ Push contents of 80-bit BCD number in fbcd-buf onto FP stack
                fbld    fbcd-buf [up]
                fpu>
                float;

: bcd-char!     ( char n -- )
                swap 0x0f and swap
                dup 1 and swap 2/ fbcd-buf + swap
                IF      dup c@ 0x0f and rot 4 lshift
                ELSE    dup c@ 0xf0 and rot
                THEN
                or swap c! ;

: >float-int    ( fs: -- r )
                intcnt @ 18 min dup 1- swap 0
                ?DO  $fsignif I + c@ over bcd-char! 1-
                LOOP
                drop sig>f
                intcnt @ 18 >                           \ allow looong input
                IF   $fsignif 18 + c@ 5 >=
                     IF   $fsignif 18 + c@ 5 >
                          IF   f1.0 f+
                          ELSE $fsignif 17 + c@ 1 and
                               IF   f1.0 f+
                               ELSE intcnt @ 19
                                    ?DO  $fsignif I + c@
                                         0<>
                                         IF   f1.0 f+
                                              LEAVE
                                         THEN
                                    LOOP
                               THEN
                          THEN
                     THEN
                     intcnt @ 18 - 10**n*f
                THEN ;

: init->float   ( -- )
                0 intcnt ! 0 fracnt !                   \ initialize various counts
                0 zerochar ! 0 mantsign !               \  and such
                false havedigits !
                fbcd-buf 10 erase                       \ clear bcd buffer
                $fsignif 128 erase ;                    \ clear intermed. buf

: fracnt@.negate ( -- n1 )
                fracnt @ negate ;

: fraction      ( fs: r1 -- r2 )
                fracnt@.negate 10**n*f ;

: >float-int.frac   ( fs: -- r )
                >float-int fraction ;

: next-fraction ( fs: r1 -- r2 )
                fracnt @
                IF   fraction
                THEN ;

: zero-result   ( fs: r1 -- r2 )
                zerochar @                      \ mantissa=0?
                IF   fdrop f0.0                 \ then make result 0.0
                THEN ;

external

\ *W <a name="Sec#17"></a>
\ *N Input of Floating Point numbers

\ fixed to pass "Dirk Zoller's Float Tests"
\ (see http://www.win32forth.org/downloads/dzfloat-test.zip)
\ Sonntag, März 14 2004 - 10:45 dbu
: >FLOAT        ( addr len -- f ; fs: -- r | <nothing> ) \ ANSI           Floating
\ *G An attempt is made to convert the string specified by c-addr and u to internal
\ ** floating-point representation. If the string represents a valid floating-point
\ ** number in the syntax below, its value r and true are returned. If the string does not
\ ** represent a valid floating-point number only false is returned. \n
\ **
\ ** A string of blanks is treated as a special case representing zero.

\ *E The syntax of a convertible string := <significand>[<exponent>]
\ **
\ ** <significand> := [<sign>]{<digits>[.<digits0>] |
\ ** .<digits> }
\ ** <exponent>    := <marker><digits0>
\ ** <marker>      := {<e-form> | <sign-form>}
\ ** <e-form>      := <e-char>[<sign-form>]
\ ** <sign-form>   := { + | - }
\ ** <e-char>      := { D | d | E | e }
        BL SKIP DUP 0= IF 2DROP f0.0 TRUE EXIT THEN

        init->float
        -trailing                               \ remove trailing blanks
        128 umin charcnt !                      \ save character count

        next-char drop                          \ get first character
        xsign 2dup and mantsign !
        IF   IF 8 ELSE 0 THEN
             19 bcd-char!
             next-char
             IF   2drop false EXIT
             THEN
        THEN

        BEGIN  digit0                          \ check for leading 0's
        WHILE  drop next-char
               IF   2drop f0.0 mantsign @ if fnegate then true EXIT
               THEN
               true zerochar !
               true havedigits !
        REPEAT

        10digit
        IF   true havedigits !
             BEGIN $fsignif intcnt @ + c!
                   1 intcnt +!

                   next-char
                   IF   2drop >float-int true EXIT
                   THEN

                   10digit 0=
             UNTIL
             false zerochar !
        THEN

        dup ascii . =                           \ decimal point?
        IF   drop

             next-char
             IF   2drop >float-int true EXIT
             THEN

             intcnt @ 0=
             IF
                  BEGIN  digit0
                  WHILE  drop next-char
                         IF   2drop f0.0 true EXIT
                         ELSE 1 fracnt +!
                         THEN
                         true zerochar !
                         true havedigits !
                  REPEAT
             THEN
             10digit
             IF   true havedigits !
                  false zerochar !
                  BEGIN $fsignif intcnt @ + c!
                        1 intcnt +!
                        1 fracnt +!
                        next-char
                        IF   2drop >float-int.frac
                             true EXIT
                        THEN
                        10digit 0=
                  UNTIL
             THEN
        THEN

        e-char
        IF                                \ exponent indicator
             havedigits @ 0=
             IF   drop false EXIT         \ September 25th, 1997 - 9:48 tjz
             THEN

             zerochar @                                 \ optimization, mantissa=0
             IF   drop f0.0 mantsign @ if fnegate then
                  true EXIT                             \ then whole number is zero
             THEN

             intcnt @ 0=
             IF   ( SMuB 07-20-95 drop ) f1.0 19 bcd-char@
                  ascii 0 <>  ( <-- SMuB 07-20-95 )
                  IF   fnegate
                  THEN
             ELSE >float-int
             THEN

             next-char
             IF   2drop
                  next-fraction
                  zero-result
                  true EXIT
             THEN

             xsign
             IF   >r next-char
                  IF   r>drop 2drop
                       next-fraction
                       zero-result
                       true EXIT
                  THEN
             ELSE 0 >r
             THEN

        ELSE >float-int

             xsign
             IF   >r next-char        \ rls 09-30-97
                  IF   r>drop 2drop                              \ rls
                       next-fraction
                       true EXIT                                 \ rls
                  THEN
             ELSE 2drop fdrop false EXIT
             THEN
        THEN

        drop 1- charcnt @ 1+ base @ >r decimal number? r> base !  \ modified to always convert exponent in decimal
        double? 0= and                  \ October 1st, 1996 - 10:51 tjz & am
                                        \ double exponent not allowed
        IF   d>s r>
             IF   negate
             THEN

             fracnt@.negate + 10**n*f
             zero-result
             true
        ELSE
             r>drop 2drop fdrop false
        THEN ;

in-system

: f#    ( Interpretation: "fp no." -- ; fs: -- r )    \ W32F             Floating extra
\ *G \b ( Compilation: "fp no." -- ; run-time: fs: -- r ) \d
\ *P An attempt is made to convert the space delimited string following F# to internal
\ ** floating-point representation. If the string represents a valid floating-point
\ ** number in the syntax below, its value r is returned. If the string does not
\ ** represent a valid floating-point number an error is thrown. \n
\ ** F# used at the end of a line is treated as a special case representing zero. \n
\ ** If interpreting the FP number is placed on the FP stack, while it is compiled as
\ ** an Fliteral if compiling. \n
\ ** The syntax of a convertible string is the same as \b >FLOAT \d.
        bl word count >float
        0= abort" invalid floating point number"
        state @
        IF  postpone fliteral  THEN ;   immediate

in-previous

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ Floating point number conversion. We do not have the floating point
\ integrated with the interpreter, so we must prefix floating point
\ literals with f#. ( f# 1.23E6 )
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

internal

code f>bcd      ( addr -- ; fs: r -- )
                fstack-check_1
                >fpu
                fbstp   DATASTACK_MEMORY
                pop     tos
                float;

: rep-normal    ( addr u -- n true ; fs: r -- ) \ handle normal floats in REPRESENT.
                1 max 2dup [char] 0 fill 18 umin
                fdup flog floor f>s 1+ dup>r over -
                fdup over 10**n-0.5 f<
                IF   negate f*10**n
                ELSE 10**n f/
                THEN
                fround fdup dup 10**n f<
                IF   fdup dup 1- 10**n f<
                     IF   f10.0 f* r> 1- >r
                     THEN
                ELSE f10.0 f/ r> 1+ >r
                THEN
                fbcd-buf f>bcd dup>r + 1- r> 0
                DO   I bcd-char@ over c! 1-
                LOOP
                drop r> true
                ;

\ ' rep-normal alias rep-denormal      \ made a colon def - [cdo-2008May13]
: rep-denormal  ( addr u -- n true ; fs: r -- ) \ handle denormal floats in REPRESENT
\ (which is the same action as for normal floats).
                rep-normal ;

\ February 6th, 1996 - 18:05 tjz added 'FDROP' to the following def to
\ correct for a floating point zero left on the stack during E. and F.S
: rep-zero      ( addr u -- 1 true ; fs: r -- )
                [char] 0 fill 1 true fdrop ;

: rep-spec      ( addr u cstr -- n false ; fs: r -- )
                >r 2dup blank r> count                  \ addr1 u addr2 v
                rot umin >r swap r> move
                0x7fffffff false fdrop ;

external

\ *W <a name="Sec#18"></a>
\ *N Output conversion

: REPRESENT     ( addr u -- n flag1 flag2 ; fs: r -- )  \ ANSI          Floating
\ *G At c-addr, place the character-string external representation of the significand of
\ ** the floating-point number r. Return the decimal-base exponent as n, the sign as flag1
\ ** and valid result as flag2. The character string shall consist of the u most significant
\ ** digits of the significand represented as a decimal fraction with the implied decimal
\ ** point to the left of the first digit, and the first digit zero only if all digits
\ ** are zero. The significand is rounded to u digits following the round to nearest
\ ** rule; n is adjusted, if necessary, to correspond to the rounded magnitude of the
\ ** significand. If flag2 is true then r was in the implementation-defined range of
\ ** floating-point numbers. If flag1 is true then r is negative. \n
\ ** An ambiguous condition exists if the value of BASE is not decimal ten. \n
\ ** When flag2 is false, n  is 7FFFFFFF and flag1 is the sign. The contents of c-addr are
\ ** the first u characters of either NAN or Infinity, padded with spaces if necessary.
                fexam                                \ get type of operand
                dup FPU_STATUS_CCF_MASK_1 and 0<> >r \ save sign = flag1
                fabs
                FPU_STATUS_CCF_MASK_023 and          \ clear C1
                CASE    FPU_STATUS_CCF_UNSUPPORTED OF  c" Unsupported" rep-spec  ENDOF
                        FPU_STATUS_CCF_NAN         OF  c" NAN"         rep-spec  ENDOF
                        FPU_STATUS_CCF_NORMAL      OF  rep-normal                ENDOF
                        FPU_STATUS_CCF_INFINITY    OF  c" Infinity"    rep-spec  ENDOF
                        FPU_STATUS_CCF_ZERO        OF  rep-zero                  ENDOF
                        FPU_STATUS_CCF_EMPTY       OF  c" Empty"       rep-spec  ENDOF
                        FPU_STATUS_CCF_DENORMAL    OF  rep-denormal              ENDOF
                        ( else )                       c" Unknown"     rep-spec
                ENDCASE
                r> swap ;

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ Output conversion.
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

variable sigdigits      6 sigdigits !   \ default precision

B/FLOAT 10 = [IF]  18  [ELSE]  16  [THEN]  constant maxsig

: PRECISION     ( -- u )     \ ANSI         Floating ext
\ *G Return the number of significant digits currently used by (F.), (FE.), (FS.), F.,
\ ** FE., or FS. as u.
                sigdigits @ ;

: SET-PRECISION ( u -- )     \ ANSI         Floating ext
\ *G Set the number of significant digits currently used by (F.), (FE.), (FS.), F.,
\ ** FE., or FS. to u.
                sigdigits ! ;

: min-precision ( u -- )     \ W32F         Floating extra
\ *G Set the number of significant digits currently used by (F.), (FE.), (FS.), F.,
\ ** FE., or FS. to u if it is greater than the present setting.
                precision umax set-precision ;

internal

128 newuser $ftemp

: +sign         ( $buf -- )
                fexam FPU_STATUS_CCF_MASK_1 and
                IF   fabs s" -" ROT +PLACE
                ELSE drop
                THEN ;

: +represent    { $buf -- true | exp sign false ; fs: r -- }
                $ftemp precision represent 0=
                -IF  3drop $ftemp precision $buf +PLACE s"  " $buf +PLACE true
                THEN ;

external

\ *W <a name="Sec#19"></a>
\ *N Format FP number to a buffer

\ *P The following words are for formatting floating point numbers as counted strings in
\ ** the buffer whose address is supplied so they can be used for purposes other than printing
\ ** the numbers to the console. The string is not null terminated.

: (F.)          ( addr -- ; fs: r -- )     \ W32F         Floating extra
\ *G Format the top number on the floating-point stack using fixed-point notation:
\ *E        [-] <digits>.<digits0>
                { $buf -- }
                $buf off
                fdepth 0 <= IF EXIT THEN

                1 min-precision
                $buf +sign

                fdup f0.5 f<
                IF   s" ." $buf  +place f1.0 f+ $ftemp
                     precision 1+ maxsig umin
                     represent
                     3drop
                     $ftemp 1+ precision maxsig 1- umin
                     $buf +place s" " $buf +place
                ELSE $buf +represent not
                     IF   drop dup precision <
                          IF   dup 0=
                               IF   drop s" ." $buf +place
                                    $ftemp precision
                                    $buf +place s" " $buf +place EXIT
                               THEN
                               $ftemp over $buf +place s" ." $buf +place
                               $ftemp over + swap precision
                               swap - $buf +place s" " $buf +place
                          ELSE dup precision =
                               IF   $ftemp swap $buf +place
                                    s" . " $buf +place EXIT
                               THEN
                               $ftemp precision $buf +place
                               precision - 0
                               DO   s" 0" $buf +place
                               LOOP
                               s" . " $buf +place
                          THEN
                     THEN
                THEN ;

: (FE.)         ( addr -- ; fs: r -- )     \ W32F        Floating extra
\ *G Format r as a string in engineering notation.
                { $buf \ -- }
                $buf off
                fdepth 0 <= IF EXIT THEN

                3 min-precision
                $buf +sign
                $buf +represent ?EXIT

                drop 1- s>d 3 fm/mod swap 1+ $ftemp over $buf +PLACE
                s" ." $buf +PLACE
                $ftemp over + swap precision swap - $buf +PLACE
                s" E" $buf +PLACE 3 *
                base @ >r decimal (.) $buf +PLACE r> base ! ;

: (FS.)          ( addr -- ; fs: r -- )     \ W32F        Floating extra
\ *G Format r as a string in scientific notation:
\ *E        <significand><exponent>
\ *P where:
\ *E        <significand>  :=  [-]<digit>.<digits0>
\ **        <exponent>     :=  E[-]<digits>
                { $buf \ -- }
                $buf off
                fdepth 0 <= IF EXIT THEN

                1 min-precision
                $buf +sign
                $buf +represent ?EXIT

                drop 1- $ftemp 1 $buf +PLACE
                s" ." $buf +PLACE
                $ftemp 1+ precision 1- $buf +PLACE
                s" E" $buf +PLACE
                base @ >r decimal (.) $buf +PLACE r> base ! ;

\ SYNONYM (E.) (FS.)  - made a colon def - [cdo-2008May13]
: (E.)          \ synonym of (FS.)
\ *G See above.
                (FS.) ;

: (G.)          ( addr -- ; fs: r -- )     \ W32F           Floating extra
\ *G Format r as a string using scientific notation or ordinary representation according
\ ** to the size of r.
                fdepth 0 <= IF EXIT THEN

                fdup fabs precision 2/ negate 10**n f<
                IF   (fs.)
                ELSE fdup fabs precision 10**n f<
                     IF   (f.)
                     ELSE (fs.)
                     THEN
                THEN ;

\ -----------------------------------------------------------------------------
\ display floating point numbers
\ changed to use words (F.) (FE.) (E.) (G.) and (FS.)
\ January 22nd, 2004 - 10:12 dbu
\ -----------------------------------------------------------------------------

internal

: (fp.)         ( xt  -- ; fs: r -- ) \ display fp #
                { \ $buf -- }
                fdepth 0 <=
                IF   drop ." EMPTY"
                ELSE MAXSTRING LocalAlloc: $buf
                     $buf swap execute $buf count type space
                THEN ;

external

\ *W <a name="Sec#20"></a>
\ *N Display FP numbers

: F.            ( fs: r -- )     \ ANSI            Floating ext
\ *G Display, with a trailing space, the top number on the floating-point stack using
\ ** fixed-point notation:
\ *E        [-] <digits>.<digits0>
                ['] (f.)  (fp.) ;

: FE.           ( fs: r -- )     \ ANSI            Floating ext
\ *G Display, with a trailing space, the top number on the floating-point stack using
\ ** engineering notation, where the significand is greater than or equal to 1.0 and less
\ ** than 1000.0 and the decimal exponent is a multiple of three.
                ['] (fe.) (fp.) ;

: FS.           ( fs: r -- )     \ ANSI            Floating ext
\ *G Display, with a trailing space, the top number on the floating-point stack in
\ ** scientific notation:
\ *E        <significand><exponent>
\ *P where:
\ *E        <significand>  :=  [-]<digit>.<digits0>
\ **        <exponent>     :=  E[-]<digits>
                ['] (fs.)  (fp.) ;

\ SYNONYM E. FS.              \ made a colon def - [cdo-2008May13]
: E.            \ Synonym of FS.
\ *G See above.
                FS. ;

: G.            ( fs: r -- )     \ W32F            Floating extra
\ *G Display the top number on the floating-point stack using scientific notation or
\ ** ordinary representation according to the size of r.
                ['] (g.)  (fp.) ;

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

\ rbs January 26th, 2003 -->
fpi f2/ fconstant fpi/2
fpi f2* fconstant f2pi

: f0<>          f0= 0= ;

: f^2           fdup f* ;

\ <-- rbs

\ \******************************************************************
\ Debugging tools
\ \******************************************************************

\ *W <a name="Sec#21"></a>
\ *N Debugging tools

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ display floating point stack
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

6 value show-fp-depth

: f.s           ( -- )   \ W32F          Floating debug
\ *G Display floating point stack.
                fdepth
                IF   fdepth cr ." {" 1 .r ." } "
                     show-fp-depth fdepth umin dup 1- swap 0
                     DO   10 ?cr
                          dup i - fpick g.
                     LOOP drop
                ELSE ." Empty fp stack "
                THEN ;

: .fdepth       ( -- )   \ W32F          Floating debug
\ *G Display depth of floating point stack.
                ." Items; " fdepth .
                ." Bytes: " FLOATSP @ . ;

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ display state of FPU unit
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

internal

in-system

create allregs 110 allot

: (tag)         ( n1 addr -- n2 )          \ Returns the 2 bit tag for ST(n1)
                dup>r cell+ @ 0x3800 and 0x0800 / +
                7 and
                R> 2 cells+ @ swap 0
                ?DO     2/ 2/
                LOOP
                3 and ;

: (s.)          ( n addr len w -- addr w )
                >r drop  swap r@ * +  r> ;

: s.            ( n addr len w -- )
                (s.) type ;

: .ftag2        ( i -- )
                allregs (tag)
                s" valid  zero   specialempty  " 7 s. ;

: npu-depth     ( -- n )
\               FR1 >FREGS>
                0 0 7
                DO      I allregs (tag) 3 <>
                        IF      DROP I 1+ LEAVE
                        THEN
                -1 +LOOP ;

77 CONSTANT FPDISPSIZE
allregs 7 cells+ CONSTANT npstk

: .tenbyte      ( addr -- )               \ Needs lots of work yet.
                10 + 10 0
                DO      1- dup c@ s>d <# # # #> type space
                LOOP
                drop ;

: h.npustack    ( -- )
                8 0
                DO   cr ." ST(" I 1 .r ." ) "
                     npstk I B/FLOAT * + .tenbyte
                     I .ftag2
                LOOP ;

: .fmask        ( n -- )
                0 5
                DO      space dup i rshift 1 and
                        i s" PrecUfloOfloZeroDnrmInvl" 4 s.
                        ." =" 1 .r
                -1 +LOOP
                drop ;

: .fstatus      ( n -- )
                ."  Flags: "
                0 7
                DO      dup i rshift 1 and
                        i s" ESSFPEUEOEZEDEIE" 2 s. ." =" .
                -1 +LOOP
                drop ;

: .ftag1        ( n -- )
                4 base !
                0 7
                DO      dup i 2* rshift 3 and .
                -1 +LOOP
                drop ;

external

: fdump         ( -- )      \ W32F        Floating debug
\ *G Dump of the real Floating Point Unit.
                cr cr ."      Dump of the Floating Point NPU "
                allregs >fregs>  cr
                base @ >r
                allregs @ dup
                ." Cntl:  " hex 0x0ffff and 4 .r
                dup 10 rshift 3 and
                ."  Rnd-" s" neardownup  chop" 4 s.
                dup 8 rshift 3 and
                ."  Size = " s" sngl????dbl ext " 4 s.
                cr ."  Msk: " .fmask
                cr allregs cell+ @
                ." Status: " 0x0ffff and dup 4 .r space
                ." CC = " dup 8 rshift dup 0x40 and
                IF      7 and 8 or
                ELSE    7 and
                THEN
                binary s>d <# # # # # #> type hex
                ."  Busy = " dup 15 rshift .
                ."  Top = " dup 11 rshift 7 and .
                cr .fstatus
                cr ." Tags: "
                allregs 2 cells+ @ 0xffff and .ftag1
                cr ." IP = "
                allregs 3 cells+ @ dup 8 .r
                ."   IP(rel) = " 8 .r
                cr ." Last Opcode = "  hex
                allregs 4 cells+ @ dup 24 rshift
                0xd8 or 0x0ff and 3 .r
                dup 16 rshift 0x0ff and 3 .r
                cr ."  CS Selector: " 0x0ffff and 4 .r
                cr ." Data Pointer: "
                allregs 5 cells+ @ dup 8 .r
                ."   DP(rel) = " 8 .r
                cr ." Operand Pointer: "
                allregs 6 cells+ @ 0x0ffff and 4 .r
                decimal
                cr ." NPU stack depth = " npu-depth .
                ."   Simulated stack depth = " fdepth .
                hex h.npustack cr
\               allregs 108 dump
                r> base ! ;

internal

fvariable ftemp

: .ftempx       ( -- )
                0 B/FLOAT 1-
                DO      ftemp I + c@ h.2 space
                -1 +LOOP ;

external

: f.x           ( fs: r1 r2 ... rn -- r1 r2 ... rn )     \ Hex dump of fstack
                fdepth
                IF      fdepth cr ." {" 1 .r ." } "
                        show-fp-depth fdepth umin dup 1- swap 0
                        DO      cr dup i - fpick fdup ftemp f!
                                .ftempx 2 spaces g.
                        LOOP
                        drop
                ELSE    ." Empty fp stack "
                THEN ;


\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

\ If you don't understand what the following definition is doing, don't
\ concern yourself. It is moving a floating point number from a1 into
\ the body of its own definition so it can display it easily. Note it must
\ compile an fliteral NOT a fconstant.

: .onefloat     ( -- r1 )
                [ f0.0 ] fliteral g. ;

: see.float     ( a1 -- a2 )
                dup ['] .onefloat >body cell+ CELLS/FLOAT cells move
                .onefloat
                CELLS/FLOAT cells+ ;

defer .float    ' see.float is .float

in-previous

\ changed arm 25/04/2005 23:09:50 to use new number chain technique (see numconv.f)

internal

0 value float?

external

: FLOAT-NUMBER? ( a1 n1 -- d )               \ input parameters
\ floating point number should only be accepted if we are in DECIMAL
\ they can still be entered manually using F# <number>
                base @ 0x0A <> throw         \ only in decimal
\ September 24th, 1997 - 11:59 tjz added
\ interpretive number conversion is explicitly more restrictive than >FLOAT,
\ so we add an extra test for the presence of the required letter 'E' in a
\ floating point string.
                2dup 'E' scan nip 0= throw
                FALSE to float?              \ need to initialize to non-floating#
                >FLOAT 0= throw              \ not a float, throw
                TRUE to float?               \ turn on float flag
                0 0                          \ return dummy double
                ;

number?-chain chain-add float-number?           \ link into number conversion chain

reset-stack-chain chain-add finit

in-system

\ changed to use the reset-stack-chain
\ January 22nd, 2004 - 13:53 dbu
: FLOAT-RESET-STACKS ( -- ) \ reset compile time values
                 0 to fsp-cached? 0 to fsp-adjust ;

\in-system-ok reset-stack-chain chain-add FLOAT-RESET-STACKS

in-previous

: _FLOAT-NUMBER, ( d1 -- d1 )           \ interpreting a double
                 ( d1 -- )              \ compiling a double
                 ( fs: r1 -- r1 )        \ interpreting a float
                 ( fs: r1 -- )           \ compiling a float
                float? 0=
                if      _number,
                else    state @
\in-system-ok           if      postpone fliteral
                        then
                        2drop 0 to float?
                then    ;

' _float-number, is number,             \ link into interpreter

: fdiscard-number ( ?? -- ?? )  \ discard a floating point number if present
                float? if fdrop then 2drop ;

' fdiscard-number is discard-number

module

\s

\ *S Handling Errors

\ *P If you reset the FPU control word to use other than the default rounding or precision
\ ** values then you may need to modify the default error handling. In version V6.10 or
\ ** higher this can be done by defining your own handler, MY-RESET-STACKS then adding it in
\ ** thus;

\ *E reset-stacks-chain chain-add my-reset-stacks
\ **
\ ** Ealier versions need to add
\ **
\ ** : new-reset-stacks [ defer@ reset-stacks compile, ] my-reset-stacks ;
\ ** new-reset-stacks is reset-stacks

\ *E You can test for the presence of NANs with;
\ **
\ **   .... fdup f= 0= ....
\ **
\ ** which returns true only for NANs. You can test for both NANs and infinities with;
\ **
\ **   .... fdup f- f0= 0=
\ **
\ ** and for infinities with;
\ **
\ **   .... fabs finf f=
\ **


\ *Z
