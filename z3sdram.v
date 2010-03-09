//`define SIMULATION

`default_nettype none

// Copyright (C) 1991-2009 Altera Corporation
// Your use of Altera Corporation's design tools, logic functions 
// and other software and tools, and its AMPP partner logic 
// functions, and any output files from any of the foregoing 
// (including device programming or simulation files), and any 
// associated documentation or information are expressly subject 
// to the terms and conditions of the Altera Program License 
// Subscription Agreement, Altera MegaCore Function License `
// Agreement, or other applicable license agreement, including, 
// without limitation, that your use is for the sole purpose of 
// programming logic devices manufactured by Altera and sold by 
// Altera or its authorized distributors.  Please refer to the 
// applicable agreement for further details.

module z3sdram
(
`ifdef SIMULATION
	clk,
`endif
	
	CLK0, 
	LED, GPIO,

	nBERR, nIORST, SENSEZ3,	nCFGINN, nCFGOUTN, nSLAVEN, READ, AD, A, SD, FC, nFCS, DOE, nDS, nDTACK, nMTCR, nMTACK,

	BA, CKE, CLK, DQ, DQMH, DQML, SA, nCAS, nCS0, nRAS, nWE
);


// ---
`ifdef SIMULATION
input	clk;
`endif
input			CLK0;
output	[2:0]	LED;
output	[8:2]	GPIO;

// Zorro III

/* Hardware Bus Error/Interrupt (/BERR)
This is a general indicator of a bus fault or special condition of some kind. Any
expansion card capable of detecting a hardware error relating directly to that card can assert
/BERR when that bus error condition is detected, especially any sort of harmful hardware error
condition. This signal is the strongest possible indicator of a bad situation, as it causes all PICs
to get off the bus, and will usually generate a level 2 exception on the host CPU. For any
condition that can be handled in software and doesn’t pose an immediate threat to hardware,
notification via a standard processor interrupt is the better choice. The bus controller will drive
/BERR in the event of a detected bus collision or DMA error (an attempt by a bus master to
access local bus resources it doesn’t have valid access permission for). All cards must monitor
/BERR and be prepared to tri-state all of their on-bus output buffers whenever this signal is
asserted. An expansion bus master will attempt to retry a cycle aborted by a single /BERR and
notify system software in the case of two subsequent /BERR results. Since any number of
devices may assert /BERR, and all bus cards must monitor it, any device that drives /BERR
must drive with an open collector or similar device, and any device that monitors /BERR should
place a minimal load on it. This signal is pulled high by a passive backplane resistor.
Note that, especially for the slave device being addressed, that /BERR alone is not always
necessaily an indication of a bus failure in the pure sense, but may indicate some other kind of
unusual condition. Therefore, a device should still respond to the bus address, if otherwise
appropriate, when a /BERR condition is indicated. It simply tri-states is bus buffers and other
outputs, and waits for a change in the bus state. If the /BERR signal is negated with the cycle
unterminated, the special condition has been resolved and the slave responds to the rest of the
cycle as it normally would have. If the cycle is terminated by the bus master, the resolution of
the special condition has indicated that the addressed slave is not needed, and so the cycle
terminates without the slave being used. */

input			nBERR;			// bus error


/* System Reset (/RESET, /IORST)
The bus supplies two versions of the system reset signal. The /RESET signal is
bidirectional and unbuffered, allowing an expansion card to hard reset the system. It should only
be used by boards that need this reset capability, and is driven only by an open collector or
similar device. The /IORST signal is a buffered output-only version of the reset signal that
should be used as the normal reset input to boards not concerned with resetting the system on
their own. All expansion devices are required to reset their autoconfiguration logic when
/IORST is asserted. These signals are pulled high by passive backplane resistors. */

input			nIORST;


