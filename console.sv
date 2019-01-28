//============================================================================
//  Console
// 
//  Port to MiSTer.
//  Oldgit
//
//  Based on https://github.com/Harry-Chen/fpga-virtual-console
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//============================================================================
`include "DataType.svh"
module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [44:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	output  [7:0] VIDEO_ARX,
	output  [7:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S, // 1 - signed audio samples, 0 - unsigned
	output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)
	input         TAPE_IN,

	// SD-SPI
	output        SD_SCK,
	output        SD_MOSI,
	input         SD_MISO,
	output        SD_CS,
	input         SD_CD,

	//High latency DDR3 RAM interface
	//Use for non-critical time purposes
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,

	//SDRAM interface with lower latency
	output        SDRAM_CLK,
	output        SDRAM_CKE,
	output [12:0] SDRAM_A,
	output  [1:0] SDRAM_BA,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nCS,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nWE,

	input         UART_CTS,
	output        UART_RTS,
	input         UART_RXD,
	output        UART_TXD,
	output        UART_DTR,
	input         UART_DSR
);
	
assign LED_USER  = ioctl_download ;
assign LED_DISK  = 0;
assign LED_POWER = 0;

assign VGA_F1 = 0;

assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
assign {DDRAM_CLK, DDRAM_BURSTCNT, DDRAM_ADDR, DDRAM_DIN, DDRAM_BE, DDRAM_RD, DDRAM_WE} = 0;
assign {SDRAM_CLK, SDRAM_CKE, SDRAM_A, SDRAM_BA, SDRAM_DQML, SDRAM_DQ, SDRAM_DQMH, SDRAM_nCS, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nWE} = 'Z;

assign VIDEO_ARX = status[1] ? 8'd16 : 8'd4;
assign VIDEO_ARY = status[1] ? 8'd9  : 8'd3; 

assign UART_RTS = UART_CTS;
assign UART_DTR = UART_DSR;

wire show_vga;
assign show_vga = status[5];



`include "build_id.v" 
parameter CONF_STR = {
	"Console;;",
	"-;",
	"-;",
	"O1,Aspect ratio,4:3,16:9;",
	"O5,VGA,new,old;",
	"-;",
	"R0,Reset;",
	"V,v0.472.",`BUILD_DATE
};

/////////////////  CLOCKS  ////////////////////////

wire clk_sys;
wire clk_50;
wire clk_25;
wire clk_200;
wire pll_locked;


pll pll
(
	.refclk(CLK_50M),	// Fractional-N PLL - 50.0 MHz - 0.0 - direct
	.rst(0),
	.outclk_0(clk_sys),	// 100.0 MHz 
	.outclk_1(clk_50),
	.outclk_2(clk_25),
	.outclk_3(clk_200),
	.locked(pll_locked)
);


/////////////////  HPS  ///////////////////////////

wire [31:0] status;
wire  [1:0] buttons;

wire [15:0] joy1, joy2;
wire  [7:0] joy1_x,joy1_y,joy2_x,joy2_y;

wire [10:0] ps2_key;
wire [24:0] ps2_mouse;

wire        ioctl_download;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire        forced_scandoubler;

wire [31:0] sd_lba;
wire        sd_rd;
wire        sd_wr;
wire        sd_ack;
wire  [8:0] sd_buff_addr;
wire  [7:0] sd_buff_dout;
wire  [7:0] sd_buff_din;
wire        sd_buff_wr;
wire        img_mounted;
wire        img_readonly;
wire [63:0] img_size;
wire        sd_ack_conf;

wire [64:0] RTC;
wire 			ps2_clk, ps2_data, mse_clk, mse_dat;

Ps2Signal_t ps2;
VgaSignal_t vga;
SramInterface_t sramInterface;
SramData_t sramDatai, sramDatao;


hps_io #(.STRLEN($size(CONF_STR)>>3)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),

	.conf_str(CONF_STR),

	.buttons(buttons),
	.status(status),
	.forced_scandoubler(forced_scandoubler),

	.RTC(RTC),

	.ps2_key(ps2_key),
	.ps2_mouse(ps2_mouse),
	.ps2_kbd_clk_out(ps2_clk),
	.ps2_kbd_data_out(ps2_data),
	.ps2_mouse_clk_out(mse_clk),
	.ps2_mouse_data_out(mse_dat),

	.ioctl_download(ioctl_download),
	.ioctl_index(ioctl_index),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	
	.uart_mode(16'b000_11111_000_11111),

	.sd_lba(sd_lba),
	.sd_rd(sd_rd),
	.sd_wr(sd_wr),
	.sd_ack(sd_ack),
	.sd_ack_conf(sd_ack_conf),
	.sd_buff_addr(sd_buff_addr),
	.sd_buff_dout(sd_buff_dout),
	.sd_buff_din(sd_buff_din),
	.sd_buff_wr(sd_buff_wr),
	.img_mounted(img_mounted),
	.img_readonly(img_readonly),
	.img_size(img_size),

	.joystick_0(joy1),
	.joystick_1(joy2),
	.joystick_analog_0({joy1_y,joy1_x}),
	.joystick_analog_1({joy2_y,joy2_x})
);

/////////////////  RESET  /////////////////////////

wire reset = RESET | status[0] | buttons[1] ;

////////////////  MEMORY  /////////////////////////

	
///////////////////////////////////////////////////
////////////////  VIDEO  /////////////////////////


///////////////////////////////////////////////////

//wire UART_RXD, UART_TXD;
wire [15:0] leds;
wire [7:0] seg1,seg2;
wire txd,rxd;
assign rxd = txd;

wire       press = ps2_key[9];
wire [7:0] code    = ps2_key[7:0];

assign ps2.clk = ps2_clk;
assign ps2.data = ps2_data;

FpgaVirtualConsole FpgaVirtualConsole
(
	.clk200M(clk_200),
	.clk100M(clk_sys),
	.clk50M(clk_50),
	.clk25M(clk_25),
	.rst(reset),
	.buttons(buttons),
	.ps2,
	.uartRx(UART_RXD),
	.uartTx(UART_TXD),
	.vga,
//	.sramInterface,
//	.sramDatao,
//	.sramDatai,
//	.segment1(seg1),
//	.segment2(seg2),
//	.led(leds),
	.switch(show_vga)
	
);


wire [7:0] audio_snr, audio_snl ;



assign AUDIO_MIX = 0;
assign AUDIO_S = 0;
wire ce_vid = 1; 
wire hs, vs, de;
wire hblank, vblank, ce_pix;
wire [2:0] r,g,b;

assign r = vga.color.red;
assign g = vga.color.green;
assign b = vga.color.blue;
assign hs = vga.hSync;
assign vs = vga.vSync;
assign ce_pix = vga.outClock;
assign de = vga.de;


assign CLK_VIDEO = clk_25;
assign CE_PIXEL   = ce_vid;
assign VGA_R = {r,r,r[1:0]};
assign VGA_G = {g,g,g[1:0]};
assign VGA_B = {b,b,b[1:0]};
assign VGA_HS = ~hs;
assign VGA_VS = ~vs;
assign VGA_DE = de;
assign VGA_SL = 2'd0;


endmodule
