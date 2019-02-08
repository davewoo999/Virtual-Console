//`include "DataType.svh"

module DisplayController (
    input                               clk,
	 input                               fclk,
    input                               rst,
    input                               blinkStatus,
    input   Cursor_t                    cursor,
    input   TextRamResult_t             textRamResult,
    output  TextRamRequest_t            textRamRequest,
    output  [8:0]             			vid_dati,
    output  [18:0]    						vid_addr_o,
	 output  [18:0]    						vid_addr_i,
	 output      								vid_wr,
	 input  [8:0]             				vid_dato,
    output  VgaSignal_t                 vga,
	 input										cur_sw
    );
	 
	 VgaSignal_t                 n_vga;

	 wire hblank,vblank;
	 wire [5:0] text_addr;
	 wire [3:0] videoR,videoG,videoB;
	 assign n_vga.Spare = 1'b0;
	 assign n_vga.color.red = videoR[2:0];
	 assign n_vga.color.green = videoG[2:0];
	 assign n_vga.color.blue = videoB[2:0];	 
	 assign n_vga.de = ~(hblank | vblank);
	 
	 assign vga = n_vga; 
			assign textRamRequest.data = 32'b11111111111111111111111111111111;
			assign textRamRequest.address = text_addr;

			assign textRamRequest.wren = 1'b0;
	 
	   vga_controller vga_controller
	(
      .reset     ( rst),
      .clk    ( clk),

      .Hsync       ( n_vga.hSync),
      .Vsync       ( n_vga.vSync),
		.Hblank		( hblank),
		.Vblank		( vblank),
		.vid_addr_o (vid_addr_o),

      .vid_dato (vid_dato),

		.videoR           ( videoR),
      .videoG           ( videoG),
      .videoB           ( videoB)
      );
		
		vga_textmode vga_textmode
		(
      .reset     ( rst),
      .clk    ( clk),
//		.fclk (fclk),
      .cursor_y             ( cursor.x[5:0]),
      .cursor_x           ( cursor.y[6:0]),
		.char_addr(fontRomAddress),
		.char_data(fontRomData),
		.display_mem_addr (text_addr),
      .display_mem_data (textRamResult),
		.vid_dati           ( vid_dati),
      .vid_addr_i           ( vid_addr_i),
      .vid_wr           ( vid_wr),
		.cur_sw				(cur_sw)
		);
		
		    // Font ROM module
    FontRomData_t fontRomData;
    FontRomAddress_t fontRomAddress;

    FontRom fontRom(
        .aclr(rst),
        .address(fontRomAddress),
        .clock(fclk),
        .q(fontRomData)
    );
		

endmodule // DisplayController