/* Backplane Type Sense (SenseZ3)
This line can be used by the PIC to determine the backplane type. It is grounded on a
Zorro II backplane, but floating on a Zorro III backplane. The Zorro III PIC connects this signal
to a 1K pullup resistor to generate a real logic level for this line. It’s possible, though more
complicated, to build a Zorro III PIC that can actually run in Zorro II mode when in a Zorro II
backplane. It’s hardly necessary or required to support this backward compatibility mechanism,
and in many cases it’ll be inpractical. The Zorro III specification does require that this signal be
used, at least, to shut the card down and pass /CFGIN to /CFGOUT when in a Zorro II
backplane. */

input			SENSEZ3;		// Z3 sense


/* Configuration Chain (/CFGINN, /CFGOUTN)
The slot configuration mechanism uses the bus signals /CFGOUTN and /CFGINN, where
"N" refers to the slot number. Each slot has its own version of both signals, which make up the
configuration chain between slots. Each subsequent /CFGINN is a result of all previous
/CFGOUTs, going from slot 0 to the last slot on the expansion bus. During the autoconfiguration
process, an unconfigured Zorro III PIC responds to the 64K address space starting at either
$00E80000 or $FF000000 if its /CFGINN signal is asserted. All unconfigured PICs start up with
/CFGOUTN negated. When configured, or told to "shut up", a PIC will assert its /CFGOUTN,
which results in the /CFGINN of the next slot being asserted. Backplane logic automatically
passes on the state of the previous /CFGOUTN to the next /CFGINN for any slot not occupied by
a PIC, so there’s no need to sequentially populate the expansion bus slots. */

input			nCFGINN;		// config in
output			nCFGOUTN;		// config out


/* Slave (/SLAVEN)								
Each slot has its own /SLAVEN output, driven actively, all of which go into the collision
detect circuitry. The "N" refers to the expansion slot number of the particular /SLAVE signal.
Whenever a Zorro III PIC is responding to an address on the bus, it must assert its /SLAVEN
output very quickly. If more than one /SLAVEN output occurs for the same address, or if a PIC
asserts its /SLAVEN output for an address reserved by the local bus, a collision is registered and
the bus controller asserts /BERR. The bus controller will assert /SLAVEN back to the
interrupting device selected during a Quick Interrupt cycle, so any device supporting Quick
Interrupts must be capable of tri-stating its /SLAVEN; all others can drive SLAVEN with a
normal active output. */
								
output nSLAVEN;


/* Read Enable (READ)
Read enable for the bus; READ is asserted by the bus master during a bus cycle to
indicate a read cycle, READ is negated to indicate a write cycle. READ is asserted at address
time, prior to /FCS, for a full cycle, and prior to /MTCR for a short cycle. READ stays valid
throughout the cycle; no latching required. */

input			READ;


/* Multiplexed Address Bus (A8-A31)
These signals are driven by the bus master during address time, prior to the assertion of
/FCS. Any responding slave must latch as many of these lines as it needs on the falling edge of
/FCS, as they’re tri-stated very shortly after /FCS goes low. These addresses always include all
configuration address bits for normal cycles, and the cycle type information for Quick Interrupt
cycles. */

inout	 [31:8]	AD;


/* Short Address Bus (A2-A7)
These signals are driven by the bus master during address time, prior to the assertion of
/FCS, for full cycles, and prior to the assertion of /MTCR for short cycles. They stay valid for
the entire full or short cycle, and as such do not need to be latched by responding slaves. */

input	[7:2]	A;
//input	[7:0]	A;


/* Short Data Bus (SD7..SD0) */

inout	[7:0]	SD;


/* Memory Space (FC0-FC2)
The memory space bits are an extension to the bus address, indicating which type of
access is taking place. Zorro III PICs must pay close attention to valid memory space types, as
the space type can change the type of the cycle driven by the current bus master. The encoding
is the same as the valid Motorola function codes for normal accesses. These are driven at
address time, and like the low short address, are valid for an entire short or full cycle. */

input	[1:0]	FC;


