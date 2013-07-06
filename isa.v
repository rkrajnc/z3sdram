module isa (
	clk,
	reset,
	en,	
	read,
	nSLAVEN,
	
	terminate,
	
	nIOR,
	nIOW,
);

input clk;
input reset;

input en;
input read;
input nSLAVEN;

input terminate;

output nIOR;
output nIOW;



reg nior_r;
reg niow_r;

reg [3:0] en_delay;

assign nIOR = nior_r | nSLAVEN;
assign nIOW = niow_r | nSLAVEN;

always @(posedge clk) begin
	
	en_delay [3] <= en;
	en_delay [2] <= en_delay [3];
	en_delay [1] <= en_delay [2];
	en_delay [0] <= en_delay [1];
	
	if (reset) begin
		{nior_r, niow_r} <= 2'b11;
		en_delay [3:0] <= 4'b0;
	end
	else
		if (en_delay [0])
			{nior_r, niow_r} <= read ? 2'b01 : 2'b10;
		else
			{nior_r, niow_r} <= 2'b11;
end

endmodule