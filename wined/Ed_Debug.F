\ $Id: Ed_Debug.F,v 1.1 2011/03/19 23:26:04 rdack Exp $
\    File: Ed_Debug.f
\  Author: Dirk Busch
\ Created: Samstag, Juli 10 2004 - 10:16 dbu
\ Updated: Samstag, Juli 10 2004 - 10:16 dbu
\ Rewritten: 2008/06/16 - Camille Doiteau
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ Debug an application in the Editor
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

: stepbp        ( -- )          \ execute a single step
                0 0 WM_STEPBP w32fForth Sendw32fMsg drop ;

: nestbp        ( -- )          \ nest into definition
                0 0 WM_NESTBP w32fForth Sendw32fMsg drop ;

: unestbp       ( -- )          \ unnest from definition
                0 0 WM_UNESTBP w32fForth Sendw32fMsg drop ;

: contbp        ( -- )          \ run continuous till key press
                0 0 WM_CONTBP w32fForth Sendw32fMsg drop ;

: jumpbp        ( -- )          \ jump over branch
                0 0 WM_JUMPBP w32fForth Sendw32fMsg drop ;

: beginbp       ( -- )          \ stop at beginning again
                0 0 WM_BEGNBP w32fForth Sendw32fMsg drop ;

: herebp        ( -- )          \ stop here next time
                0 0 WM_HEREBP w32fForth Sendw32fMsg drop ;

: rstkbp        ( -- )          \ display return stack
                0 0 WM_RSTKBP w32fForth Sendw32fMsg drop ;

: donebp        ( -- )          \ done debugging
                0 0 WM_DONEBP w32fForth Sendw32fMsg drop ;


NewEditDialog InquireDlg "Inquire for Data Item" "Get Current Value for:" "Inquire" "" ""

0 value debug-buttons?

create prev-lines MAXSTRING 5 * allot
       prev-lines MAXSTRING 5 * blank

create edstack 64 cells allot
create edreturn maxstring allot
create edname maxstring allot

:Object DbgButtonsDlg  <Super  ModelessDialog

IDD_DEBUG WinEdit find-dialog-id constant template

 int HexBase
Font dbFont
int inq-running?

:M ClassInit:   ( -- )
                ClassInit: super
                FALSE to HexBase        \ FALSE = Decimal, TRUE = Hex
                FALSE to inq-running?
                 8                Width: dbFont
                14               Height: dbFont
                s" Courier" SetFaceName: dbFont         \ default to Courier
                ;M

:M GetTemplate: ( -- template )
                template ;M

:M ExWindowStyle: ( -- )
                ExWindowStyle: super WS_EX_TOOLWINDOW or ;M

: "addstack     { adr len \ ztemp -- }
                MAXSTRING LocalAlloc: ztemp             \ allocate buffer
                ztemp MAXSTRING erase                   \ null fill buffer
                adr ztemp len MAXSTRING 1- min move     \ move text to buffer
                ztemp
                0 LB_ADDSTRING IDL_STACK SendDlgItemMessage: self drop ;

: "addreturn    { adr len \ ztemp -- }
                MAXSTRING LocalAlloc: ztemp             \ allocate buffer
                ztemp MAXSTRING erase                   \ null fill buffer
                adr ztemp len MAXSTRING 1- min move     \ move text to buffer
                ztemp
                0 LB_ADDSTRING IDL_RETURN SendDlgItemMessage: self drop ;

: n>"           ( n1 -- a1 n2 )
                base @ >r
                HexBase
                IF      HEX
                ELSE    DECIMAL
                THEN
                HexBase
                IF      0 <# #s s" 0x" "hold #>
                ELSE    s>d tuck dabs <# #s rot sign #>
                THEN
                r> base ! ;

:M ShowStack:   { \ temp$ -- }
                MAXSTRING LocalAlloc: temp$
                s" Debugging: " temp$  place
                edname count   temp$ +place
                temp$ count IDT_NAME SetDlgItemText: self drop
                0 0 LB_RESETCONTENT IDL_STACK SendDlgItemMessage: self drop
                edstack @ ?dup
                IF      dup 0<
                        IF      drop 11 0
                                ?DO     s" UnderFlow!" "addstack
                                LOOP
                        ELSE    10 min 1 swap
                                DO      edstack i cells+ @ n>" "addstack
                            -1 +LOOP
                        THEN
                ELSE    s" Empty" "addstack
                THEN
                0 0 LB_RESETCONTENT IDL_RETURN SendDlgItemMessage: self drop
                edreturn count bl skip
                bl scan bl skip                 \ skip "RETURN"
                bl scan bl skip                 \ skip "STACK[xx]"
                BEGIN   2dup bl scan 2dup 2>r nip - dup
                WHILE   "addreturn 2r> bl skip
                REPEAT  2drop 2r> 2drop ;M

: "adddebug     { adr len \ ztemp -- }
                MAXSTRING LocalAlloc: ztemp             \ allocate buffer
                ztemp MAXSTRING erase                   \ null fill buffer
                adr ztemp len MAXSTRING 1- min move     \ move text to buffer
                ztemp
                0 LB_ADDSTRING IDL_WORDS SendDlgItemMessage: self drop ;

