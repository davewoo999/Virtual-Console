`include "DataType.svh"
module VideoController(
	 input                               clk200M,
    input                               clk100M,
    input                               clk50M,
	 input                               clk25M,
    input                               rst,
    input                               uartRx,
    output  VgaSignal_t                 vga,					// hsync,vsync,3 red 3 green 3 blue, outclock, de
    // sram read/write
//    output  SramInterface_t             sramInterface,	// [17:0] address,cs oe_n, we_n
//    input   [`SRAM_DATA_WIDTH - 1:0]    sramDatao,			// [7:0]
//	 output  [`SRAM_DATA_WIDTH - 1:0]    sramDatai,			// [7:0]
    // debug
    output  logic[70:0]                 debug,
	 input										switch
    );

        // UART Receiver
    logic         uartReady;
    logic [7:0]   uartDataReceived;

    AsyncUartReceiver #(
        .ClkFrequency(100_000_000),
        .Baud(`BAUD_RATE)
    ) 
	 uartReceiver(
        .clk(clk100M),
        .RxD(uartRx),
        .RxD_data_ready(uartReady),
        .RxD_data(uartDataReceived)
    );


    // Global blink generator module
    logic blinkStatus;

    BlinkGenerator #(
        .ClkFrequency(100_000_000)
    ) blink(
        .clk(clk100M),
		.sync_reset(1'b0),
        .status(blinkStatus)
    );


	// VT100 parser module
    logic [70:0] vt100_debug;
    assign debug = vt100_debug;
    Cursor_t cursor;

	VT100Parser vt100Parser(
        .clk(clk100M),
        .rst,
        .dataReady(uartReady),				// 1
        .data(uartDataReceived),				// 8
        .ramRes(textRamResultParser),		// 32
        .ramReq(textRamRequestParser),		// [5:0] [2559:0] 1
        .debug(vt100_debug),
        .cursorInfo(cursor)
    );


    // Text RAM module
    TextRamRequest_t textRamRequestParser, textRamRequestRenderer;
    TextRamResult_t textRamResultParser, textRamResultRenderer;

    TextRam textRam(
        .aclr_a(rst),
        .aclr_b(rst),
        .address_a(textRamRequestParser.address),
        .address_b(textRamRequestRenderer.address),
        .clock_a(clk100M),
        .clock_b(clk200M),
        .data_a(textRamRequestParser.data),
        .data_b(textRamRequestRenderer.data),
        .wren_a(textRamRequestParser.wren),
        .wren_b(textRamRequestRenderer.wren),
        .q_a(textRamResultParser),
        .q_b(textRamResultRenderer)
    );


    // Video controller module
    DisplayController controller(
        .clk(clk200M),
        .rst,
        .blinkStatus,
        .cursor,
        .textRamResult(textRamResultRenderer),
        .textRamRequest(textRamRequestRenderer),
//        .sramInterface,
//        .sramDatai,
//		  .sramDatao,
        .vga,
		  .switch
    );

endmodule
