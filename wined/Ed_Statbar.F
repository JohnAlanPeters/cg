\ $Id: Ed_Statbar.F,v 1.3 2011/11/22 18:47:32 brookline Exp $
\    File: Ed_Statbar.f
\  Author: Dirk Busch
\ Created: September 10th, 2003 - 12:20 dbu
\ Updated: September 10th, 2003 - 12:20 dbu
\ Statusbar for WinEd
\
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 8     Simple Statusbar Class
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
needs ExControls.f

:Object Win-EdStatusbar  <Super MultiStatusbar

create MultiWidth 125 , 250 , 400 , 880 ,  \ width of statusbar parts
create SingleWidth -1 ,                   \ width of statusbar parts

:M SetMulti:    ( -- )
        MultiWidth 4 SetParts: self ;M

:M SetSingle:   ( -- )
        SingleWidth 1 SetParts: self ;M

:M Start:       ( Parent -- )
        Start: super
        SetMulti: self
        ;M

;Object

