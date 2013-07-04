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
inout		[8:2]	GPIO;



// Zorro III

/* Hardware Bus Error/Interrupt (/BERR)
This is a general indicator of a bus fault or special condition of some kind. Any
expansion card capable of detecting a hardware error relating directly to that card can assert
/BERR when that bus error condition is detected, especially any sort of harmful hardware error
condition. This signal is the strongest possible indicator of a bad situation, as it causes all PICs
to get off the bus, and will usually generate a level 2 exception on the host CPU. For any
condition that can be handled in software and doesnРїС—Р…t pose an immediate threat to hardware,
notification via a standard processor interrupt is the better choice. The bus controller will drive
/BERR in the event of a detected bus collision or DMA error (an attempt by a bus master to
access local bus resources it doesnРїС—Р…t have valid access permission for). All cards must monitor
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
//output			nBERR;


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
to a 1K pullup resistor to generate a real logic level for this line. ItРїС—Р…s possible, though more
complicated, to build a Zorro III PIC that can actually run in Zorro II mode when in a Zorro II
backplane. ItРїС—Р…s hardly necessary or required to support this backward compatibility mechanism,
and in many cases itРїС—Р…ll be inpractical. The Zorro III specification does require that this signal be
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
a PIC, so thereРїС—Р…s no need to sequentially populate the expansion bus slots. */

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
/FCS, as theyРїС—Р…re tri-stated very shortly after /FCS goes low. These addresses always include all
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
is asserted by the master (based on READ). ItРїС—Р…s valid for reads when /DTACK is asserted by the
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
valid data onto the data bus. For a write cycle, it asserts /DTACK as soon as itРїС—Р…s done with the
data. Latching the data on writes may be a good idea; that can allow a slave to end the cycle
before it has actually finished writing the data to its local memory. */

output			nDTACK;


/* Multiple Cycle Transfers (/MTCR,/MTACK)
These lines comprise the Multiple Transfer Cycle handshake signals. The bus master
asserts /MTCR at the start of data time if itРїС—Р…s capable of supporting Multiple Transfer Cycles,
and the slave asserts /MTACK with /SLAVEN if itРїС—Р…s capable of supporting Multiple Transfer
Cycles. If the handshake goes through, /MTCR strobes in the short address and write data as
long as the full cycle continues. */

input			nMTCR;
output			nMTACK;





// SDRAM
output	[1:0]	BA;												// bank
output			CKE;											// clock enable
output			CLK;											// clock
inout	[15:0]	DQ;												// data lines
output			DQMH;											// upper bits strobe
output			DQML;											// lower bits strobe
output			nCAS;											// CAS
output			nCS0;											// chip select
output			nRAS;											// RAS
output			nWE;											// write enable
output	[12:0]	SA;												// address lines


// -----
reg	[31:0] addr;
reg	[31:0] data;
reg [31:0] data_o;

reg [8:0] autocfg_reg;


parameter 	ZS_IDLE 				= 5'b00000,										// 0000000000000001
			ZS_MATCH_PHASE 		= 5'b00001,										// 0000000000000010
			ZS_DATA_PHASE 			= 5'b00010,										// 0000000000000100
			ZS_DTACK 				= 5'b00011,										// 0000000000001000
			ZS_WRITE_DATA			= 5'b00100,										// 0000000000010000
			ZS_WAIT_ACK				= 5'b00101,										// 0000000000100000
			ZS_DTACK0				= 5'b00110,										// 0000000001000000
			ZS_WRITE_DATA_STB		= 5'b00111,										// 0000000010000000
			ZS_READ_STB				= 5'b01000,										// 0000000100000000
			ZS_FAST_READ			= 5'b01001,										// 0000001000000000
			ZS_WRITE_DATA_STB1	= 5'b01010,									// 0000010000000000
			
			ZS_DTACK1				= 5'b01011,										// 0000100000000000
			ZS_DTACK2				= 5'b01100,										// 0001000000000000
			ZS_DTACK3				= 5'b01101,										// 0010000000000000
			ZS_DTACK4				= 5'b01110,										// 0100000000000000
			
			ZS_DTACK_ERR			= 5'b01111;										// 1000000000000000

reg [3:0] ZorroState;
reg [3:0] next;


