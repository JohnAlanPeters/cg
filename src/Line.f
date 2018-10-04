\ December 28, 2001  by Robert Ackerman

 forth definitions
: LINE ( n -- a) \ Line number -- address
        [ editor ]
        to cursor-line
        get-cursor-line
                cur-buf lcount drop ;
