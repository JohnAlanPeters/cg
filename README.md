# cg
Forth source for estimating electrical jobs. A full system of parts with prices as well and times from the Manuel of Labor units
that came form NECA (National Electiical Contractors Association)  I am hoping that it will be put to use.  I wil halp for fun.
We are gradually navagating Win32Forth on to the cloud.
Currently we are live at http://24.5.40.11:8888/interpret 

For support please text me at 415-239-5393 John Alan Peters
The whole Win32Forth dictionary is available via a litle input window in your browser.
Try something simple like 2 2 + .
Don't use the CR key on the input window, instead use the DoIt button.
Most Forth words work like SEE <word> and ORDER and VOCS
You can CD to another directory, FLOAD a file (and all the usuall Forth commands)
DEBUG probably will not work because Forth is in a loop. Some of the words are named VECTINT  DOSCK
VV short for VIEW will not work unless you log in via TeamViewer.  You will need to ask for the address and password.
The output to your browser window is sent via some Python code.
All the code is availabe here, but you may have some trouble with paths and directorys if you install it locally.
One way to make a change is to use TeamViewer to go on to the dedicated 'Surface' machine.
Colon definitions work most of the time.
SEE of a short definition is fine.  If it is a lond devinition the "words' will
We are using CATCH for the errors.
The CR that you get is not comming from the standart Forth but from a part of the loop.
Not sure of the following:
There is a LOCALHOST file in Win32Forth
SHORT HAND
W32 is short for Win32Forth
CG is short for Contract Generator.  

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
TV TeamViewer
VOCS
VV
VIEW
WORDS
XT-SEE
We did have some trouble with anti-virus erasing the EXE file but not it seems to be working most of the time.

The surface machine has an icon that starts what we call Webby so if the system crashes one of us can use TV to go on to the
machind and close the black screens that are part of runing Webby and restart the system.

There is some Forth socket code some place.
TYPE has been vectored to send the output to the web page instead of the usuall console.  It is in a loop

Early on Bob Ackerman had to figure out how to send data to the server and how do we get that data interpred and sent
 back to tote browsing page.  So far it wi working pretty well.  Dont expect perfection.  It is here for your to enjoy 
 the progress so far. At first it woruld only run on Firefox, but now all browsers work including Safari.
 Try this test of the CG  
 50 EMT 1/2
 or
 2 CB
 You should see the time and the costs.