/* Full Cycle Strobe (/FCS)

This is the standard Zorro III full cycle strobe. This is asserted by the bus master shortly
after addresses are valid on the bus, and signals the start of any kind of Zorro III bus cycle.
Shortly after this line is asserted, all the multiplexed addresses will go invalid, so in general, all
slaves latch the bus address on the falling edge of /FCS. Also, /BGN line is negated for a Zorro
III mastered cycle shortly after /FCS is asserted by the master. */

input			nFCS;


/* Data Output Enable (DOE)
This signal is used by an expansion card to enable the buffers on the data bus. The bus
master drives this line is to keep slave PICs from driving data on the bus until data time. */

input			DOE;


/* Data Bus (D0-D31)
This is the Zorro III data bus, which is driven by either the master or the slave when DOE
is asserted by the master (based on READ). It’s valid for reads when /DTACK is asserted by the
slave; on writes when at least one of /DSN is asserted by the master, for all cycle types. 

Zorro III		Zorro III
Address Phase	Data Phase
=============	==========
	AD8				D0
	AD9				D1
	AD10			D2
	AD11			D3			/DS0
	AD12			D4
	AD13			D5
	AD14			D6
	AD15			D7
	
	AD16			D8
	AD17			D9
	AD18			D10
	AD19			D11
	AD20			D12
	AD21			D13
	AD22			D14
	AD23			D15
	
SD0				D16
SD1				D17
SD2				D18
SD3				D19
SD4				D20
SD5				D21
SD6				D22
SD7				D23
	
	AD24			D24
	AD25			D25
	AD26			D26
	AD27			D27
	AD28			D28			/DS3
	AD29			D29
	AD30			D30
	AD31			D31
	

*/



/* Data Strobes (/DSN)
These strobes fall during data time; /DS3 strobes D24-D31, while /DS0 strobes D0-D7. For
write cycles, these lines signal data valid on the bus. At all times, they indicate which bytes in
the 32 bit data word the bus master is actually interested in. For cachable reads, all four bytes
must be returned, regardless of the value of the sizing strobes. For writes, only those bytes
corresponding to asserted /DSN are written. Only contiguous byte cycles are supported; e.g.
/DS3-0 = 2, 4, 5, 6, or 10 is invalid. */

input	[3:0]	nDS;


/* Data Transfer Acknowledge (/DTACK)
This signal is used to normally terminate a Zorro III cycle. The slave is always
responsible for driving this signal. For a read cycle, it asserts /DTACK as soon as it has driven
valid data onto the data bus. For a write cycle, it asserts /DTACK as soon as it’s done with the
data. Latching the data on writes may be a good idea; that can allow a slave to end the cycle
before it has actually finished writing the data to its local memory. */

output			nDTACK;


/* Multiple Cycle Transfers (/MTCR,/MTACK)
These lines comprise the Multiple Transfer Cycle handshake signals. The bus master
asserts /MTCR at the start of data time if it’s capable of supporting Multiple Transfer Cycles,
and the slave asserts /MTACK with /SLAVEN if it’s capable of supporting Multiple Transfer
Cycles. If the handshake goes through, /MTCR strobes in the short address and write data as
long as the full cycle continues. */

input			nMTCR;
output			nMTACK;





// SDRAM
output	[1:0]	BA;				// bank
output			CKE;			// clock enable
output			CLK;			// clock
inout	[15:0]	DQ;				// data lines
output			DQMH;			// upper bits strobe
output			DQML;			// lower bits strobe
output			nCAS;			// CAS
output			nCS0;			// chip select
output			nRAS;			// RAS
output			nWE;			// write enable
output	[12:0]	SA;				// address lines



// -----
reg	[31:0] addr;
reg	[31:0] data;
reg [31:0] data_o;

reg [8:0] autocfg_reg;

parameter ZS_IDLE 			= 4'b0000;
//parameter ZS_ADDRESS_PHASE 	= 3'd001;
parameter ZS_MATCH_PHASE 	= 4'b0001;
parameter ZS_DATA_PHASE 	= 4'b0010;
parameter ZS_DTACK 			= 4'b0100;
parameter ZS_WRITE_DATA		= 4'b1000;

