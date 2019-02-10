THIS IS NOT A FINISHED PROJECT - A WORK IN PROGRESS
***************************************************

IMPORTANT
*********

If you do use this be aware it may not work as expected, the keyboard has no repeat on keys and some keys are not
mapped or mapped for  non UK keyboard.

ON FIRST USE
Enter 2nd page of OSD and change UART connection to Console.

log in as root 

enter export TERM=xterm 
enter stty columns 80 rows 40. 

Linux asks the console for max cols and rows at log in, hence the cursor dropping to 
the bottom of the screen. The console does not understand part of the Esc7 Esc[r Esc[999;999H Esc[6n sequence at present.

to run mc you need mc -a to run non unicode graphic characters

cursor keys should work - tested in mc and vi  vim
The console used to transmit Esc[A Esc[B Esc[C Esc[D for the arrow keys (standard vt220)
As vi and mc as standard require EscOA EscOB EscOC EscOD I changed the keyboard scan decoder. I have moved the 
original escape sequences to shift and arrow if required.

you will need to use export TERM=xterm  and stty columns 80 rows 40 each time you log in unless
you create a file called say mister and enter the export and stty commands. On login just type source mister to set
the terminal type and screen size. 

program notes
-------------
DataType.svh holds all the settings for variable types.

Console.sv is emu
FpgaVirtualConsole.sv the main program transmits data from Keyboardcontroller and receives data for the VideoController

Keyboardcontroller calls PsReceiver Ps2Translator UartTxFifo FifoComsumer then uartTramsmitter

VideoController calls uartReceiver VT100Paser TextRam VideoRam BlinkGenerator then DisplayController

Display controller calls vga-controller and vga_textmode which takes the preformatted data from textRam and produces output, 
with changes for the controller to take account of the clock cycle delay in retrieving the ram data. 

There is no history buffer. Blinking, underline and negative in the attributes are implemented at present but no bright.
There is room for 4 character sets - only set1 is fully functional I have been using 2 and 3 for testing.

This is still a work in progress.
The keyboard is annoying as I am used to UK layout and there is no repeat.
Theres plenty to do but will take some time. Its a reasonable start point. Down to 235 Warnings on compilation (over 2000 at start)

