library ieee;
	use ieee.std_logic_1164.all;
-- use IEEE.STD_LOGIC_ARITH.all; 
	use IEEE.NUMERIC_STD.all;
	use IEEE.STD_LOGIC_UNSIGNED.all;

entity vga_textmode is
  port(
    n_reset  : in std_logic;
	 
    pixelClk : in std_logic;            -- pixel clock (25MHz)

    disp_enable : in std_logic;

    column      : in std_logic_vector(6 downto 0);
    row         : in std_logic_vector(5 downto 0);

    frame_start : in std_logic;
    row_start   : in std_logic;

    display_mem_addr : out std_logic_vector(5 downto 0);

    display_mem_data : in  std_logic_vector(2559 downto 0);

    videoR : out std_logic_vector(3 downto 0);
    videoG : out std_logic_vector(3 downto 0);
    videoB : out std_logic_vector(3 downto 0)
    );
end vga_textmode;

architecture vga_textmode_arch of vga_textmode is
--  signal ch_row : std_logic_vector(5 downto 0) := "000000";
--  signal ch_col : std_logic_vector(6 downto 0) := "0000000";
  signal vid_row : std_logic_vector(5 downto 0) := "000000";
  signal vid_col : std_logic_vector(6 downto 0) := "0000000";
--  signal ch_val : std_logic_vector(11 downto 0) := "000000000000";

  signal chardata_row : std_logic_vector(95 downto 0) ;

  signal shift_load : std_logic := '0';

  signal flash_flag        : std_logic := '0';
  signal cursor_flash_flag : std_logic := '0';
  signal jiffy_counter     : integer   := 0;
  signal curs_enable     	: std_logic := '0';

  signal pix_counter : std_logic_vector(2 downto 0) := "000";
  signal pix_line 	 : std_logic_vector(3 downto 0) := "0000";
  signal pix_clear   : std_logic                    := '0';
  signal pix_wrap    : std_logic                    := '0';
  signal pix_r_wrap    : std_logic                    := '0';
  signal pix_l_wrap : std_logic := '0';


  signal pixel : std_logic := '0';

--  signal attr_fg    : std_logic_vector(3 downto 0) := "1111";
--  signal attr_bg    : std_logic_vector(3 downto 0) := "0000";  -- high bit will always be 0 (only 3 stored in display attr byte)
--  signal attr_flash : std_logic                    := '0';

  signal next_attr_fg    : std_logic_vector(3 downto 0) := "1111";
  signal next_attr_bg    : std_logic_vector(3 downto 0) := "0000";  -- high bit will always be 0 (only 3 stored in display attr byte)
  signal next_attr_flash : std_logic                    := '0';

  signal selector_bg_in : std_logic_vector(5 downto 0);
  signal selector_fg_in : std_logic_vector(5 downto 0);

  signal display_mem_addr_tmp : std_logic_vector(15 downto 0);

  signal dispram_attrbyte  : std_logic_vector(7 downto 0);
  signal dispram_codepoint : std_logic_vector(7 downto 0);
  signal next_char  : std_logic_vector(7 downto 0);
  signal next_attr  : std_logic_vector(7 downto 0);
  signal str			: integer;
  signal fin			: integer;

begin

	display_mem_addr  <= vid_row;
	dispram_codepoint <= display_mem_data(str) & display_mem_data(str-1) & display_mem_data(str-2) & display_mem_data(str-3) & display_mem_data(str-4) & display_mem_data(str-5) & display_mem_data(str-6) & display_mem_data(str-7) ;
   dispram_attrbyte  <= "00000111"; -- display_mem_data(7 downto 0);
	str <= 7 + (to_integer(unsigned(vid_col)) * 32);
	fin <= 31 + (to_integer(unsigned(vid_col)) * 32);
	pix_clear    <= frame_start or row_start;
	pixel <= chardata_row(95 - (to_integer(unsigned(pix_line)) * 8 + to_integer(unsigned(pix_counter))));

	next_attr_fg    <= dispram_attrbyte(3 downto 0);
	next_attr_bg    <= '0' & dispram_attrbyte(6 downto 4);
	next_attr_flash <= dispram_attrbyte(7);
		
-- 4 video counters		
  vid_l_cnt_inst : entity work.mod_m_counter
    generic map(N => 4, M => 11)
    port map(
		rst	=> n_reset,
		q     => pix_line,
		wrap  => pix_r_wrap,
		clear => frame_start,
      clock => pix_l_wrap
      );	  
		
  vid_r_cnt_inst : entity work.mod_m_counter
    generic map(N => 6, M => 39)
    port map(
		rst	=> n_reset,
		q     => vid_row,
		wrap  => open,
		clear => frame_start,
      clock => pix_r_wrap
      );			
	  
  vid_p_cnt_inst : entity work.mod_m_counter
    generic map(N => 3, M => 7)
    port map(
		rst	=> n_reset,
		q     => pix_counter,
		wrap  => pix_wrap,
		clear => pix_clear,
      clock => pixelClk and disp_enable
      );

  vid_c_cnt_inst : entity work.mod_m_counter
    generic map(N => 7, M => 79)
    port map(
		rst	=> n_reset,
		q     => vid_col,
		wrap  => pix_l_wrap,
		clear => pix_clear,
      clock => pix_wrap or row_start
      );

  palette_selector_inst : entity work.attr_selector
    port map(
      fg          => selector_fg_in,
      bg          => selector_bg_in,
      flashing    => next_attr_flash,
      clock       => pixelClk,
      flashclk    => flash_flag,
		cursclk		=> cursor_flash_flag,
      load        => shift_load,
      curs_enable => curs_enable,
      outR        => videoR,
      outG        => videoG,
      outB        => videoB,
      input       => pixel
      );

  fg_palette_inst : entity work.COLOUR_ROM
    port map(
      A => next_attr_fg,
      D => selector_fg_in
      );


  bg_palette_inst : entity work.COLOUR_ROM
    port map(
      A => next_attr_bg,
      D => selector_bg_in
      );

  font_rom_inst : entity work.font_rom
    port map(
      clock   => pixelClk,
      address => dispram_codepoint,
      q       => chardata_row
      );
	  
  process (pix_counter,vid_row,vid_col,pix_line)
  begin
	 if (vid_row = row and vid_col = column and pix_line = "1011") then
		curs_enable <= '1';
	 else
		curs_enable <= '0';
	 end if;
    if (pix_counter = "001") then 
      shift_load <= '1';
    else
      shift_load <= '0';
    end if;
  end process;

  process(frame_start)
  begin
    if(rising_edge(frame_start)) then
      jiffy_counter <= jiffy_counter + 1;
      if (jiffy_counter mod 16 = 0) then
        flash_flag <= not flash_flag;
      end if;
      if (jiffy_counter mod 12 = 0) then
        cursor_flash_flag <= not cursor_flash_flag;
      end if;
    end if;
  end process;

end vga_textmode_arch;
