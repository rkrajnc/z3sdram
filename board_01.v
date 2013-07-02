module board_01 (
	clk,
	reset,
	en,
	addr,
	di,
	do,
	read,
	stb,
	red_led
);

input clk;
input reset;
input en;
input [15:0] addr;
input [31:0] di;
output [31:0] do;
input read;
input stb;

output reg red_led;

always @(posedge clk) begin

	if (reset)
		red_led <= 1'b0;
	else begin
		if (en & stb)
			red_led <= di [0];
	end

end

endmodule