module cs8900a_8bit (
	clk, reset, stb, nIOR, nIOW, addr_i, nDS, addr_o, cs8900_ack
);

input clk;
input reset;
input stb;
input nIOR;
input nIOW;
input [3:0] nDS;
input [1:0] addr_i;
output [3:0] addr_o;

output reg cs8900_ack;


wire [1:0] subaddr;

// convert nDS [3:0] strobes into low address lines A1, A0
assign subaddr [1:0] = nDS [3] ? (nDS [2] ? (nDS [1] ? 2'b11 : 2'b10) : 2'b01) : 2'b00;

assign addr_o [3:0] = {addr_i [1:0], subaddr [1:0]};

// IORW low to SD valid is max 135ns, need to delay rdy
parameter TIOR3 = 4'd14;
reg [3:0] ticks;

always @(posedge clk) begin
	if (reset) begin
		cs8900_ack <= 1'b0;
		ticks [3:0] <= 4'b0;
	end
	else begin
	
		if (stb) begin
			if (ticks [3:0] != TIOR3) begin
				ticks [3:0] <= ticks [3:0] + 4'b1;
				cs8900_ack <= 1'b0;
			end
			else
				cs8900_ack <= 1'b1;
		end
		else begin
			ticks [3:0] <= 4'b0;
			cs8900_ack <= 1'b0;
		end
	
	end
	
end

endmodule