/*
A Zorro III cycle begins when the bus master simultaneously drives addressing information on
the address bus and memory space codes on the FCN lines, quickly following that with the
assertion of the Full Cycle Strobe, /FCS; this is called the address phase of the bus. Any active
slaves will latch the bus address on the falling edge of /FCS, and the bus master will tri-state the
addressing information very shortly after /FCS is asserted. ItРїС—Р…s necessary only to latch A31-A8;
the low order A7-A2 addresses and FCN codes are non-multiplexed.

As quickly as possible after /FCS is asserted, a slave device will respond to the bus address by
asserting its /SLAVEN line, and possibly other special-purpose signals. The autoconfiguration
process assigns a unique address range to each PIC base on its needs, just as on the Zorro II bus.
Only one slave may respond to any given bus address; the bus controller will generate a /BERR
signal if more than one slave responds to an address, or if a single slave responds to an address
reserved for the local bus (this is called a bus collision, and should never happen in normal
operation). Slaves donРїС—Р…t usually respond to CPU memory space or other reserved memory space
types, as indicated by the memory space code on the FCN lines (see Chapter 4 for details)!

The data phase is the next part of the cycle, and itРїС—Р…s started when the bus master asserts DOE
onto the bus, indicating that data operations can be started. The strobes are the same for both
read and write cycles, but of course the data transfer direction is different.

For a read cycle, the bus master drives at least one of the data strobes /DSN, indicating the
physical transfer size requested (however, cachable slaves must always supply all 32 bits of
data). The slave responds by driving data onto the bus, and then asserting /DTACK. The bus
master then terminates the cycle by negating /FCS, at which point the slave will negate its
/SLAVEN line and tri-state its data. The cycle is done at this point. There are a few actions that
modify a cycle termination, those will be covered in later sections.

The write cycle starts out the same way, up until DOE is asserted. At this point, itРїС—Р…s the master
that must drive data onto the bus, and then assert at least one /DSN line to indicate to the slave
that data is valid and which data bytes are being written. The slave has the data for its use until it
terminates the cycle by asserting /DTACK, at which point the master can negate /FCS and
tri-state its data at any point. For maximum bus bandwidth, the slave can latch data on the
falling edge of the logically ORed data strobes; the bus master doesnРїС—Р…t sample /DTACK until
after the data strobes are asserted, so a slave can actually assert /DTACK any time after /FCS.
*/


// ---------------------------

reg trigger;		// GPIO [8] triggers SignalTap with CPU /BERR
wire gpio8 = GPIO [8];


//assign red_led = trigger;


always @(negedge nBERR or negedge nIORST) begin
	if (~nIORST)
		trigger <= 1'b0;
	else		
		trigger <= 1'b1;
end


parameter ONEMICROSECOND	= 10'd1000;
parameter DTACK_TIMEOUT		= 10'h30;
reg [10:0] cntr_us;


// ---------------------------	
	
	

initial begin
	ZorroState <= ZS_IDLE;
			
	
	match_r <= 1'b0;
	cardspace_match_r <= 1'b0;
	cfgspace_match_r <= 1'b0;
	
	addr [31:0] <= 32'b0;
	
	trigger <= 1'b0;
	
	cntr_us [10:0] <= 10'b0;
end


reg nFCS_r;
reg _nFCS_r;			// nFCS_r delayed by 1 clock, to delay tristating of DTACK
reg DOE_r;
reg [3:0] nDS_r;
reg [3:0] _nDS_r;

reg [1:0] FC_r;


// Lock address always in the beginning of FCS
//

wire [31:16] CardBaseAddr;
wire [31:16] CardBaseAddr_board_01;
wire [7:4] cfg_rdata;
wire unconfigured, configured, shutup;

