// collects preformatted data containing attributes for flashing, underline, bright, negative, character set and ascii data.
// Data held in memory by screen lines (40) and rows (80) with 32 bits for each location.
// 9 bit pixel data (RGB333) is calculated and input to video memory (9 bits x 640 x 480)
// cursor data is used to highlight cursor location .
// Dave Wood (old_git 2019)

module vga_textmode (
	input wire reset,
	input wire clk,

	input 		[5:0]  	cursor_y,
	input 		[6:0]  	cursor_x,
	output reg 	[9:0] 	char_addr,
	input 		[95:0]   char_data,

	output 		[5:0]		display_mem_addr,
	input 		[2559:0]	display_mem_data,
	output reg  [8 :0] 	vid_dati,
	output reg  [18:0] 	vid_addr_i,
	output reg   			vid_wr,
	input reg 				cur_sw
);

reg [2:0] 	counter;
reg [10:0] 	h_count;
reg [9:0] 	v_count;
reg 			frame_start;
reg [6:0] 	column;
reg [3:0] 	crow;
reg [2:0] 	ccolumn;
reg [5:0] 	row;
reg 			curs_enable;
reg [11:0] 	str,mid;
reg [23:0] 	char_attr;
reg 			pixel;
reg [1:0]	attr_set;
reg [8:0] 	attr_fg, attr_bg, result;
reg 			attr_flash, attr_ul, attr_neg;
reg 			flash_flag, cursor_flash_flag;
reg [8:0] 	flash_counter;

always @(posedge clk) begin
	if(reset) begin
		counter <= 3'b000;
		column  <= 7'd0;
		ccolumn <= 3'd0;
		row     <= 6'd0;
		crow    <= 4'd0;
		h_count <= 11'd0;
		v_count <= 10'd0;
	end else begin
		counter <= counter + 1'b1;

		if(counter == 3'b001) begin
			if (h_count == 11'd0 && v_count == 10'd0)
				frame_start <= 1;
			else
				frame_start <= 0;
			
			column<= (h_count)/8;
			ccolumn <= (h_count)%8;
			row <= (v_count)/12;
			crow <= (v_count)%12;
		end
	
		if(counter == 3'b010) begin
			display_mem_addr <= row;
			if ((cursor_y == row) && (cursor_x == column)) begin
				if (cur_sw == 1'b1)
					curs_enable <= 1'b1;
				else if (crow == 4'd11)
					curs_enable <= 1'b1;
			end else
				curs_enable <= 1'b0;
			
			str <= 9 + (column * 32);
			mid <= 31 + (column *32);
		end
	
		if(counter == 3'b011) begin
			vid_addr_i <= v_count * 640 + h_count;
			char_addr <= display_mem_data[str-:10];
			char_attr <= display_mem_data[mid-:24];
		end
	
		if(counter == 3'b101) begin
			pixel 		<= char_data[95 - (crow *8 + ccolumn)];
			attr_set 	<= char_attr[1:0];
			attr_ul 		<= char_attr[20];
			attr_fg 		<= char_attr[10:2];
			attr_bg 		<= char_attr[19:11];
			attr_flash 	<= char_attr[23];
			attr_neg 	<= char_attr[22];
		
			if (((curs_enable == 1'b1) && (cursor_flash_flag == 1'b1)) || (( attr_ul == 1'b1) && (crow == 4'd11)))
				result <= 9'b000011011;
			else 
			if (attr_neg == 1'b1) begin
				if ( (pixel == 1'b0) || ((flash_flag & attr_flash) == 1'b1))
					result <= attr_fg;
				else
					result <= attr_bg;
			end else begin
				if ( (pixel == 1'b0) || ((flash_flag & attr_flash) == 1'b1))
					result <= attr_bg;
				else
					result <= attr_fg;
			end
		
			vid_dati <= result;
			vid_wr <= 1'b1 ;	
		end
	
		if(counter == 3'b110)
			vid_wr <= 1'b0;
		
		if(counter == 3'b111) begin
			if (h_count < 11'd639)
				h_count <= h_count + 11'd1;
			else begin
				h_count <= 11'd0;
				if (v_count < 10'd479)
					v_count <= v_count + 10'd1;
				else
					v_count <= 10'd0;
			end
		end
	end	
end		
		
always @(posedge frame_start) begin
	flash_counter <= flash_counter + 9'd1;
	if ( flash_counter %4 == 0)
		flash_flag <= ~flash_flag;
	if ( flash_counter %3 == 0)
		cursor_flash_flag <= ~cursor_flash_flag;
end

endmodule
