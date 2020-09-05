\ $Id: Ed_FileFuncs.F,v 1.1 2011/03/19 23:26:04 rdack Exp $
\
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 24    Change to PC and Change to Apple
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

: change-to-pc  { \ inform? -- }
    >E
    bitImage? ?EXIT
    lend-len 2 <    \ if unix, apple or BLOCK, then change to PC
    IF  file-lines 4000 >
        IF  s" Too long to convert to PC file in memory,\nuse Save MAC/UNIX file as PC\n\nPress a key.."
            "message beep key drop
            message-off
            EXIT
        THEN
        file-lines 1000 > dup to inform?
        IF  s" Converting to PC file format....\n\nPress ESC to Stop" "message
        THEN
        FALSE to search-aborted?
        0 to cursor-line
        FALSE to editAsBinary?
        text-length set-line-pointers
        file-lines 0
        ?DO i 1+ 15 and 0=
            inform? and
            IF      key?
                    IF      key K_ESC = to search-aborted?
                    THEN
                    search-aborted? ?LEAVE
                    16 +row-cursor
            THEN
            1 to lend-len i #line" "LCLIP"
            2 to lend-len i #line!
            1 to lend-len
        LOOP
        0x0D to lend-char       \ set line terminator info
        2    to lend-len
        message-off
    THEN ;

: change-to-apple  { \ inform? old-len old-char -- }
        >E
        bitImage? ?EXIT
        lend-len  TO old-len
        lend-char TO old-char
        file-lines 1000 > dup to inform?
        IF      s" Converting to Apple file format....\n\nPress ESC to Stop"
                "message
        THEN
        FALSE to search-aborted?
        0 to cursor-line
        FALSE to editAsBinary?
        text-length set-line-pointers
        file-lines 0
        ?DO     i 1+ 15 and 0=
                inform? and
                IF      key?
                        IF      key K_ESC = to search-aborted?
                        THEN
                        search-aborted? ?LEAVE
                        16 +row-cursor
                THEN
                old-char to lend-char                 \ set line terminator info
                old-len  to lend-len i #line" "LCLIP"
                0x0D     to lend-char                 \ set line terminator info
                1        to lend-len i #line!
                old-char to lend-char                 \ set line terminator info
                old-len  to lend-len
        LOOP
        0x0D to lend-char       \ set line terminator info
        1    to lend-len
        message-off ;

: change-to-binary-toggle  { \ inform? old-len old-char -- }
        >E
        bitImage? ?EXIT
        lend-len  TO old-len
        lend-char TO old-char
        file-lines 1000 > dup to inform?
        IF      s" Converting to Binary file format....\n\nPress ESC to Stop"
                "message
        THEN
        FALSE to search-aborted?
        0 to cursor-line
        lend-len 0=
        IF      FALSE to editAsBinary?
        ELSE    TRUE  to editAsBinary?
        THEN
        text-length set-line-pointers
        message-off
        update-mirrors
        all-lines: DocWindow
        refresh-screen ;

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 25    Select a file to edit and print  
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

: open-1-*-file ( -- )
        name-buf count "+open-text ;

