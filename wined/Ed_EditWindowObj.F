\ $Id: Ed_EditWindowObj.F,v 1.6 2011/05/30 21:45:23 rdack Exp $
\
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 10      EditWindowClass
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

:Class EditWindowClass <super child-window

        int xpixel
        int ypixel
        int refreshing?
        int TopOfWindow
        int Stack#
        int built-cursor?
        int alreadyPainting
        int paintAgain

MAXSTRING bytes update-flags  \ bytes to mark lines that need updating

Rectangle ClientRect

Record: LPWinScrollInfo
        int cbSize
        int fMask
        int nMin
        int nMax
        int nPage
        int nPos
        int nTrackPos
;RecordSize: sizeof(LPWinScrollInfo)

:M ClassInit:   ( -- )
        ClassInit: super
        sizeof(LPWinScrollInfo) to cbSize       \ init structure to right size
        0 to TopOfWindow
        0 to Stack#
        0 to built-cursor?
        TRUE to refreshing?
        FALSE to alreadyPainting
        FALSE to paintAgain
        #fonts 0
        DO      font-list i cells+ @ >r
                 8                 Width: [ r@ ]
                14                Height: [ r@ ]
                s" Fixedsys" SetFaceName: [ r> ]  \ default to Courier
        LOOP
        ;M

:M SetStack:    ( n1 -- )
                dup to Stack#
                    to entry#
                ;M

:M GetStack:    ( -- n1 )
                Stack#
                ;M

:M CharHeight:  ( -- n1 )  \ return the font character height
                the-height
                ;M

:M CharWidth:   ( -- n1 )
                the-width
                ;M

0 value ignoring?       \ TRUE if we are ignoring text till '>' encountered
0 value linking?        \ TRUE if we are displaying a link
0 value ruling?         \ TRUE if we are drawing a Horizontal Rule
0 value HRSize          \ Horizontal Rule height in pixels

: "IgnoreTo     ( a1 n1 -- )             \ ignore text till a1,n1 string found
                dup >r caps-search       \ ONLY on same line though
                IF      r@ /string       \ strip off found string
                THEN    r>drop ;

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ Colorization stuff {BE}
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
: ISKEY?        ( a n -- action color T | F )  { \ maxkey -- }
                \ Returns the color of the string and a flag: FALSE if not found
                -trailing tempkey place  tempkey uppercase drop
                keywords @ 1- to maxkey
                0 maxkey
                BEGIN   ?dup
                WHILE   2/ 1 under+
                REPEAT                          \ position of MSB?
                1 swap lshift
                dup 2/                          \ binary search of keyword list
        BEGIN   over                              ( size index . )
        WHILE   >r 2/ r>
                dup 'keyword @ char+ char+ count
                tempkey count compare  dup
                IF   0< IF      over + maxkey min
                        ELSE    over - 0max
                        THEN
                ELSE    drop nip 'keyword @ count swap c@
                        TRUE
                        EXIT                    \ found
                THEN
        REPEAT
        2drop  false ;                          \ not found

: ishex?        ( a n -- f )
                BASE @ >r hex number? r> BASE ! nip nip ;

: commanumber? ( a n -- f )
  true -rot
  0 ?do dup c@ dup ascii 0 ascii 9 between
        over ascii . = or swap ascii , = or not
        if swap drop false swap leave then 1+
     loop drop ;

: ISNUMBER?     ( a n -- f )
        -trailing 2dup number? nip nip          \ ( fl )
        IF      2drop TRUE EXIT THEN            \ decimal number
        dup 3 =
        IF      over count [char] ' = swap        ( a n f a' )
                char+ c@   [char] ' = and
                IF 2drop TRUE EXIT THEN         \ '?' literal
        THEN
        2dup >float
        IF      fdrop 2drop TRUE EXIT THEN      \ floating point
        over c@ '$' =  ASMoptions and
        IF      1 /string ishex? EXIT THEN      \ $hex
        over 2 s" 0x" compare 0=
        IF      2 /string ishex? EXIT THEN      \ 0xhex
         2dup commanumber?     \ ( fl ) allow commas in a decimal#
         IF 2drop true exit then
        2drop 0 ;

: is$number? ( a n -- f)
  over c@ ascii $ =            \ 1st char is '$'?
  if 1 -1 d+ -trailing commanumber?   \ rest is valid#
  else 2drop false then ;

: typestr       ( a n -- )
        xpixel ypixel 2over TextOut: dc         \ output the text
        GetTextExtent: dc drop +to xpixel ;     \ and adjust X pixel counter

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 11    Colorization support
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

: ColorWord     ( n -- )                \ set color based on 4-bit value
        0x0F and cells keycolors + @  SetTextColor: dc ;

\ changed May 4th, 2003 - 11:22 dbu
\ Colorization didn't work on files with names like WinEd2.13.f
\ changed March 9th, 2005 - 22:32 aws
\ Colorization now works for *.f *.frm *.cfg *.col and *.seq files
: Forth-Source? ( -- flag )                      \ Is current file *.?
        cur-filename count ".EXT-ONLY" 2dup upper
        2dup s" .F"   compare 0= -rot
        2dup s" .FRM" compare 0= -rot
        2dup s" .CFG" compare 0= -rot
        2dup s" .COL" compare 0= -rot
             s" .SEQ" compare 0=
             OR OR OR OR ;

: colorable?    ( -- f )
        Forth-Source?
        normalFG textFG = and
        colorize? and                           \ ok to customize?
        keywords @ 0<> and                      \ we have a table
        lend-len 0> and ;                       \ and not in binary mode

0 value comment?

: endface  ( rda )                       \ jp May 12th, 2002 - 10:57
        Handle: vFont SetFont: dc ;      \ set the font to be used

: Underline     ( -- )
        Handle: uFont 0=                \ or is it change to underlned chars?
        IF     TRUE Underline: uFont
                       Create: uFont
        THEN
        Handle: uFont SetFont: dc ;

: /Underline    ( -- )                  \ cancel underline font
        endface ;

: Italics       ( -- )
        Handle: iFont 0=                \ set font to italics
        IF       TRUE Italic: iFont
                      Create: iFont
        THEN
        Handle: iFont SetFont: dc ;

: /Italics      ( -- )                  \ cancel italics font
        endface ;

: Bold  ( -- )
        Handle: bFont 0=                \ set font to bold
        IF    FW_BOLD Weight: bFont
                      Create: bFont
        THEN
        Handle: bFont SetFont: dc ;

: /Bold         ( -- )
        endface ;                       \ cancel bold font

: StrikeOut     ( -- )                  \ set the strikeout font
        Handle: xFont 0=
        IF    TRUE StrikeOut: xFont
                      Create: xFont
        THEN
        Handle: xFont SetFont: dc ;

: /StrikeOut    ( -- )                  \ cancel strikeout font
        endface ;

: (typetext)    ( addr len -- ) \ rda made a new version
  colorable?
  if begin dup                             \ this is text
     while bl kparse                       ( a' n' a n )
           2dup iskey?
           if comment? ?dup if swap drop then
              over dup 10 = swap 12 = or
              if dup to comment? then
                 ColorWord
                 case 1 of endof  \ no action
                   2 of typestr 0 0 2swap   endof  \ EOL comment
                   3 of typestr ')' kparse  endof  \ string)
                   4 of typestr '"' kparse  endof  \ string"
                   5 of typestr '}' kparse  endof  \ string}
                   6 of typestr ']' kparse  endof  \ string]
                   7 of typestr '>' kparse  endof  \ string>
                   8 of typestr bl  kparse 0 ColorWord endof
                   9 of typestr bl  kparse  endof  \ pair
                  11 of false to comment?   endof
                endcase
           else  2dup isnumber? comment? 0= and
                 if RED SetTextColor: dc then
           then typestr comment? 0=
           if BLACK SetTextColor: dc then
     repeat  2drop
   else highlighting? 0=
     if begin dup
        while bl kparse totline?
         if ( Bold ) BLUE  SetTextColor: dc typestr /bold BLACK SetTextColor: dc
         else vtop?
           if BLUE SetTextColor: dc typestr BLACK  SetTextColor: dc
           else 2dup isnumber?
           if RED SetTextColor: dc typestr BLACK SetTextColor: dc
           else typestr then then
         then
        repeat 2drop
     else typestr then
   then    ;

