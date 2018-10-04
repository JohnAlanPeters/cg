\ $Id: Ed_Colorize.F,v 1.1 2011/03/19 23:26:04 rdack Exp $
\
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 2     Brad Eckert's colorization support                              {BE}
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

create  keycolors
        black ,    red ,       green ,    yellow ,
        blue ,     magenta ,   cyan ,     ltgray ,
        dkgray ,   ltred ,     ltgreen ,  yellow ,
        ltblue ,   ltmagenta , ltcyan ,   gray ,
        brown ,    ltgray ,    dkmagenta ,  ( 0-17 jap )

: FileName ( addr n <-name-> -- ) \ Create a word that holds a filename
           ( -- addr )
        create here MAX-PATH allot place
        does> ;

s" WINEDCOLORIZE.F" Prepend<home>\ FileName keyfileName$

: keyfileName   ( -- a n )
        keyfileName$ count ;

create tempkey MAXSTRING chars allot    \ used by iskey?
1024    value maxkeys
  16    value maxkeylen      \ keys are really variable length, might be typical
   0    value keyhere
   0    value keyfile        \ file handle for color file
   0    value ASMoptions

variable OVERSTRIKE  ( insert )     \ toggle with insert key

maxkeys 1+ cells    Pointer keywords          \ sorted list of links to keywords
maxkeys maxkeylen * Pointer keyword-strings   \ space for the strings

: 'keyword      ( n -- addr )   \ address a keyword link
        1+ cells keywords + ;

: keyc,         ( c -- )        \ lay a character into the keyword-strings area
        keyhere c! [ 1 chars ] literal +to keyhere ;

: kparse        ( a n char -- a' n' a len ) \ parse out next XXXX___
        -rot 2dup 2>r rot dup>r scan r> skip
        2r> 2 pick - ;

: ParseNum      ( a n -- a' n' number )
        \ parse number from a string, return 0 if not a number
        bl kparse -trailing number? nip 0<> and ;


\ 2a \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ Opens the keyword list and loads it from a text file.  Each line contains:
\ COLOR ACTION NAME where color=0..255, action=0..255, name is the string name
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
: open-keywords ( a n -- ) \ load keywords file
    keywords off
    0 to ASMoptions
    keyword-strings to keyhere
    r/o open-file 0=
    IF  to keyfile
        BEGIN
            pad 80 keyfile read-line            \ read a line from color file
            IF      2drop EXIT
            THEN
            keywords @ maxkeys u< AND           \ maxxed out link table
            keyhere keywords -                  \ length of keyword strings
            80 +                                \ could add 80 more characters
            maxkeys maxkeylen * u< AND          \ less than allowed length?
        WHILE
            pad swap                             ( addr len )
            ParseNum dup  \ parse number from a string, return 0 if not a number
            IF  CASE
                    1000 OF  2drop 1 to ASMoptions   \ enable ASM options
                    ENDOF
                    1001 OF  2drop 2 to ASMoptions
                    ENDOF
                    keyhere >r  keyc,  ParseNum keyc,
                    bl kparse 2nip -trailing
                    dup keyc,                       \ save length of string
                    bounds       \ calculate loop bounds from adr,len
                    ?DO     i c@ keyc,
                    LOOP         \ save number and string
                    r> keywords @ dup>r 'keyword !  \ place link at end of table
                    r@           \ get a copy of the top of the return stack
                    BEGIN
                        ?dup                      \ bubble up so table is sorted
                    WHILE
                        dup 1- 'keyword           \ cnt idx
                        dup 2@ >r 2 chars + count r>
                        2 chars + count  compare 0<
                        IF  dup>r 2@ swap r> 2!   \ swap indicies
                        ELSE
                            drop                  \ finishes with sort
                            drop 1                \ bubbling is finished
                        THEN
                        1-
                    REPEAT  r> 1+ keywords !
                0 ENDCASE
            ELSE 3drop                            \ 1st wasn't a number
            THEN
        REPEAT  drop
        keyfile close-file drop
    ELSE    drop
    THEN    ;

: close-keywords ( -- ) \ Releases memory used by keyword colorization
        keyword-strings release
        keywords        release ;

: default-keywords ( -- )
        keyfileName open-keywords ;

initialization-chain chain-add default-keywords \ open keyword file upon startup
unload-chain chain-add-before close-keywords    \ make sure memory is released

