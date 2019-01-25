THIS IS NOT A FINISHED PROJECT - A WORK IN PROGRESS
***************************************************

DataType.svh holds all the settings for variable types.

Console.sv is emu
FpgaVirtualConsole.sv the main program collects data from Keyboardcontroller and sends data to VideoController

Keyboardcontroller calls PsReceiver Ps2Translator UartTxFifo FifoComsumer then uartTramsmitter

VideoController calls uartReceiver VT100Paser TextRam BlinkGenerator then DisplayController


DisplayController used to call sramController FontRom Textrenderer and vgaDisplayAdapter which used a large amount of ram.

Display controller now just calls vga_controller which takes the preformatted data from textRam and produces output, albeit 1 pixel out at present.
vga needs to be re-written in verilog to keep in with the original. (working on it, increase memory for history buffer)


There is no history buffer and only blinking in the attributes is implemented at present.

This is still a work in progress just the vga has been 'bolted' on to make a working platform to improve when uart works.
There are still lots of unused parts of verilog.