module cs8900a_8bit (
	clk, reset, en, nIOR, nIOW, addr_i, nDS, addr_o
);

input clk;
input reset;
input en;
input nIOR;
input nIOW;
input [3:0] nDS;
input [1:0] addr_i;
output [3:0] addr_o;


wire [1:0] subaddr;

assign subaddr [1:0] = nDS [3] ? (nDS [2] ? (nDS [1] ? 2'b11 : 2'b10) : 2'b01) : 2'b00;


assign addr_o [3:0] = {addr_i [1:0], subaddr [1:0]};


always @(posedge clk) begin
	
end

endmodule