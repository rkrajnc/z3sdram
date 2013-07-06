module cs8900a_8bit (
	clk, reset, stb, addr_i, nDS, addr_o, cs8900_ack
);

input clk;
input reset;
input stb;

input [3:0] nDS;
input [1:0] addr_i;
output [3:0] addr_o;

output reg cs8900_ack;


wire [1:0] subaddr;

// convert nDS [3:0] strobes into low address lines A1, A0
assign subaddr [1:0] = nDS [3] ? (nDS [2] ? (nDS [1] ? 2'b11 : 2'b10) : 2'b01) : 2'b00;

assign addr_o [3:0] = {addr_i [1:0], subaddr [1:0]};

// IORW low to SD valid is max 135ns, need to delay rdy
parameter TIOR3 = 5'd20; //4'd14;
reg [4:0] ticks;

always @(posedge clk) begin
	if (reset) begin
		cs8900_ack <= 1'b0;
		ticks [4:0] <= 5'b0;
	end
	else begin
	
		if (stb) begin
			if (ticks [4:0] != TIOR3) begin
				ticks [4:0] <= ticks [4:0] + 5'b1;
				cs8900_ack <= 1'b0;
			end
			else
				cs8900_ack <= 1'b1;
		end
		else begin
			ticks [4:0] <= 5'b0;
			cs8900_ack <= 1'b0;
		end
	
	end
	
end

endmodule