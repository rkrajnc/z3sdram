/*
Amiga autoconfiguration is surprisingly simple. When an Amiga powers up or resets, every card
in the system goes to its unconfigured state. At this point, the most important signals in the
system are /CFGINN and /CFGOUTN. As long as a card�s /CFGINN line is negated, that card sits
quietly and does nothing on the bus (though memory cards should continue to refresh even
through reset, and any local board activities that don�t concern the bus may take place after
/RESET is negated). As part of the unconfigured state, /CFGOUTN is negated by the PIC
immediately on reset.

The configuration process begins when a card�s /CFGINN line is asserted, either by the
backplane, if it�s the first slot, or via the configuration chain, if it�s a later card. The
configuration chain simply ensures that only one unconfigured card will see an asserted
/CFGINN at one time. An unconfigured card that sees its /CFGINN line asserted will respond to a
block of memory called configuration space. In this block, the PIC will assert a set of read-only
registers, followed by a set of write-only registers (the read-only registers are also known as
AUTOCONFIG� ROM). Starting at the base of this block, the read registers describe the
device�s size, type, and other requirements. The operating system reads these, and based on
them, decides what should be written to the board. Some write information is optional, but a
board will always be assigned a base address or be told to shut up. The act of writing the final
bit of base address, or writing anything to a shutup address, will cause the PIC to assert its
/CFGOUTN, enabling the next board in the configuration chain.

The Zorro III configuration space
is the 64K memory block beginning at $FF00xxxx, which is always driven with 32 bit Zorro III
cycles (PICs need only decode A31-A24 during configuration). A Zorro III PIC can configure in
Zorro II or Zorro III configuration space, at the designer�s discretion, but not both at once. All
read registers physically return only the top 4 bits of data, on D31-D28 for either bus mode. Write
registers are written to support nybble, byte, and word registers for the same register, again based
on what works best in hardware. This design attempts to map into real hardware as simply as
possible. Every AUTOCONFIG� register is logically considered to be 8 bits wide; the 8 bits
actually being nybbles from two paired addresses.


nCFGINN	nCFGOUTN
-------	--------
   1	    1		reset (unconfigured)
   0		1
   
   1		0		configured
   0		1		
   
   1		0		shut up
   0		0
   

*/

	
module Autoconfig (
	
	clk,
	
	zs_match,
	zs_writedata,
	
	nIORST,
	nCFGINN,
	nCFGOUTN,
		
	READ,
	nDS,
	
	en,
	
	autocfg_reg,	// AD [8], A [7:2]
	rdata, wdata,

	
	ec_BaseAddress, ec_Z3_HighByte,
	
	unconfigured, configured, shutup,
	
	pool_link
);

input clk;
input zs_match;
input zs_writedata;
input nIORST;
input nCFGINN;
output nCFGOUTN;
input READ;
input [3:0] nDS;
input en;

input [6:0] autocfg_reg;
input [15:0] wdata;
output reg [7:4] rdata;

parameter	PIC_UNCONFIGURED 		= 2'b00;
parameter	PIC_IN_PROGRESS			= 2'b01;
parameter	PIC_CONFIGURED			= 2'b10;
parameter	PIC_SHUTUP				= 2'b11;

output unconfigured 	= (Status == PIC_UNCONFIGURED);
output configured 	= (Status == PIC_CONFIGURED);
output shutup 			= (Status == PIC_SHUTUP);

input pool_link;


// AUTOCONFIG registers

// write only
output reg [7:0] ec_Z3_HighByte;			// bits 31:24
output reg [7:0] ec_BaseAddress;			// bits 23:16

reg [1:0] Status;
reg [1:0] next;


//
// Bit values for AUTOCONFIG registers
//

//
// Register 00 (er_Type)
//
parameter	AC_PIC_TYPE_ZORROIII		= 2'b10;
parameter	AC_PIC_TYPE_ZORROII			= 2'b11;
parameter	AC_SYSTEM_POOL_NO_LINK		= 1'b0;
parameter	AC_SYSTEM_POOL_LINK			= 1'b1;
parameter	AC_AUTOBOOT_ROM				= 1'b1;
parameter	AC_NO_AUTOBOOT_ROM			= 1'b0;
parameter	AC_NEXT_BOARD_RELATED		= 1'b1;
parameter	AC_NEXT_BOART_NOT_RELATED	= 1'b0;

parameter	AC_CONFSIZE_8M_16M			= 3'b000;
parameter	AC_CONFSIZE_64K_32M			= 3'b001;
parameter	AC_CONFSIZE_128K_64M		= 3'b010;
parameter	AC_CONFSIZE_256K_128M		= 3'b011;
parameter	AC_CONFSIZE_512K_256M		= 3'b100;
parameter	AC_CONFSIZE_1M_512M			= 3'b101;
parameter	AC_CONFSIZE_2M_1G			= 3'b110;
parameter	AC_CONFSIZE_4M_RESERVED		= 3'b111;


//
// Register 08 (er_Flags)
//
parameter	AC_MEMORY_DEVICE			= 1'b1;
parameter	AC_IO_DEVICE				= 1'b0;
parameter	AC_NO_SHUTUP				= 1'b1;
parameter	AC_SHUTUP					= 1'b0;
parameter	AC_EXTENDED_SIZE			= 1'b1;
parameter	AC_NORMAL_SIZE				= 1'b0;
parameter	AC_SUBSIZE_MATCH_PHYSICAL	= 4'b0000;
parameter	AC_SUBSIZE_AUTOSIZED		= 4'b0001;
parameter	AC_SUBSIZE_64K				= 4'b0010;
parameter	AC_SUBSIZE_128K				= 4'b0011;
parameter	AC_SUBSIZE_256K				= 4'b0100;




