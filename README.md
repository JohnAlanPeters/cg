# cg
This syatem is an attempt to bring Forth in to the age of the cloud. Forth83 was DOS based. Forth migrated from DOS to Windows XP and then via Win32Forth on to Windows W7, W8 & W10 via c/o and with thanks to Tom Zimmer. Now I am working with you (the eader) to bring Forth on to the Cloud. Soon you will be able to use Forth with outthe hastle fo downloding it (AV problems etc, or the fear of downloading an unknowd .EXE and more.

The full Forth source for estimating electrical jobs is included. A full system (data base?) of parts with prices as well and times from the Manual of Labor units that came from NECA (National Electiical Contractors Association). I am hoping to see it put to use.  I will help for fun. It normally uses the WinEd editor to output in to a file sutable for showing to the client.

We are gradually navagating Win32Forth on to the cloud.
Currently we are live at http://24.5.40.11:8888/interpret 

For support please text me at 415-239-5393 John Alan Peters
Email is not looked at very ofter so if you email me pleae text that "You have mail!"
japeters@pacbell.net

The whole Win32Forth dictionary is available via a litle input window in your browser when you log on to the above URL.
Try something simple like 2 2 + .
Don't use the CR key on the input window, instead use the [DoIt] button.
TYPE has been vectored to send the output to the web page instead of the usuall console.  It is in a loop in Forth.

Most Forth words work like SEE <word> and ORDER and VOCS
You can CD to another directory, FLOAD a file (and all the usuall Forth commands)
DEBUG probably will not work because Forth is in a loop. Some of the words are named VECTINT  DOSOCK  (socket)

VV short for VIEW will not work unless you log in via TeamViewer and quit Webby and run CG.EXE via the icon on the 
desk top.  You will need to ask for the address and password.
The output is sent to your browser window via some Python code by my friend and expert programer Mr. Bob Ackerman.
All the code is availabe on GitHub, but you may have some trouble with paths and directorys if you install it locally.

One way to make a code change is to use TeamViewer to go on to the dedicated 'Surface' machine and change the code.
We have a a backup here on GitHub, and ofcourse it works as a version updater and tracker.

Colon definitions work most of the time. I think they are lost on a reboot
SEE of a short definition is fine.  If it is a long devinition the "words' will just say "Error 13"
We are using CATCH for the errors.
The CR that you get is not comming from the standart Forth but from a part of the loop.

SHORT HAND
W32 is short for Win32Forth
CG is short for Contract Generator.  
TV TeamViewer

You can try ELECTRIC WORDS but it probbably will fail (too many words)
ROOT WORDS works as there are only three VOCABULARIES However if you execute ROOT WORDS from a regular disk based W32 
you will see that there are some ------- lines that are EMITed incorrectly.  I don't know if the solution is in Forth or Python.

Here are some words to try or test. They all work on a disk based Forth but we can use some spiffing up of the web based system.
DUMP
HH 'word' ( -- )  (Show all the definitons that contain 'word'
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
machind and close the black screens that are part of runing Webby and restart the system.

There is some Forth socket code some place.

Early on Bob Ackerman had to figure out how to send data to the server and how do we get that data interpred and sent
 back to tote browsing page.  So far it wi working pretty well.  Dont expect perfection.  It is here for your to enjoy 
 the progress so far. At first it woruld only run on Firefox, but now all browsers work including Safari.
 Try this test of the CG  
 50 EMT 1/2
 or
 2 CB
 You should see the time and the costs.
