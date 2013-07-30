module cs8900a_8bit (
	clk, reset, stb, ior, iow, addr_i, nDS, addr_o, cs8900_ack
);

input clk;
input reset;
input stb;
input ior, iow;

input [3:0] nDS;
input [1:0] addr_i;
output reg [3:0] addr_o;

output reg cs8900_ack;


wire [1:0] subaddr;

// convert nDS [3:0] strobes into low address lines A1, A0
assign subaddr [1:0] = nDS [3] ? (nDS [2] ? (nDS [1] ? 2'b11 : 2'b10) : 2'b01) : 2'b00;

//assign addr_o [3:0] = {addr_i [1:0], subaddr [1:0]};


//assign addr_o [3:0] = {addr_i [1:0], subaddr [1:0]};

// IORW low to SD valid is max 135ns, need to delay ack
parameter TIOR3 = 6'd16; //4'd14;
reg [5:0] ticks;


always @(posedge clk) begin
	if (reset) begin
		cs8900_ack <= 1'b0;
		ticks [5:0] <= 6'b0;
	end
	else begin
	
	//	addr_o [3:0] <= {addr_i [1:0], subaddr [1:0]};
	
	
	
		
		if (stb) begin
//		if (~(ior & iow)) begin
			if (ticks [4:0] == 5'd0)
				addr_o [3:0] <= {addr_i [1:0], subaddr [1:0]};
			if (ticks [5:0] != TIOR3) begin
				if (~(ior & iow)) begin
					ticks [5:0] <= ticks [5:0] + 6'b1;
				end;
				cs8900_ack <= 1'b0;
			end
			else
				cs8900_ack <= 1'b1;
		end
		else begin
			ticks [5:0] <= 6'b0;
			cs8900_ack <= 1'b0;
		end
	
	end
	
end

endmodule