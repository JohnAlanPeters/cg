\ WORDS can be stopped and restarted by the space-bar etc.
\ To abort hit the Escape key or the Enter key twice in a row.
\ Modified by John Peters via the example in F83s
\ The number key pad sets the speed that the WORDS scroll.

: _START-STOP   ( -- )
                KEY?
                IF KEY  10 DIGIT ( number keys select delay )
                        IF 2 * DELAYS + W@ TO SCREENDELAY
                        ELSE   13 = IF ABORT THEN  WAIT
                        THEN
                THEN ;

' _START-STOP IS START/STOP