wire board_00_match 		= (AD [31:26] == CardBaseAddr [31:26]);
wire board_01_match 		= (AD [31:26] == CardBaseAddr_board_01 [31:26]);
wire cardspace_match 	= board_00_match | board_01_match;
wire cfgspace_match		= (AD [31:16] == 16'hFF00) /* & ~nFCS_r */;
wire match					= (cardspace_match_r | cfgspace_match_r) & (FC_r [0] ^ FC_r [1]) & ~nFCS;

always @(negedge nFCS) begin
	addr [31:0] <= {AD [31:8], A [7:2], 2'b0};
	FC_r [1:0] <= FC [1:0];
	cardspace_match_r <= cardspace_match;
	cfgspace_match_r <= cfgspace_match;
	board_00_match_r <= board_00_match;
	board_01_match_r <= board_01_match;
end




reg ack_o_r;


reg match_r;
reg cardspace_match_r;
reg cfgspace_match_r;
reg board_00_match_r;
reg board_01_match_r;

always @(posedge clk) begin	

		nFCS_r <= nFCS;
		_nFCS_r <= nFCS_r;
	
		DOE_r <= DOE;	
	
		_nDS_r [3:0] <= nDS [3:0];
		nDS_r [3:0] <= _nDS_r [3:0];
	
		
		//match_r <= ~nFCS_r & _match_r;
		//match_r <= nFCS ? 1'b0 : _match_r;			// for simulation, 17.05.2010
	
		//match_r <= ~nFCS_r & match;
		match_r <= match & ~nFCS_r;			// wtf?
	
		ack_o_r <= ack_o;	
		

end





//
// === 1 ===
//
// 
//
always @(posedge clk or negedge nIORST) begin
	if (!nIORST)
		ZorroState <= ZS_IDLE;	
	else
		ZorroState <= next;
end


//
// === 2 ===
//
//
//
always @(*) begin
	next = 4'bx;		// ???
	
	if (nFCS | ~nIORST)
		next = ZS_IDLE;
	else
	
	case (ZorroState)
		ZS_IDLE:
			begin
				if (match_r)						
					next = ZS_MATCH_PHASE;
				else								
					next = ZS_IDLE;					
			end
					
		ZS_MATCH_PHASE: 
			if (DOE_r)							
				next = ZS_DATA_PHASE;
			else								
				next = ZS_MATCH_PHASE;												
		
		ZS_DATA_PHASE:	
			if (READ)	
				if (cfgspace_match_r | ack_o_r | cs8900_ack)
					next = ZS_DTACK3;						// delay DTACK
				else							
					next = ZS_DATA_PHASE;					
			else // ---- WRITE ----
				begin
					if ((nDS_r [3:0] == 4'b1111))	
						next = ZS_DATA_PHASE;			// TODO need a better way to detect nDS assertion
					else 
						begin
							data [31:0] = {AD [31:24], SD [7:0], AD [23:8]};
							next = ZS_WRITE_DATA_STB;
						end
				end
		
		ZS_WRITE_DATA_STB:									
			next = ZS_WRITE_DATA;
									
		
		ZS_WRITE_DATA:	
			if (cfgspace_match_r | ack_o_r | cs8900_ack)		// | cs8900_ack
				next = ZS_DTACK;							
				//next = ZS_DTACK0;
			else								
				next = ZS_WRITE_DATA;						
								
	//	ZS_FAST_READ:	next = ZS_WAIT_ACK;
		
		ZS_WAIT_ACK:	
			if (ack_o_r)						
				next = ZS_DTACK0;
			else 			
				next = ZS_WAIT_ACK;						
		
		ZS_DTACK0:											
			next = ZS_DTACK1;
			//next = ZS_DTACK;
		
		ZS_DTACK1:										
			next = ZS_DTACK2;
		
		ZS_DTACK2:
			next = ZS_DTACK3;
		
		ZS_DTACK3:	
			next = ZS_DTACK4;
		
		ZS_DTACK4:			
			next = ZS_DTACK;

		ZS_DTACK: 											
			if (cntr_us [10:0] == DTACK_TIMEOUT)	
				next = ZS_DTACK_ERR;
			else									
				next = ZS_DTACK;
						
		ZS_DTACK_ERR:
			next = ZS_DTACK_ERR;

	endcase
end


//
// === 3 ===
//
// data_o
//
always @(posedge clk or negedge nIORST) begin
	if (~nIORST)
		data_o [31:0] <= 32'b0;
	else
		case (ZorroState)
			ZS_DATA_PHASE: 
				begin
					if (cfgspace_match_r)	
						data_o [31:0] <= {cfg_rdata [7:4], 28'hFFFFFFF};
					else														
					if (ack_o_r)		
						data_o [31:0] <= dat_o [31:0];
				end
		
			ZS_WAIT_ACK:				
				data_o [31:0] <= dat_o [31:0];
		endcase	
end




wire stb = (READ ? zs_match : zs_write_data_stb) & board_00_match_r;





//
// cntr_us
//
always @(posedge clk) begin
	case (ZorroState)		
		ZS_MATCH_PHASE: begin
			//trigger <= 1'b0;
			cntr_us [10:0] <= 10'b0;
		end
		ZS_DTACK: begin
			cntr_us [10:0] <= cntr_us [10:0] + 10'b1;
	//		if (cntr_us [10:0] == DTACK_TIMEOUT)
	//			trigger <= 1'b1;
		end
	endcase
end






wire zs_idle = (ZorroState == ZS_IDLE);
wire zs_match = (ZorroState == ZS_MATCH_PHASE);
wire zs_data_phase = (ZorroState == ZS_DATA_PHASE) |
								(ZorroState == ZS_WRITE_DATA) | 
								(ZorroState == ZS_WRITE_DATA_STB) |
								(ZorroState == ZS_DTACK0) |
								(ZorroState == ZS_DTACK1) |
								(ZorroState == ZS_DTACK2) |
								(ZorroState == ZS_DTACK3) |
								(ZorroState == ZS_DTACK4);
wire zs_writedata = (ZorroState == ZS_WRITE_DATA);
wire zs_write_data_stb = (ZorroState == ZS_WRITE_DATA_STB);
								
wire zs_dtack = (ZorroState == ZS_DTACK);









`ifdef SIMULATION
	wire clk;
`else
	wire clk; // = CLK0;
`endif



		

//
// nSLAVEN
//

//OPNDRN opndrn_nslaven (.in (nFCS | nslaven_r), .out (nSLAVEN));

//assign nSLAVEN = nFCS | nslaven_r;
//assign nSLAVEN = nFCS | ~match_r;
//assign nSLAVEN = nFCS | zs_idle_r;			// nSLAVEN driven from Zorro state machine, and qualified by nFCS
//assign nSLAVEN = nFCS | ~match_r;
assign nSLAVEN = nFCS | ~(cardspace_match_r | cfgspace_match_r) | ~(FC_r [0] ^ FC_r [1]) | nCFGINN;


	

//
// nDTACK
//

//assign nDTACK = nFCS | nSLAVEN | ~zs_dtack_r;
//OPNDRN ndtack (.in(nFCS | nSLAVEN | ~zs_dtack_r), .out(nDTACK));
//OPNDRN ndtack (.in(nFCS | nslaven_r | ~zs_dtack_r), .out(nDTACK));
//OPNDRN ndtack (.in(nFCS | ~zs_dtack), .out(nDTACK));		// nDTACK also driven from Zorro state machine

// --- Prometheus
//OPNDRN ndtack (.in(nFCS | ~zs_dtack | nSLAVEN), .out(nDTACK));
//assign nDTACK = nFCS | ~zs_dtack | nSLAVEN;		// for external 74lvc1g07 chip or for direct (non-opendrain) control
ALT_OUTBUF_TRI ndtack (.i (nFCS | ~zs_dtack | nSLAVEN), .oe (~_nFCS_r), .o (nDTACK));



//
// nBERR
//
//OPNDRN nberr (.in (nFCS | nSLAVEN | ~zs_dtack_err_r), .out (nBERR));


//wire dboe = ~nFCS & ~(zs_idle | zs_match) & READ_r;
//wire dboe = ~nFCS & ~nSLAVEN & DOE & READ;
//wire dboe = ~nFCS & ~nSLAVEN & DOE & READ & nBERR;
//wire dboe = ~nFCS & (zs_data_phase | zs_dtack) & READ & nBERR;

// --- Prometheus
wire dboe = ~nSLAVEN & DOE & READ & nBERR & (board_00_match_r | cfgspace_match_r);


assign {AD [31:24], SD [7:0], AD [23:8]} = dboe ? data_o [31:0] : 32'bZ;	// (board_00_match | cfgspace_match)
//OPNDRN opndrn_ad (.in (dboe ? data_o [31:0] : 32'hFFFFFFFF), .out ({AD [31:24], SD [7:0], AD [23:8]}));

//
// nMTACK
//
assign nMTACK = 1'bZ;








Autoconfig _Autoconfig (
	.clk (clk),
		
	//.zs_match (zs_match),
	.zs_writedata (zs_writedata),
	.nIORST (nIORST), .nCFGINN (nCFGINN), .nCFGOUTN (nCFGOUTN), 
	
	.autocfg_reg (addr [8:2]),

	.en (cfgspace_match_r),
	
	.rdata (cfg_rdata [7:4]), 
	.wdata (data [15:0]),
	
	.ec_Z3_HighByte (CardBaseAddr [31:24]), 
	.ec_BaseAddress (CardBaseAddr [23:16]),

	.ec_Z3_HighByte_board_01 (CardBaseAddr_board_01 [31:24]), 
	.ec_BaseAddress_board_01 (CardBaseAddr_board_01 [23:16]),


	
	.unconfigured (unconfigured), 
	.configured (configured),
	.shutup (shutup),
		
	.READ (READ),
	.nDS (nDS_r [3:0]),
	
	
	.pool_link (1'b1 /* GPIO [2] */)
	
	);



// assign LED[2] = cfgspace_hit;

leds leds_i (.clk (clk), .unconfigured (unconfigured), .configured (configured), .shutup (shutup), .red_led (~red_led), .LED (LED [2:0]));

board_01 board_01_i (.clk (clk), .reset (~nIORST), .en (board_01_match_r), .addr (addr [15:0]), .di (data [31:0]), .do (), .read (READ), .stb (zs_write_data_stb), .red_led (red_led));

wire nIOR, nIOW, RST;
assign GPIO [2] = nIOR | nFCS;
assign GPIO [3] = nIOW | nFCS;
assign GPIO [4] = ~nIORST;
//assign GPIO [8:5] = {addr [3:2], 2'b00};

isa isa_i (
	.clk (clk), 
	.reset (~nIORST), 
	.en (board_01_match_r & (zs_data_phase | zs_dtack)), 
	.read (READ), 
	.nIOR (nIOR), 
	.nIOW (nIOW)
);


wire cs8900_ack;

cs8900a_8bit cs8900a_8bit_i (
	.clk (clk), 
	.reset (~nIORST), 
	.stb (board_01_match_r & zs_data_phase),
	.addr_i (addr [3:2]),
	.nDS (nDS_r [3:0]), 
	.addr_o (GPIO [8:5]),
	.cs8900_ack (cs8900_ack)
);
	
	

sdram_controller sdram_controller_i (
	.clk_i (clk133), 	
	.dram_clk_i (clk133_3),	
	.rst_i (~nIORST), 
	.dll_locked (1'b1),
	
	.dram_addr (SA [12:0]),
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

	 .addr_i (addr [25:1]),
	
	.dat_i (data [31:0]),
	.dat_o (dat_o [31:0]),
	
	.dqm_n (nDS_r [3:0]),	

	.ack_o (ack_o),
	.stb_i (stb),	
	.we_i (~READ),
	
	.busy (busy)
	
	
);





// ------------------------------------------------ mem test --------------------------
/*
//
// Memory tester
//
wire [31:0] test_addr;
wire [31:0] test_dat_o;
wire [31:0] test_dat_i;
wire test_we_i;
wire test_ack_o;
wire test_stb_i;


sdram_rw sdram_rw_i (
	.clk_i (clk), 
	.rst_i (~nIORST),
	.addr_i (test_addr [31:0]),
	.dat_i (test_dat_i [31:0]),
	.dat_o (test_dat_o [31:0]),
	.we_i (test_we_i),
	.ack_o (test_ack_o),
	.stb_i (test_stb_i),
	.red_led (red_led),
	
	.busy (busy)
);

sdram_controller sdram_controller_i (
	.clk_i (clk133), 	
	.dram_clk_i (clk133_3),
	.rst_i (~nIORST), 
	.dll_locked (1'b1),
	
	.dram_addr (SA [12:0]),
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
	.dqm_n (4'b0),

	.addr_i (test_addr [25:1]),

	.dat_i (test_dat_i [31:0]),
	.dat_o (test_dat_o [31:0]),

	.ack_o (test_ack_o),
	.stb_i (test_stb_i),	
	.we_i (test_we_i),
	
	.busy (busy)
);
*/
// ------------------------------------------------ mem test --------------------------




wire [31:0] dat_o;
wire we_i;
wire ack_o;


wire red_led;
wire busy;


wire clk133, clk133_3;

`ifdef SIMULATION

`else

	// SFL
//	sfl sfl_instance (1'b0);

	// PLL
	pll pll_instance (.inclk0 (CLK0), .c0 (clk), .c1 (clk133), .c2 (clk133_3));

`endif

endmodule



