# cg
This system will bring Forth into the age of the cloud. Historically, Forth was typed in from a paper listing. Later Forth83 was DOS based. Forth migrated to Windows on XP and then via Win32Forth on to Windows W7, W8 & W10 via thanks to Tom Zimmer. Now I am asking you the reader to help improve Forth on the Cloud. Soon you will be able to use Forth without the hassle of downloading it (Anti Virus protection problems) etc, or the fear of downloading an unknown .EXE file and so on.

SHORT HAND
W32 is short for Win32Forth<br>
CG is short for Contract Generator. <br> 
TV TeamViewer<br>

The full W32 system is running on a Windows 10 Surface computer.  It includes the Forth source for estimating electrical jobs. A full system (database?) of parts with prices as well and times from the Manual of Labor units that came from NECA (National Electrical Contractors Association). I am hoping to see it put to use.  I will help for fun. It normally uses the WinEd editor to output to a file suitable for showing to the client.  This application is a whole other story and how to use it will come later

Currently, we are live at http://25.5.40.11:8888/interpret 

Support will be provided by me. Please text me at 415-239-5393 John Alan Peters
My Email is not checked very often so if you email me please text that "You have mail!"
japeters@pacbell.net

The whole Win32Forth dictionary is available via a little input window in your browser when you log on to the above URL.
Try something simple like 2 2 + .
Don't use the CR key on the input window, instead, use the [DoIt] button.

TYPE has been vectored to VTYPE to send the output to the web page via some python code, instead of the usual console.  
It is in a loop in Win32Forth named VECTINT

The source for both VTYPE & VECTINT can be seen via the SEE command like below,
SEE VTYPE

Most Forth words work like SEE <word> ORDER and VOCS
You can CD to another directory, FLOAD a file (and all the usual Forth commands)
 
DEBUG probably will not work because Forth is in a loop. Some of the words are named VECTINT  DOSOCK  (socket)

VV short for VIEW displays code in the forth editor so it will not work from a webpage. You can log in via TeamViewer and quit Webby and run CG.EXE via the icon on the desktop.  You will need to ask for the TV address and password.

The output is sent to your browser window via some Python code by my friend and programmer Bob Ackerman.
All the code is available on GitHub, but you may have some trouble with paths and directories if you try to install it and compile the source locally.

One way to make a code change is to use TeamViewer to go on to the dedicated 'Surface' machine and change the code.
We have a a backup here on GitHub, and of course it works as a version updater and tracker.

Colon definitions work most of the time but are lost on a reboot.
SEE of a short definition is fine.  If there is a problem, the system say "Error 13"
We are using CATCH for the errors.

You can try ELECTRIC WORDS but it probably will fail (too many words)
ROOT WORDS works as there are only three VOCABULARIES However if you execute ROOT WORDS from a regular disk based W32 
you will see that there are some ------- lines that are EMITed incorrectly.  I don't know if the solution is in Forth or Python.

Here are some words to try or test. They all work on the desktop Forth but we can use some spiffing up of the web based system.
DUMP
HH 'word' ( -- )  (Show all the definitions that contain 'word'
LOCATE
SEE
SEE-CODE
SIMPLE-SEE
VOCS
VV
VIEW
WORDS
XT-SEE
We did have some trouble with anti-virus erasing the EXE file but now it seems to be working most of the time.

The surface machine has an icon that starts what we call 'Webby' so if the system crashes, one of us can use TV to go on to the
machine and close the dos shell windows and the cg forth window that are part of running Webby and restart the system.

There is some Forth socket code in the initial directory files.

data is sent from the webpage to the python webserver and from there to forth where the data is interpreted and sent
 back to the browser's web page.  So far it is working pretty well.  Don't expect perfection.  It is here for your to enjoy 
 the progress so far.
 Try this test of the CG  
 50 EMT 1/2
 or
 2 CB
 You should see the time and the costs to install a CB or circuit breaker.
 
 John Alan Peters
 415-539-5393 Please text (I don't answer the phone)
