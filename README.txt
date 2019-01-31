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

to run mc you need mc-a to run non unicode graphic characters

cursor keys do not work in vi or vim use hjkl 

you will need to use export TERM=xterm-256color each time you log in. ( I changed /sbin/uartmode to include the xterm-256color in agetty
 so its there until I make a new SD card)

program notes
-------------
DataType.svh holds all the settings for variable types.

Console.sv is emu
FpgaVirtualConsole.sv the main program collects data from Keyboardcontroller and sends data to VideoController

Keyboardcontroller calls PsReceiver Ps2Translator UartTxFifo FifoComsumer then uartTramsmitter

VideoController calls uartReceiver VT100Paser TextRam BlinkGenerator then DisplayController

DisplayController used to call sramController FontRom Textrenderer and vgaDisplayAdapter which used a huge amount of ram.

Display controller now  calls vga_controller and vga_textmode which takes the preformatted data from textRam and produces output, 
with changes for the controller to take account of the 4 clock cycle delay in retrieving the ram data. 
This still uses more memory than I wanted but couldn't get the display to work from text ram only.

vga needs to be re-written in verilog to keep in with the original. (working on it, increase memory for history buffer)


There is no history buffer. Blinking, underline and negative in the attributes is implemented at present but no bold.

This is still a work in progress just the vga has been 'bolted' on to make a working platform.
There are still lots of unused parts of verilog and the keyboard is annoying as I am used to UK layout.
Theres plenty to do but will take some time. Its a reasonable start point. Down to 315 Warnings on compilation (over 2000 at start)