: typecomment   ( a n -- )
        GREEN SetTextColor: dc                \ display text in green
        typestr
        BLACK SetTextColor: dc ;

: typetext      ( a n -- )   \ output colorized text to edit window
        colorable? ASMoptions and             \ ASM colorization options?
        IF      2dup ';' scan dup               ( a n a' n' . )
                IF      tuck 2>r - (typetext) \ type the non-comment part
                        2r> typecomment exit  \ type the comment part
                ELSE    2drop
                THEN
                ASMoptions 1 >
                IF      over c@ '*' =
                        IF  typecomment exit
                        THEN
                THEN
        THEN    (typetext) ;

\       End of Colorization support

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 12    Text output and font changes
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

: Show-size-in-Bites&Lines  ( a1 len len -- a1 len )
                IF      base @ >r hex
                        tempLine off                   \ clear the temp buffer
                        displayingLine BLOCKLINE-SIZE *
                        0 <# # # # # BL hold # # # # #>
                        tempLine +place                \ 9 wide
                        s"   | "
                        tempLine +place                \ 4 wide
                        2dup bounds
                        ?DO     i c@ 0 <# # # BL hold #>
                                tempLine +place        \ 3 * BLOCKLINE-SIZE wide
                        LOOP
                        SPCS BLOCKLINE-SIZE 3 * 14 + tempLine c@ - 0MAX
                        tempLine +place
                        tempLine +place
                        tempLine count
                        r> base !
                THEN ;

\ New above latest on bottom

: "PutTextOut   ( a1 n1 -- )
        ignoring?                            \ are we still discarding HTML

\ Discard-HTML-tags
        IF      '>' scan dup                 \ discard text upto '>' or end
                IF   1 /string               \ and remove '>' too
                     FALSE to ignoring?      \ and we are done skipping
                ELSE 2drop
                     EXIT
                THEN                         \ still skipping till '>' found
        THEN
        lend-len 0=                 \ if not a TEXT file, then discard non ASCII
        IF      dup
                Show-size-in-Bites&Lines
        THEN
        browse?
        IF      \ expand TABs if we are browsing
\ Expand-tabs
                BEGIN   dup                      \ while there is text remaining
                WHILE   2dup K_TAB scan          \ scan for TAB
                        2dup 2>r nip -
                        typetext \ {BE}
                        2r> over c@ K_TAB =      \ if we found a TAB
                        IF                       \ then calc pixels by TAB width
                                tab-size xpixel the-width
                                / tab-size 1 max mod -
                                the-width * +to xpixel  \ expand by a tab width
                                1 /string        \ remove TAB from string
                        THEN
                REPEAT  2drop
        ELSE    typetext \ {BE}
        THEN    ;

: IgnoreTo'>'   ( -- )
    TRUE to ignoring? ;

: Get#To'>'     ( a1 n1 -- a2 n2 n3 )
        2dup '>' scan                   \ find '>'
        2dup 1 /string 2>r              \ skip '>' and save following string
        nip - number? 2drop             \ extracted number string
        2r> rot ;

VARIABLE #lit

: TextTo';'     ( a1 n1 -- a2 n2 )
        2dup ';' scan                   \ find ';'
        2dup 1 /string 2>r              \ skip ';' and save following string
        nip - number? 2drop             \ extracted number string
        #lit c! #lit 1 "PutTextOut      \ output as a literal character
        2r> ;

: HorizontalRule ( -- )                 \ put out a line on screen
        TRUE to ruling? ;

: StartLink     ( -- )                  \ start a HREF link
        linking? 0=
        IF      Underline
                LTBLUE SetTextColor: dc
                TRUE to linking?
        THEN    ;

: EndLink       ( -- )
        linking?                        \ end the linking
        IF      BLACK SetTextColor: dc
                /Underline
                FALSE to linking?
        THEN    ;

\ Examples of Links:
\ Read the <A HREF="file:disclaim.html">Disclaimer</A>.
\ Send a message to PSE with <A HREF="mailto:PSE@ix.netcom.com">suggestions</A>.

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 13    HTML statment processors
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

new-chain html-chain
new-chain &-chain

: (?htm-EXIT)    ( a1 n1 a2 n2 -- a3 n3 )
        dup 3 pick >               \ if looking for longer string than we have
        IF      2drop
                r>drop
                EXIT
        THEN
        2>r over 2r@ tuck compare 0=     \ a2,n2 starts a1,n1?
        IF      2r> nip /string          \ then remove n2 chars
        ELSE    2r> 2drop
                r>drop                   \ don't execute rest of HTML statment
        THEN    ;

: StringHtml
        BEGIN   dup @
        WHILE   @
        REPEAT  here swap ! 0 , here cell+ ,
        docol ,                          \ make a headerless def
        compile (s") ,"text" align       \ compile in html command string
        compile (?htm-EXIT)              \ compile in html test
        !csp ] ;                         \ define a headerless definition

: HTML:  ( "htmlstring" -- )             \ compile time
         ( a1 n1 -- a2 n2 )              \ runtime
         html-chain                      \ link into html-chain
         StringHtml ;

: &:     ( "&string" -- )                \ compile time
         ( a1 n1 -- a2 n2 )              \ runtime
         &-chain                         \ link into &-chain
         StringHtml ;


