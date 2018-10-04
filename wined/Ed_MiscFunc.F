\ $Id: Ed_MiscFunc.F,v 1.1 2011/03/19 23:26:04 rdack Exp $
\ 
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\       Splitter class
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\


:Class Splitter         <super child-window

:M WindowStyle: ( -- style )            \ return the window style
                WindowStyle: super
                [ WS_OVERLAPPED WS_DLGFRAME or WS_DISABLED or ] literal or
                ;M

:M On_Paint:    ( -- )          \ screen redraw method
                0 0 Width Height LTGRAY FillArea: dc
                ;M

;Class

Splitter SplitterV
Splitter SplitterH

\ : in-EditWindow? ( -- f1 )
\                 GetHandle: EditWindow dup>r get-mouse-xy r> in-button? ;

: >E            ( -- )
                EditWindow to DocWindow
                GetStack: DocWindow to entry# ;

: next-window   ( -- )
                DocWindow EditWindow =
                IF      beep
                ELSE    >E
                THEN
                ReTitle: EditorWindow
                Refresh: EditorWindow ;