:M ShowDebug:   { addr \ ed-dbgline -- }
                addr count dup 1+ localalloc: ed-dbgline
                ed-dbgline place
                0 0 LB_RESETCONTENT IDL_WORDS SendDlgItemMessage: self drop
                prev-lines dup MAXSTRING + swap MAXSTRING 4 * move
                ed-dbgline count 2dup 0x0D scan 2dup 1 /string 2>r
                2drop
                2r> prev-lines MAXSTRING 4 * + place
                5 0
                ?DO     prev-lines i MAXSTRING * + count "adddebug
                LOOP
                ;M

:M ShowResponse: { addr \ temp$ -- }
                MAXSTRING LocalAlloc: temp$
                s"  " temp$ place               \ init to empty type
                addr @ 4 min 0
                ?DO     addr i 1+ cells+ @ n>" temp$ +place
                        s"  "                  temp$ +place
                LOOP    temp$ count IDT_RESULT SetDlgItemText: self ;M

: inquirebp     ( -- )
\ *G inquire for the value of a data item
\ ???                ed-ptr 0= ?EXIT         \ only if we have shared memory
                msgpad off
                inq-running? 0=
                IF   TRUE to inq-running?

                     highlighting? 0=        \ if nothing highlighted
                     if highlight-word then  \ try to highlight something
                     highlighting?           \ if something highlighted
                     hlst hled = and         \ but only on one line
                     if      highlight"      \ get highlight
                             msgpad place
                     then

                     msgpad EditorWindow Start: InquireDlg
                     msgpad c@ 0> and
                     IF   msgpad dup c@ 1+ WM_INQUIRE w32fForth Sendw32fMsg drop
                     THEN

                     FALSE to inq-running?
                ELSE beep
                THEN ;

:M On_Init:     ( -- )
                On_Init: super
                HexBase
                IF      IDR_HEX
                ELSE    IDR_DECIMAL
                THEN    IDR_DECIMAL IDR_HEX CheckRadioButton: self
                Handle: dbFont 0=
                IF      Create: dbFont
                THEN
                Handle: dbFont
                IF      Handle: dbFont IDL_STACK  SetDlgItemFont: self
                        Handle: dbFont IDL_RETURN SetDlgItemFont: self
                        Handle: dbFont IDL_WORDS  SetDlgItemFont: self
                THEN
                ShowStack: self
                ;M

:M On_Command:  ( hCtrl code ID -- f1 ) \ returns 0=cancel
                CASE
                     IDB_STEP     OF stepbp                             ENDOF
                     IDB_NEST     OF nestbp                             ENDOF
                     IDB_UNEST    OF unestbp                            ENDOF
                     IDB_CONT     OF contbp                             ENDOF
                     IDB_JUMP     OF jumpbp                             ENDOF
                     IDB_PROC     OF beginbp                            ENDOF
                     IDB_HERE     OF herebp                             ENDOF
                     IDB_DONE     OF donebp                             ENDOF
                     IDB_INQUIRE  OF inquirebp                          ENDOF
                     IDR_HEX      OF TRUE  to HexBase ShowStack: self   ENDOF
                     IDR_DECIMAL  OF FALSE to HexBase ShowStack: self   ENDOF
                     IDCANCEL     OF FALSE to debug-buttons?
                                     Delete: dbFont
                                     DestroyWindow: self                ENDOF
                                     false swap ( default result )
                ENDCASE ;M

:M WM_CLOSE     ( -- )
                FALSE to debug-buttons?
                Delete: dbFont
                WM_CLOSE WM: Super
                ;M

;Object

: debug-buttons ( -- )
\ *G Open the Debug dialog
                EditorWindow Start: DbgButtonsDlg
                TRUE to debug-buttons? ;

: receive-stack ( addr -- )
\ *G Get stack from Forth
                dup edstack 64 cells cmove
                64 cells + edreturn maxstring cmove
                ShowStack: DbgButtonsDlg ;

: receive-response ( addr -- )
\ *G Get response from Forth to a WM_INQUIRE msg
                ShowResponse: DbgButtonsDlg ;

: receive-debug ( addr -- )
\ *G display the debug line sent by Forth
                ShowDebug: DbgButtonsDlg ;

: receive-name  ( addr -- )
\ *G display the debug line sent by Forth
                count edname place ;

\ -----------------------------------------------------------------------------
\ -----------------------------------------------------------------------------

: zMessageBox   ( szString -- )
                z" Notice"
                MB_OK MB_ICONSTOP or
                WinEdMessageBox: EditorWindow ;

MAXSTRING pointer debug-buf
NewEditDialog DebugDlg "Insert BreakPoint at Word" "BreakPoint at: ' [ vocabulary (sp) ]  word '" "Set" "" ""

: "debug-word   ( a1 n1 -- )
\ *G Set a breakpoint on word a1 n1
                0 0 ExecForth drop
                2dup edname place
                msgpad place                    \ the name we want debugged
                msgpad dup c@ 1+ WM_SETBP w32fForth Sendw32fMsg
                ( result)
                if   debug-buttons
                else beep z" Failed to set BreakPoint!" zMessageBox
                then ;

: debug-word    ( -- )          \ set a breakpoint on a word
        highlighting?
        hlst hled = and                 \ but only on one line
        ?control and                    \ must have control key
        ?shift 0= and                   \ must not have shift key
        IF      highlight" "-blanks" "debug-word
        ELSE    debug-buf count -trailing nip debug-buf c!  \ no trailing bl's
                debug-buf EditorWindow start: DebugDlg
                IF       debug-buf count "debug-word
                THEN
        THEN    ;

