# cg
This software serves Forth to you via cloud and a browser to your browser.
It is live at http://24.5.42.64:4444
The full W32 system is hosted on a W10 Surface computer.  

Support is provided by text at 415-239-5393 John Alan Peters
My Email is not checked very often so if you email me please text that "You have mail!"
japeters747@gmail.com

The whole Win32Forth dictionary is available via a console window in your browser when you log on to the above URL.
Try something simple like SE SEE  SE is a short version of SEE that shows the stack comments and more. ( -- text )

TYPE has been vectored to VTYPE to send the output to the web page. It is in a loop in Win32Forth named VECTINT

The source for both VTYPE & VECTINT can be seen via the SEE command like below,
SEE VTYPE

Most Forth words work like SEE <word> ORDER VOCS WORDS 
You can CD to another directory, FLOAD a file (and all the usual Forth commands)
 
DEBUG probably will not work because Forth is in a loop. Some of the words are named VECTINT  DOSOCK  (socket)

VV short for VIEW displays code in the CONSOLE.

tHE wEBBY CODE is by my friend and programmer Bob Ackerman.
All the code is available on GitHub. If you have trouble with paths and directories let us know.

When we make a code change we use TeamViewer to go on to the 'Surface' machine and change the code.
We have a a backup here on GitHub, and of course it works as a version updater and tracker.

Colon definitions work finie of course. You have to save them in a file or they will be lost on a reboot.
If there is a problem, the system say "Error 13" We are using CATCH for the errors.

CG is the Forth source for estimating electrical jobs. A full system (database?) of parts with prices as well and times from the Manual of Labor units that came from NECA (National Electrical Contractors Association). I am hoping to see it put to use.  I will help for fun. It normally uses the WinEd editor to output to a file suitable for showing to the client.  This application is a whole other story and how to use it will come later

CG is short for Contract Generator. <br> 
You can try ELECTRIC WORDS but it will take a while.(Many words)  Use the space bar to start-stop the output. ESC to quit WORDS.
ROOT WORDS is quick as there are only three VOCABULARIES 

Here are some words to try or test. 
DUMP
HH 'word' ( -- )  Show all the definitions that contain 'word'  HH is really just another name for WORD with a delimier. (or something)
LOCATE
SEE
SEE-CODE
SIMPLE-SEE
VOCS
VV
VIEW
WORDS
XT-SEE

The surface machine has an icon that starts what we call 'Webby' so if the system crashes, one of us can use TV to go on to the
machine and close the DOS shell window and the cg forth window that are part of running Webby and restart the system.

There is some Forth socket code in the initial directory files.

data is sent from the webpage to the forth webserver and from there it is interpreted and sent  back to the browser's web page.  
It is here for your to enjoy the progress so far.

Try this test of the CG  
 50 EMT 1/2
 or
 2 CB
 You should see the time and the costs to install a CB or circuit breaker.
 
P.S. Historically, Forth was typed in from a paper listing. Later Forth83 was DOS based. Forth migrated to Windows on XP and then via Win32Forth on to Windows W7, W8 & W10  thanks to Tom Zimmer. Now I am asking you the reader to teach a friend how to use Forth on the Cloud. You can uuse Forth without the hassle of downloading it (Anti Virus problems) or the fear of downloading an unknown .EXE file.
 
 John Alan Peters
 415-539-5393 Please text (I don't answer the phone)
