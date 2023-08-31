module wave_shape(input clk, reset, output reg wave_one, wave_zero);

	reg [3:0] counter;

	always@(posedge clk) begin

		if (~reset) begin
			counter = 4'd0;
			wave_one = 1'b0;
            wave_zero = 1'b0;
		end
		
        counter = counter + 4'd1;
        
        if(counter < 4'd8) wave_one = 1'b1;
        else wave_one = 1'b0;
        
        if(counter < 4'd4) wave_zero = 1'b1;
        else wave_zero = 1'b0;

        if (counter == 4'd13) counter = 4'd0;
		
		
		
	end

endmodule

