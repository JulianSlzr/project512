# project512

Standalone demos whose binaries are restricted to 512 bytes (i.e., x86 boot sector programs).

### About

As a 14-year-old, I thought computing glory was in writing the next Windows, leading me to C and x86 assembly. The forum I frequented, OSDev.org, ran some informal 512-byte challenges. It was a big deal to teenage me:

* Snake512 (snake.asm) was 3rd place in the [2nd contest](http://forum.osdev.org/viewtopic.php?f=2&t=18827)
* MusicDemo (music.asm) was 2nd place in the [3rd contest](http://forum.osdev.org/viewtopic.php?f=2&t=20006)

I now upload these for nerd cred, potential improvement, and a reminder of what is possible. This README is larger than both binaries combined.

### Screenshot:

snake.asm running in an emulator. 512 bytes of gaming fun!

![snake.asm](screenshot.png?raw=true)

### Assembling:

First, install the NASM (the Netwide Assembler), e.g.,

	apt-get install nasm

then run:

	nasm -O3 -f bin snake.asm -o snake.bin
	nasm -O3 -f bin music.asm -o music.bin

### Usage (emulation):

For the philistines without floppy drives, one can run the binaries on the excellent QEMU emulator. Install:

	apt-get install qemu

then run

	qemu -M pc -soundhw pcspk -fda [binary] -boot a

where [binary] is snake.bin or music.bin.

### Usage (hardware):

Based on opcodes, these should run fine on a 486 with VGA and a PC speaker. Having never owned such a machine, I can't guarantee that these are the minimum system requirements.

To write one of these to a floppy disk, assuming your drive is at /dev/fd0:

	dd if=[binary] of=/dev/fd0 bs=512

Boot your computer from the floppy and enjoy.