\ ISO 8859-1 characters set
&: "&quot;"     s$ '"'  "PutTextOut ;    \ Quotes
&: "&QUOT;"     s$ '"'  "PutTextOut ;    \  idem
&: "&amp;"      s" &"   "PutTextOut ;    \ Ampersand
&: "&AMP;"      s" &"   "PutTextOut ;    \  idem
&: "&LT;"       s" <"   "PutTextOut ;    \ Less Than
&: "&lt;"       s" <"   "PutTextOut ;    \  idem
&: "&GT;"       s" >"   "PutTextOut ;    \ Greater than
&: "&gt;"       s" >"   "PutTextOut ;    \  idem
&: "&nbsp;"     s"  "   "PutTextOut ;    \ Non-breaking space
&: "&iexcl;"    s" ¡"   "PutTextOut ;    \ Inverted exclamation
&: "&cent;"     s" ¢"   "PutTextOut ;    \ Cent sign
&: "&pound;"    s" £"   "PutTextOut ;    \ Pound sterling
&: "&curren;"   s" ¤"   "PutTextOut ;    \ General currency sign
&: "&yen;"      s" ¥"   "PutTextOut ;    \ Yen sign
&: "&brvbar;"   s" ¦"   "PutTextOut ;    \ Broken vertical bar
&: "&sect;"     s" §"   "PutTextOut ;    \ Section sign
&: "&uml;"      s" ¨"   "PutTextOut ;    \ Umlaut - dieresis
&: "&copy;"     s" ©"   "PutTextOut ;    \ Copyright
&: "&ordf;"     s" ª"   "PutTextOut ;    \ Feminine ordinal
&: "&laquo;"    s" «"   "PutTextOut ;    \ Left angle quote, guillemet left
&: "&not;"      s" ¬"   "PutTextOut ;    \ Not sign
&: "&shy;"      s" ­"   "PutTextOut ;    \ Soft hyphen
&: "&reg;"      s" ®"   "PutTextOut ;    \ Registered trademark
&: "&macr;"     s" ¯"   "PutTextOut ;    \ Macron accent
&: "&deg;"      s" °"   "PutTextOut ;    \ Degree sign
&: "&plusmn;"   s" ±"   "PutTextOut ;    \ Plus or minus
&: "&sup2;"     s" ²"   "PutTextOut ;    \ Superscript two
&: "&sup3;"     s" ³"   "PutTextOut ;    \ Superscript three
&: "&acute;"    s" ´"   "PutTextOut ;    \ Acute accent
&: "&micro;"    s" µ"   "PutTextOut ;    \ Micro sign
&: "&para;"     s" ¶"   "PutTextOut ;    \ Paragraph sign
&: "&middot;"   s" ·"   "PutTextOut ;    \ Middle dot
&: "&cedil;"    s" ¸"   "PutTextOut ;    \ Cedilla
&: "&sup1;"     s" ¹"   "PutTextOut ;    \ Superscript one
&: "&ordm;"     s" º"   "PutTextOut ;    \ Masculine ordinal
&: "&raquo;"    s" »"   "PutTextOut ;    \ Right angle quote, guillemotright
&: "&frac14;"   s" ¼"   "PutTextOut ;    \ Fraction one-fourth
&: "&frac12;"   s" ½"   "PutTextOut ;    \ Fraction one-half
&: "&frac34;"   s" ¾"   "PutTextOut ;    \ Fraction three-fourths
&: "&iquest;"   s" ¿"   "PutTextOut ;    \ Inverted question mark
&: "&Agrave;"   s" À"   "PutTextOut ;    \ Capital A, grave accent
&: "&Aacute;"   s" Á"   "PutTextOut ;    \ Capital A, acute accent
&: "&Acirc;"    s" Â"   "PutTextOut ;    \ Capital A, circumflex accent
&: "&Atilde;"   s" Ã"   "PutTextOut ;    \ Capital A, tilde
&: "&Auml;"     s" Ä"   "PutTextOut ;    \ Capital A, dieresis or umlaut mark
&: "&Aring;"    s" Å"   "PutTextOut ;    \ Capital A, ring
&: "&AElig;"    s" Æ"   "PutTextOut ;    \ Capital AE dipthong, ligature
&: "&Ccedil;"   s" Ç"   "PutTextOut ;    \ Capital C, cedilla
&: "&Egrave;"   s" È"   "PutTextOut ;    \ Capital E, grave accent
&: "&Eacute;"   s" É"   "PutTextOut ;    \ Capital E, acute accent
&: "&Ecirc;"    s" Ê"   "PutTextOut ;    \ Capital E, circumflex accent
&: "&Euml;"     s" Ë"   "PutTextOut ;    \ Capital E, dieresis or umlaut mark
&: "&Igrave;"   s" Ì"   "PutTextOut ;    \ Capital I, grave accent
&: "&Iacute;"   s" Í"   "PutTextOut ;    \ Capital I, acute accent
&: "&Icirc;"    s" Î"   "PutTextOut ;    \ Capital I, circumflex accent
&: "&Iuml;"     s" Ï"   "PutTextOut ;    \ Capital I, dieresis or umlaut mark
&: "&ETH;"      s" Ð"   "PutTextOut ;    \ Capital Eth, Icelandic
&: "&Ntilde;"   s" Ñ"   "PutTextOut ;    \ Capital N, tilde
&: "&Ograve;"   s" Ò"   "PutTextOut ;    \ Capital O, grave accent
&: "&Oacute;"   s" Ó"   "PutTextOut ;    \ Capital O, acute accent
&: "&Ocirc;"    s" Ô"   "PutTextOut ;    \ Capital O, circumflex accent
&: "&Otilde;"   s" Õ"   "PutTextOut ;    \ Capital O, tilde accent
&: "&Ouml;"     s" Ö"   "PutTextOut ;    \ Capital O, dieresis or umlaut mark
&: "&times;"    s" ×"   "PutTextOut ;    \ Multiply sign
&: "&Oslash;"   s" Ø"   "PutTextOut ;    \ Capital O, slash
&: "&Ugrave;"   s" Ù"   "PutTextOut ;    \ Capital U, grave accent
&: "&Uacute;"   s" Ú"   "PutTextOut ;    \ Capital U, acute accent
&: "&Ucirc;"    s" Û"   "PutTextOut ;    \ Capital U, circumflex accent
&: "&Uuml;"     s" Ü"   "PutTextOut ;    \ Capital U, dieresis or umlaut mark
&: "&Yacute;"   s" Ý"   "PutTextOut ;    \ Capital Y, acute accent
&: "&THORN;"    s" Þ"   "PutTextOut ;    \ Capital THORN, Icelandic
&: "&szlig;"    s" ß"   "PutTextOut ;    \ Small sharp s, German, sz ligature
&: "&agrave;"   s" à"   "PutTextOut ;    \ Small a, grave accent
&: "&aacute;"   s" á"   "PutTextOut ;    \ Small a, acute accent
&: "&acirc;"    s" â"   "PutTextOut ;    \ Small a, circumflex accent
&: "&atilde;"   s" ã"   "PutTextOut ;    \ Small a, tilde accent
&: "&auml;"     s" ä"   "PutTextOut ;    \ Small a, dieresis or umlaut mark
&: "&aring;"    s" å"   "PutTextOut ;    \ Small a, ring
&: "&aelig;"    s" æ"   "PutTextOut ;    \ Small ae diphthong, ligature
&: "&ccedil;"   s" ç"   "PutTextOut ;    \ Small c, cedilla
&: "&egrave;"   s" è"   "PutTextOut ;    \ Small e, grave accent
&: "&eacute;"   s" é"   "PutTextOut ;    \ Small e, acute accent
&: "&ecirc;"    s" ê"   "PutTextOut ;    \ Small e, circumflex accent
&: "&euml;"     s" ë"   "PutTextOut ;    \ Small e, dieresis or umlaut mark
&: "&igrave;"   s" ì"   "PutTextOut ;    \ Small i, grave accent
&: "&iacute;"   s" í"   "PutTextOut ;    \ Small i, acute accent
&: "&icirc;"    s" î"   "PutTextOut ;    \ Small i, circumflex accent
&: "&iuml;"     s" ï"   "PutTextOut ;    \ Small i, dieresis or umlaut mark
&: "&eth;"      s" ð"   "PutTextOut ;    \ Small eth, Icelandic
&: "&ntilde;"   s" ñ"   "PutTextOut ;    \ Small n, tilde
&: "&ograve;"   s" ò"   "PutTextOut ;    \ Small o, grave accent
&: "&oacute;"   s" ó"   "PutTextOut ;    \ Small o, acute accent
&: "&ocirc;"    s" ô"   "PutTextOut ;    \ Small o, circumflex accent
&: "&otilde;"   s" õ"   "PutTextOut ;    \ Small o, tilde
&: "&ouml;"     s" ö"   "PutTextOut ;    \ Small o, dieresis or umlaut mark
&: "&divide;"   s" ÷"   "PutTextOut ;    \ Division sign
&: "&oslash;"   s" ø"   "PutTextOut ;    \ Small o, slash
&: "&ugrave;"   s" ù"   "PutTextOut ;    \ Small u, grave accent
&: "&uacute;"   s" ú"   "PutTextOut ;    \ Small u, acute accent
&: "&ucirc;"    s" û"   "PutTextOut ;    \ Small u, circumflex accent
&: "&uuml;"     s" ü"   "PutTextOut ;    \ Small u, dieresis or umlaut mark
&: "&yacute;"   s" ý"   "PutTextOut ;    \ Small y, acute accent
&: "&thorn;"    s" þ"   "PutTextOut ;    \ Small thorn, Icelandic
&: "&yuml;"     s" ÿ"   "PutTextOut ;    \ Small y, dieresis or umlaut mark

create trademark-ligature 153 c,
&: "&trade;" trademark-ligature 1 "PutTextOut ;  \ Trademark
&: "&TRADE;" trademark-ligature 1 "PutTextOut ;

