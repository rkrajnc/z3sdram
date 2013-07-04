module isa (
	clk,
	reset,
	en,
	stb,
	read,
	nIOR,
	nIOW
);

input clk;
input reset;
input stb;
input en;
input read;
output reg nIOR;
output reg nIOW;

always @(posedge clk) begin
	if (reset)
		{nIOR, nIOW} <= 2'b10;
	else
		if (stb & en)	
			{nIOR, nIOW} <= read ? 2'b01 : 2'b10;
		else
			{nIOR, nIOW} <= 2'b11;
end

endmodule