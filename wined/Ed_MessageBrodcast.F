\ $Id: Ed_MessageBrodcast.F,v 1.1 2011/03/19 23:26:04 rdack Exp $
\
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 16    A replacement for win32forth-message to get rid of HWND_BRODCAST
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

: GetProcessId { hWnd -- ProcessID }  \ get ProcessId for given window
        here hWnd call GetWindowThreadProcessId drop here @ ;

create Win32ForthClassName ," Win32Forth" \ the window class name of the forth console
create Win32ForthName MAXSTRING allot Win32ForthName off \ the window name of the forth console
0 value hWndForthWindow \ holds the current handle of forth console

2 CallBack: GetForthWindowCallback { hWnd SciEditProcessID \ buff$ -- int }
        MAXSTRING localalloc: buff$

        true \ default return value

        \ get classname
        MAXSTRING buff$ hWnd call GetClassName 0<>
        if   \ is it the window we are lookin for?
             Win32ForthClassName count buff$ over COMPARE 0=
             if   MAXSTRING buff$ hWnd call GetWindowText drop
                  Win32ForthName count buff$ over COMPARE 0=
                  if   \ don't return our own (hidden) console window
                       hWnd GetProcessId SciEditProcessID <>
                       if   hWnd to hWndForthWindow
                            drop false \ stop enum
                       then
                  then
             then
        then ;

: BuildWin32ForthName ( -- )
\ Build the window name of the Forth console window.
\ If a Forth console window is embedded within an turnkey application
\ the name is "Win32Forth".
\ For a stand alone console which is needed here it is "Win32forth <Version>",
\ were <Version> is something like "6.11.09" (see src/extend.f).
        base @ decimal
        S" Win32Forth " Win32ForthName place
        version# ((version)) Win32ForthName +place
        Win32ForthName +NULL
        base !
        ;

: GetForthWindow ( -- ) \ get the handle of the forth console window
        BuildWin32ForthName
        0 to hWndForthWindow
        GetHandle: EditorWindow GetProcessId
        &GetForthWindowCallback
        Call EnumWindows drop ;

: FindForthWindow ( -- flag ) \ check if there is a forth console
        hWndForthWindow call IsWindow not
        if   GetForthWindow hWndForthWindow 0<>
        else true
        then ;

: wined_win32forth-message ( lParam wParam -- ) \ send message to forth console
        \ check if we have a valid window handle to the forth console
        hWndForthWindow call IsWindow not
        if   \ if not try to get one
             GetForthWindow
        then

        hWndForthWindow 0<>
        if   \ if we have a valid window handle to the forth console
             \ we can just send the message directly
             WM_WIN32FORTH hWndForthWindow Call SendMessage drop
        else 2drop  \ [rda 1/18/04]
        then ;