&: "&#"         TextTo';' ;             \ handle literal characters

: "Process&"    { adr len \ &$ -- a2 n2 }       \ process one HTML statement
        LMAXSTRING LocalAlloc: &$
        adr len &$ LPLACE               \ save original string away
        &$ LCOUNT
        &-chain do-chain                \ go look for an html command
        over &$ CELL+ =                 \ if we didn't process any,
        IF      2drop                   \ August 4th, 1997 tjz
                                        \ correct for a stack depth problem
                adr 1 "PutTextOut       \ then output 1 original character
                1                       \ one character processed
        ELSE    nip len swap -          \ else calc the processed characters
        THEN    adr len rot 0MAX /string ;   \ remove them from original string

: "&PutTextOut  ( adr len -- )
        BEGIN
                2dup s" &" search
        WHILE
                2swap 2over nip -
                "PutTextOut   \ display leading text
                "Process&"
        REPEAT  2drop
        "PutTextOut ;

\ HTML statements

HTML: "<A HREF" ( a1 n1 -- a2 n2 )         \ an embeded reference
                IgnoreTo'>'                \ ignore text till '>' encountered
                StartLink ;                \ turn on hypertext marker

HTML: "</A>"    ( a1 n1 -- a2 n2 )         \ put out text upto end of link
                EndLink ;

\ The following 3 definitions are NOT Standard:

HTML: "<R>"     RED     SetTextColor: dc ; \ RDA March 16th, 2002
HTML: "<BL>"    BLUE    SetTextColor: dc ; \ RDA March 16th, 2002
HTML: "<BK>"    BLACK   SetTextColor: dc ; \ RDA March 16th, 2002

HTML: "<A NAME"  IgnoreTo'>' ;             \ ignore label during display
HTML: "<ADDRESS>"  ;                       \ ignore Address
HTML: "</ADDRESS>" ;                       \ ignore Address
HTML: "<B>"       Bold ;                   \ turn on  Bold
HTML: "</B>"      /Bold ;                  \ turn off Bold
HTML: "<BIG>"     ;                        \ ignore     Big font
HTML: "</BIG>"    ;                        \ ignore not Big font
HTML: "<BLINK>"   ;                        \ ignore turn on  Blink
HTML: "</BLINK>"  ;                        \ ignore turn off Blink
HTML: "</BLOCKQUOTE>" ;                    \ ignore end   BLOCKQUOTE
HTML: "<BODY>"    ;                        \ ignore start of body
HTML: "</BODY>"   ;                        \ ignore end   of body
HTML: "<BR>"      ;                        \ ignore line break
HTML: "</BUTTON>"   ;                      \ ignore end  button
HTML: "</CAPTION>"  ;                      \ ignore turn off Captioning
HTML: "<CENTER>"  ;                        \ ignore turn on  Centering
HTML: "</CENTER>" ;                        \ ignore turn off Centering
HTML: "<CITE>"    Italics ;                \ turn on  Citation
HTML: "</CITE>"   /Italics ;               \ turn off Citation
HTML: "<CODE>"    ;                        \ ignore CODE
HTML: "</CODE>"   ;                        \ ignore /CODE
HTML: "<DFN>"     ;                        \ ignore start definition
HTML: "<DD>"      ;                        \ ignore ???
HTML: "</DD>"     ;                        \ ignore ???
HTML: "<DT>"      ;                        \ ignore ???
HTML: "</DT>"     ;                        \ ignore ???
HTML: "</DFN>"    ;                        \ ignore end   definition
HTML: "<DIR>"     ;                        \ ignore start directory list
HTML: "</DIR>"    ;                        \ ignore end   directory list
HTML: "<DEL>"     ;                        \ ignore start delete
HTML: "</DEL>"    ;                        \ ignore end   delete
HTML: "<DIV>"     ;                        \ ignore start division
HTML: "</DIV>"    ;                        \ ignore end   division
HTML: "<DL>"      ;                        \ ignore Definition list
HTML: "</DL>"     ;                        \ ignore Definition list
HTML: "<EM>"      Italics ;                \ turn on  Emphasize
HTML: "</EM>"     /Italics ;               \ turn off Emphasize
HTML: "<FIELDSET>"   ;                     \ ignore start fieldset
HTML: "</FIELDSET>"   ;                    \ ignore end   fieldset
HTML: "</FONT>"   ;                        \ ignore font selection
HTML: "</FORM>"   ;                        \ ignore end of Form
HTML: "<H1>"      Bold ;                   \ Start current heading 1
HTML: "</H1>"     /Bold ;                  \ end current heading 1
HTML: "<H2>"      Italics ;                \ Start current heading 2
HTML: "</H2>"     /Italics ;               \ end current heading 2
HTML: "<H3>"      Bold ;                   \ Start current heading 3
HTML: "</H3>"     /Bold ;                  \ end current heading 3
HTML: "<H4>"      ;                        \ Start current heading 4
HTML: "</H4>"     ;                        \ end current heading 4
HTML: "<H5>"      ;                        \ Start current heading 5
HTML: "</H5>"     ;                        \ end current heading 5
HTML: "<H6>"      ;                        \ Start current heading 6
HTML: "</H6>"     ;                        \ end current heading 6
HTML: "<HEAD>"    ;                        \ ignore start of header
HTML: "</HEAD>"   ;                        \ ignore end   of header
HTML: "<HR>"      HorizontalRule ;         \ ignore Horizontal Rule
HTML: "<HR SIZE=" Get#To'>' to HRSize ;    \ extract Horiz Rule size parameter
HTML: "<HTML>"    ;                        \ ignore start of html document
HTML: "</HTML>"   ;                        \ ignore end   of html document
HTML: "<I>"       Italics ;                \ turn on  Italics
HTML: "</I>"      /Italics ;               \ turn off Italics
HTML: "<INS>"     ;                        \ ignore start insert
HTML: "</INS>"    ;                        \ ignore end   insert
HTML: "<KBD>"     ;                        \ ignore keyboard input
HTML: "</KBD>"    ;                        \ ignore not keyboard input
HTML: "<LEGEND>"  ;                        \ ignore start legend
HTML: "</LEGEND>" ;                        \ ignore end   legend
HTML: "<LI>"      s"   * " "PutTextOut ;   \ start a list item
HTML: "</MAP>"    ;                        \ ignore map
HTML: "<META>"    ;                        \ ignore Meta information
HTML: "<MENU>"    ;                        \ ignore start Menu
HTML: "</MENU>"   ;                        \ ignore end   Menu
HTML: "<NOBR>"    ;                        \ ignore start No Break
HTML: "</NOBR>"   ;                        \ ignore stop No Break
HTML: "<NOFRAME>"  ;                       \ ignore No frames
HTML: "</NOFRAME>" ;                       \ ignore Not No frames
HTML: "</OBJECT>"  ;                       \ ignore /Object
HTML: "<OL>"  ;                            \ ignore ???
HTML: "</OL>"  ;                           \ ignore ???
HTML: "<OPTION>"  ;                        \ ignore Options
HTML: "<P>"       ;                        \ ignore start paragraph
HTML: "</P>"      ;                        \ ignore end paragraph
HTML: "<PRE>"     ;              \ ignore (Use text as formatted in file)
HTML: "</PRE>"    ;              \ ignore (Stop using text as formatted in file)
HTML: "</Q>"      ;                        \ ignore end question
HTML: "<S>"       Strikeout ;              \ turn on  Strikeout
HTML: "</S>"      /Strikeout ;             \ turn off Strikeout
HTML: "<SAMP>"    ;                        \ ignore     Sample output
HTML: "</SAMP>"   ;                        \ ignore not Sample output
HTML: "</SCRIPT>" ;                        \ ignore not Script
HTML: "</NOSCRIPT>" ;                      \ ignore not NoScript
HTML: "<SELECT>"  ;                        \ ignore     Selection list
HTML: "</SELECT>" ;                        \ ignore     Selection list
HTML: "<SMALL>"   ;                        \ ignore     Small font
HTML: "</SMALL>"  ;                        \ ignore not Small font
HTML: "<STRIKE>"  Strikeout ;              \ turn on  Strikeout
HTML: "</STRIKE>" /Strikeout ;             \ turn off Strikeout
HTML: "<STRONG>"  Bold ;                   \ turn on  Strong Emphesis
HTML: "</STRONG>" /Bold ;                  \ turn off Strong Emphesis
HTML: "<STYLE>"   ;                        \ ignore     Stype
HTML: "</STYLE>"  ;                        \ ignore not Style
HTML: "<SUB>"     ;                        \ ignore Subscript
HTML: "<SUP>"     ;                        \ ignore Superscript
HTML: "<TD>"      ;                        \ ignore Table Cols
HTML: "</TD>"     ;                        \ ignore Table Cols
HTML: "<TH>"      ;                        \ ignore Table Rows
HTML: "</TH>"     ;                        \ ignore Table Rows
HTML: "<TABLE>"   ;                        \ ignore start table
HTML: "</TABLE>"  ;                        \ ignore end   table
HTML: "<TBODY>"   ;                        \ ignore tbody
HTML: "<TFOOT>"   ;                        \ ignore tfoot
HTML: "<TITLE>"   s" </TITLE>" "IgnoreTo ; \ start of title
HTML: "</TITLE>"  ;                        \ end   of title
HTML: "<TR>"      ;                        \ ignore Table Rows
HTML: "</TR>"     ;                        \ ignore Table Rows
HTML: "<TT>"      ;                        \ ignore Typewriter font
HTML: "<U>"       Underline ;              \ turn on  Underline
HTML: "</U>"      /Underline ;             \ turn off Underline
HTML: "<UL>"      ;                        \ ignore start unordered list
HTML: "</UL>"     ;                        \ ignore end   unordered list
HTML: "<VAR>"     ;                        \ ignore start variable
HTML: "</VAR>"    ;                        \ ignore end   variable
HTML: "<WBR>"     ;                        \ ignore Word Break

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 14    These processors need to be last, since they are short & open ended.
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

