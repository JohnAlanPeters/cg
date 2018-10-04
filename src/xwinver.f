\ 1 PROC GetVersionEx

\ 1  constant win95
\ 2  constant win98
\ 3  constant winme
\ 4  constant winnt351
\ 5  constant winnt4
\ 6  constant win2k
\ 7  constant winxp
\ 8  constant win2003   \ Windows Server 2003 R2
\ 9  constant winvista  \ Windows Vista
10 constant win2008   \ Windows Server 2008
11 constant win2008r2 \ Windows Server 2008 R2
12 constant win7      \ Windows 7
13 constant win8

\ To check for a version, say Win2K or greater, try WINVER WIN2K >=

: xwinver-init ( -- )                \ get windows version
            156 dup _localalloc dup>r ! \ set length of OSVERSIONINFOEX structure
            r@ call GetVersionEx \ call os for version
            0= abort" call failed"
            r@ 4 cells+ @        \ get osplatformid
            case
              1 of                  \ 95, 98, and me
                r@ 2 cells+ @       \ minorversion
                case
                  0  of win95 endof \ 95
                  10 of win98 endof \ 98
                  90 of winme endof \ me
                endcase
              endof

              2 of                  \ nt, 2k, xp
                r@ cell+ @          \ majorversion
                case
                  3  of winnt351 endof \ nt351
                  4  of winnt4 endof \ nt4
                  5  of
                     r@ 2 cells+ @  \ minor version
                     case
                       0 of win2k endof \ win2k
                       1 of winxp endof \ winxp
                       2 of win2003 endof \ 2003
                     endcase
                  endof
                  6  of
                    r@ 2 cells+ @  \ minor version
                     case
                       0 of r@ 154 + c@ \ Product Type
                           ( VER_NT_WORKSTATION ) 1 = if winvista  \ Windows Vista
                                                 else win2008 \ Windows Server 2008
                                                 then
                       endof
                       1 of r@ 154 + c@ \ Product Type
                           ( VER_NT_WORKSTATION ) 1 = if win7  \ Windows 7
                                                 else win2008r2 \ Windows Server 2008 R2
                                                 then
                       endof
                       2 of win8 endof
                     endcase

                  endof
                drop -1 dup   \ unknown windows version
                endcase
              endof
            endcase to winver
            rdrop _localfree
            ;

xwinver-init

