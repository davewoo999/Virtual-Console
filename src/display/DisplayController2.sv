//`include "DataType.svh"
module DisplayController2 (
    input                               clk,
    input                               rst,
    input                               blinkStatus,
    input   Cursor_t                    cursor,
    input   TextRamResult_t             textRamResult,  // textRamResult.data is [2559:0]
    output  TextRamRequest_t            textRamRequest, // textRamRequest.address [5:0] textRamRequest.data [2559:0] textRamRequest.wren 
    output  SramInterface_t             sramInterface,
    input   [`SRAM_DATA_WIDTH - 1:0]    sramDatao,
	 output  [`SRAM_DATA_WIDTH - 1:0]    sramDatai,
    output  VgaSignal_t                 vga    // vga.hSync vga.vSync vga.color.red [2:0] vga.color.green [2:0] vga.color.blue [1:0] 
    );														// vga.outClock vga.hblank vga.vblank

	 wire reset_n = ~rst;
	 wire dot,frame_start,row_start,mem_fstart,mem_rstart,display_enable,mem_enable;
	 wire [5:0] mem_addr;
	 wire [3:0] videoR,videoG,videoB;
	 
	 assign vga.color.red = videoR[3:1];
	 assign vga.color.green = videoG[3:1];
	 assign vga.color.blue = videoB[3:2];
	 	 
  vga_controller vga_controller
	(
      .n_reset     ( reset_n),
      .pixelClk    ( clk),
		.dot				( dot),
      .hSync       ( vga.hSync),
      .vSync       ( vga.vSync),
		.hblank		( vga.hblank),
		.vblank		( vga.vblank),
      .frame_start ( frame_start),
      .row_start   ( row_start),
		.mem_fstart   ( mem_fstart),
		.mem_rstart   ( mem_rstart),
      .disp_enable ( display_enable),
		.mem_enable       ( mem_enable)
//      row         => row,
//      column      => col
      );
		
		assign textRamRequest = mem_addr & textRamResult & 1'b0 ;
				
	  vga_textmode vga_textmode
     (
      .n_reset          ( reset_n),
      .pixelClk         ( clk),
      .row              ( cursor.y[5:0]),
      .column           ( cursor.x[6:0]),
      .disp_enable      ( display_enable),
		.mem_enable       ( mem_enable),
      .frame_start      ( frame_start),
      .row_start        ( row_start),
		.mem_fstart   	  ( mem_fstart),
		.mem_rstart   	  ( mem_rstart),
      .display_mem_addr ( mem_addr),

      .display_mem_data ( textRamResult),

      .videoR           ( videoR),
      .videoG           ( videoG),
      .videoB           ( videoB)
      );
		

endmodule // DisplayController2