reg	[3:0] ZorroState = ZS_IDLE;



/*
A Zorro III cycle begins when the bus master simultaneously drives addressing information on
the address bus and memory space codes on the FCN lines, quickly following that with the
assertion of the Full Cycle Strobe, /FCS; this is called the address phase of the bus. Any active
slaves will latch the bus address on the falling edge of /FCS, and the bus master will tri-state the
addressing information very shortly after /FCS is asserted. It’s necessary only to latch A31-A8;
the low order A7-A2 addresses and FCN codes are non-multiplexed.

As quickly as possible after /FCS is asserted, a slave device will respond to the bus address by
asserting its /SLAVEN line, and possibly other special-purpose signals. The autoconfiguration
process assigns a unique address range to each PIC base on its needs, just as on the Zorro II bus.
Only one slave may respond to any given bus address; the bus controller will generate a /BERR
signal if more than one slave responds to an address, or if a single slave responds to an address
reserved for the local bus (this is called a bus collision, and should never happen in normal
operation). Slaves don’t usually respond to CPU memory space or other reserved memory space
types, as indicated by the memory space code on the FCN lines (see Chapter 4 for details)!

The data phase is the next part of the cycle, and it’s started when the bus master asserts DOE
onto the bus, indicating that data operations can be started. The strobes are the same for both
read and write cycles, but of course the data transfer direction is different.

For a read cycle, the bus master drives at least one of the data strobes /DSN, indicating the
physical transfer size requested (however, cachable slaves must always supply all 32 bits of
data). The slave responds by driving data onto the bus, and then asserting /DTACK. The bus
master then terminates the cycle by negating /FCS, at which point the slave will negate its
/SLAVEN line and tri-state its data. The cycle is done at this point. There are a few actions that
modify a cycle termination, those will be covered in later sections.

The write cycle starts out the same way, up until DOE is asserted. At this point, it’s the master
that must drive data onto the bus, and then assert at least one /DSN line to indicate to the slave
that data is valid and which data bytes are being written. The slave has the data for its use until it
terminates the cycle by asserting /DTACK, at which point the master can negate /FCS and
tri-state its data at any point. For maximum bus bandwidth, the slave can latch data on the
falling edge of the logically ORed data strobes; the bus master doesn’t sample /DTACK until
after the data strobes are asserted, so a slave can actually assert /DTACK any time after /FCS.
*/

// Resample some input signals
reg nFCS_r;			// = 1'b1;
reg nIORST_r;		// = 1'b1;
reg DOE_r;			// = 1'b0;
reg [3:0] nDS_r;	// = 4'b1111;

always @(posedge clk) begin
	nIORST_r <= nIORST;
	nFCS_r <= nFCS;
	DOE_r <= DOE;
	nDS_r [3:0] <= nDS [3:0];
end

/*
// Lock address always in the beginning of FCS
//
always @(negedge nFCS) begin
	addr [31:0] <= {AD [31:8], A [7:2], 2'b0};
	autocfg_reg [8:0] <= {AD [8], A [7:2], 2'b0};

end
*/