parameter	ER_TYPE = {
									AC_PIC_TYPE_ZORROIII, 
				
									AC_SYSTEM_POOL_NO_LINK,
									//AC_SYSTEM_POOL_LINK ,
				
									AC_NO_AUTOBOOT_ROM,
									AC_NEXT_BOART_NOT_RELATED, 
				
									//AC_CONFSIZE_64K_32M
									//AC_CONFSIZE_8M_16M
									AC_CONFSIZE_128K_64M
									//AC_CONFSIZE_256K_128M
				
									};

parameter ER_TYPE_POOL_LINK = {	AC_PIC_TYPE_ZORROIII, AC_SYSTEM_POOL_LINK ,
				
									AC_NO_AUTOBOOT_ROM,
									AC_NEXT_BOART_NOT_RELATED, 
				
									AC_CONFSIZE_128K_64M
};


parameter	ER_PRODUCT			= 8'h17;			// 004/104:		Product 0x17 (23 decimal)


parameter	ER_FLAGS			= {
									AC_MEMORY_DEVICE,
									AC_SHUTUP, 
									
									//AC_NORMAL_SIZE,
									AC_EXTENDED_SIZE,
									
									1'b1,
							
									AC_SUBSIZE_MATCH_PHYSICAL
									//AC_SUBSIZE_AUTOSIZED
									//AC_SUBSIZE_64K
									//AC_SUBSIZE_128K
									//AC_SUBSIZE_256K
									
									};

parameter	ER_RESERVED03		= 8'b00000000;		// 00c/10c:		Reserved, must be 0

parameter	ER_MANUFACTURER_HI	= 8'h13;			// 010/110:		Manufacturer number, high byte
parameter	ER_MANUFACTURER_LO	= 8'ha6;			// 014/114:							low byte
													//				02 02 = COMMODORE

reg wrote_to_44 = 1'b0;

//
// 
//
always @(posedge clk or negedge nIORST)
	if (~nIORST)	Status <= PIC_UNCONFIGURED;
	else			Status <= next;
	
//
//
//
always @(*) begin
	next = 2'bx;
	
	case (Status)
		PIC_UNCONFIGURED:		
			if (wrote_to_44)	next <= PIC_CONFIGURED;
			else				next <= PIC_UNCONFIGURED;
		
		PIC_CONFIGURED:			next <= PIC_CONFIGURED;
		
		PIC_SHUTUP:				next <= PIC_SHUTUP;
	endcase
end

//
// Read from Autoconfig registers
// 
//always @(*) begin	
always @(posedge clk) begin	
	rdata = 4'bx;
	
	if (unconfigured)
		case ({autocfg_reg, 2'b00})
			9'h000: 	rdata = pool_link ? ER_TYPE_POOL_LINK [7:4] : ER_TYPE [7:4];
			9'h100: 	rdata = pool_link ? ER_TYPE_POOL_LINK [3:0] : ER_TYPE [3:0];
				
			9'h004: 	rdata = ~(ER_PRODUCT [7:4]);
			9'h104: 	rdata = ~(ER_PRODUCT [3:0]);
				
			9'h008: 	rdata = ~(ER_FLAGS [7:4]);
			9'h108: 	rdata = ~(ER_FLAGS [3:0]);

			9'h00c: 	rdata = ~(ER_RESERVED03 [7:4]);
			9'h10c: 	rdata = ~(ER_RESERVED03 [3:0]);

			9'h010: 	rdata = ~(ER_MANUFACTURER_HI [7:4]);
			9'h110: 	rdata = ~(ER_MANUFACTURER_HI [3:0]);
					
			9'h014: 	rdata = ~(ER_MANUFACTURER_LO [7:4]);
			9'h114: 	rdata = ~(ER_MANUFACTURER_LO [3:0]);					
					
			default: 	rdata = 4'b1111;					
	endcase
	else
				rdata = 4'b1111;
end

//
// Write to Autoconfig registers
//
always @(posedge clk or negedge nIORST) begin
	
	if (~nIORST) begin
		ec_Z3_HighByte [7:0] <= 8'h77;
		ec_BaseAddress [7:0] <= 8'h77;
		wrote_to_44 <= 1'b0;
	end
	
	else
	
	if (en & ~READ & zs_writedata & unconfigured) begin	
		casex ({autocfg_reg, 2'b00})
			9'hX44: begin
						ec_Z3_HighByte [7:0] <= wdata [15:8];			// 44, word access, address bits A31..A24. Actual configuration
						if (~nDS [2])
							ec_BaseAddress [7:0] <= wdata [7:0];	
						wrote_to_44 <= 1'b1;
					end
			
			9'hX48: 	ec_BaseAddress <= wdata [7:0];					// 48, byte access, address bits A23..A16
		endcase
	end				
end



	
//assign nCFGOUTN = !(nCFGINN & ((Status == PIC_CONFIGURED) | (Status == PIC_SHUTUP)));
assign nCFGOUTN = nCFGINN | unconfigured;

	
endmodule