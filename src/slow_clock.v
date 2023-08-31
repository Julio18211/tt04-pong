module slow_clk(input clk, output s_clk,ss_clk);

	reg [22:0] count;
	
	
	assign s_clk = count[16];
	assign ss_clk = count[21];
	
	always@(posedge clk) count = count + 17'd1;


endmodule
