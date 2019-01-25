//`include "DataType.svh"

module DisplayController (
    input                               clk,
    input                               rst,
    input                               blinkStatus,
    input   Cursor_t                    cursor,
    input   TextRamResult_t             textRamResult,
    output  TextRamRequest_t            textRamRequest,
//    output  SramInterface_t             sramInterface,
//    input   [`SRAM_DATA_WIDTH - 1:0]    sramDatao,
//	 output  [`SRAM_DATA_WIDTH - 1:0]    sramDatai,
    output  VgaSignal_t                 vga,
	 input										switch
    );
	 
	 VgaSignal_t                 o_vga,n_vga;
	 TextRamRequest_t lost;
//	 wire reset_n = ~rst;
	 wire dot,frame_start,row_start,display_enable,text_wren,hblank,vblank;
	 wire [5:0] mem_addr,text_addr;
	 wire [2559:0] mem_data, text_data;
	 wire [3:0] videoR,videoG,videoB;
	 
	 assign n_vga.color.red = videoR[3:1];
	 assign n_vga.color.green = videoG[3:1];
	 assign n_vga.color.blue = videoB[3:1];	 
	 assign n_vga.de = ~(hblank | vblank);
	 
	 assign vga = switch ? o_vga  : n_vga; 
/*
    // Sram controller module
    SramRequest_t vgaRequest, rendererRequest;
    SramResult_t vgaResult, rendererResult;
    logic paintDone;
    SramAddress_t vgaBaseAddress;

    SramController sramController(
        .clk,
        .rst,
        .sramInterface,
        .sramDatai,
		  .sramDatao,
        .vgaRequest,
        .vgaResult,
        .rendererRequest,
        .rendererResult
    );


    // Font ROM module
    FontRomData_t fontRomData;
    FontRomAddress_t fontRomAddress;

    FontRom fontRom(
        .aclr(rst),
        .address(fontRomAddress),
        .clock(clk),
        .q(fontRomData)
    );


    // synchronize signals from other clock domain
    logic blinkStatusReg1, blinkStatusReg2;
    Cursor_t cursorReg1, cursorReg2;

    always_ff @(posedge clk) begin
        cursorReg1 <= cursor;
        cursorReg2 <= cursorReg1;
        blinkStatusReg1 <= blinkStatus;
        blinkStatusReg2 <= blinkStatusReg1;
    end

    // Renderer module
    TextRenderer renderer(
        .clk,
        .rst(rst),
        .paintDone,
        .ramRequest(rendererRequest),
        .ramResult(rendererResult),
        .vgaBaseAddress,
        .textRamRequest(lost),
        .textRamResult(text_data),
        .fontRomAddress,
        .fontRomData,
        .cursor(cursorReg2),
        .blinkStatus(blinkStatusReg2)
    );
*/	 
			assign textRamRequest.address = text_addr; //textRamRequest.address;
			assign text_data = textRamResult;
			assign textRamRequest.wren = 1'b0;
/*			

	     Textvga textvga(
        .aclr_a(rst),
        .aclr_b(rst),
        .address_a(text_addr),
        .address_b(mem_addr),
        .clock_a(clk),
        .clock_b(clk),
        .data_a(text_data),
        .data_b(0),
        .wren_a(text_wren),
        .wren_b(1'b0),
        .q_a(),
        .q_b(mem_data)
    );
*/	 
	   vga_controller vga_controller
	(
      .reset     ( rst),
      .clk    ( clk),

      .hSync       ( n_vga.hSync),
      .vSync       ( n_vga.vSync),
		.hblank		( hblank),
		.vblank		( vblank),
		.display_mem_addr (text_addr),

      .display_mem_data (textRamResult),
      .cursor_y             ( cursor.x[5:0]),
      .cursor_x           ( cursor.y[6:0]),
		.videoR           ( videoR),
      .videoG           ( videoG),
      .videoB           ( videoB)
      );
		

/*				
	  vga_textmode vga_textmode
     (
      .n_reset          ( reset_n),
      .pixelClk         ( clk),
      .row              ( cursor.x[5:0]),
      .column           ( cursor.y[6:0]),
      .disp_enable      ( display_enable),

      .frame_start      ( frame_start),
      .row_start        ( row_start),

      .display_mem_addr (text_addr),

      .display_mem_data (textRamResult),

      .videoR           ( videoR),
      .videoG           ( videoG),
      .videoB           ( videoB)
      );
	 
	
    // VGA module
    VgaDisplayAdapter display(
        .clk,
        .rst,
        .baseAddress(vgaBaseAddress),
        .ramRequest(vgaRequest),
        .ramResult(vgaResult),
        .vga(o_vga),
        .paintDone
    );
*/
endmodule // DisplayController