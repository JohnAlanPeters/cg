\ $Id: Ed_Url.F,v 1.1 2011/03/19 23:26:04 rdack Exp $
\
WinLibrary WININET.DLL

: "skip-URLbase" ( a1 n1 --- a2 n2 )  \ return a2 and count=n2 of URL after base
                                      \ scan past "HTTP://" to last '/' in URL
                s" //" search IF 2 /string THEN
                [char] / scan dup
                IF      1 /string
                        BEGIN   2dup [char] / scan ?dup
                        WHILE   2nip 1 /string
                        REPEAT  drop
                THEN    ;

: "URL-base"    ( a1 n1 -- a2 n2 )      \ return URL base
                2dup "skip-URLbase" nip - ;

LMAXSTRING Pointer URLcombined

: "build-URL"   { relURL relLen -- adr2 len2 }
        URL$    LCOUNT "URL-base"       URLcombined  LPLACE
        URLcombined LCOUNT + 1- c@ [char] / <>      \ make sure it ends in a '\'
        IF      [char] / URLcombined C+LPLACE
        THEN
        relURL relLen over c@ [char] / = IF 1 /string THEN  URLcombined +LPLACE
        URLcombined +LNULL
        URLcombined LCOUNT ;

#define INTERNET_OPEN_TYPE_PRECONFIG    0   \ use registry configuration
#define INTERNET_OPEN_TYPE_DIRECT       1   \ direct to net
#define INTERNET_OPEN_TYPE_PROXY        3   \ via named proxy

#define INTERNET_FLAG_NO_CACHE_WRITE    0x04000000  \ don't write this item to the cache
#define INTERNET_FLAG_DONT_CACHE        INTERNET_FLAG_NO_CACHE_WRITE
#define INTERNET_FLAG_MAKE_PERSISTENT   0x02000000  \ make this item persistent in cache
#define INTERNET_FLAG_OFFLINE           0x01000000  \ use offline semantics

0 value HAVEInternet?
0 value HINTERNETSESSION
0 value HINTERNETURL

: html-release  ( -- )                  \ release the session handle
        HAVEInternet? 0= ?EXIT
        s" InternetCloseHandle" [ also hidden ] "find-proc 0= ?EXIT drop [ previous ]
        HINTERNETSESSION Call InternetCloseHandle drop
        NULL to HINTERNETSESSION ;

UNLOAD-CHAIN CHAIN-ADD-BEFORE html-release       \ add to termination chain

VARIABLE NumberOfBytesRead
4000     CONSTANT HTMLSIZE
HTMLSIZE Pointer  HtmlBuf
0        value    HTMLcnt

: "HTML         { htmlAdr HtmlLen \ open$ html$ name$ fhndl -- }
      max-path   LocalAlloc: open$
      LMAXSTRING LocalAlloc: html$
      MAXSTRING  LocalAlloc: name$
      htmlAdr HtmlLen html$ LPLACE
                      html$ +LNULL
      >E
      ?save-new ?EXIT
      s" InternetAttemptConnect"
      [ also hidden ] "find-proc 0= ?EXIT drop [ previous ]
      HAVEInternet? 0=
      IF    s" Interogating Internet..." "message
            0 Call InternetAttemptConnect dup 0= to HAVEInternet?
            IF    beep message-off EXIT
            THEN
      THEN
      HINTERNETSESSION 0=
      IF    s" Opening Connection..." "message
            NULL
            NULL
            NULL
            INTERNET_OPEN_TYPE_DIRECT
            z" Win-Ed"
            Call InternetOpen dup to HINTERNETSESSION 0=
            IF    beep message-off EXIT
            THEN
      THEN
      s" Opening URL..." "message
      0                                          \ dwContext
      INTERNET_FLAG_DONT_CACHE                   \ dwFlags
      s" Accept: */*\n\n" swap                   \ dwHeadersLength, lpszHeader
      html$ LCOUNT DROP                          \ lpszUrl
      HINTERNETSESSION                           \ hInternetSession
      Call InternetOpenUrl dup to HINTERNETURL
      IF    s" Win-Ed."           name$  place
            HTMLcnt 0 <# # # # #> name$ +place
            1 +to HTMLcnt
            name$ count       delete-file drop
            name$ count   r/w create-file 0=
            IF    to fhndl
                  s" Reading URL..." "message
                  BEGIN NumberOfBytesRead
                        HTMLSIZE
                        HtmlBuf
                        HINTERNETURL
                        Call InternetReadFile >r
                        HtmlBuf NumberOfBytesRead @ fhndl write-file drop
                        r> 0<>                          \ read succeeded
                        NumberOfBytesRead @ 0> and 0=   \ and more bytes to read
                  UNTIL
                  fhndl close-file drop
                  name$ count "+open-text
                  FALSE to browse?
                  browse-toggle
                  TRUE to from-web?                     \ mark as from the Web
                  html$ LCOUNT URL$ LPLACE              \ save the URL
                               URL$ +LNULL
            ELSE  beep
            THEN
            HINTERNETURL Call InternetCloseHandle drop
            NULL to HINTERNETURL
      ELSE  beep
      THEN
      message-off
      SetFocus: EditWindow
      RefreshAll: EditWindow
      ReTitle: EditorWindow ;

: "ViewWeb-Link ( a1 n1 -- )
        WinEd-web?                    \ user selected WinEd for web browsing
        ?control
        OR
        IF      "HTML
        ELSE    GetHandle: EditorWindow "Web-Link
        THEN    ;

NewEditDialog OpenUrlDlg "Open URL" "URL Address:" "Open"  ""  ""

create url-buf MAXSTRING allot
       url-buf off

: open-html     ( -- )
                url-buf conhndl Start: OpenUrlDlg
                IF      url-buf count "HTML
                THEN    ;