HTML: "<A REL"    IgnoreTo'>' ;          \ ignore Relationships
HTML: "<A REV"    IgnoreTo'>' ;          \ ignore Reverse Relationships
HTML: "<A SHAPE"  IgnoreTo'>' ;          \ ignore shape statements
HTML: "<APPLET"   IgnoreTo'>' ;          \ ignore APPLETs
HTML: "<AREA "    IgnoreTo'>' ;          \ ignore Map Sections
HTML: "<BASE "    IgnoreTo'>' ;          \ ignore Base specifications
HTML: "<BASEFONT" IgnoreTo'>' ;          \ ignore BASEFONTs
HTML: "<BLOCKQUOTE" IgnoreTo'>' ;        \ ignore blockquotes
HTML: "<BODY "    IgnoreTo'>' ;          \ ignore Color references
HTML: "<BR "      IgnoreTo'>' ;          \ ignore Clear textwrap
HTML: "<BUTTON"   IgnoreTo'>' ;          \ ignore buttons
HTML: "<CAPTION"  IgnoreTo'>' ;          \ ignore CAPTIONs
HTML: "<COL"      IgnoreTo'>' ;          \ ignore COLumn specifications
HTML: "<DIR "     IgnoreTo'>' ;          \ ignore Directory compact
HTML: "<DIV "     IgnoreTo'>' ;          \ ignore Align Division
HTML: "<DL "      IgnoreTo'>' ;          \ ignore Definition list
HTML: "<EMBED "   IgnoreTo'>' ;          \ ignore Embeded objects
HTML: "<FONT"     IgnoreTo'>' ;          \ ignore FONTs
HTML: "<FORM"     IgnoreTo'>' ;          \ ignore Forms
HTML: "<FRAME"    IgnoreTo'>' ;          \ ignore FRAMEs
HTML: "<H1 "      IgnoreTo'>' ;          \ start a new heading 1
HTML: "<H2 "      IgnoreTo'>' ;          \ start a new heading 2
HTML: "<H3 "      IgnoreTo'>' ;          \ start a new heading 3
HTML: "<H4 "      IgnoreTo'>' ;          \ start a new heading 4
HTML: "<H5 "      IgnoreTo'>' ;          \ start a new heading 5
HTML: "<H6 "      IgnoreTo'>' ;          \ start a new heading 6
HTML: "<HR "      IgnoreTo'>' ;          \ ignore Horizontal parameters
HTML: "<IMG "     IgnoreTo'>' ;          \ ignore IMAGEs
HTML: "<INPUT "   IgnoreTo'>' ;          \ ignore Input fields
HTML: "<ISINDEX"  IgnoreTo'>' ;          \ ignore searchable index
HTML: "<LI "      IgnoreTo'>' ;          \ ignore List bullet
HTML: "<LINK "    IgnoreTo'>' ;          \ ignore Relationship
HTML: "<NOSCRIPT" IgnoreTo'>' ;          \ ignore NoScript
HTML: "<MAP "     IgnoreTo'>' ;          \ ignore MAPs
HTML: "<MENU "    IgnoreTo'>' ;          \ ignore Menu compact
HTML: "<META "    IgnoreTo'>' ;          \ ignore Client Pull
HTML: "<MULTICOL" IgnoreTo'>' ;          \ ignore MULTICOLs
HTML: "<OBJECT"   IgnoreTo'>' ;          \ ignore Object
HTML: "<OL "      IgnoreTo'>' ;          \ ignore Ordered list
HTML: "<OPTION "  IgnoreTo'>' ;          \ ignore Options
HTML: "<P "       IgnoreTo'>' ;          \ ignore Alignment
HTML: "<Q "       IgnoreTo'>' ;          \ ignore question
HTML: "<SCRIPT"   IgnoreTo'>' ;          \ ignore Script
HTML: "<SELECT "  IgnoreTo'>' ;          \ ignore Selection list
HTML: "<SPACER"   IgnoreTo'>' ;          \ ignore SPACERs
HTML: "<TABLE "   IgnoreTo'>' ;          \ ignore TABLEs
HTML: "<TEXTAREA " IgnoreTo'>' ;         \ ignore Textarea
HTML: "<THEAD"    IgnoreTo'>' ;          \ ignore thead
HTML: "<TD "      IgnoreTo'>' ;          \ ignore TABLEs
HTML: "<TH "      IgnoreTo'>' ;          \ ignore TABLEs
HTML: "<TR "      IgnoreTo'>' ;          \ ignore TABLEs
HTML: "<UL "      IgnoreTo'>' ;          \ ignore unordered list
HTML: "<!"        IgnoreTo'>' ;          \ comments are not displayed

: "ProcessHTML" { adr len \ html$ -- a2 n2 }    \ process one HTML statement
        LMAXSTRING LocalAlloc: html$
        adr len html$ LPLACE            \ save original string away
        html$ LCOUNT
        2dup '>' scan nip - upper       \ convert partial to uppercase
        html$ LCOUNT
        html-chain do-chain             \ go look for an html command
        over html$ CELL+ =              \ if we didn't process any,
                                        \ at the end of the chain
        IF      2drop
                adr 1 "PutTextOut       \ then output 1 original character
                1                       \ one character processed
        ELSE    nip len swap -          \ else calc the processed characters
        THEN    adr len rot 0MAX /string     \ remove them from original string
        ;

-1 value ignoreNextLine

: /split { str len part -- remainder len1 prefix len2 }
        str len part /string            \ adr len of remainder of string
        str len part min 0max ;         \ adr len of prefix of string

