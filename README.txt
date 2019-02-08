THIS IS NOT A FINISHED PROJECT - A WORK IN PROGRESS
***************************************************

IMPORTANT
*********

If you do use this be aware it may not work as expected especially cursor keys and function keys. The keyboard appears to be USA 
and no repeat on keys.

ON FIRST USE
log in as root 

type clear to get rid of the test data.  
Use /src/storage/TextRamBlank.mif for TextRam on a recompile to start a clear screen.

enter export TERM=xterm-256color (any changes made in linux for this terminal will not affect the xterm for PuTTy)

amend file ~/.config/mc/ini
add the following to the end of file
[terminal:xterm-256color]
up=\\e[A
down=\\e[B
right=\\e[C
left=\\e[D

to run mc you need mc -a to run non unicode graphic characters

cursor keys do not work in vi or vim use hjkl 

you will need to use export TERM=xterm-256color each time you log in. ( I changed /sbin/uartmode to include the xterm-256color in agetty
 so its there until I make a new SD card)

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

