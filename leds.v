module leds (
	clk,
	
	configured,
	unconfigured,
	shutup,	
	
	red_led,
	
	LED [2:0]
);

input	clk;

input	shutup;
input	configured;
input	unconfigured;
input	red_led;

output	[2:0] LED;


reg [32:0] counter;

wire heartbit = counter [24];
always @(posedge clk) begin
	counter <= counter + 1'b1;
end

	
assign LED [0] = heartbit;			// heartbit
assign LED [1] = shutup ? 1'b1 : configured ? 1'b0 : heartbit;
//assign LED [2] = shutup ? 1'b0 : 1'b1;
assign LED [2] = red_led;


endmodule