: "/TTO  ( a1 n1 n2 -- a2 n3)   \ show part n2 of string a1,n1, return remainder
        /split                  \ split string a1 n1 into two parts
        browse?
        IF      ignoreNextLine displayingLine =
                \ if we are on the next display line
                IF      -1 to ignoreNextLine
                        2drop
                        EXIT
                THEN
                BEGIN   2dup s" <" search
                WHILE   2swap 2over nip -
                        "&PutTextOut            \ display leading text
                        "ProcessHTML"
                REPEAT  2drop
                linking?
                IF      2drop
                        FALSE to ignoring?
                        displayingLine 1+ #Line"
                        BEGIN   2dup s" <" search
                        WHILE   2swap 2over nip -
                                "&PutTextOut            \ display leading text
                                "ProcessHTML"
                                displayingLine 1+ to ignoreNextLine
                        REPEAT   2drop
                THEN
                "&PutTextOut
        ELSE    "PutTextOut
        THEN    ;               \ return the remainder of string as a2 n3

: _+bg          ( -- )
                highBG   to textBG textBG   SetBkColor: dc
                highFG   to textFG textFG SetTextColor: dc ;

defer +bg       ' _+bg is +bg

: -bg           ( -- )
        normalBG to textBG textBG   SetBkColor: dc
        normalFG to textFG textFG SetTextColor: dc ;

\ rls January 2nd, 2001 - 16:09
: "/TTO+    ( a1 n1 n2 -- a2 n3)
        \ show part n2 of string a1,n1, returning remainder
        2dup >=
        IF      "/TTO
        ELSE
                over - >r dup "/TTO
                mspcs r> dup "/TTO
                2drop
        THEN ;

: showHighlightLine { theline \ stcol edcol -- }
      theline #line" col-cur /string          \ portion of text on screen
      dup hcst col-cur - 0max min to stcol    \ clip start to length of line
      dup hced col-cur - 0max min to edcol    \ clip end   to length of line
      theline hled <>                         \ extra if not last line
      hlst    hled <> and                     \ and if multiple lines
      theline hlst hled between and           \ and if highlighting this line
      IF      1 +to edcol
              1+
      THEN
      RectHigh
      IF
              theline hlst hled between
              IF
                      theline #line" col-cur /string
                      hcst col-cur - 0max to stcol
                      hced col-cur - 0max to edcol
                      stcol "/TTO+                    \ show unhighlighted part
                      +bg edcol stcol - "/TTO+        \ show highlighted part
                      -bg dup "/TTO                   \ show remainder
              ELSE
                      -bg                     \ any other line, just display it
                      dup "/TTO               \ other lines are not highlighted
              THEN
              2drop EXIT
      THEN
      theline hlst =
      IF      stcol "/TTO                     \ show unhighlighted part of line
              theline hled =
              IF      +bg
                      edcol stcol - "/TTO     \ show highlighted portion
                      -bg dup "/TTO           \ show remainder
              ELSE    +bg dup "/TTO           \ all rest is highlighted
                      -bg
              THEN
      ELSE    theline hlst >
              theline hled < and              \ middle lines, then highlight all
              IF      +bg
                      dup "/TTO               \ just show it all highlighted
                      -bg
              ELSE    theline hled =          \ last line, highlight start
                      IF      +bg
                              edcol "/TTO     \ unhighlighted up to end column
                              -bg
                              dup "/TTO       \ remainder is shown highlighted
                      ELSE    -bg             \ any other line, just display it
                              dup "/TTO       \ other lines are not highlighted
                      THEN
              THEN
      THEN    2drop ;                         \ discard any remaining text

:M StartPos:    ( -- x y )
        0 StartSize: Win-EdToolbar nip 1+
        ;M

:M SetTopOf:    ( n1 -- )
        to TopOfWindow
        ;M

:M WindowStyle: ( -- style )            \ return the window style
        WindowStyle: super
        [ WS_VSCROLL WS_HSCROLL or WS_OVERLAPPED or ] literal or
        ;M  \ add horizontal and vertical scroll bars

:M ExWindowStyle: ( -- extended_style )
        ExWindowStyle: super
        ;M

: window-lines  ( -- n1 )
        Height: self CharHeight: self / ;

: margin-check  ( -- )
\        s" 9" GetTextExtent: dc drop            \ width of a '9' char
\        5 3 */ 14 max to window-lmargin ;
        s" 9,999" GetTextExtent: dc drop            \ width of a '9' char
        to window-lmargin ;

:M all-lines:   ( -- )
        update-flags MAXSTRING 1 fill
        ;M

:M 1-line-flag: ( n1 -- )       \ n1 = number in file to update if on screen
        line#>indx              \ convert to screen relative
        1 swap 0max MAXSTRING 1- min update-flags + c!
        ;M

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 15    Start RePaint that works with Colons-Only  July 6th, 2002 RDA JAP
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

:M RePaint:     ( -- )
    alreadyPainting 0=

