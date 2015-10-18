In <1995Aug16....@imada.ou.dk>, big...@imada.ou.dk (Jesper Matthiesen) writes:

>Does anyone know how to do 'dirty' hardware expansions in an ZorroIII slot in an A4000.

It's possible, but you can't be 100% "dirty" and expect to work.

>I need to do a temprorary project and I don't want to bother with AutoConfig and stuff.

Autoconfig, you can run without. "And stuff" you'll have to support.

>It seems like the /AS won't go low even though i access ZorroII address space ($e90000).  Does anyone know why this is so!?

There's no reason it that won't work (though it's called "/CCS" in
Zorro III terms). However, you won't get much of a response from a
board without driving back the /SLAVE line, when you're selected, at
the very least. And if there's anything else on the Zorro bus, you
better pay attention to your /CFGIN and /CFGOUT lines.

You can, actually, prevent a /CCS from being driven if you dare to
drive anything onto the bus before you get a /CCS and a valid address
you can claim. Until /CCS comes along, the bus is doing Zorro III
things that are not friendly to the Zorro II protocols, if those
protocols are abused. Correct Zorro II protocols, like responding only
when qualified by /CCS, and driving data only when DOE is asserted.

Dave Haynie          | ex-Commodore Engineering |   for DiskSalv 3 &
Sr. Systems Engineer |  Hardwired Media Company | "The Deathbed Vigil"
Scala Inc., US R&D   |    Ki No Kawa Aikido     |     in...@iam.com