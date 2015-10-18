# 2.1.1 Bus Timeout Support #
The Gary+ timeout support is necessary to trap processor access to unmapped memory resources.

In early Amigas, the motherboard controller would simply run zero wait state cycles for all
memory accesses unless instruction to add waits for Chip bus or expansion resources. This
policy has two problems. First of all, it makes detecting access to non-existant memory very
difficult. Secondly, it pretty much requires one central agency to do all of the cycle timing in the system. Being a more sophisticated Amiga system, the A3000+ really needs the ability to trap random addressing in hardware. And cycle termination isn’t central; it comes from several different places, such as Gary+ itself, RAMSEY, Buster, the 68882, and a possible slave device in the Local bus slot.

At power up, the TIMEOUT and TOENB registers are both zero, which indicates that the
default timeout is selected. Default timeout yields an automatic 32 bit asynchronous cycle
termination (via /DSACK0 and /DSACK1) after 9µS, effectively ignoring the access. This mode
is used during power up, since the OS polls certain memory locations that may not respond, and we don’t want powerup to take all day. When a one is written to TIMEOUT, the detectable
timeout mode is set. This causes a termination via /BERR after 250 mS. This is the normal
operating mode of A3000 class systems under AmigaOS 2.0. For special purposes, timeout may
be turned off altogether. This is done by writing a one to the TOENB register. Also, since the Chip bus may lock the CPU out for extended periods of time, all timeout logic is disabled during an access to any Chip bus resource.