( Start of the refresh the screen routine )
    IF  TRUE to alreadyPainting
        ( Keep painting untill paintAgain is zero )
        BEGIN
            FALSE to paintAgain
            SaveDC: dc                      \ save device context
            entry# >r                       \ save the current entry#
            Stack# to entry#
            endface
            text-ptr
            ( Draw the left border )
            IF  margin-check
                        \ draw left border
                0 0 window-lmargin 2 -
                Height: self
                ( Get the margin color and fill the left margin )
                overstrike @ if marginColor else BMarginColor then
                FillArea: dc
                      \ vertical line beside left border
                Gray LineColor: dc
                3 0
                ( Draw a blended white line to left of blue border )
                DO  window-Lmargin 3 - i + 0 MoveTo: dc
                    window-Lmargin 3 - i +
                    Height: self
                    LineTo: dc
                    White LineColor: dc
                LOOP  -bg
                window-lines 1+ 0
                ( Pixel atributes, back ground color, line number, rule line )
                DO
                    update-flags i + c@
                    ( Pixel atributes, background color, line # etc )
                    IF  0 update-flags i + c!
                        window-lmargin       to xpixel  \ x
                        CharHeight: self i * to ypixel  \ y
                        xpixel ypixel
                        s" 0" GetTextExtent: dc nip
                        >r Width: EditorWindow
                        xpixel + r> ypixel + 1+
                        i indx>line# file-lines 1- >
                            \ set the trail color
                        ( Select background color or trail background? )
                        IF  LTGRAY                        \ trail ???jap
                        ELSE
                            line-cur i + hlst hled between
                            highlighting? and
                            IF     selectBG
                            ELSE    trailBG
                            THEN
                        THEN
                        ( End of select background color )
                         FillArea: dc
                        i indx>line# to displayingLine
                        highlighting?
                        ( Display the line number at bottom of the screen )
                        IF  displayingLine showHighlightLine
                        ELSE
                            displayingLine #line"
                             col-cur /string
                             dup "/TTO 2drop
                        THEN
                         ruling?
                        ( Draw a rule if needed )
                        IF  BLACK               LineColor: dc
                            HRSize 1 max 12 min 0
                            ( Loop thru and do some thing )
                            DO      window-Lmargin ypixel I +
                                    MoveTo: dc
                                    Width ypixel I + LineTo: dc
                            LOOP
                            FALSE to ruling?
                        THEN
                    THEN
                LOOP
                browse? 0=
                ( Prnter settings )
                IF  right-edge 0=
                    ( Declare printer settings )
                    IF  page-lines?
                        \ show page lines
                        ( If line length is not zero then setup elements )
                        IF lend-len 0=
                             ( Set printer #columns, colors, char widths, hights, margins )
                             IF    binaryColor  LineColor: dc
                                   PRINTER-COLS
                             ELSE  linesColor  LineColor: dc
                                   PRINTER-COLS
                             THEN
                             col-cur - 0max dup>r
                             CharWidth: self * window-lmargin + 0
                             MoveTo: dc
                             r> CharWidth: self * window-lmargin +
                             Height LineTo: dc
                        THEN
                    ELSE ( Something about a red line )
                        LTRED LineColor: dc
                        right-edge col-cur - 0max
                        CharWidth: self * window-lmargin + 0
                        MoveTo: dc
                        right-edge col-cur - 0max
                        CharWidth: self * window-lmargin + Height
                        LineTo: dc
                    THEN
                THEN
                window-lmargin 0>
                IF  linesColor   LineColor: dc   \ display page breaks
                    marginColor SetBkColor: dc
                    lend-len 0=
                    IF      binaryColor   LineColor: dc
                            BLOCK-LINES to PRINTER-ROWS
                    THEN
                    0          \ show line numbers
                    BEGIN dup window-lines <
                    WHILE ( MIDDLE OF LOOP )
                       \ -- screenline#
                        dup>r line-cur +
                        ( Output text in the right character height )
                          overstrike @ if marginColor else BMarginColor then
                          SetBkColor: dc
                          0 <# #s #> 2dup GetTextExtent: dc drop
                          window-Lmargin 5 - swap - 1 max
                          r@     CharHeight: self *
                          2swap TextOut: dc
                          r> 1+
                    REPEAT  drop
                THEN
                textBG SetBkColor: dc
            THEN
            using98/NT? 0=
            \ only support variable sized scroll bars in Windows98 and WindowsNT
                    \ *** See note below ***
            file-lines 32767 > OR   \ if we have a big file, revert to
                                    \ non-resizable scroll buttons
            ( Position the vertical & horizontal scroll bars & buttons )
            IF
                \ set the vertical scroll bar limits
                FALSE file-lines window-lines - 0max 32767 min 0 SB_VERT
                GetHandle: self Call SetScrollRange drop
                \ position the vertical button in the scroll bar
                TRUE line-cur file-lines 32767 min file-lines 1 -
                1 max */ 32767 min SB_VERT
                GetHandle: self Call SetScrollPos drop
                \ set the horizontal scroll bar limits
                FALSE max-cols screen-cols 3 - - 0max col-cur max
                32767 min 0 SB_HORZ
                GetHandle: self Call SetScrollRange drop
                \ position the horizontal button in the scroll bar
                TRUE col-cur 32767 min SB_HORZ
                GetHandle: self Call SetScrollPos drop
            ELSE  \ Set the vertical scroll bar limits, position and page size )
                window-lines to nPage
                line-cur to nPos
                0 to nMin
                file-lines to nMax
                SIF_ALL to fMask
                TRUE LPWinScrollInfo SB_VERT
                GetHandle: self Call SetScrollInfo drop
                screen-cols to nPage
                col-cur to nPos
                0 to nMin
                max-cols to nMax
                SIF_ALL to fMask
                TRUE LPWinScrollInfo SB_HORZ
                GetHandle: self Call SetScrollInfo drop
            THEN
            \ restore the current entry#
            r> to entry#
            \ restore the original DC
            RestoreDC: dc
            paintAgain 0=
        UNTIL
        FALSE to alreadyPainting
    ELSE  ( refresh the screen again or not )
        TRUE to paintAgain
    THEN
 ;M


((      *** Note referenced above ***


February 24th, 2000 - 11:06 tjz
Can't even really get it to work in WindowsNT, because SB_THUMBTRACK doesn't
work for live scroll tracking

Here is an excerpt from the Win32SDK help entry for GetScrollInfo, which is the
function you use to get the scroll position of the scroll bars;

"The limitation on this technique applies to real-time scrolling of a window’s
contents.  An application implements real-time scrolling by processing the
WM_HSCROLL or WM_VSCROLL messages that carry the SB_THUMBTRACK notification
value, thereby tracking the position of the scroll box (thumb) as the user moves
it. Unfortunately, there is no function to retrieve the 32-bit position
scroll-box position as the user moves the scroll box.  Because GetScrollInfo
provides only the static position, an application can obtain only 32-bit
position data before or after a scroll operation."

So, all we can do, is use variable size scroll bars when the file contains less
than 32767 lines.  Oh, well.
))

:M On_Paint:    ( -- )          \ screen redraw method
        bitImage?
        IF      SRCCOPY 0 0 imageDC GetHandle: [ ] GetSize: self 0 0 BitBlt: dc
        ELSE    all-lines: self
                RePaint: self
        THEN
        ;M

:M GetHandleOfDC: ( -- a1 )
        GetHandle: dc
        ;M

:M On_Init:     ( -- )
        On_Init: super
        #fonts 0
        DO      font-list i cells+ @ >r
                char-width            Width: [ r@ ]
                char-height          Height: [ r> ]
        LOOP                         Create: vFont
        GetWindowDC: self PutHandle: screenDC
        SaveDC: screenDC                        \ save device context
        Handle: vFont SetFont: screenDC         \ set the font to be used
        s" #" ( A CHARACTER ) GetTextExtent: screenDC
        to the-height to the-width
        RestoreDC: screenDC                     \ restore the device context
        GetHandle: screenDC ReleaseDC: self
        ;M

:M On_Done:     ( -- )
                #fonts 0
                DO      font-list i cells+ @ >r
                        Delete: [ r> ]
                LOOP
                On_Done: super
                ;M

:M WM_CLOSE     ( -- )
                FALSE to cursor-on?
                WM_CLOSE WM: Super
                ;M

:M RefreshOn:   ( -- )
                TRUE to refreshing?
                ;M

:M RefreshOff:  ( -- )
                FALSE to refreshing?
                ;M

0 value prev-depth

:M Refresh:     ( -- )          \ refresh the windows contents
                refreshing?
                IF      bitImage?
                        IF      Paint: self
                        ELSE    entry# >r
                                Stack# to entry#
                                get-dc
                                RePaint: self
                                release-dc
                                r> to entry#
                        THEN
                THEN
                ;M

:M RefreshAll:  ( -- )
                Paint: self
                ;M

:M VPosition:   ( n1 -- )       \ move to line n1 in file
                line-cur >r
                0max file-lines 1 - 0max min to line-cur
                setcolontbl r> line-cur <>
                IF      all-lines: self
                THEN
                ;M

:M HPosition:   ( n1 -- )       \ move to column n1
                col-cur >r
                0max max-cols screen-cols 4 - - 0max min to col-cur
                r> col-cur <>
                IF      all-lines: self
                THEN
                ;M

:M Home:        ( -- )          \ goto the top of the current file
                0 VPosition: self
                0 HPosition: self
                0 to cursor-line
                0 to cursor-col
                highlight-cursor
                RefreshAll: self
                ;M

:M End:         ( -- )          \ goto the end of the current file
                file-lines window-lines - VPosition: self
                file-lines 1- to cursor-line
                0             HPosition: self
                0             to cursor-col
                highlight-cursor
                ;M

:M VScroll:     ( n1 -- )       \ scroll up or down n1 lines in file
                 +line-cur
                ;M

:M VPage:       ( n1 -- )       \ scroll up or down n1 pages in file
                window-lines 3 - 0max * VScroll: self
                ;M

:M HScroll:     ( n1 -- )       \ scroll horizontally n1 characters
                col-cur + HPosition: self
                ;M

:M HPage:       ( n1 -- )       \ scroll horizontally by n1 page
                screen-cols 4 - 0max * HScroll: self
                ;M

:M DefaultCursor: ( -- cursor-id )
                IDC_IBEAM
                ;M

: cur-column    ( -- n1 )  \ calculate cursor position from actual position of
                           \ the mouse-cursor
                mousex window-lmargin - 0max CharWidth: self /mod
                swap CharWidth: self 2 - > IF 1+ THEN
                col-cur +  ;

create info$ MAXSTRING allot

0 value lremain

:M WM_SETCURSOR { hndl msg wparam lparam \ oladr ladr llen lstrt lend lcol theLine linkCnt -- res }
    EraseRect: ClientRect                \ init to zeros
    Addrof: ClientRect GetClientRect: self
    hWnd get-mouse-xy Top: ClientRect Bottom: ClientRect between
    over Left: ClientRect Right: ClientRect between and
    IF  Left: ClientRect dup window-lmargin 2 - + between
        IF  uparrow-cursor
        ELSE
            FALSE to html-link?
            FALSE to on-text?
            browse?
            IF  cur-column to lcol
                0 to lend
                mousey CharHeight: self / line-cur + file-lines
                1- min to theLine
                theLine #line"  to llen to ladr
                ladr to oladr
                0 to linkCnt              \ #found links
                BEGIN
                    html-link? 0=         \ haven't found a link
                    llen    7 >= and      \ and we have enough text remaining
                    linkCnt 3 <  and      \ ignore more than 3 links on a line
                    IF  ladr llen s" <A HREF"
                        caps-search
                    ELSE
                        0 0 FALSE
                    THEN
                WHILE
                    1 +to linkCnt           \ found one link
                    llen over - to lstrt    \ start of "<A"
                    2dup
                    7 /string               \ remove "<A HREF"
                    bl skip                 \ skip blanks and equal
                    '=' skip
                    bl skip
                    '"' skip                \ and leading '"'
                    '#' skip                \ and leading '#'
                    2dup '>' scan nip -     \ scan to ending '>'
                    2dup + 1- c@ '"' =
                    IF   1- THEN            \ remove trailing '"'
                    s"   Link to: "
                    SetSimpleStatus: EditorWindow
                    s" >"     search drop   \ find ">" and discard flag
                    1 /string 2dup          \ remove the '>' char from text
                    s" </A>" caps-search        \ skip to </A>
                    IF  dup 4 - 0max to lremain \ remove </A> from text
                        nip - nip 1- 0max       \ calc length till </A>
                        lstrt + to lend
                        lcol lstrt lend between dup
                        IF      lstrt 1+ to html-link?
                        THEN
                    ELSE
                        theLine 1+ #line" 2dup
                        s" </A>" caps-search drop   \ skip to </A>
                        dup 4 - 0max to lremain     \ remove </A> from text
                        nip - nip 1- 0max           \ calc length till </A>
                        lstrt + to lend
                        lcol lstrt lend between dup
                        IF      lstrt 1+ to html-link?
                        THEN
                    THEN
                    lcol lend - 0max to lcol
                    ladr llen llen lremain - 0MAX
                    /string to llen to ladr
                REPEAT
                2drop
                html-link? 0=
                IF  lcol llen <
                    IF      oladr lcol + c@ bl <>    \ if NOT a blank
                            dup to on-text?
                    ELSE    FALSE
                    THEN
                    SetMultiStatus: EditorWindow
                ELSE
                    TRUE
                THEN
                IF
                     harrow-cursor
                ELSE
                    arrow-cursor
                THEN
            ELSE
                ibeam-cursor
                SetMultiStatus: EditorWindow
            THEN
        THEN
        1
    ELSE
        drop
        hndl msg wparam lparam DefWindowProc: [ self ]
    THEN
    ;M

:M RefreshCursor: ( -- )
        have-focus?
        IF      cursor-col  col-cur  - CharWidth: self * window-lmargin +
                cursor-line line#>indx dup 0<
                IF      drop -4
                THEN    CharHeight: self * MoveCursor: self
        THEN
        ;M

:M On_SetFocus: ( h m w l -- )
        On_SetFocus: super
        DocWindow >r
        entry# >r
        self to DocWindow
        Stack# to entry#        \ select our file in file stack
        cursor-col   col-cur -  CharWidth: self * window-lmargin +
        cursor-line line#>indx CharHeight: self *
        2 CharHeight: self 1- MakeCursor: self
        refresh: self
        r> to entry#
        r> to DocWindow
        ;M

:M On_KillFocus: ( h m w l -- )
        DestroyCursor: self
        On_KillFocus: super
        refresh: self
        ;M

[UNDEFINED] WM_MOUSEWHEEL  [if]
\ Wheelmouse support added
\ March 9th, 2003 - 11:49  dbu
0x020A constant WM_MOUSEWHEEL \ because it's missing in the Windows Constants
[then]

[UNDEFINED] SWORD-SPLIT [if]
CODE SWORD-SPLIT ( s1 -- low high ) \ split the signed 32bit s1 into its high
        movsx eax, bx               \ and low 16bit quantities.
        push eax                    \ by Alex McDonald
        shr ebx, # 16
        movsx ebx, bx
        next c;

: S-HIWORD SWORD-SPLIT NIP ;
: S-LOWORD SWORD-SPLIT DROP ;
[then]

:M WM_MOUSEWHEEL   ( h m w l -- res )
        SetFocus: self
        self to DocWindow
        Stack# to entry#

        \ get the WHEEL_DELTA (hiword of wParam)
        \ A positive value indicates that the wheel was rotated forward, away
        \ from the user; a negative value indicates that the wheel was rotated
        \ backward, toward the user.
        OVER S-HIWORD
        0<
        IF
                \ is the shift-button down?
                OVER S-LOWORD MK_SHIFT AND
                IF    1   VPage: self \ scroll one page up
                ELSE  3 VScroll: self \ scroll three lines up
                THEN
        ELSE
                \ is the shift-button down?
                OVER S-LOWORD MK_SHIFT AND
                IF   -1   VPage: self \ scroll one page down
                ELSE -3 VScroll: self \ scroll three lines down
                THEN
        THEN

        RefreshAll: self
        RefreshCursor: self
        0 ;M

: cur2top: ( -- )  \ scroll current line to top of window
  cursor-line to line-cur refresh: self ;

0 value prevLine

:M WM_VSCROLL   ( h m w l -- res )
        SetFocus: self
        self to DocWindow
        Stack# to entry#
        swap word-split >r
        CASE
                SB_BOTTOM        OF          End: self          ENDOF
                SB_TOP           OF         Home: self          ENDOF
                SB_LINEDOWN      OF    1 VScroll: self          ENDOF
                SB_LINEUP        OF   -1 VScroll: self          ENDOF
                SB_PAGEDOWN      OF      cur2top: self          ENDOF
                SB_PAGEUP        OF      cur2top: self          ENDOF
                SB_THUMBTRACK
                OF    ?control
                      IF      r@ prevLine < 2* 1+ VScroll: self
                      ELSE    file-lines 32767 >
                              IF     file-lines r@ 32767 */ VPosition: self
                              ELSE              r@          VPosition: self
                              THEN
                      THEN
                ENDOF
        ENDCASE
        r> to prevLine
        RefreshAll: self
        RefreshCursor: self
        0 ;M

:M WM_HSCROLL   ( h m w l -- res )
                SetFocus: self
                self to DocWindow
                Stack# to entry#
                swap word-split >r
                CASE
                        SB_BOTTOM        OF          End: self   ENDOF
                        SB_TOP           OF         Home: self   ENDOF
                        SB_LINELEFT      OF   -1 HScroll: self   ENDOF
                        SB_LINERIGHT     OF    1 HScroll: self   ENDOF
                        SB_PAGELEFT      OF   -1   HPage: self   ENDOF
                        SB_PAGERIGHT     OF    1   HPage: self   ENDOF
                        SB_THUMBPOSITION OF r@ HPosition: self   ENDOF
                        SB_THUMBTRACK    OF r@ HPosition: self   ENDOF
                ENDCASE r>drop
                RefreshAll: self
                RefreshCursor: self
                0 ;M

\ Don't allow window to be moved up into toolbar
:M WM_WINDOWPOSCHANGING ( h m w l -- res )
                dup 3 cells+ dup @ TopOfWindow max swap !
                DefWindowProc: [ self ]
                ;M
;Class

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\       End of EditWindowClass Methods
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

EditWindowClass EDIT-WINDOW             \ this is an instance of a class
edit-window    to EditWindow
edit-window    to DocWindow
