# PS-FPGA Project

This project is a recreation of the PS1 in digital hardware for FPGA.  
It is not fully complete yet and is the work of multiple authors.  
It has been demonstrated to play a number of commercially available PS1 games, albeit without any sound or FMV (e.g. intro videos).

Disclaimer: This is clean-room re-implementation done from the following specs and SW emulators:

* [https://psx-spx.consoledev.net](https://psx-spx.consoledev.net)
* [https://github.com/JaCzekanski/Avocado](https://github.com/JaCzekanski/Avocado.git)

This core was implemented using only publically available documentation, with no proprietary knowledge of the original's internals.

## Cloning

**This repo contains submodules.**  
Make sure to clone them all with the following command;

```
git clone --recursive https://github.com/PS-FPGA/ps-fpga.git

```

## Targets
The current design targets the Xilinx Artix 7 (100T) FPGA:
* https://store.digilentinc.com/arty-a7-artix-7-fpga-development-board/

The design should be portable to the MiSTer FPGA system, but special care needs to be paid to:
* Memory subsystem - this core requires a 256-bit AXI interface to DDR / SDRAM with sufficient bandwidth.
* RAM mapping - there are a number of inferred RAMs in the design (x_ram.v files).
* Display - DVI is driven directly from the FPGA pins and needs mapping to the video subsystem.

## Memory Map
The design has the following memory map;
* Main RAM -> 0x0000_0000 [2MB-16MB]
* BIOS ROM -> 0x01c0_0000 [512KB]
* CDROM FW -> 0x01C8_0000 [64KB]
* Video RAM -> 0x0300_0000 [1MB]
* Game store (CDROM preload images) -> 0x4000000+

The current design requires that all these things are loaded before releasing reset (e.g. using another preload bitstream), but access is also possible to DDR using a UART -> AXI debug unit.

## BIOS
This project can make use of the open-source OpenBIOS;
* [https://github.com/grumpycoders/pcsx-redux/tree/main/src/mips/openbios](https://github.com/grumpycoders/pcsx-redux/tree/main/src/mips/openbios)

It can also run the retail BIOS dumped from a console you legally own.

## CDFW
The *CDROM* unit is a RISC-V CPU with a SPI SD interface. Games could be loaded via SPI, or can be preloaded into the 'Game store' memory region.

The current CDFW accepts 'psfcd' files, a converter tool is provided here:
* tools/cue2psfcd

Note: You should only play backups of games or content that you legally own. This project is not designed to assist piracy.

A prebuilt version of the cdfw is provided in images/cdfw.bin (and needs to be loaded to 0x01C8_0000 in DDR).  
Building the CDFW requires a copy of the RISC-V toolchain (RV32I).

## Games
Convert a game CUE/BIN file into a .psfcd and load into DDR @ 0x4000000.

## Hardware
* CPU
* GPU
* GTE
* SPU (stub)
* MDEC (stub - produces a white screen)
* DMA
* CDROM (SPI / RAM based 'CDROM')
* Various peripherals (timers, interrupts, serial ports).
* DVI - driving DVI/HDMI directly from the FPGA pins (TMDS)
* Controller - can be hooked up to a standard controller and memory card.

## Limitations
* Currently running at 30MHz instead of 33.8MHz (for DVI purposes).
* CDFW needs completion.
* Missing SPU / MDEC (lack of functioning SPU causes issues for a number of games).

