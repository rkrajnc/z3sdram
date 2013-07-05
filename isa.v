module isa (
	clk,
	reset,
	en,	
	read,
	nSLAVEN,
	
	nIOR,
	nIOW
);

input clk;
input reset;

input en;
input read;
input nSLAVEN;


output nIOR;
output nIOW;

reg nior_r;
reg niow_r;

assign nIOR = nior_r | nSLAVEN;
assign nIOW = niow_r | nSLAVEN;

always @(posedge clk) begin
	if (reset)
		{nior_r, niow_r} <= 2'b11;
	else
		if (en)
			{nior_r, niow_r} <= read ? 2'b01 : 2'b10;
		else
			{nior_r, niow_r} <= 2'b11;
end

endmodule