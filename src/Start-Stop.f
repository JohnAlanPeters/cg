\ This version can be started and stopped by use of any key except for two.
\ Hit the Escape key or the Enter key twice in a row to abort WORDS etc.
\ Modified by John Peters via the example in F83s

: _START-STOP   ( -- )
                KEY?
                IF KEY  10 DIGIT ( number keys select delay )
                        IF 2 * DELAYS + W@ TO SCREENDELAY
                        ELSE   13 = IF ABORT THEN  WAIT
                        THEN
                THEN ;

' _START-STOP IS START/STOP



