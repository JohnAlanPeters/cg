\ $Id: Ed_Clipboard.F,v 1.5 2011/06/23 04:26:01 rdack Exp $
\
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 23    Text Copy Functions
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

\ rls January 5th, 2001 - 10:44
: copy-text     { \ gblhndl gblptr hwidth scnt -- } \ Copy text to clipboard
        bitImage? ?EXIT
        highlighting? 0=                \ nothing is highlighted
        IF      highlight-word          \ try to highlight something
        THEN
        highlighting? 0=                \ if still not highlighting
        IF      beeper EXIT             \ then just beep and leave
        THEN
        wait-cursor             \ release/allocate line pointer table
        GetHandle: EditorWindow call OpenClipboard 0=
        IF      beep EXIT
        THEN
        RectHigh
        IF
                hled file-lines 1- min to hled
                hced hcst - to hwidth
                hwidth 2 + hled hlst - 1+ *          \ size of buffer
                cell+                                \ total length needed
                GMEM_MOVEABLE GMEM_DDESHARE or       \ flags
                call GlobalAlloc to gblhndl          \ allocate a buffer
                gblhndl call GlobalLock              \ lock memory
                to gblptr
                hled 1+ hlst                         \ highlighted lines
                ?DO
                        I #line" hcst /string        \ source to start col
                        dup hwidth <
                        IF                           \ need to append to source
                                dup to scnt          \ save source count
                                gblptr swap move     \ move source to buffer
                                scnt +to gblptr      \ bump destination ptr
                                MSPCS gblptr
                                hwidth scnt - move   \ copy spaces
                                hwidth scnt -
                                +to gblptr           \ bump destination ptr
                        ELSE                         \ we can just copy source
                                drop gblptr hwidth
                                move
                                hwidth +to gblptr    \ bump dest pointer
                        THEN
                        CRLF$ count gblptr swap move \ append a cr+lf
                        2 +to gblptr
                LOOP
                RectTerm gblptr !
                4 +to gblptr
        ELSE
                hlst #line" drop hcst +             \ start of data
                hled file-lines <
                IF      hled #line" hced min +      \ end of highlighted data
                ELSE    file-lines 1- #line" +      \ or end of file
                THEN    over -                      \ -- start len
                dup cell+                           \ total length needed
                GMEM_MOVEABLE GMEM_DDESHARE or      \ flags
                call GlobalAlloc to gblhndl         \ allocate a buffer
                                                    \ lock memory
                gblhndl call GlobalLock
                to gblptr
                2dup gblptr swap move               \ fill in text
                nip gblptr + off                    \ null terminate
        THEN
        gblhndl call GlobalUnlock drop              \ unlock it, done
        call EmptyClipboard ?win-error              \ clear out the clipboard
                                                    \ pass to windows
        gblhndl CF_TEXT call SetClipboardData ?win-error
        call CloseClipboard ?win-error ;

: clear-text    ( -- )
                bitImage? ?EXIT
                browse? ?EXIT
                delete-highlight ;

: cut-text      ( -- )
                bitImage? ?EXIT
                browse? ?EXIT
                copy-text
                clear-text ;

\ rls  January 8th, 2001 - 0:17
: clean-paste   ( -- )
        call CloseClipboard ?win-error
        update-mirrors
        all-lines: DocWindow
        refresh-screen ;

\ rls  January 8th, 2001 - 0:17
: Split+Move     { adr1 cnt1 adr2 cnt2 --  adr3 cnt3 }
        cnt1 cnt2 >=
        IF      adr1 cnt1 cnt2 /split adr2 swap move
        ELSE    adr1 adr2 cnt1 move
                mspcs adr2 cnt1 + cnt2 cnt1 - move      \ append spaces
                adr1 cnt1 + 0
        THEN ;

