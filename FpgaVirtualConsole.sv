//`include "DataType.svh"
module FpgaVirtualConsole(
    // general signals
	 input                              clk200M,
    input                              clk100M,
	 input                              clk50M,
	 input                              clk25M,
    input                              rst,
    input  [4:0]                       buttons,
    // PS/2 receiver
    input  Ps2Signal_t                 ps2,
    // uart transceiver
    input                              uartRx,
    output reg                         uartTx,
    // vga output
    output VgaSignal_t                 vga,
    // sram read/write
//    output SramInterface_t             sramInterface,
//    input  [`SRAM_DATA_WIDTH - 1:0]    sramDatao,
//	 output [`SRAM_DATA_WIDTH - 1:0]    sramDatai,
    // debug output
//    output reg [7:0]                   segment1,
//    output reg [7:0]                   segment2,
//    output reg [15:0]                  led,
	 input 										switch
    );

    // synchronize reset signal
//    logic reset, preReset;

//    always_ff @(posedge clk100M) begin
//        preReset <= rst;
//        reset <= preReset;
//    end


    // debug probe
//    logic [127:0] debug;
    logic [70:0]  vt100_debug;
//	assign debug[102:32] = vt100_debug;

//    Probe debugProbe(
//		.probe(debug),
//		.source(0)
//    );
    

    // segments to show state
//    LedDecoder decoder_1(.hex(vt100_debug[19:16]), .segments(segment1));
//    LedDecoder decoder_2(.hex(vt100_debug[23:20]), .segments(segment2));


	 
	 
    // Phase-locked loops to generate clocks of different frequencies
//    logic clk50M, clk100M;
//    logic rstPll, rstPll_n;
//	assign rstPll = ~rstPll_n;

//    TopPll topPll(
 //       .areset(reset),
 //       .inclk0(clk),
 //       .c0(clk50M),
//        .c1(clk100M),
//        .locked(rstPll_n)
//    );


    // Keyboard to uart
    KeyboardController #(
        .ClkFrequency(100_000_000)
    ) keyboardController(
        .clk(clk100M),
		  .clk25M(clk25M),
        .rst(rst),
        .ps2,
        .uartTx
    );
        
    
    // uart to screen
    VideoController VideoController(
		  .clk200M,
        .clk100M,
        .clk50M,
		  .clk25M(clk25M),
        .rst(rst),
        .uartRx,
        .vga,
//        .sramInterface,
//        .sramDatai,
//		  .sramDatao,
        .debug(vt100_debug),
		  .switch
    );



endmodule
