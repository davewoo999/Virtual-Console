// user-defined data structures
`ifndef DATATYPE_SVH
`define DATATYPE_SVH

// avoid typos
`default_nettype none

// constants
`define BAUD_RATE 115200
//`define BAUD_RATE 3_000_000  // 3M Baud, not standard
`define BOARD_CLOCK_FRENQUENCY 100_000_000
`define CURSOR_BLINKING_FREQ  2

`define TEXT_RAM_ADDRESS_WIDTH 6
`define TEXT_RAM_CHAR_WIDTH 32
`define TEXT_RAM_LINE_WIDTH (`TEXT_RAM_CHAR_WIDTH * `CONSOLE_COLUMNS)
`define TEXT_RAM_DATA_WIDTH `TEXT_RAM_LINE_WIDTH

`define DEFAULT_BG 9'b000_000_000
`define DEFAULT_FG 9'b110_110_110
`define EMPTY_DATA { 4'b0, `DEFAULT_BG, `DEFAULT_FG, 2'b00, 8'h20 }

/*
  [K][N][B][U][  BG  ][  FG  ][ CS ][ ASCII ]
   31 30 29 28      19      10     8        0
 
  K: Blink
  N: Negative   ( swaps bg and fg )
  B: Bright     ( applies brightness/intensity flag to fg )
  U: Underline
  BG: Background color ( RGB333 )
  FG: Foreground color ( RGB333 )
  CS: Charset 
 */
`define CHAR_ASCII_OFFSET 0
`define CHAR_ASCII_LENGTH 10
`define CHAR_FOREGROUND_OFFSET (`CHAR_ASCII_OFFSET + `CHAR_ASCII_LENGTH)
`define CHAR_FOREGROUND_LENGTH 9
`define CHAR_BACKGROUND_OFFSET (`CHAR_FOREGROUND_OFFSET + `CHAR_FOREGROUND_LENGTH)
`define CHAR_BACKGROUND_LENGTH 9
`define CHAR_EFFECT_OFFSET (`CHAR_BACKGROUND_OFFSET + `CHAR_BACKGROUND_LENGTH)
`define CHAR_EFFECT_LENGTH $bits(CharEffect_t)

`define FONT_ROM_ADDRESS_WIDTH 10
`define FONT_ROM_DATA_WIDTH 96

`define SRAM_ADDRESS_WIDTH 18
`define SRAM_DATA_WIDTH 9

`define COLOR_NUMBERS_BITS 3
`define CONSOLE_LINES 40
`define CONSOLE_COLUMNS 80
`define HEIGHT_PER_CHARACTER 12
`define WIDTH_PER_CHARACTER 8
`define PIXEL_PER_CHARACTER `HEIGHT_PER_CHARACTER * `WIDTH_PER_CHARACTER

`define VIDEO_BUFFER_SIZE (640 * 480)

`define UART_DATA_WIDTH 8
`define UART_FIFO_LENGTH 8
`define UART_FIFO_WIDTH (`UART_DATA_WIDTH * `UART_FIFO_LENGTH)

// uart transmission
typedef logic [`UART_DATA_WIDTH - 1:0] UartData_t;
typedef UartData_t                     Scancode_t;

typedef struct packed {
	UartData_t length;
	UartData_t char7;
	UartData_t char6;
	UartData_t char5;
	UartData_t char4;
	UartData_t char3;
	UartData_t char2;
	UartData_t char1;
} UartFifoData_t;


// PS2 signal
typedef struct packed {
	logic clk;
	logic data;
} Ps2Signal_t;


// vga signal
typedef struct packed {
    logic [2:0]  red;
    logic [2:0]  green;
    logic [2:0]  blue;
} VgaColor_t;

typedef struct packed {
    logic        hSync;
    logic        vSync;
    VgaColor_t   color;
    logic        Spare;
    logic        de;
} VgaSignal_t;


// text ram read/write
typedef logic [`TEXT_RAM_DATA_WIDTH - 1:0]    TextRamData_t;
typedef logic [`TEXT_RAM_ADDRESS_WIDTH - 1:0] TextRamAddress_t;

typedef struct packed {
	TextRamAddress_t address;
	TextRamData_t    data;
	logic	         wren;
} TextRamRequest_t;

typedef TextRamData_t TextRamResult_t;


// font rom read
typedef logic [`FONT_ROM_DATA_WIDTH - 1:0]    FontRomData_t;
typedef logic [`FONT_ROM_ADDRESS_WIDTH - 1:0] FontRomAddress_t;


// sram read/write
typedef logic [`SRAM_ADDRESS_WIDTH - 1:0] SramAddress_t;
typedef logic [`SRAM_DATA_WIDTH - 1:0] SramData_t;

typedef struct packed {
    SramAddress_t   address;
    logic           cs;
    logic           oe_n;
    logic           we_n;
} SramInterface_t;

typedef struct packed {
    SramData_t      dout;
    logic           den;
    SramAddress_t 	address;
    logic           oe_n;
    logic           we_n;
} SramRequest_t;

typedef struct packed {
    SramData_t 	din;
    logic       done;
} SramResult_t;


// char on screen
typedef struct packed {
	logic [$bits(SramData_t) - 2 * $bits(VgaColor_t) - 1:0] placeholder;
	VgaColor_t                                              pixelOdd;
    VgaColor_t                                              pixelEven;
} Pixel_t;

typedef struct packed {
    logic   [`PIXEL_PER_CHARACTER - 1:0] shape;
    VgaColor_t                           foreground;
    VgaColor_t                           background;
} CharGrid_t;


