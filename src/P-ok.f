\ $Id: P-ok.f,v 1.1 2011/03/19 23:26:09 rdack Exp $
Comment:

         THIS IS THE START OF P-OK.F

         Modified to work with Win32Forth 4-21-2001  JAP

         I added extra blank lines in the file so I can page down section by
         section like a block file, while I am converting from F83s    4-22-01

         I did this so I can see what source I am re-using and what source
         I am marking as a comment, for later reuse when we find out how to
         make words that can handle screen output and so on.
comment;


\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ THE ELECTRIC VOCABULARY IS DEFINED HERE Start of code that is in use
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

only Forth also definitions  \ maybe this will work
\ forth definitions

( 2/4 )
Vocabulary ELECTRIC
forth
: ELECT
   Only Forth Also Electric Also definitions  ;
: ELECT2  only Electric Also definitions  ;
: ELE ELECT ;
: ELECTRIC-ORDER            Elect ;
: DEFS       also definitions ;

          COMMENT: \ XXXXXXXX (These not needed)
          : DONE    ELECT SAVE-BUFFERS ." Saving Buffers"   file-commit ;
          .( DONE is smarter )

          : HELLO-P
             RTRTRTRT   31 DSP-ATRB !  DARK  !VIDEO
             start
          Comment; \ THESE ARE NOT IN USE YET -- --

( 3/4 )

cr  .(     PARTS PRICES LOOKUP SYSTEM)
cr
cr .( Copyright by John A. Peters 1985 6 7 8 9 90 91 92 1993)
cr .(    To rent a current copy call 415 239-5393)
cr

COMMENT: \ THIS IS NOT IN USE YET -  -  -
           cr ." From the command line type  WANT HELP"
           cr
           cr  .path  2 spaces  ." P.EXE"                ELECT
               [ EDITOR ]  WRAP OFF   free ;
           ' hello-p  is boot


( 4/4 )
COMMENT: \ NOT IN USE BUT NEEDED
           AEC : HELP
           cr ." Start by typing the following:" cr cr ." \WORK"
           cr ." CREATE-TEMPLATE  <Job-name.ID>  <-Any DOS file name"
           cr ." V"   cr cr ." The Visual editor uses the usual "
           cr ." INSERT  DELETE  END  HOME  PAGE-UP/DOWN & ARROW  keys"
           cr ." ^E  to Extend the prices and times for each line"
           cr ." F1  for Editor help from within the editor"
           cr ." F2  to save your work and  ESC  to leave the Editor"
           cr cr ." From the command line type  HELP"
           cr ." Goofy? Try CAF (Close All Files)(bug)"  ;
           ( Above are not in use )

Comment;  cr .( Made to the finish of P-OK.F ) \ ( END OF FILE )
