
library ieee;
	use ieee.std_logic_1164.all;
-- use IEEE.STD_LOGIC_ARITH.all; 
	use IEEE.NUMERIC_STD.all;
	use IEEE.STD_LOGIC_UNSIGNED.all;

entity vga_controller is
  generic(
    h_pulse      : integer   := 96;
    h_backporch  : integer   := 48;
    h_pixels     : integer   := 640;
    h_frontporch : integer   := 16;
	 h_limit			: integer := 642;
    h_syncpol    : std_logic := '1';

    v_pulse      : integer   := 2;
    v_backporch  : integer   := 33;
    v_pixels     : integer   := 480;
    v_frontporch : integer   := 10;
	 v_limit			: integer := 480;
    v_syncpol    : std_logic := '1'
    );
  port(
    reset  : in std_logic;
    clk : in std_logic; 	
    hSync : out std_logic;
    vSync : out std_logic;
	 hblank : out std_logic;
	 vblank : out std_logic;
    vid_addr_o : out std_logic_vector(18 downto 0);
    vid_dato : in  std_logic_vector(8 downto 0);
    videoR : out std_logic_vector(2 downto 0);
    videoG : out std_logic_vector(2 downto 0);
    videoB : out std_logic_vector(2 downto 0)
    );

end vga_controller;

architecture behavior of vga_controller is
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
  
begin

  
  process(clk,reset,counter)
--    variable column : integer;
--    variable ccolumn : integer;
--    variable row : integer;
--    variable crow : integer;
  begin

		if(reset = '1') then
--			column  := 0;
--			ccolumn := 0;
--			row     := 0;
--			crow    := 0;	
			h_count := 796;
			v_count := 478;
		elsif (rising_edge(clk)) then
				if(h_count < horiz_period ) then
					h_count := h_count + 1;
				else
					h_count := 0;
					if(v_count < vert_period ) then
						v_count := v_count + 1;
					else
						v_count := 0;
					end if;
				end if;
				if (h_count = 796) then
					hd_count := 0;
					if (v_count = 479) then
						vd_count := 0;
					else
						vd_count := v_count + 1;
					end if;
				elsif (h_count = 797) then
					hd_count := 1;
					if (v_count = 479) then
						vd_count := 0;
					else
						vd_count := v_count + 1;
					end if;
				elsif (h_count = 798) then
					hd_count := 2;
					if (v_count = 479) then
						vd_count := 0;
					else
						vd_count := v_count + 1;
					end if;
				elsif (h_count = 799) then
					hd_count := 3;
					if (v_count = 479) then
						vd_count := 0;
					else
						vd_count := v_count + 1;
					end if;
				else
					hd_count := h_count +4;
					vd_count := v_count;
				end if;
					
				vid_addr_o <= std_logic_vector(to_unsigned(vd_count *640  + hd_count,19));
				if(h_count < h_pixels + h_frontporch or h_count > h_pixels + h_frontporch + h_pulse) then
					hSync <= not h_syncpol;
				else
					hSync <= h_syncpol;
				end if;

				if(v_count < v_pixels + v_frontporch or v_count > v_pixels + v_frontporch + v_pulse) then
					vSync <= not v_syncpol;
				else
					vSync <= v_syncpol;
				end if;

				if( h_count >= h_pixels) then
					hblank <= '1';
				else
					hblank <= '0';
				end if;		
		
				if(v_count >= v_pixels) then
					vblank <= '1';
				else
					vblank <= '0';
				end if;	

				if(h_count < h_pixels and v_count < v_pixels) then
--					vid_addr_o <= std_logic_vector(to_unsigned(v_count *640  + h_count,19));
					result <= vid_dato;

					videoR <= result(8 downto 6) ;
					videoG <= result(5 downto 3) ;
					videoB <= result(2 downto 0) ;

				end if;
		end if;
  end process;

end behavior;
