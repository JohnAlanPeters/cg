\ $Id: Ed_EditWindow.F,v 1.1 2011/03/19 23:26:04 rdack Exp $
\
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 8      Define the EDIT-WINDOW object
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

                     0 value textBG
                     0 value textFG
    0   0   0 rgb  new-color highBG
  255 255 255 rgb  new-color highFG
  Color: WHITE     new-color normalBG
  Color: BLACK     new-color normalFG
\  192 225 255 rgb  new-color marginColor
  Color: GREEN     new-color marginColor
  Color: LTGRAY    new-color linesColor
  Color: BLACK     new-color binaryColor
( BLUE ) GREEN     value BmarginColor       \ browse margin color

defer trailBG  ' normalBG is trailBG
defer selectBG ' normalBG is selectBG

: highlighting? ( -- f1 )
                hcst hlst hced hled d= 0= ;     \ if start and end are same

: increment/    ( n1 -- n2 )            \ adjust for very large file
                file-lines 65536 >                      \ if MANY lines, then
                IF      file-lines 65536 / 1+ /         \ divide scroll lines
                THEN    ;

0 value the-width
0 value the-height
0 value html-link?
0 value on-text?
0 value saved-depth

create tempLine MAXSTRING allot

WinDC screenDC          \ The screen's device context

\ is string a2,n2 at the start of string a1,n1?  If it is, then remove n2
\ leading characters from a1,n1 returning the result as a3,n3 and a TRUE flag.
\ else return a1,n1 unmodified as a3,n3 and return a FALSE flag.

: HTML?         ( a1 n1 a2 n2 -- a3 n3 f1 )
                2>r over 2r@ tuck caps-compare 0=       \ a2,n2 starts a1,n1?
                IF      2r@ nip /string                 \ then remove n2 chars
                        TRUE                            \ return true
                ELSE    FALSE                           \ else return false
                THEN    2r> 2drop ;                     \ cleanup return stack