\ rls  January 8th, 2001 - 0:17
: RectPaste     { tadr tlen \ iadr idelt rectx recty dcnt -- }
      tadr tlen crlf$ count search 0= \ get end of first insert line
      IF      beep EXIT       THEN
      drop tadr - to rectx            \ save length of first line of insert source
      tlen rectx 2 + /mod to recty    \ save number of lines of insert source
      IF      beep EXIT       THEN    \ Verify insert is rectangular
      rectx cursor-col + 2 +
      recty * to idelt                \ get maximum insert size
      text-length tlen + start-text-size +
      to text-blen
      text-blen text-ptr realloc      \ adj buffer
      s" Failed to adjust the text buffer size"
      ?TerminateBox
      to text-ptr
      text-length set-line-pointers   \ pointer may have moved
      cursor-line #line.addr to iadr  \ place to start insert destination
      iadr dup idelt + end.addr iadr -
      move                            \ open up file for maximum possible insert
      recty 0
      DO
            I cursor-line + idelt #line+"
            dup cursor-col max rectx + to dcnt
            iadr cursor-col Split+Move      \ copy partial line from source
            I rectx 2 + * tadr +
            iadr cursor-col + rectx move    \ Move line from rectangular buffer
            iadr cursor-col + rectx +
            swap move                       \ Move remaining chars from source line
            iadr dcnt -trailing dup>r       \ drop trailing spaces
            + 0x0a0d swap w!                \ add crlf
            r> 2 + +to iadr                 \ update iadr
      LOOP
      cursor-line recty + #line.addr idelt +
      dup iadr over end.addr idelt + swap -
      move                                    \ move source back to fill hole
      iadr - idelt swap - text-length +
      set-line-pointers                       \ Update the line pointers
\      set-longest-line
      ;

\ rls  January 8th, 2001 - 0:17
: paste-text    { \ gblhndl gblptr tlen tadr iadr textlen rectmode -- }
        bitImage? ?EXIT
        browse? ?EXIT
        delete-highlight
        GetHandle: EditorWindow call OpenClipboard 0=
        IF      beep clean-paste        EXIT    THEN
        0 to rectmode
        wait-cursor                        \ release/allocate line pointer table
        rectmode 0=
        IF                                 \ cursor may be to right of line end
                get-cursor-line
                cur-buf @ cursor-col max "LCLIP" cur-buf !      \ extend line
                \ put-cursor-line                                 \ if needed
                cur-buf LCOUNT cursor-line #line!  \ no trim blanks
        THEN
        CF_TEXT call GetClipboardData dup 0=
        IF      beep clean-paste        EXIT    THEN
        to gblhndl
        gblhndl call GlobalLock to gblptr  \ lock memory
        gblptr 4000000 2dup 0 scan swap
        w@ RectTerm = to rectmode
        - to tlen to tadr
        tlen 0=
        IF      beep gblhndl call GlobalUnlock drop
                clean-paste       EXIT
        THEN
        text-length to textlen
        cursor-line #line.len cursor-col - >r           \ save relative col
        file-lines                         >r
        file-lines line-cur -              >r           \ save top line from end
        file-lines cursor-line -           >r           \ save line from end
        rectmode
        IF      tadr tlen RectPaste
        ELSE
           0  \ overstrike @
           if get-cursor-line cursor-col tlen + cur-buf w@ max cur-buf !
              tadr cur-buf lcount drop cursor-col + tlen move
              put-cursor-line
           else
                textlen tlen + start-text-size +
                to text-blen
                text-blen text-ptr realloc              \ adj buffer
                s" Failed to adjust the text buffer size"
                ?TerminateBox
                to text-ptr
                textlen set-line-pointers           \ pointer may have moved
                cursor-line #line.addr cursor-col + to iadr  \ insert point
                iadr                                \ from
                iadr tlen +                         \ to
                end.addr iadr -                     \ remaining text len
                move                                \ make a hole for new text
                tadr iadr tlen move                 \ move in new text
                textlen tlen + set-line-pointers
           then
        THEN
        set-longest-line
        file-lines r> - to cursor-line              \ restore cursor line
        file-lines r> - 0max                        \ lines from bottom of file
        file-lines r> -                             \ lines added to file
         - 0max                                     \ backup that count of lines
        cursor-line screen-rows 3 - - 0max          \ top line at least this
        max to line-cur                             \ use largest of the two
        \ cursor-line #line.len r> - to cursor-col    \ restore cursor col
        highlight-cursor
        file-has-changed                            \ mark as modified
        gblhndl call GlobalUnlock drop              \ unlock it, done
        clean-paste ;

: temp-text     ( -- )          \ Copy text and tell Forth to paste and load
        highlighting? 0=                \ nothing is highlighted,
        IF                              \ then highlight entire line
                cursor-line dup to hlst to hled
                0 to hcst
                cursor-line #line.len to hced
        THEN
        copy-text
         \ todo: open tempfile, paste, save, fload it, exit editor
        ;

