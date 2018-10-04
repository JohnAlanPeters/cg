\ $Id: Ed_SdkHelp.F,v 1.1 2011/03/19 23:26:04 rdack Exp $
\
\    File: SdkHelp.f
\  Author: Dirk Busch
\ Created: Mittwoch, November 10 2004 - dbu
\ Updated: Sonntag, Dezember 26 2004 - dbu
\
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ Interface to the WIN32-SDK Help file
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\


anew -SdkHelp.f

needs Win32Help.f \ WinHelp access

internal

\ path to the WIN32-SDK help file
create sdk-help$ ," doc\hlp\win32.hlp" MAXSTRING allot-to
sdk-help$ +null

: sdk-GetFilename ( -- addr len )
                sdk-help$ count 2dup IsAbsolutePath? 0=
                if   prepend<home>\
                then ;

external

: sdk-help?     ( -- f ) \ returns true if win32.hlp file is avalible
                sdk-GetFilename FILE-STATUS nip 0= ;

: (sdk-help)    ( addr len -- ) \ show help for Win32 API function
                { \ old_help_file$ function$ -- }
                sdk-help?
                if   MAX_PATH LocalAlloc: old_help_file$
                     MAX_PATH LocalAlloc: function$

                     help_file$ count old_help_file$ place \ save current help file
                     sdk-GetFilename help_file$ place \ set help-file to the Win32 SDK help
                     function$ place function$ +null function$ $help \ open the help file for the given function
                     old_help_file$ count help_file$ place \ restore help file
                else 2drop
                then ;

: sdk-help      ( -<word>- -- ) \ show help for Win32 API function
                bl word count (sdk-help) ;


