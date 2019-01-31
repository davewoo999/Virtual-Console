module vga_controller (
	input wire rst,
	input wire clk,

	output reg  	hSync,
	output reg  	vSync,
	output reg  	hblank,
	output reg  	vblank,
	output [18:0]	vid_addr_o,
	input [8:0]		vid_dato,
	output reg  [ 2 : 0 ] videoR,
	output reg  [ 2 : 0 ] videoG,
	output reg  [ 2 : 0 ] videoB
);

wire [7:0] 	char_addr;
wire [23:0]	char_attr;
wire [95:0]	char_data;



  constant horiz_period : integer := h_pulse + h_pixels + h_backporch + h_frontporch -1;
  constant vert_period  : integer := v_pulse + v_pixels + v_backporch + v_frontporch - 1;
  signal char_addr  : std_logic_vector(7 downto 0);
  signal char_attr  : std_logic_vector(23 downto 0);
  signal char_data : std_logic_vector(95 downto 0) ;
  signal pixel :std_logic;
  signal flash_flag        : std_logic := '0';
  signal cursor_flash_flag : std_logic := '0';
  signal flash_counter     : integer   := 0;
  signal curs_enable :std_logic;
--  signal frame_start :std_logic;
  signal attr_set		:std_logic_vector(1 downto 0);
  signal attr_fg    : std_logic_vector(8 downto 0) := "111111111";
  signal attr_bg    : std_logic_vector(8 downto 0) := "000000000";  -- high bit will always be 0 (only 3 stored in display attr byte)
  signal attr_flash : std_logic                    := '0';
  signal colour_bg : std_logic_vector(5 downto 0);
  signal colour_fg : std_logic_vector(5 downto 0);
  signal result      : std_logic_vector(8 downto 0);
  signal counter      : std_logic_vector(2 downto 0) := "111";
--  signal disp_enable :std_logic;
  shared variable h_count : integer range 0 to horiz_period := 796;
  shared variable v_count : integer range 0 to vert_period  := 478;
  shared variable hd_count : integer range 0 to horiz_period := 0;
  shared variable vd_count : integer range 0 to vert_period  := 0;
--  signal pixelclk :std_logic := '0';
  signal str			: integer;
  signal mid			: integer;