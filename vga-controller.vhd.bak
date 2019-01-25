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
	 h_limit			: integer := 640;
    h_syncpol    : std_logic := '1';

    v_pulse      : integer   := 2;
    v_backporch  : integer   := 33;
    v_pixels     : integer   := 480;
    v_frontporch : integer   := 10;
	 v_limit			: integer := 480;
    v_syncpol    : std_logic := '1'
    );
  port(
    n_reset  : in std_logic;
    clk : in std_logic;            --  clock (100MHz)		
	 cursor_y : in std_logic_vector(5 downto 0);
	 cursor_x : in std_logic_vector(6 downto 0);
    hSync : out std_logic;
    vSync : out std_logic;
	 hblank : out std_logic;
	 vblank : out std_logic;
    display_mem_addr : out std_logic_vector(5 downto 0);
    display_mem_data : in  std_logic_vector(2559 downto 0);
    videoR : out std_logic_vector(3 downto 0);
    videoG : out std_logic_vector(3 downto 0);
    videoB : out std_logic_vector(3 downto 0)
    );

end vga_controller;

architecture behavior of vga_controller is
  constant horiz_period : integer := h_pulse + h_pixels + h_backporch + h_frontporch;
  constant vert_period  : integer := v_pulse + v_pixels + v_backporch + v_frontporch;
  signal char_addr  : std_logic_vector(7 downto 0);
  signal char_attr  : std_logic_vector(23 downto 0);
  signal char_data : std_logic_vector(95 downto 0) ;
  signal pixel :std_logic;
  signal flash_flag        : std_logic := '0';
  signal cursor_flash_flag : std_logic := '0';
  signal flash_counter     : integer   := 0;
  signal curs_enable :std_logic;
  signal frame_start :std_logic;
  signal attr_set		:std_logic_vector(1 downto 0);
  signal attr_fg    : std_logic_vector(8 downto 0) := "111111111";
  signal attr_bg    : std_logic_vector(8 downto 0) := "000000000";  -- high bit will always be 0 (only 3 stored in display attr byte)
  signal attr_flash : std_logic                    := '0';
  signal colour_bg : std_logic_vector(5 downto 0);
  signal colour_fg : std_logic_vector(5 downto 0);
  signal result      : std_logic_vector(8 downto 0);
  signal counter      : std_logic_vector(1 downto 0) := "11";
  signal disp_enable :std_logic;
  shared variable h_count : integer range 0 to horiz_period := 0;
  shared variable v_count : integer range 0 to vert_period  := 0;
  signal pixelclk :std_logic := '0';
  signal str			: integer;
  signal mid			: integer;
  
begin

	process (counter,clk)
	begin
	if(n_reset = '0') then
		counter <= "11";
		
    elsif(rising_edge(clk)) then
		counter <= counter + '1';
		if (counter = "00") then 
			pixelclk <= '1';
		else 
			pixelclk <= '0';
		end if;
	end if;
	
	end process;
  
  process(clk)
    variable column : integer;
    variable ccolumn : integer;
    variable row : integer;
    variable crow : integer;
  begin

		if(n_reset = '0') then
			column  := 0;
			ccolumn := 0;
			row     := 0;
			crow    := 0;		
		elsif (h_count < h_pixels and v_count < v_pixels) then
			if counter = "00" then
				column := (h_count / 8);
				ccolumn := (h_count mod 8);
				row := (v_count / 12);
				crow := (v_count mod 12);
				display_mem_addr  <= std_logic_vector(to_unsigned(row,6));
				if (to_integer(unsigned(cursor_y)) = row and to_integer(unsigned(cursor_x)) = column and crow = 11) then
					curs_enable <= '1';
				else
					curs_enable <= '0';
				end if;
			end if;
			if counter = "10" then
				str <= 7 + (column * 32);
				mid <= 31 + (column * 32);
				char_addr <= display_mem_data(str) & display_mem_data(str-1) & display_mem_data(str-2) & display_mem_data(str-3) & display_mem_data(str-4) & display_mem_data(str-5) & display_mem_data(str-6) & display_mem_data(str-7) ;
				char_attr <= display_mem_data(mid) & display_mem_data(mid-1) & display_mem_data(mid-2) & display_mem_data(mid-3) & display_mem_data(mid-4) & display_mem_data(mid-5) & display_mem_data(mid-6) & display_mem_data(mid-7) & display_mem_data(mid-8) & display_mem_data(mid-9) & display_mem_data(mid-10) & display_mem_data(mid-11) & display_mem_data(mid-12) & display_mem_data(mid-13) & display_mem_data(mid-14) & display_mem_data(mid-15) & display_mem_data(mid-16) & display_mem_data(mid-17) & display_mem_data(mid-18) & display_mem_data(mid-19) & display_mem_data(mid-20) & display_mem_data(mid-21) & display_mem_data(mid-22) & display_mem_data(mid-23);
			end if;
			if counter = "11" then
				pixel <= char_data(95 - (crow * 8 + ccolumn));
				attr_set    <= char_attr(1 downto 0);
				attr_fg    <= char_attr(10 downto 2);
				attr_bg    <= char_attr(19 downto 11);
				
				attr_flash <= char_attr(23);
				if (curs_enable = '1' and cursor_flash_flag = '1') then
					result <= "111111111";
				else
					if (pixel = '0' or (flash_flag and attr_flash) = '1') then
						result <= attr_bg;
					else
						result <= attr_fg;
					end if;
				end if;			
				videoR <= result(8 downto 6) & "0";
				videoG <= result(5 downto 3) & "0";
				videoB <= result(2 downto 0) & "0";
			end if;
		end if;
  end process;

  process(pixelClk, n_reset)


  begin

    if(n_reset = '0') then
      h_count := horiz_period;
      v_count := vert_period;
      hSync <= not h_syncpol;
      vSync <= not v_syncpol;
      disp_enable <= '0';
    elsif(rising_edge(pixelClk)) then
	 
      -- handle coordinate counters
      if(h_count < horiz_period) then
        h_count := h_count + 1;
      else
        h_count := 0;
        if(v_count < vert_period) then
          v_count := v_count + 1;
        else
          v_count := 0;
        end if;
      end if;

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

      if(h_count < h_pixels and v_count < v_pixels) then
        disp_enable <= '1';

        if (h_count = 0 and v_count = 0) then
          frame_start <= '1';
        else
          frame_start <= '0';
        end if;

--        if (h_count = 0) then
--          row_start <= '1';
 --       else
 --         row_start <= '0';
 --       end if;	  
      else
        disp_enable <= '0';
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
		

    end if;

  end process;
  
  process(frame_start)
  begin
    if(rising_edge(frame_start)) then
      flash_counter <= flash_counter + 1;
      if (flash_counter mod 16 = 0) then
        flash_flag <= not flash_flag;
      end if;
      if (flash_counter mod 12 = 0) then
        cursor_flash_flag <= not cursor_flash_flag;
      end if;
    end if;
  end process;
  
--  fg_palette_inst : entity work.COLOUR_ROM
--    port map(
--      A => attr_fg,
--      D => colour_fg
--      );


--  bg_palette_inst : entity work.COLOUR_ROM
--    port map(
--      A => attr_bg,
 --     D => colour_bg
 --     );
  
  font_rom_inst : entity work.font_rom
    port map(
      clock   => pixelClk,
      address => char_addr,
      q       => char_data
      );

end behavior;
