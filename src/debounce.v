module debounce(input pb_1,clk,output pb_out);
wire Q1,Q2,Q2_bar,Q0;

my_dff d0(clk, pb_1,Q0 );

my_dff d1(clk, Q0,Q1 );
my_dff d2(clk, Q1,Q2 );

assign Q2_bar = ~Q2;
assign pb_out = Q1 & Q2_bar;


endmodule

// D-flip-flop for debouncing module 
module my_dff(input DFF_CLOCK, D, output reg Q);

    always @ (posedge DFF_CLOCK) begin
        Q <= D;
    end

endmodule