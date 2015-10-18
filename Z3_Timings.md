Well, for timing the maximum theoretical speeds for Zorro III full and
multiple cycles, I simply pulled out "The Zorro III Bus Specification by Dave
Haynie", flip to "Chapter 5: Timing", and add up the various lengths of
different cycle events for each type of cycle.  That figure sets the minimum
possible cycle time on the bus, in nanoseconds in this case.  A cycle
transfers 4 bytes, so if you know ns/byte, it's easy to find bytes/ns,
and ultimately, megabytes/second.  Again, actual Zorro III cycle time is
based on the efficiency of the Zorro III bus master and Zorro III bus slave
acting together.

A 68030 isn't a perfect Zorro III bus master, so you'll find that, for a
given memory chip speed, a 68030 will talk to a 68030 memory design faster
than a Zorro III memory design.  It'll be harder or more expensive to build
a Zorro III memory board that'll go 20MB/s with a 68030 (I built one, but
it uses expensive SRAM) than it would be to build a native 68030 memory
board that'll go 20MB/s with a 68030.  That's rather common on I/O buses,
and a well designed I/O bus master will be able to drive the Zorro III bus
significantly faster than the 68030, or most any CPU, can.

--
Dave Haynie Commodore-Amiga (Amiga 3000)