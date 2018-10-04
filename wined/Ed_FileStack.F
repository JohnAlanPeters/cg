\ $Id: Ed_FileStack.F,v 1.1 2011/03/19 23:26:04 rdack Exp $
\
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 3      Multiple File Support Data Structure 
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

128           constant entry-max       \ maximum number of files in file stack
entry-max 2 + constant entry-console   \ the console is always in the same place
                                       \ always two above the
entry-max 3 + constant entry-max-items \ last, defines the stack size in items

0             value    entry#          \ the internal entry in the file stack
0             value    entry-#bytes    \ adjusted to the size of a stack entry
0             Pointer  entry-buffer    \ the pointer to the start of file stack

: entry-size    ( -- n1 )              \ total size of all file stack entries
                entry-max-items entry-#bytes * ;

cfa-code $entry@
                push    ebx
                mov     ecx, 4 [eax]                    \ @
                mov     eax, &of entry#                 \ entry#
                mov     ebx, &of entry-#bytes           \ entry-#bytes
                push    edx                             \ save UP
                mul     ebx                             \ *
                mov     ebx, eax                        \
                add     ebx, ecx                        \ +
                add     ebx, &of entry-buffer           \ entry-buffer +
                pop     edx                             \ restore UP
                next    c;


cfa-code entry@
                push    ebx
                mov     ecx, 4 [eax]                    \ @
                mov     eax, &of entry#                 \ entry#
                mov     ebx, &of entry-#bytes           \ entry-#bytes
                push    edx                             \ save UP
                mul     ebx                             \ *
                mov     ebx, eax                        \
                add     ebx, ecx                        \ +
                add     ebx, &of entry-buffer           \ entry-buffer +
                pop     edx                             \ restore UP
                mov     ebx, 0 [ebx]                    \ @
                next    c;
                

cfa-code entry!
                push    ebx
                mov     ecx, -4 [eax]                   \ 2 cells - @
                mov     eax, &of entry#                 \ entry#
                mov     ebx, &of entry-#bytes           \ entry-#bytes
                push    edx                             \ save UP
                mul     ebx                             \ *
                mov     ebx, eax                        \
                add     ebx, ecx                        \ +
                add     ebx, &of entry-buffer           \ entry-buffer +
                pop     edx                             \ restore UP
                pop     eax
                mov     0 [ebx], eax                    \ !
                pop     ebx
                next    c;


cfa-code entry+!
                push    ebx
                mov     ecx, -8 [eax]                   \ 3 cells - @
                mov     eax, &of entry#                 \ entry#
                mov     ebx, &of entry-#bytes           \ entry-#bytes
                push    edx                             \ save UP
                mul     ebx                             \ *
                mov     ebx, eax                        \
                add     ebx, ecx                        \ +
                add     ebx, &of entry-buffer           \ entry-buffer +
                pop     edx                             \ restore UP
                pop     eax
                add     0 [ebx], eax                    \ +!
                pop     ebx
                next    c;
                

variable entry-init-link
         entry-init-link off

: entry-init+   ( n1 -- )
                entry-init-link link,
                entry-#bytes , , ;

: entry+        ( size -- offset )
                entry-#bytes
                swap +to entry-#bytes ;

: entry         ( -<name>- )           \ un-initialized CELL entry
                header  entry@  , CELL entry+ , entry! , entry+! ,
                entry-size Sizeof!> entry-buffer ;
                \ a self fetching value you change with TO     jap

: #entry        ( n1 -<name>- )        \ initialized CELL entry
                entry-init+
                header  entry@  , CELL entry+ , entry! , entry+! ,
                entry-size Sizeof!> entry-buffer ;

: $entry        ( -<name>- )           \ string entry, MAXSTRING bytes long
                header  $entry@ , MAXSTRING entry+ , -1 , -1 ,
                entry-size Sizeof!> entry-buffer  ;

: n$entry       ( n1 -<name>- )        \ string entry, 'n1' bytes long
        header  $entry@ , entry+ , -1 , -1 ,
        entry-size Sizeof!> entry-buffer  ;

Comment:  I believe each open file has its own set of values for
        each 'entry'. we could add to the list if we had some
        value we wanted to be different for each open file. RDA via JP
Comment;

              entry edit-changed?
              entry file-lines     \ the number of lines in the file
              entry num-pages      \ the number of pages        rls - page
              entry browse?        \ are we in browse mode, don't allow changes?
              entry from-web?      \ was this page read from web?

        1000 #entry max-lines      \ initial maximum number of lines
         200 #entry max-pages      \ initial maximum number of pages  rls - page
         512 #entry max-cols       \ maximum width of text currently editing
          84 #entry screen-cols    \ default rows and columns at startup
          66 #entry screen-rows
          14 #entry window-lmargin \ graphics pixels of the window left margin
           0 #entry right-edge     \ default right margin
           0 #entry lend-char      \ value of first line end character
           2 #entry lend-len       \ length of line end sequence 0=binary/block
           0 #entry imageDC        \ image DC for bitmap files
           0 #entry vga-bitmap     \ the bitmap of the image file
           0 #entry bitImage?      \ is this a bitmapped file
              entry line-tbl       \ address of the line pointer table
              entry page-tbl       \ address of page table      rls - page
              entry text-ptr       \ address of text buffer
              entry text-blen      \ total text buffer length
   LMAXSTRING n$entry URL$         \ a place to save the URL

entry-#bytes CONSTANT mirror#      \ number of bytes to mirror

\ These following fields are not mirrored between multiple copies of a file.

                    entry line-cur       \ the current top screen line
                    entry page-cur       \ the current page   rls - page
                    entry  col-cur       \ the current left column

                    entry cursor-col     \ absolute column on current line
                    entry cursor-line    \ absolute line in current file

                    entry hlst           \ highlight line start
                    entry hled           \ highlight line end
                    entry hcst           \ highlight column start
                    entry hced           \ highlight column end
                    entry mlst           \ what's this ?!?
                    entry mcst           \ what's this ?!?

                    \ for saving the actual state of highlight
                    \ see save-highlight and restore-highlight
                    \ April 27th, 2003 - 9:47 dbu
                    entry hlst-save      \ highlight line start
                    entry hled-save      \ highlight line end
                    entry hcst-save      \ highlight column start
                    entry hced-save      \ highlight column end

                   $entry cur-filename
       LMAXSTRING n$entry cur-buf       \ 1k line buffer

: entries-init  ( -- )                  \ first NULL out the entire buffer
                entry-buffer entry-size erase
                                        \ then initialize any non-0 entries
                entry-init-link
                BEGIN   @ ?dup
                WHILE   dup cell+ @ over 2 cells+ @ swap
                        entry-max-items 0
                        DO      2dup i entry-#bytes * entry-buffer + + !
                        LOOP    2drop
                REPEAT  ;

entries-init    \ initialize the buffer now so we can use it

initialization-chain chain-add entries-init

FALSE value editAsBinary?       \ should we edit this file as a binary file?

  16 CONSTANT BLOCKLINE-SIZE    \ the length of each line of a binary/block file
  16 CONSTANT BLOCK-LINES       \ lines in a block
1024 CONSTANT BLOCK-SIZE        \ a Forth block size