//always @(posedge clk) begin
always @(negedge nFCS_r) begin
	//if (nFCS_r & ~nFCS) begin
		addr [31:0] <= {AD [31:8], A [7:2], 2'b0};
		autocfg_reg [8:0] <= {AD [8], A [7:2], 2'b0};
	//end
end


always @(posedge clk) begin

//	if (~nIORST | nFCS) begin	
	if (~nIORST_r | nFCS_r) begin
		ZorroState <= ZS_IDLE;
	end

//	if (~nFCS)
//		ZorroState <= ZS_IDLE;

	else
	
	  case (ZorroState)
	
		ZS_IDLE: begin
//			stb_i <= 1'b0;
//			cyc_i <= 1'b0;
		
			//ZorroState <= (~nFCS & match & ~shutup) ? ZS_MATCH_PHASE : ZS_IDLE;
			ZorroState <= (~nFCS_r & match & ~shutup) ? ZS_MATCH_PHASE : ZS_IDLE;
		end

		ZS_MATCH_PHASE: begin															// 0001						
			
			//ZorroState <= (DOE & ~busy) ? ZS_DATA_PHASE : ZS_MATCH_PHASE;
			ZorroState <= (DOE_r & ~busy) ? ZS_DATA_PHASE : ZS_MATCH_PHASE;
			
		end
	
		ZS_DATA_PHASE: begin															// 0010

			if (cardspace_match) begin
				stb_i <= 1'b1;
				cyc_i <= 1'b1;				
			end

			if (READ) begin
				// wait for data from SDRAM or Autoconfig register
				// then go to ZS_DTACK

//				data_o [31:0] <= (nCFGINN) ? dat_o [31:0] : {cfg_rdata [7:4], 28'bZ};
			
/*
				data_o [31:0] <= (configured) ? 
									dat_o [31:0] :
									unconfigured ? {cfg_rdata [7:4], 28'bZ} : 32'bZ;

*/
				
				if (configured)
					ZorroState <= (ack_o) ? ZS_DTACK : ZS_DATA_PHASE;				
				else
					ZorroState <= ZS_DTACK;
	
		
					
			end
			else begin
				// wait for at least nDS [3:0] to be asserted
				// then latch data and go to ZS_DTACK
				//if (!(nDS [3:0] == 4'b1111)) begin
				if (!(nDS_r [3:0] == 4'b1111)) begin
					data [31:0] <= {AD [31:24], SD [7:0], AD [23:8]};		// for write to Autoconfig regs
					ZorroState <= ZS_WRITE_DATA;
				end
		//		else
		//			ZorroState <= ZS_DATA_PHASE;
			end
		end
		
		ZS_WRITE_DATA: begin
			
			//data [31:0] <= {AD [31:24], SD [7:0], AD [23:8]};
	
			//ZorroState [2:0] <= ZS_DTACK;			
			
			if (configured)
				ZorroState <= (ack_o) ? ZS_DTACK : ZS_WRITE_DATA;
			else
				ZorroState <= ZS_DTACK;			
		end
	
		ZS_DTACK: begin
				stb_i <= 1'b0;
				cyc_i <= 1'b0;

			
				//ZorroState <= (nFCS) ? ZS_IDLE : ZS_DTACK;
				ZorroState <= (nFCS_r) ? ZS_IDLE : ZS_DTACK;
		end
			
	//	default:
	//		begin
	//			ZorroState <= ZorroState;
	//		end			
	  endcase
end





`ifdef SIMULATION
	wire clk;
`else
	wire clk; // = CLK0;
`endif



//wire cardspace_match = (addr [31:24] == CardBaseAddr [31:24]);			// our card is being addressed (4xxx.xxxx)
wire cardspace_match = (addr [31:25] == CardBaseAddr [31:25]);			// our card is being addressed (4xxx.xxxx)

wire cfgspace_match = (addr [31:16] == 16'hFF00);						// Autoconfig configuration space is being addressed

wire match = cardspace_match | cfgspace_match;

//wire hit = ~nSLAVEN & ~nFCS;
//wire dboe = hit & DOE;	// & !BERR
//wire dbdir = ~nSLAVEN & READ;

wire select = match & (FC[0] ^ FC [1]);

//wire dboe = ~nSLAVEN & DOE & READ;
wire dboe = ~nSLAVEN & DOE_r & READ;


//assign nSLAVEN = ~select | nFCS | shutup; // | nCFGINN;
assign nSLAVEN = ~select | nFCS_r | shutup; // | nCFGINN;


//assign nDTACK = nFCS | !(ZorroState == ZS_DTACK);
assign nDTACK = nFCS_r | !(ZorroState == ZS_DTACK);



/* (nCFGINN) ? dat_o [31:0] : {cfg_rdata [7:4], 28'bZ}; */
//assign {AD [31:8], SD [7:0]} = dboe ? 
assign {AD [31:24], SD [7:0], AD [23:8]} = dboe ? 

						// 12345678 was reading as 12783456
						// {AD [31:24], SD [7:0], AD [23:8]}

								(configured ? dat_o [31:0] : (unconfigured ? {cfg_rdata [7:4], 28'bZ} : 32'bZ)) :
								//(configured ? {dat_o [31:24], dat_o [7:0], dat_o [23:8]} : (unconfigured ? {cfg_rdata [7:4], 28'bZ} : 32'bZ)) :
								
								32'bz;

//assign {AD [31:8], SD [7:0]} = dboe ? 
//								((nCFGINN) ? data_o [31:0] : {cfg_rdata [7:4], 28'bZ}) : 
//								32'bz;

/*
				data_o [31:0] <= (configured) ? 
									dat_o [31:0] :
									unconfigured ? {cfg_rdata [7:4], 28'bZ} : 32'bZ;
*/



wire [31:16] CardBaseAddr;
//wire [15:0] cfg_wdata;
wire [7:4] cfg_rdata;
wire unconfigured, configured, shutup;


Autoconfig _Autoconfig (
	.clk (clk),
	//.clk (clk133),
	.ZorroState (ZorroState [3:0]),
	.nIORST (nIORST_r), .nCFGINN (nCFGINN), .nCFGOUTN (nCFGOUTN), 
	.autocfg_reg (autocfg_reg [8:0]),
	.en (cfgspace_match),
	.rdata (cfg_rdata [7:4]), .wdata (data [15:0]),
	.ec_Z3_HighByte (CardBaseAddr [31:24]), .ec_BaseAddress (CardBaseAddr [23:16]),
	
	.unconfigured (unconfigured), .configured (configured),
	.shutup (shutup),
	
	.DOE (DOE_r), .READ (READ), .nDS (nDS_r [3:0])
	);



// assign LED[2] = cfgspace_hit;

// îòëàäêà

//reg [32:0] counter;

//always @(posedge clk)
//	counter <= counter + 1'b1;
	
//assign LED [2:0] = counter [26:24];

leds leds_i (.clk (clk), .unconfigured (unconfigured), .configured (configured), .shutup (shutup), .red_led (~red_led), .LED (LED [2:0]));

sdram_controller sdram_controller_i (
	.clk_i (clk133), 	
	.dram_clk_i (clk133_3),
	.rst_i (~nIORST_r), 
	.dll_locked (1'b1),
	
	.dram_addr (SA [11:0]),
	.dram_bank (BA [1:0]),
	.dram_cas_n (nCAS),
	.dram_cke (CKE),
	.dram_clk (CLK),
	.dram_cs_n (nCS0),
	.dram_dq (DQ [15:0]),
	.dram_ldqm (DQML),
	.dram_udqm (DQMH),
	.dram_ras_n (nRAS),
	.dram_we_n (nWE),

//	 .addr_i (addr [23:0]),

	 .addr_i (addr [23:1]),

//	.dat_i (data [31:0]),
	.dat_i ({AD [31:24], SD [7:0], AD [23:8]}),
	.dat_o (dat_o [31:0]),
	
	.dqm_n (nDS_r [3:0]),	

	.ack_o (ack_o),
	.stb_i (stb_i),
	.cyc_i (cyc_i),
	.we_i (~READ),
	
	.busy (busy)
	
	
);

//wire [21:0] addr_i;
//wire [31:0] dat_i;
wire [31:0] dat_o;
wire we_i;
wire ack_o;
//wire stb_i;
//wire cyc_i;
reg stb_i;
reg cyc_i;
wire red_led;
wire busy;


wire clk133, clk133_3;

`ifdef SIMULATION

`else

	// SFL
	sfl sfl_instance (1'b0);

	// PLL
	pll pll_instance (.inclk0 (CLK0), .c0 (clk), .c1 (clk133), .c2 (clk133_3));

`endif

endmodule