: *-open-file   { sadr slen \ SpathSource spath$ smask$ -- }
        MAXSTRING 2 cells+ LocalAlloc: SpathSource
        MAXSTRING LocalAlloc: smask$
        SpathSource 2 cells+ to spath$
        mask-ptr >r
        spath$ MAXSTRING erase
        smask$ MAXSTRING erase
        sadr slen "path-only"  spath$ place
        spath$ c@ 0=
        IF      current-dir$ count spath$ place
        THEN
        sadr slen "to-pathend" smask$ place
        smask$ to mask-ptr
        ['] open-1-*-file is process-1file
        s" Opening Files..." "top-message
        1 seconds
        FALSE to search-aborted?
        spath$ (do-files-process
        message-off
        r> to mask-ptr ;

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 26    Word count usage functions  
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

            20000 constant MAX-WORDS
NAME-MAX-CHARS 1+ constant WORD-BYTES
WORD-BYTES CELL + constant ENTRY-BYTES
0 value words-found

  ENTRY-BYTES MAX-WORDS 10 + * Pointer word-storage

word-storage value append-pointer

: "find-word+   ( a1 n1 -- a1 n1 f1)
                append-pointer word-storage
                ?DO     2dup i CELL+ count caps-compare 0=
                        IF      i INCR
                                FALSE
                                UNLOOP EXIT
                        THEN
   ENTRY-BYTES +LOOP    TRUE ;

: "save-word    ( a1 n1 -- )
                "find-word+        ( a1 n1 -- a1 n1 f1 )
                IF      1 +to words-found
                        words-found MAX-WORDS >=
                        IF      2drop
                                TRUE to search-aborted?
                        THEN
                        append-pointer CELL+ place
                        append-pointer INCR
                        ENTRY-BYTES +TO append-pointer
                ELSE    2drop
                THEN    ;

: count-file    { \ line$ -- }
        search-aborted? ?EXIT
        MAXSTRING LocalAlloc: line$
        1 loadline !                            \ reset line counter to zero
        line$ MAXSTRING erase                   \ clear buffer
        source 2>r              \ save source pointers
        BEGIN                                   \ get a line
                line$ 1+ MAXCOUNTED search-hndl read-line
                rot line$ c!
                                0= and
                search-aborted? 0= and
        WHILE
                line$ count (source) 2! >in off
                BEGIN   bl word dup c@
                        dup '\' =               \ ignore '\' and beyond
                        IF      drop FALSE
                        THEN
                WHILE   count NAME-MAX-CHARS min "save-word
                REPEAT  drop
                search-aborted? ?EXIT
                1 loadline +!
                loadline @ 15 and 0=
                IF      WINPAUSE
                THEN
        REPEAT
        2r> (source) 2! ;        \ restore source pointers

: count-1-file  { \ line$ -- }
                search-aborted? ?EXIT
                name-buf count "+open-text
                count-file
                close-text ;

: "save-counts   { adr len \ fileid -- }
                adr len r/w CREATE-FILE 0=
                IF      to fileid
                        append-pointer word-storage
                        ?DO     i @
                                0 (D.) 6 OVER - spcs swap fileid write-file drop
                                                          fileid write-file drop
                                                spcs 2    fileid write-file drop
                                i CELL+ count             fileid write-line drop
           ENTRY-BYTES +LOOP    fileid CLOSE-FILE drop
                ELSE    drop
                THEN    ;

: word-count-file { sadr slen \ SpathSource spath$ smask$ -- }
                MAXSTRING 2 cells+ LocalAlloc: SpathSource
                MAXSTRING LocalAlloc: smask$
                SpathSource 2 cells+ to spath$
                mask-ptr >r
                spath$ MAXSTRING erase
                smask$ MAXSTRING erase
                sadr slen "path-only"  spath$ place
                spath$ c@ 0=
                IF      current-dir$ count spath$ place
                THEN
                sadr slen "to-pathend" smask$ place
                smask$ to mask-ptr
                ['] count-1-file is process-1file
                1 seconds
                FALSE to search-aborted?
                word-storage TO append-pointer
                0 to words-found
                spath$ (do-files-process
                r> to mask-ptr
                s" WORDCOUNTS.TXT" 2dup 2>r "save-counts
                2r> "+open-text ;

: cwords        ( <file> -- ) \ counts the words in a file and stores the count
                              \ in a file named wordcounts.txt
                s" *.f" word-count-file ;

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 27    Load Bitmap File support   
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

Rectangle bitRect

: "open-bitmap  { openAdr len \ editHndl bitDC hbm hdcMem --  } \ open the bitmap
        \ openAdr is null terminated, len is not used
        GetHandle: EDIT-WINDOW to editHndl
        editHndl call GetDC to bitDC            \ get the edit window's DC

        New> WinDC to imageDC                  \ create the Image DC
        0 call CreateCompatibleDC imageDC PutHandle: [ ]

        SM_CYSCREEN Call GetSystemMetrics  4 -  \ maximum size of screen
        SM_CXSCREEN Call GetSystemMetrics  4 -
        bitDC Call CreateCompatibleBitmap       \ create a compatible bitmap
        to vga-bitmap
                                                \ select it into the Image DC
        vga-bitmap imageDC SelectObject: [ ] drop
        bitDC editHndl call ReleaseDC drop      \ release the edit window's DC

        LR_LOADFROMFILE                         \ open the .BMP file
        LR_CREATEDIBSECTION or
        NULL
        NULL
        IMAGE_BITMAP
        openAdr
        NULL
        Call LoadImage to hbm
        imageDC GetHandle: [ ]
        Call CreateCompatibleDC to hdcMem

        0 0                                     \ initialize the bit rectangle
        SM_CXSCREEN Call GetSystemMetrics 4 -
        SM_CYSCREEN Call GetSystemMetrics 4 -  SetRect: bitRect

        LTGRAY_BRUSH Call GetStockObject
        AddrOf: bitRect imageDC GetHandle: [ ] call FillRect ?win-error

        hbm hdcMem Call SelectObject  drop

        SRCCOPY                                 \
        0 0                                     \ y,x origin
        hdcMem                                  \ from memory dc
        SM_CYSCREEN Call GetSystemMetrics  4 -  \ height of dest rect
        SM_CXSCREEN Call GetSystemMetrics  4 -  \ width of dest rect
        0 0                                     \ y,x dest
        imageDC GetHandle: [ ]                  \ to screen
        Call BitBlt ?win-error
        hdcMem Call DeleteDC ?win-error ;

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 28    Load color configuration File support
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

FileOpenDialog ColorText "Load Color File" "Color Files (*.COL)|*.COL|All Files (*.*)|*.*|"

: load-colors   ( -- )
        GetHandle: EditorWindow Start: ColorText dup c@        \ -- a1 n1
        IF      count open-keywords
        ELSE    drop beep                                       \ {BE}
        THEN    refresh-screen ;

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 29    Open/Save text File support   
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

  FileNewDialog ViewText "Load Forth File" "Forth Files (*.f,*.cfg,*.frm,*.fpj,*.seq)|*.f;*.cfg;*.frm;*.fpj;*.seq|All Files (*.*)|*" 
  FileSaveDialog SaveText "Save Forth File" "Forth Files (*.f)|*.f|All Files (*.*)|*.*|"

: "open-text    { nadr nlen \ textlen open$ create$ path$ org-path-ptr -- }
    GetHandle: DocWindow 0=                 \ if no window, make one
    IF  EditorWindow Start: DocWindow        \ then startup child window
        Refresh: EditorWindow
    THEN
    def-right-edge to right-edge            \ set default right edge
    nadr nlen '*' scan nip
    IF  nadr nlen *-open-file
        EXIT
    THEN
    URL$ OFF                                \ clear the URL buffer
    MAXSTRING localAlloc: open$
    MAXSTRING localAlloc: create$

    nadr nlen "CLIP" open$ place
    nadr unnamed-file? 0=                   \ if its a real file
    IF
        open$ count "path-file drop open$ place
        open$ count r/o open-file           \ try to open original file
        IF  drop                            \ rda jp 01/27/2002  DROP added
            open$ ?defext
            open$ count r/o open-file       \ try to open original file
            IF    drop                      \ can't, then strip off path
                  nadr nlen "to-pathend"
                  "CLIP" open$ place
                  open$ count "path-file    \ search through the Forth path
                  drop "CLIP" open$ place
                  open$ ?defext             \ make sure it has an extension
            ELSE  close-file drop           \ else close if we opened it
            THEN
        ELSE
             close-file drop                \ else close if we opened it
        THEN
    THEN

    wait-cursor                            \ release/allocate line pointer table
    open$ count r/o open-file 0=           \ -- string len handle flag
    IF  open$ count s" .BMP" caps-search nip nip        \ if it's a BMP
        open$ count s" .DIB" caps-search nip nip or     \ or a DIB
        IF  close-file drop                         \ don't open this way
            open$ count "CLIP" cur-filename place
            cur-filename +NULL                      \ need NULL termination
            cur-filename count "open-bitmap         \ for "open-bitmap
            text-ptr ?dup IF release THEN           \ make dummy empty file
            2 to textlen
            textlen start-text-size + to text-blen
            text-blen malloc to text-ptr
            crlf$ count text-ptr swap move  \ move in CRLF
            0x0D to lend-char               \ set line terminator info
            2    to lend-len
            FALSE to browse?
            browse-toggle
            TRUE to bitImage?
            Home: DocWindow
        ELSE                                    \ else open as text file
            FALSE to bitImage?
            FALSE to browse?
            Home: DocWindow
            >r                              \ save the file handle
            open$ count "CLIP" cur-filename place
                               cur-filename +NULL
                                            \ release/allocate the text buffer
            text-ptr ?dup IF release THEN
            r@ file-size 2drop to textlen

            textlen start-text-size +  to text-blen
            text-blen malloc to text-ptr
\           textlen 200000 >                \ if greater than 200k bytes
\           IF      s" Reading text file..." "message
\           THEN                            \ read the file into memory 
            text-ptr textlen r@ read-file drop
            to textlen
            \ if its and EXE file, THEN edit as a binary file
            open$ count s" .BLK" caps-search nip nip to editAsBinary?
            r> close-file drop
            addFileMenu
        THEN
    ELSE
        drop                                \ discard garbage handle
                                            \ we make a NEW FILE here
        nadr unnamed-file?
        auto-new? or                    \ automatically make a new file
                                        \ if it doesn't already exist
        IF  TRUE
        ELSE
            unnamed-file count RECURSE      \ recurse, make new
            nadr nlen "CLIP" open$ place
            open$ count "path-file drop open$ place
            open$ ?defext           \ make sure it has an extension
            z" Do you want to Create it?"
            s" Can't Open: " create$  place
            open$ count      create$ +place
                             create$ +NULL
\ removed next line to allow filnames not only in uppercase - May 18th, 2003 dbu
\           open$ count upper
            create$ 1+
            MB_OKCANCEL MB_ICONSTOP or
            WinEdMessageBox: EditorWindow IDOK =
        THEN                            \ -- TRUE if making a new empty file
        IF  open$ count "CLIP" cur-filename place
            text-ptr ?dup IF release THEN
            2 to textlen
            textlen start-text-size + to text-blen
            text-blen malloc to text-ptr
            crlf$ count text-ptr swap move  \ move in CRLF
            0x0D to lend-char               \ set line terminator info
            2    to lend-len
            FALSE to browse?                \ reset browse mode
        ELSE
            unnamed-file count RECURSE      \ recurse, make new
            close-text                      \ canceled. close file
            EXIT                            \ and leave
        THEN
    THEN
    textlen set-line-pointers
    set-longest-line
    message-off                             \ clear message box
    0 #line" s" <HTML>" xsearch nip nip     \ detect HTML document
    IF  FALSE to browse?                    \ reset browse mode
        browse-toggle                       \ so we can set it again
    THEN
    false to edit-changed?
    home-doc
    Refresh: EditorWindow
    Update: FilesList
    ReTitle: EditorWindow
    ;

: "browse       ( a1 n1 -- )
        >E
        "+open-text
        browse? 0=
        IF      browse-toggle
        THEN  ;

: _save-text    { \ save$ fhndl -- }    \ save the file in memory to a disk file
        bitImage?
        IF      save-bitmap-as
                EXIT            \ save as bitmap and leave
        THEN
        MAXSTRING LocalAlloc: save$
        edit-changed? 0= ?EXIT
        cur-filename c@ 0=
        IF      GetHandle: EditorWindow Start: SaveText dup c@
                IF    \ dup   May 5th, 1998 tjz remove 'dup' per bjg
                        count "CLIP" cur-filename place
                ELSE    drop EXIT       \ leave if canceled save
                THEN
        THEN
        wait-cursor             \ release/allocate line pointer table
        cur-filename count r/w create-file 0=           \ -- handle flag
        IF      to fhndl                                \ save file handle
                first-line-saved #line.addr             \ from
                file-lines #line.addr over -            \ length
                dup 200000 >
                IF      s" Saving text file..." "message
                THEN
                as-pc?
                IF      2drop                           \ discard total params
                        file-lines first-line-saved     \ loop on all lines
                        ?DO     i #line"        save$  place
                                crlf$ count     save$ +place
                                save$ count fhndl write-file drop
                        LOOP    FALSE to as-pc?
                ELSE    fhndl write-file drop
                THEN
                fhndl close-file drop
                false to edit-changed?                  \ clear changed flag
                line-cur >r
                cursor-col >r
                cursor-line >r
                text-length dup>r start-text-size + to text-blen
                text-blen text-ptr realloc              \ adj buffer
                s" Failed to adjust the text buffer size"
                ?TerminateBox to text-ptr
                r> set-line-pointers
                set-longest-line
                update-mirrors
                r> to cursor-line
                r> to cursor-col
                r> to line-cur
                false to warned?
                message-off
        ELSE    drop beep
                z" Use SaveAs to save your file to a new drive or name"
                z" WARNING Failed to create file!"
                MB_OK WinEdMessageBox: EditorWindow drop
        THEN
        SetFocus: DocWindow
        ReTitle: EditorWindow ;

' _save-text is primitive-save-text

: save-text-as  ( -- )          \ save with a new name
        >E
        bitImage?
        IF      save-bitmap-as
        ELSE    no-highlight
                GetHandle: EditorWindow Start: SaveText dup c@
                IF      dup count "CLIP" cur-filename place
                        file-has-changed
                        _save-text
                        Update: FilesList       \ October 28th, 1997 tjz
                                                \ bug fix per Fredrich Prinz
                THEN    drop
        THEN    SetFocus: DocWindow ;

: save-text-as-pc ( -- )        \ SAVE AS a PC file
        >E
        bitImage? ?EXIT
        TRUE to as-pc?
        save-text-as 
        false to edit-changed?
        cur-filename count "open-text
        sync-mirrors ;

: save-text-pc  ( -- )          \ save to same filename as a PC file
        >E
        bitImage? ?EXIT
        TRUE to as-pc?
        no-highlight
        file-has-changed
        _save-text
        false to edit-changed?
        cur-filename count "open-text
        sync-mirrors ;

: do-save-text  ( -- )
        >E
        bitImage?
        IF      save-bitmap-as
        ELSE    cur-filename count 2dup '.' scan nip - nip 0=  \ no file,
                cur-file-unnamed? or                           \ or new file
                IF      save-text-as
                ELSE    _save-text
                THEN
        THEN    update-mirrors ;

' do-save-text is save-text

: save-all-text ( -- )          \ save all modified files
        >E
        entry# >r
        entry-max 0
        DO
                I to entry#     \ select the hyper file index
                I SetStack: EditWindow \ dbu
                edit-changed?
                IF
                        refresh-screen
                        save-text
                THEN
        LOOP
        r> to entry#
        entry# SetStack: EditWindow \ dbu
        refresh-screen
        ReTitle: EditorWindow ;

: _warn-to-save ( -- )
        z" Can I save your edit changes now?\n\nThe edit buffer length will also be increased"
        z" WARNING You are Almost OUT of Buffer Space!"
        MB_YESNO WinEdMessageBox: EditorWindow
        CASE
                IDYES     OF    save-text       ENDOF
                IDNO      OF                    ENDOF
        ENDCASE ;

' _warn-to-save is warn-to-save

: _must-save    ( -- )
        z" MUST save your edit changes now?\n\nThe edit buffer length will also be increased"
        z" WARNING Buffer Space EXAUSTED!"
        MB_YESNO WinEdMessageBox: EditorWindow
        CASE
                IDYES     OF    save-text       ENDOF
                IDNO      OF    bye             ENDOF
        ENDCASE ;

' _must-save is must-save

: revert-text   ( -- ) \ undo & return to same place, same file \ dbu c/o jap
        browse?
        >E
        false to edit-changed?
        line-cur       \ get current top line     \ jp
        cursor-col
        cursor-line
        cur-filename count "open-text
        sync-mirrors
        to cursor-line to cursor-col
        VPosition: DocWindow    \ set cursor-line
        to browse?
        ;

: _?save-text   ( -- f1 )       \ return f1=true if we canceled
      cur-filename count "already-open# 2 <
      edit-changed? and
      IF    save-minutes 0>
            IF    save-text
                  FALSE
            ELSE  z" Save the changes to the current file?"
                  z" The Current File Has Been Modified!"
                  MB_YESNOCANCEL MB_ICONSTOP or
                  WinEdMessageBox: EditorWindow   
                  CASE
                        IDYES     OF    save-text               FALSE ENDOF
                        IDNO      OF    false to edit-changed?  FALSE ENDOF
                        IDCANCEL  OF                            TRUE  ENDOF
                        FALSE swap
                  ENDCASE
            THEN
      ELSE  false to edit-changed?
            FALSE
      THEN ;

' _?save-text is ?save-text     \ link into deferred word

: ?save-new     ( -- f1 )
                cur-file-unnamed?
                IF   ?save-text
                ELSE false
                THEN ;

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 30    Load Bitmap File support (part 2)    
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

FileOpenDialog OpenBitmap "Open Bitmap File" "Bitmap Files (*.bmp, *.dib)|*.bmp;*.dib"

: load-bitmap   ( -- )
        GetHandle: EditorWindow Start: OpenBitmap dup c@ \ -- a1 n1
        IF      count "open-text
        ELSE    drop beep
        THEN    refresh-screen ;

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 31    Save Bitmap File support  
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

FileSaveDialog SaveBitmap "Save Bitmap File" "Bitmap Files (*.BMP)|*.BMP|*.DIB|All Files (*.*)|*.*|"

        4 constant sizeof(RGBQUAD)
       14 constant sizeof(BitmapFileHeader)
       40 constant sizeof(BitmapInfoHeader)

        0 constant biSize
        4 constant biWidth
        8 constant biHeight
       12 constant biPlanes
       14 constant biBitCount
       16 constant biCompression
       20 constant biSizeImage
       24 constant biXPelsPerMeter
       28 constant biYPelsPerMeter
       32 constant biClrUsed
       36 constant biClrImportant

: _save-bitmap-as { \ nBits pbmi lpBits hbm  hdcMem hfile nrgbquad BitmapFileHeader save$  -- }
        16 to nBits                     \ always saves 16bit color files
        14 LocalAlloc: BitmapFileHeader
        max-path    LocalAlloc: save$
        s" Save Bitmap File: "  save$ place
        nBits (.)               save$ +place
        s"  Bit"                save$ +place
        save$ count SetTitle: SaveBitmap
        GetHandle: EditorWindow Start: SaveBitmap dup c@

        IF count save$ place

                sizeof(BitmapInfoHeader)  sizeof(RGBQUAD) 256 * + malloc to pbmi
                \ ******** DON'T DELETE FOLLOWING LINE: ***********************
                pbmi sizeof(BitmapInfoHeader) sizeof(RGBQUAD) 256 * + erase
        sizeof(BitmapInfoHeader)                pbmi biSize            +   !
        SCREEN-WIDTH                            pbmi biWidth           +   !
        SCREEN-HEIGHT                           pbmi biHeight          +   !
        1                                       pbmi biPlanes          +  w!
        nBits                                   pbmi biBitCount        +  w!
        nBits
         CASE
          1 OF BI_RGB    2 to nrgbquad    ENDOF
          4 OF BI_RLE4  16 to nrgbquad    ENDOF \ Could also be BI_RGB for
          8 OF BI_RLE8 256 to nrgbquad    ENDOF \ uncompressed format
         16 OF BI_RGB    0 to nrgbquad    ENDOF
         24 OF BI_RGB    0 to nrgbquad    ENDOF
         32 OF BI_RGB    0 to nrgbquad    ENDOF
         ENDCASE                                   pbmi biCompression     +   !

        SCREEN-HEIGHT
        SCREEN-WIDTH
        imageDC GetHandle: [ ]
        Call CreateCompatibleBitmap to hbm

        imageDC GetHandle: [ ]
        Call CreateCompatibleDC to hdcMem
        hbm hdcMem Call SelectObject drop

        SRCCOPY                                   \
        0 0                                       \ y,x origin
        imageDC GetHandle: [ ]                    \ from screen dc
        SCREEN-HEIGHT                             \ height of dest rect
        SCREEN-WIDTH                              \ and width of dest rect
        0 0                                       \ y,x dest
        hdcMem                                    \ to memory dc
        Call BitBlt ?win-error                    \

        DIB_RGB_COLORS
        pbmi
        NULL
        SCREEN-HEIGHT
        0
        hbm
        hdcMem
        Call GetDIBits 0= abort" 1st GetDIBits"
        pbmi biSizeImage + @ malloc to lpBits
        lpBits pbmi biSizeImage + @ erase

        DIB_RGB_COLORS
        pbmi
        lpBits
        SCREEN-HEIGHT
        0
        hbm
        hdcMem
        Call GetDIBits 0= abort" 2nd GetDIBits"
        save$
        count
        GENERIC_READ GENERIC_WRITE or
        create-file abort" CreateFile Error"
        to hfile

        0x4d42 BitmapFileHeader     w!                        \ hdr.bfType

        sizeof(BitmapFileHeader)
        sizeof(BitmapInfoHeader) +
        nrgbquad sizeof(RGBQUAD) * +
        pbmi biSizeImage + @     +
               BitmapFileHeader 2 +  !                        \ hdr.bfSize
        0      BitmapFileHeader 6 + w!                        \ hdr.bfReserved1
        0      BitmapFileHeader 8 + w!                        \ hdr.bfReserved2
        sizeof(BitmapFileHeader)
        sizeof(BitmapInfoHeader) +
        nrgbquad sizeof(RGBQUAD) * +
               BitmapFileHeader 10 + !                        \ hdr.bfOffBits

        BitmapFileHeader
        sizeof(BitmapFileHeader)
        hfile write-file  drop

        pbmi
        sizeof(BitmapInfoHeader)
        nrgbquad sizeof(RGBQUAD) * +
        hfile write-file drop

        lpBits
        pbmi biSizeImage + @
        hfile write-file drop

        hfile close-file drop

        hdcMem call DeleteDC ?win-error
        hbm call DeleteObject ?win-error

        lpBits release
        pbmi release
     ELSE drop
     THEN       ;

' _save-bitmap-as is save-bitmap-as

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 32    Calculate printer font height     
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

: WinEd_calc_font_height ( --- points_high )
        83 printer-lpi / ;              \ rls February 6th, 2002 - 16:00

' WinEd_calc_font_height is calc_font_height

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 33    Print Text File support     
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

\ rls February 5th, 2002 - 11:21
: print-text    { \ message$ fromline toline -- }
        bitImage? ?EXIT
        MAXSTRING localAlloc: message$
        printed-columns 9 *    to screen-width
        484                    to screen-height
        char-height     >r  12 to char-height
        char-width      >r   9 to char-width
        true PD_HIDEPRINTTOFILE lastpage
        start-scaled2   ( -- flag )
        print-flags PD_SELECTION and highlighting? and
        IF      hlst to fromline
                hled to toline
                s" Selection from File: "  message$ place
        ELSE    0 to fromline
                file-lines to toline
                s" File: "  message$  place
        THEN
        cur-filename count message$ +place
        message$ count UserMessage: ThePrinter
        #pages-up ?dup
        IF    2 =
              IF      two-page
              ELSE    four-page
              THEN
        THEN
        ( flag )
        IF
              s" Courier New Bold" SetPrinterFont: ThePrinter
              toline fromline
              ?DO   i #line"
                    browse? \ if browsing, ignore HTML when printing
                    IF    BEGIN
                                2dup s" <" search
                          WHILE
                                2swap 2over nip - Type: ThePrinter
                                2dup '>' scan dup
                                IF    2nip
                                ELSE  2drop dup
                                      IF   over 1 Type: ThePrinter
                                      THEN
                                THEN  1 /string
                          REPEAT
                          2drop
                    ELSE
                          lend-len 0= \ if not TEXT file, then discard non ASCII
                          IF
                                -IF   i BLOCKLINE-SIZE * to displayingLine
                                      base @ >r hex
                                      tempLine off       \ clear the temp buffer
                                      displayingLine
                                      0 <# # # # # BL hold # # # # #>
                                      tempLine +place    \ 9 wide
                                      s"   | "
                                      tempLine +place    \ 4 wide
                                      2dup bounds
                                      ?DO     i c@ 0 <# # # BL hold #>
                                      tempLine +place  \ 3 * BLOCKLINE-SIZE wide
                                      LOOP
                                      SPCS BLOCKLINE-SIZE 3 * 14 +
                                      tempLine c@ - 0MAX tempLine +place
                                      tempLine +place
                                      tempLine count
                                      r> base !
                                THEN
                          THEN
                    THEN
                    Type: ThePrinter
                      Cr: ThePrinter
              LOOP
              print-scaled            \ print the results if single-page
              single-page             \ print the results if multi-page
        THEN
        r> to char-width
        r> to char-height
        FALSE to direct-print? ;    \ if we enable auto-print, use it only once.

: text-setup    ( -- )
        bitImage? ?EXIT
        GetHandle: EditorWindow Setup: ThePrinter ;

: text-up-setup ( -- )
        bitImage? ?EXIT
        EditorWindow Start: page-up-dialog to #pages-up
        SetFocus: DocWindow ;