// parser states
typedef enum logic[7:0] {
	START, ESC, CSI, PN1, PN2, DEL1, DEL2, PNS,
	RBRACKET, LBRACKET, QUES, QPN1, QDEL1, QPNS, TRAP
} CommandsState;

typedef enum logic[7:0] {
	/* Character Input */
	INPUT,
	/* Cursor Commands */
	CUP, CUU, CUD, CUF, CUB, IND,
	CNL, CPL, CHA, VPA,
	NEL, RI, DECSC, DECRC,
	/* Scrolling */
	DECSTBM, SU, SD,
	/* Editing */
	ED, EL, ICH, DCH, ECH, IL, DL, REP,
	/* Charset */
	SCS0, SCS1, SS2, SS3,
	/* Mode */
	SETMODE, RESETMODE,
	SETDEC, RESETDEC,
	/* Graphics */
	SGR0, SGR,
	/* Multi-param */
	EMIT_PN, INIT_PN,
	/* Tab Stop */
	TBC, HTS
} CommandsType;


// cursor status
typedef struct packed {
	// cursor visiblity
	logic visible;
	// cursor position, starts from 0
	logic [7:0] x, y;
} Cursor_t;

typedef struct packed {
	logic blink, negative, bright, underline;
} CharEffect_t;

typedef struct packed {
	logic [8:0]  fg, bg;
	CharEffect_t effect;
} Graphics_t;

typedef struct packed {
	logic origin_mode, auto_wrap, insert_mode, line_feed;
	logic cursor_blinking, cursor_visibility;
} TermMode_t;

typedef struct packed {
	logic [1:0] charset;
	logic [7:0] scroll_top, scroll_bottom;
} TermAttrib_t;

// terminal status
typedef struct packed {
	Cursor_t      cursor;
	Graphics_t    graphics;
	TermMode_t    mode;
	TermAttrib_t  attrib;
	logic [31:0]  prev_data;
} Terminal_t;

typedef struct packed {
	logic [7:0] Pchar;
	logic [7:0] Pn1, Pn2, Pns;
} Param_t;

typedef struct packed {
	logic       reset;
	logic       dir;   // 0 - scroll down, 1 - scroll up
	logic [7:0] step, top, bottom;
} Scrolling_t;

`endif
