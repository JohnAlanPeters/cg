\ $Id
\ Created originally on 89-04-22
\ Open each file in the current directory and execute the word that is
\ vectored into  EXECUTE-IN-FILE In oher words,
\
\ OO-THRU has a defered word called EXECUTE-IN-FILE that lets
\ any task be executed inside of each file in a directory.
\ See the samples below for some examples.
\
\ MONEY         DISK-ABSTRACT   DISK-INDEX   PUNCH-LIST    INCOME
\ EXTRAS        REFERENCES      DISK-EXHIBIT


\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ file info stuff               At RDA's house     2-05-91 AEC
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

Create FINFO 44 allot
Create FTYPE ," ????????.???"

: GET-FIRST-FILE ( -- flag )              \ true=success
   ftype count addr>asciiz                 \ template
   asciiz 0 ( attrb) 0 $4e00 0 get:ds      \ dx cx bx ax es ds
   xfdos nip nip nip 0= ;                  \ cs=fail
: GET-NEXT-FILE ( -- flag )               \ true=success
   finfo 0 0 $4f00 0 get:ds
   xfdos nip nip nip 0= ;
have set-dma not if       : SET-DMA 26 bdos drop ;  then

\ First-file and next-file                                   AEC
: FINFO>OPEN
   finfo 30 + 12 0len          \ file name
 \ addr>asciiz
   FILE>ASCIIZ
   name-open drop ;

\ First-file and next-file                                   AEC
: FIRST-FILE
   finfo set-dma                   \ get file info to mem
   get-first-file                  \ get 1st 1 that matches
   if  finfo>open  then ;          \ open it
: NEXT-FILE   ( -- f )
   close-file                      \ close that other one
   finfo>open                      \ open it
   get-next-file 0= ;              \ check for more
: OPEN-FILES  file @ 0= if first-file then next-file  ;
: TT  r# @ >r  next-file  0 list+  r> r# !  ; \ Title
: TT1 next-file  1 list+ ;         \ Time card
: TT2 next-file  2 list+ ;         \ Parts
: TT3 next-file  3 list+ ;         \ Parts
: TT4 next-file  4 list+ ;         \ Meta
: EOFTT   next-file  EOF list+ ;   \ Statement
\ OO-THRU files  Factored version                   04-04-90 AEC
Defer EXECUTE-IN-FILE
: OO-THRU ( -- )   \ open a set of files and do a defered word
   file @ scr @                        \ save current file
   finfo set-dma                       \ get file info to memory
   get-first-file                      \ get 1st 1 that matches
   if begin finfo>open                 \ file name
    EXECUTE-IN-FILE          \ process
    close-file get-next-file 0=   \ check for more
    until                            \ done
   then scr ! !files ;                 \ restore

: (test)  cr .file ;
' (test)  is execute-in-file

: LOOP-THRU-FILES  oo-thru ;

: LF              oo-thru ; \ short for testing

: OO-FIRST  first-file   ;

: OO-NEXT   next-file  ;

\  These words complete the task when you un-slash them and test them.
\  : (DISK-CATALOGUE)
\     print-the-first-n-lines-of-a-file ;  \ this word is needed

\  : DISK-CATALOGUE
\     ['] (disk-catalogue) is  execute-in-file  loop-files ;

\  : CAT  Disk-Catalogue  ;

\s
Sunday, July 04 2004 - 16:23 offered to comp.lang.forth asking for help
Japeters@pacbell.net  This code is by RDA as requested by me


