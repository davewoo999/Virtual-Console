// collects 9bit (RGB333) data from memory and uses this for diplaying a pixel on screen (640 x 480)
// Dave Wood (old_git) 2019

module vga_controller (
	input wire reset,
	input wire clk,

	output reg  		Hsync,
	output reg  		Vsync,
	output reg  		Hblank,
	output reg  		Vblank,
	output reg [18:0]	vid_addr_o,
	input 		[8:0]	vid_dato,
	output reg  [2:0] videoR,
	output reg  [2:0] videoG,
	output reg  [2:0] videoB
);

reg [8:0] 	result;
reg [10:0] 	h_count, hd_count;
reg [9:0] 	v_count, vd_count;

always @(posedge clk) begin
	if(reset) begin
		h_count <= 11'd793;
		v_count <= 10'd478;
	end else begin
// h & v pixel counters	
		if(h_count < 11'd799)
			h_count <= h_count + 1'd1;
		else begin
			h_count <= 11'd0;
			if(v_count < 10'd524)
				v_count <= v_count + 1'b1;
			else
				v_count <= 10'd0;
		end
	
// collect ram data early to take account of clock cycles needed to address and receive data.
		if(h_count == 11'd796) begin 
			hd_count <= 11'd0;
			if(v_count == 10'd479)
				vd_count <= 10'd0;
			else
				vd_count <= v_count + 1'b1;
		end else if(h_count == 11'd797) begin  
			hd_count <= 11'd1;
			if(v_count == 10'd479)
				vd_count <= 10'd0;
			else
				vd_count <= v_count + 1'b1; 
		end else if(h_count == 11'd798) begin
			hd_count <= 11'd2;
			if(v_count == 10'd479)
				vd_count <= 10'd0;
			else
				vd_count <= v_count + 1'b1;
		end else if(h_count == 11'd799) begin
			hd_count <= 11'd3;
			if(v_count == 10'd479)
				vd_count <= 10'd0;
			else
				vd_count <= v_count + 1'b1;
		end else begin
			hd_count <= h_count + 11'd4;
			vd_count <= v_count;
		end
// v & h sync signals	
		if(h_count == 11'd656)
			Hsync <= 1'b1;
		else if(h_count == 11'd752)
			Hsync <= 1'b0;
		
		if(v_count == 10'd490)
			Vsync <= 1'b1;
		else if(v_count == 10'd492)
			Vsync <= 1'b0;
// h & v blanking signals		
		if(h_count >= 11'd640)
			Hblank <= 1'b1;
		else 
			Hblank <= 1'b0;	
		
		if(v_count >= 10'd480)
			Vblank <= 1'b1;
		else 
			Vblank <= 1'b0;
// set pixel colour		
		if(h_count <  11'd640 && v_count <  10'd480) begin
			vid_addr_o <= (vd_count *640  + hd_count);
			result <= vid_dato;
			videoR <= result[8:6] ;
			videoG <= result[5:3] ;
			videoB <= result[2:0] ;		
		end
	end
end	
endmodule