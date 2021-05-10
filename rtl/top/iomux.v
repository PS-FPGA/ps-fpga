//-----------------------------------------------------------------
// Copyright (c) 2021, admin@ultra-embedded.com
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions 
// are met:
//   - Redistributions of source code must retain the above copyright
//     notice, this list of conditions and the following disclaimer.
//   - Redistributions in binary form must reproduce the above copyright
//     notice, this list of conditions and the following disclaimer 
//     in the documentation and/or other materials provided with the 
//     distribution.
//   - Neither the name of the author nor the names of its contributors 
//     may be used to endorse or promote products derived from this 
//     software without specific prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR 
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE 
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR 
// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
// LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF 
// THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF 
// SUCH DAMAGE.
//-----------------------------------------------------------------
module iomux
(
    // Inputs
     input           clk_i
    ,input           rst_i
    ,input  [ 31:0]  inport_addr_i
    ,input  [ 31:0]  inport_data_wr_i
    ,input           inport_stb_i
    ,input           inport_cyc_i
    ,input  [  3:0]  inport_sel_i
    ,input           inport_we_i
    ,input  [ 31:0]  outport_joy_data_rd_i
    ,input           outport_joy_stall_i
    ,input           outport_joy_ack_i
    ,input           outport_joy_err_i
    ,input  [ 31:0]  outport_sio_data_rd_i
    ,input           outport_sio_stall_i
    ,input           outport_sio_ack_i
    ,input           outport_sio_err_i
    ,input  [ 31:0]  outport_dma_data_rd_i
    ,input           outport_dma_stall_i
    ,input           outport_dma_ack_i
    ,input           outport_dma_err_i
    ,input  [ 31:0]  outport_irqctrl_data_rd_i
    ,input           outport_irqctrl_stall_i
    ,input           outport_irqctrl_ack_i
    ,input           outport_irqctrl_err_i
    ,input  [ 31:0]  outport_timers_data_rd_i
    ,input           outport_timers_ack_i
    ,input           outport_timers_stall_i
    ,input  [ 31:0]  outport_spu_data_rd_i
    ,input           outport_spu_stall_i
    ,input           outport_spu_ack_i
    ,input           outport_spu_err_i
    ,input  [ 31:0]  outport_cdrom_data_rd_i
    ,input           outport_cdrom_stall_i
    ,input           outport_cdrom_ack_i
    ,input           outport_cdrom_err_i
    ,input  [ 31:0]  outport_gpu_data_rd_i
    ,input           outport_gpu_ack_i
    ,input           outport_gpu_stall_i
    ,input  [ 31:0]  outport_mdec_data_rd_i
    ,input           outport_mdec_ack_i
    ,input           outport_mdec_stall_i
    ,input  [ 31:0]  outport_atcons_data_rd_i
    ,input           outport_atcons_ack_i
    ,input           outport_atcons_stall_i
    ,input  [ 31:0]  outport_uart_data_rd_i
    ,input           outport_uart_ack_i
    ,input           outport_uart_stall_i

    // Outputs
    ,output [ 31:0]  inport_data_rd_o
    ,output          inport_stall_o
    ,output          inport_ack_o
    ,output          inport_err_o
    ,output [ 31:0]  outport_joy_addr_o
    ,output [ 31:0]  outport_joy_data_wr_o
    ,output          outport_joy_stb_o
    ,output          outport_joy_cyc_o
    ,output [  3:0]  outport_joy_sel_o
    ,output          outport_joy_we_o
    ,output [ 31:0]  outport_sio_addr_o
    ,output [ 31:0]  outport_sio_data_wr_o
    ,output          outport_sio_stb_o
    ,output          outport_sio_cyc_o
    ,output [  3:0]  outport_sio_sel_o
    ,output          outport_sio_we_o
    ,output [ 31:0]  outport_dma_addr_o
    ,output [ 31:0]  outport_dma_data_wr_o
    ,output          outport_dma_stb_o
    ,output          outport_dma_cyc_o
    ,output [  3:0]  outport_dma_sel_o
    ,output          outport_dma_we_o
    ,output [ 31:0]  outport_irqctrl_addr_o
    ,output [ 31:0]  outport_irqctrl_data_wr_o
    ,output          outport_irqctrl_stb_o
    ,output          outport_irqctrl_cyc_o
    ,output [  3:0]  outport_irqctrl_sel_o
    ,output          outport_irqctrl_we_o
    ,output [ 31:0]  outport_timers_addr_o
    ,output [ 31:0]  outport_timers_data_wr_o
    ,output          outport_timers_stb_o
    ,output          outport_timers_we_o
    ,output [ 31:0]  outport_spu_addr_o
    ,output [ 31:0]  outport_spu_data_wr_o
    ,output          outport_spu_stb_o
    ,output          outport_spu_cyc_o
    ,output [  3:0]  outport_spu_sel_o
    ,output          outport_spu_we_o
    ,output [ 31:0]  outport_cdrom_addr_o
    ,output [ 31:0]  outport_cdrom_data_wr_o
    ,output          outport_cdrom_stb_o
    ,output          outport_cdrom_cyc_o
    ,output [  3:0]  outport_cdrom_sel_o
    ,output          outport_cdrom_we_o
    ,output [ 31:0]  outport_gpu_addr_o
    ,output [ 31:0]  outport_gpu_data_wr_o
    ,output          outport_gpu_stb_o
    ,output          outport_gpu_we_o
    ,output [ 31:0]  outport_mdec_addr_o
    ,output [ 31:0]  outport_mdec_data_wr_o
    ,output          outport_mdec_stb_o
    ,output          outport_mdec_we_o
    ,output [ 31:0]  outport_atcons_addr_o
    ,output [ 31:0]  outport_atcons_data_wr_o
    ,output          outport_atcons_stb_o
    ,output          outport_atcons_we_o
    ,output [ 31:0]  outport_uart_addr_o
    ,output [ 31:0]  outport_uart_data_wr_o
    ,output          outport_uart_stb_o
    ,output          outport_uart_we_o
);




wire [13:0] io_addr_w = inport_addr_i[13:0];
wire [31:0] addr_w    = {18'b0, io_addr_w}; // 32-bit masked address

//--------------------------------------------------------------------
// I/O Map
//--------------------------------------------------------------------  
// Memory Control 1
//   1F801000h 4    Expansion 1 Base Address (usually 1F000000h)
//   1F801004h 4    Expansion 2 Base Address (usually 1F802000h)
//   1F801008h 4    Expansion 1 Delay/Size (usually 0013243Fh; 512Kbytes 8bit-bus)
//   1F80100Ch 4    Expansion 3 Delay/Size (usually 00003022h; 1 byte)
//   1F801010h 4    BIOS ROM    Delay/Size (usually 0013243Fh; 512Kbytes 8bit-bus)
//   1F801014h 4    SPU_DELAY   Delay/Size (usually 200931E1h)
//   1F801018h 4    CDROM_DELAY Delay/Size (usually 00020843h or 00020943h)
//   1F80101Ch 4    Expansion 2 Delay/Size (usually 00070777h; 128-bytes 8bit-bus)
//   1F801020h 4    COM_DELAY / COMMON_DELAY (00031125h or 0000132Ch or 00001325h)
wire addr_mc1_w = (io_addr_w >= 14'h1000 && io_addr_w <= 14'h1020);

// Peripheral I/O Ports
//   1F801040h 1/4  JOY_DATA Joypad/Memory Card Data (R/W)
//   1F801044h 4    JOY_STAT Joypad/Memory Card Status (R)
//   1F801048h 2    JOY_MODE Joypad/Memory Card Mode (R/W)
//   1F80104Ah 2    JOY_CTRL Joypad/Memory Card Control (R/W)
//   1F80104Eh 2    JOY_BAUD Joypad/Memory Card Baudrate (R/W)
wire addr_joy_w = (io_addr_w >= 14'h1040 && io_addr_w < 14'h1050);

//   1F801050h 1/4  SIO_DATA Serial Port Data (R/W)
//   1F801054h 4    SIO_STAT Serial Port Status (R)
//   1F801058h 2    SIO_MODE Serial Port Mode (R/W)
//   1F80105Ah 2    SIO_CTRL Serial Port Control (R/W)
//   1F80105Ch 2    SIO_MISC Serial Port Internal Register (R/W)
//   1F80105Eh 2    SIO_BAUD Serial Port Baudrate (R/W)
wire addr_sio_w = (io_addr_w >= 14'h1050 && io_addr_w < 14'h1060);

// Memory Control 2
//   1F801060h 4/2  RAM_SIZE (usually 00000B88h; 2MB RAM mirrored in first 8MB)
wire addr_mc2_w = (io_addr_w == 14'h1060);

// Interrupt Control
//   1F801070h 2    I_STAT - Interrupt status register
//   1F801074h 2    I_MASK - Interrupt mask register
wire addr_irq_w = (io_addr_w >= 14'h1070 && io_addr_w < 14'h1080);

// DMA Registers
//   1F80108xh      DMA0 channel 0 - MDECin
//   1F80109xh      DMA1 channel 1 - MDECout
//   1F8010Axh      DMA2 channel 2 - GPU (lists + image data)
//   1F8010Bxh      DMA3 channel 3 - CDROM
//   1F8010Cxh      DMA4 channel 4 - SPU
//   1F8010Dxh      DMA5 channel 5 - PIO (Expansion Port)
//   1F8010Exh      DMA6 channel 6 - OTC (reverse clear OT) (GPU related)
//   1F8010F0h      DPCR - DMA Control register
//   1F8010F4h      DICR - DMA Interrupt register
//   1F8010F8h      unknown
//   1F8010FCh      unknown
wire addr_dma_w = (io_addr_w >= 14'h1080 && io_addr_w < 14'h1100);

// Timers (aka Root counters)
//   1F80110xh      Timer 0 Dotclock
//   1F80111xh      Timer 1 Horizontal Retrace
//   1F80112xh      Timer 2 1/8 system clock
wire addr_tmr_w = (io_addr_w >= 14'h1100 && io_addr_w < 14'h1140);

// CDROM Registers (Address.Read/Write.Index)
//   1F801800h.x.x   1   CD Index/Status Register (Bit0-1 R/W, Bit2-7 Read Only)
//   1F801801h.R.x   1   CD Response Fifo (R) (usually with Index1)
//   1F801802h.R.x   1/2 CD Data Fifo - 8bit/16bit (R) (usually with Index0..1)
//   1F801803h.R.0   1   CD Interrupt Enable Register (R)
//   1F801803h.R.1   1   CD Interrupt Flag Register (R/W)
//   1F801803h.R.2   1   CD Interrupt Enable Register (R) (Mirror)
//   1F801803h.R.3   1   CD Interrupt Flag Register (R/W) (Mirror)
//   1F801801h.W.0   1   CD Command Register (W)
//   1F801802h.W.0   1   CD Parameter Fifo (W)
//   1F801803h.W.0   1   CD Request Register (W)
//   1F801801h.W.1   1   Unknown/unused
//   1F801802h.W.1   1   CD Interrupt Enable Register (W)
//   1F801803h.W.1   1   CD Interrupt Flag Register (R/W)
//   1F801801h.W.2   1   Unknown/unused
//   1F801802h.W.2   1   CD Audio Volume for Left-CD-Out to Left-SPU-Input (W)
//   1F801803h.W.2   1   CD Audio Volume for Left-CD-Out to Right-SPU-Input (W)
//   1F801801h.W.3   1   CD Audio Volume for Right-CD-Out to Right-SPU-Input (W)
//   1F801802h.W.3   1   CD Audio Volume for Right-CD-Out to Left-SPU-Input (W)
//   1F801803h.W.3   1   CD Audio Volume Apply Changes (by writing bit5=1)
wire addr_cdrom_w = (io_addr_w >= 14'h1800 && io_addr_w < 14'h1810);

// GPU Registers
//   1F801810h.Write 4   GP0 Send GP0 Commands/Packets (Rendering and VRAM Access)
//   1F801814h.Write 4   GP1 Send GP1 Commands (Display Control)
//   1F801810h.Read  4   GPUREAD Read responses to GP0(C0h) and GP1(10h) commands
//   1F801814h.Read  4   GPUSTAT Read GPU Status Register
//   1F801818h.Read  4   GPUDEBUG0
//   1F80181ch.Read  4   GPUDEBUG1
wire addr_gpu_w = (io_addr_w >= 14'h1810 && io_addr_w < 14'h1820);

// MDEC Registers
//   1F801820h.Write 4   MDEC Command/Parameter Register (W)
//   1F801820h.Read  4   MDEC Data/Response Register (R)
//   1F801824h.Write 4   MDEC Control/Reset Register (W)
//   1F801824h.Read  4   MDEC Status Register (R)
//   1F801828h.Read  4   MDECDEBUG0
//   1F80182ch.Read  4   MDECDEBUG1
wire addr_mdec_w = (io_addr_w >= 14'h1820 && io_addr_w < 14'h1830);

// SPU Voice 0..23 Registers
//   1F801C00h+N*10h 4   Voice 0..23 Volume Left/Right
//   1F801C04h+N*10h 2   Voice 0..23 ADPCM Sample Rate
//   1F801C06h+N*10h 2   Voice 0..23 ADPCM Start Address
//   1F801C08h+N*10h 4   Voice 0..23 ADSR Attack/Decay/Sustain/Release
//   1F801C0Ch+N*10h 2   Voice 0..23 ADSR Current Volume
//   1F801C0Eh+N*10h 2   Voice 0..23 ADPCM Repeat Address
// SPU Control Registers
//   1F801D80h 4  Main Volume Left/Right
//   1F801D84h 4  Reverb Output Volume Left/Right
//   1F801D88h 4  Voice 0..23 Key ON (Start Attack/Decay/Sustain) (W)
//   1F801D8Ch 4  Voice 0..23 Key OFF (Start Release) (W)
//   1F801D90h 4  Voice 0..23 Channel FM (pitch lfo) mode (R/W)
//   1F801D94h 4  Voice 0..23 Channel Noise mode (R/W)
//   1F801D98h 4  Voice 0..23 Channel Reverb mode (R/W)
//   1F801D9Ch 4  Voice 0..23 Channel ON/OFF (status) (R)
//   1F801DA0h 2  Unknown? (R) or (W)
//   1F801DA2h 2  Sound RAM Reverb Work Area Start Address
//   1F801DA4h 2  Sound RAM IRQ Address
//   1F801DA6h 2  Sound RAM Data Transfer Address
//   1F801DA8h 2  Sound RAM Data Transfer Fifo
//   1F801DAAh 2  SPU Control Register (SPUCNT)
//   1F801DACh 2  Sound RAM Data Transfer Control
//   1F801DAEh 2  SPU Status Register (SPUSTAT) (R)
//   1F801DB0h 4  CD Volume Left/Right
//   1F801DB4h 4  Extern Volume Left/Right
//   1F801DB8h 4  Current Main Volume Left/Right
//   1F801DBCh 4  Unknown? (R/W)
// SPU Reverb Configuration Area
//   1F801DC0h 2  dAPF1  Reverb APF Offset 1
//   1F801DC2h 2  dAPF2  Reverb APF Offset 2
//   1F801DC4h 2  vIIR   Reverb Reflection Volume 1
//   1F801DC6h 2  vCOMB1 Reverb Comb Volume 1
//   1F801DC8h 2  vCOMB2 Reverb Comb Volume 2
//   1F801DCAh 2  vCOMB3 Reverb Comb Volume 3
//   1F801DCCh 2  vCOMB4 Reverb Comb Volume 4
//   1F801DCEh 2  vWALL  Reverb Reflection Volume 2
//   1F801DD0h 2  vAPF1  Reverb APF Volume 1
//   1F801DD2h 2  vAPF2  Reverb APF Volume 2
//   1F801DD4h 4  mSAME  Reverb Same Side Reflection Address 1 Left/Right
//   1F801DD8h 4  mCOMB1 Reverb Comb Address 1 Left/Right
//   1F801DDCh 4  mCOMB2 Reverb Comb Address 2 Left/Right
//   1F801DE0h 4  dSAME  Reverb Same Side Reflection Address 2 Left/Right
//   1F801DE4h 4  mDIFF  Reverb Different Side Reflection Address 1 Left/Right
//   1F801DE8h 4  mCOMB3 Reverb Comb Address 3 Left/Right
//   1F801DECh 4  mCOMB4 Reverb Comb Address 4 Left/Right
//   1F801DF0h 4  dDIFF  Reverb Different Side Reflection Address 2 Left/Right
//   1F801DF4h 4  mAPF1  Reverb APF Address 1 Left/Right
//   1F801DF8h 4  mAPF2  Reverb APF Address 2 Left/Right
//   1F801DFCh 4  vIN    Reverb Input Volume Left/Right
// SPU Internal Registers
//   1F801E00h+N*04h  4 Voice 0..23 Current Volume Left/Right
//   1F801E60h      20h Unknown? (R/W)
//   1F801E80h     180h Unknown? (Read: FFh-filled) (Unused or Write only?)
wire addr_spu_w = (io_addr_w >= 14'h1c00 && io_addr_w < 14'h2000);

// Expansion Region 2 (default 128 bytes, max 8 KBytes)
//   1F802000h      80h Expansion Region (8bit data bus, crashes on 16bit access?)
// Expansion Region 2 - Dual Serial Port (for TTY Debug Terminal)
//   1F802020h/1st    DUART Mode Register 1.A (R/W)
//   1F802020h/2nd    DUART Mode Register 2.A (R/W)
//   1F802021h/Read   DUART Status Register A (R)
//   1F802021h/Write  DUART Clock Select Register A (W)
//   1F802022h/Read   DUART Toggle Baud Rate Generator Test Mode (Read=Strobe)
//   1F802022h/Write  DUART Command Register A (W)
//   1F802023h/Read   DUART Rx Holding Register A (FIFO) (R)
//   1F802023h/Write  DUART Tx Holding Register A (W)
//   1F802024h/Read   DUART Input Port Change Register (R)
//   1F802024h/Write  DUART Aux. Control Register (W)
//   1F802025h/Read   DUART Interrupt Status Register (R)
//   1F802025h/Write  DUART Interrupt Mask Register (W)
//   1F802026h/Read   DUART Counter/Timer Current Value, Upper/Bit15-8 (R)
//   1F802026h/Write  DUART Counter/Timer Reload Value,  Upper/Bit15-8 (W)
//   1F802027h/Read   DUART Counter/Timer Current Value, Lower/Bit7-0 (R)
//   1F802027h/Write  DUART Counter/Timer Reload Value,  Lower/Bit7-0 (W)
//   1F802028h/1st    DUART Mode Register 1.B (R/W)
//   1F802028h/2nd    DUART Mode Register 2.B (R/W)
//   1F802029h/Read   DUART Status Register B (R)
//   1F802029h/Write  DUART Clock Select Register B (W)
//   1F80202Ah/Read   DUART Toggle 1X/16X Test Mode (Read=Strobe)
//   1F80202Ah/Write  DUART Command Register B (W)
//   1F80202Bh/Read   DUART Rx Holding Register B (FIFO) (R)
//   1F80202Bh/Write  DUART Tx Holding Register B (W)
//   1F80202Ch/None   DUART Reserved Register (neither R nor W)
//   1F80202Dh/Read   DUART Input Port (R)
//   1F80202Dh/Write  DUART Output Port Configuration Register (W)
//   1F80202Eh/Read   DUART Start Counter Command (Read=Strobe)
//   1F80202Eh/Write  DUART Set Output Port Bits Command (Set means Out=LOW)
//   1F80202Fh/Read   DUART Stop Counter Command (Read=Strobe)
//   1F80202Fh/Write  DUART Reset Output Port Bits Command (Reset means Out=HIGH)

// Expansion Region 2 - Int/Dip/Post
//   1F802000h 1 DTL-H2000: ATCONS STAT (R)
//   1F802002h 1 DTL-H2000: ATCONS DATA (R and W)
//   1F802004h 2 DTL-H2000: Whatever 16bit data ?
//   1F802030h 1/4 DTL-H2000: Secondary IRQ10 Flags
//   1F802032h 1 DTL-H2000: Whatever IRQ Control ?
//   1F802040h 1 DTL-H2000: Bootmode "Dip switches" (R)
//   1F802041h 1 PSX: POST (external 7 segment display, indicate BIOS boot status)
//   1F802042h 1 DTL-H2000: POST/LED (similar to POST) (other addr, 2-digit wide)   1F802070h 1 PS2: POST2 (similar to POST, but PS2 BIOS uses this address)
wire addr_atcons_w = (io_addr_w >= 14'h2000 && io_addr_w < 14'h2040);
wire addr_exp2_w   = (io_addr_w >= 14'h2040 && io_addr_w < 14'h2080);

// BIOS uart
wire addr_uart_w   = (io_addr_w == 14'h2080);
wire dbg_putc_w    = addr_uart_w;

wire invalid_addr_w = ~(addr_mc1_w | addr_joy_w | addr_sio_w | addr_mc2_w | addr_irq_w | addr_dma_w | addr_tmr_w | addr_cdrom_w | addr_gpu_w | addr_mdec_w | addr_spu_w | addr_exp2_w | addr_atcons_w | addr_uart_w);

//-----------------------------------------------------------------
// State machine
//-----------------------------------------------------------------
localparam STATE_W          = 2;
localparam STATE_IDLE       = 2'd0;
localparam STATE_ACCESS     = 2'd1;
localparam STATE_RESP       = 2'd2;
localparam STATE_ERR        = 2'd3;

reg [STATE_W-1:0] state_q;
reg [STATE_W-1:0] next_state_r;

reg               output_stall_r;

always @ *
begin
    next_state_r = state_q;

    case (state_q)
    STATE_IDLE :
    begin
        // TODO: The reason for this SM is handle access unrolling to narrow regions, etc
        // One cycle of latency can be removed easily here, at the expense of the critical path...
        if (inport_cyc_i && inport_stb_i && ~inport_stall_o)
            next_state_r = invalid_addr_w ? STATE_ERR : STATE_ACCESS;
    end
    STATE_ACCESS:
    begin
          if (~output_stall_r)
              next_state_r = STATE_RESP;
    end    
    STATE_ERR, STATE_RESP:
    begin
        next_state_r = STATE_IDLE;
    end
    default :
       ;

    endcase
end

// Update state
always @ (posedge clk_i )
if (rst_i)
    state_q <= STATE_IDLE;
else
    state_q <= next_state_r;

assign inport_stall_o = (state_q != STATE_IDLE);

//-----------------------------------------------------------------
// Address / Data 
//-----------------------------------------------------------------
reg [31:0] addr_q;

always @ (posedge clk_i )
if (rst_i)
    addr_q <= 32'b0;
else if (~inport_stall_o)
    addr_q <= addr_w;

reg [31:0] data_q;

always @ (posedge clk_i )
if (rst_i)
    data_q <= 32'b0;
else if (~inport_stall_o)
    data_q <= inport_data_wr_i;

reg [3:0] sel_q;

always @ (posedge clk_i )
if (rst_i)
    sel_q <= 4'b0;
else if (~inport_stall_o)
    sel_q <= inport_sel_i;

reg we_q;

always @ (posedge clk_i )
if (rst_i)
    we_q <= 1'b0;
else if (~inport_stall_o)
    we_q <= inport_we_i;

//-------------------------------------------------------------
// Simulation Helpers
//-------------------------------------------------------------
`ifdef verilator

function [0:0] get_io_valid; /*verilator public*/
begin
    get_io_valid = inport_ack_o;
end
endfunction
function [31:0] get_io_addr; /*verilator public*/
begin
    get_io_addr = 32'h1F800000 | addr_q;
end
endfunction
function [3:0] get_io_sel; /*verilator public*/
begin
    get_io_sel = sel_q;
end
endfunction
function [31:0] get_io_wr_data; /*verilator public*/
begin
    get_io_wr_data = data_q;
end
endfunction
function [0:0] get_io_we; /*verilator public*/
begin
    get_io_we = we_q;
end
endfunction
function [31:0] get_io_rd_data; /*verilator public*/
begin
    get_io_rd_data = inport_data_rd_o;
end
endfunction

`endif

//-------------------------------------------------------------------
// set_verbosity: 
//-------------------------------------------------------------------
`ifdef verilator
integer v_level = 1;
function set_verbosity; /*verilator public*/
    input [31:0] level;
begin
    v_level = level;
end
endfunction
`endif

//-----------------------------------------------------------------
// Simulation Only
//-----------------------------------------------------------------
`ifdef verilator

reg [31:0] dbg_cycle_q;
always @ (posedge clk_i )
if (rst_i)
    dbg_cycle_q <= 32'b0;
else
    dbg_cycle_q <= dbg_cycle_q + 32'd1;

reg [31:0] dbg_cycle_prev_q;
always @ (posedge clk_i )
if (rst_i)
    dbg_cycle_prev_q <= 32'b0;
else if (inport_cyc_i && inport_stb_i && ~inport_stall_o && ~dbg_putc_w)
    dbg_cycle_prev_q <= dbg_cycle_q;

wire signed [31:0] dbg_delta_w = dbg_cycle_q - dbg_cycle_prev_q;

always @ (posedge clk_i)
if (inport_cyc_i && inport_stb_i && ~inport_stall_o && ~dbg_putc_w && v_level > 0)
begin
    if (inport_we_i)
    begin
        case (1'b1)
        addr_mc1_w:    $display("IO Access (W) [MC1]:     %08x = %08x [mask=%x] [delta=%0d @ %0d]", inport_addr_i, inport_data_wr_i, inport_sel_i, dbg_delta_w, dbg_cycle_q);
        addr_joy_w:    $display("IO Access (W) [JOY]:     %08x = %08x [mask=%x] [delta=%0d @ %0d]", inport_addr_i, inport_data_wr_i, inport_sel_i, dbg_delta_w, dbg_cycle_q);
        addr_sio_w:    $display("IO Access (W) [SIO]:     %08x = %08x [mask=%x] [delta=%0d @ %0d]", inport_addr_i, inport_data_wr_i, inport_sel_i, dbg_delta_w, dbg_cycle_q);
        addr_mc2_w:    $display("IO Access (W) [MC2]:     %08x = %08x [mask=%x] [delta=%0d @ %0d]", inport_addr_i, inport_data_wr_i, inport_sel_i, dbg_delta_w, dbg_cycle_q);
        addr_irq_w:    $display("IO Access (W) [IRQ]:     %08x = %08x [mask=%x] [delta=%0d @ %0d]", inport_addr_i, inport_data_wr_i, inport_sel_i, dbg_delta_w, dbg_cycle_q);
        addr_dma_w:    $display("IO Access (W) [DMA]:     %08x = %08x [mask=%x] [delta=%0d @ %0d]", inport_addr_i, inport_data_wr_i, inport_sel_i, dbg_delta_w, dbg_cycle_q);
        addr_tmr_w:    $display("IO Access (W) [TMR]:     %08x = %08x [mask=%x] [delta=%0d @ %0d]", inport_addr_i, inport_data_wr_i, inport_sel_i, dbg_delta_w, dbg_cycle_q);
        addr_cdrom_w:  $display("IO Access (W) [CDROM]:   %08x = %08x [mask=%x] [delta=%0d @ %0d]", inport_addr_i, inport_data_wr_i, inport_sel_i, dbg_delta_w, dbg_cycle_q);
        addr_gpu_w:    $display("IO Access (W) [GPU]:     %08x = %08x [mask=%x] [delta=%0d @ %0d]", inport_addr_i, inport_data_wr_i, inport_sel_i, dbg_delta_w, dbg_cycle_q);
        addr_mdec_w:   $display("IO Access (W) [MDEC]:    %08x = %08x [mask=%x] [delta=%0d @ %0d]", inport_addr_i, inport_data_wr_i, inport_sel_i, dbg_delta_w, dbg_cycle_q);
        addr_spu_w:    $display("IO Access (W) [SPU]:     %08x = %08x [mask=%x] [delta=%0d @ %0d]", inport_addr_i, inport_data_wr_i, inport_sel_i, dbg_delta_w, dbg_cycle_q);
        addr_exp2_w:   $display("IO Access (W) [EXP2]:    %08x = %08x [mask=%x] [delta=%0d @ %0d]", inport_addr_i, inport_data_wr_i, inport_sel_i, dbg_delta_w, dbg_cycle_q);
        addr_atcons_w: $display("IO Access (W) [ATCONS]:  %08x = %08x [mask=%x] [delta=%0d @ %0d]", inport_addr_i, inport_data_wr_i, inport_sel_i, dbg_delta_w, dbg_cycle_q);
        default:       $display("IO Access (W) [UNKNOWN]: %08x = %08x [mask=%x] [delta=%0d @ %0d]", inport_addr_i, inport_data_wr_i, inport_sel_i, dbg_delta_w, dbg_cycle_q);
        endcase
    end
    else
    begin
        case (1'b1)
        addr_mc1_w:    $display("IO Access (R) [MC1]:     %08x [delta=%0d @ %0d]", inport_addr_i, dbg_delta_w, dbg_cycle_q);
        addr_joy_w:    $display("IO Access (R) [JOY]:     %08x [delta=%0d @ %0d]", inport_addr_i, dbg_delta_w, dbg_cycle_q);
        addr_sio_w:    $display("IO Access (R) [SIO]:     %08x [delta=%0d @ %0d]", inport_addr_i, dbg_delta_w, dbg_cycle_q);
        addr_mc2_w:    $display("IO Access (R) [MC2]:     %08x [delta=%0d @ %0d]", inport_addr_i, dbg_delta_w, dbg_cycle_q);
        addr_irq_w:    $display("IO Access (R) [IRQ]:     %08x [delta=%0d @ %0d]", inport_addr_i, dbg_delta_w, dbg_cycle_q);
        addr_dma_w:    $display("IO Access (R) [DMA]:     %08x [delta=%0d @ %0d]", inport_addr_i, dbg_delta_w, dbg_cycle_q);
        addr_tmr_w:    $display("IO Access (R) [TMR]:     %08x [delta=%0d @ %0d]", inport_addr_i, dbg_delta_w, dbg_cycle_q);
        addr_cdrom_w:  $display("IO Access (R) [CDROM]:   %08x [delta=%0d @ %0d]", inport_addr_i, dbg_delta_w, dbg_cycle_q);
        addr_gpu_w:    $display("IO Access (R) [GPU]:     %08x [delta=%0d @ %0d]", inport_addr_i, dbg_delta_w, dbg_cycle_q);
        addr_mdec_w:   $display("IO Access (R) [MDEC]:    %08x [delta=%0d @ %0d]", inport_addr_i, dbg_delta_w, dbg_cycle_q);
        addr_spu_w:    $display("IO Access (R) [SPU]:     %08x [delta=%0d @ %0d]", inport_addr_i, dbg_delta_w, dbg_cycle_q);
        addr_exp2_w:   $display("IO Access (R) [EXP2]:    %08x [delta=%0d @ %0d]", inport_addr_i, dbg_delta_w, dbg_cycle_q);
        addr_atcons_w: $display("IO Access (R) [ATCONS]:  %08x [delta=%0d @ %0d]", inport_addr_i, dbg_delta_w, dbg_cycle_q);
        default:       $display("IO Access (R) [UNKNOWN]: %08x [delta=%0d @ %0d]", inport_addr_i, dbg_delta_w, dbg_cycle_q);
        endcase
    end
end

always @ (posedge clk_i)
if (addr_q[13:0] != 14'h2080)
begin
    if (inport_ack_o && ~we_q && v_level > 0)
        $display(" IO Resp: %08x", inport_data_rd_o);
    if (inport_err_o)
        $display(" IO Error");
end

always @ (posedge clk_i)
if (inport_cyc_i && inport_stb_i && inport_we_i && ~inport_stall_o && io_addr_w == 14'h2041)
    $display("POST1: %08x @ %d", inport_data_wr_i, dbg_cycle_q);

always @ (posedge clk_i)
if (inport_cyc_i && inport_stb_i && inport_we_i && ~inport_stall_o && io_addr_w == 14'h2042)
    $display("POST2: %08x @ %d", inport_data_wr_i, dbg_cycle_q);

`endif

//-----------------------------------------------------------------
// Simulator print
//-----------------------------------------------------------------
`ifdef verilator
  // Buffer writes
  reg [7:0] v_buffer[255:0];
  reg [7:0] v_ptr;

  integer i;

  always @ (posedge clk_i )
  if (rst_i)
      v_ptr <= 8'd0;
  else if (inport_cyc_i && inport_stb_i && inport_we_i && ~inport_stall_o && dbg_putc_w)
  begin
      v_buffer[v_ptr] = inport_data_wr_i[7:0];

      if (v_ptr == 8'd255 || inport_data_wr_i[7:0] == 8'd10) // LF
      begin
          v_buffer[v_ptr] = 8'd0; // Null terminate / clear LF

          $write("[UART] ");
          for (i=0;i<255;i=i+1)
          begin
              if (v_buffer[i] == 8'b0)
                  i = 255;
              else
                  $write("%c", v_buffer[i]);
          end
          $display(" @ %d", dbg_cycle_q);
          v_ptr <= 8'd0;
      end
      else
          v_ptr <= v_ptr + 8'd1;
  end
`endif

//-----------------------------------------------------------------
// Output Mux
//-----------------------------------------------------------------
wire src_mc1_w;
wire src_joy_w;
wire src_sio_w;
wire src_mc2_w;
wire src_irq_w;
wire src_dma_w;
wire src_tmr_w;
wire src_cdrom_w;
wire src_gpu_w;
wire src_mdec_w;
wire src_spu_w;
wire src_exp2_w;
wire src_atcons_w;
wire src_uart_w;

reg [13:0] region_q;

always @ (posedge clk_i )
if (rst_i)
    region_q <= 14'b0;
else if (~inport_stall_o)
    region_q <= {addr_uart_w, addr_mc1_w, addr_joy_w, addr_sio_w, addr_mc2_w, addr_irq_w, addr_dma_w, addr_tmr_w, addr_cdrom_w, addr_gpu_w, addr_mdec_w, addr_spu_w, addr_exp2_w, addr_atcons_w} & {14{inport_stb_i}};

assign {src_uart_w, src_mc1_w, src_joy_w, src_sio_w, src_mc2_w, src_irq_w, src_dma_w, src_tmr_w, src_cdrom_w, src_gpu_w, src_mdec_w, src_spu_w, src_exp2_w, src_atcons_w} = region_q;

// Not yet supported
wire src_dummy_w = src_mc1_w | src_mc2_w | src_exp2_w;

wire [31:0] addr_word_w = {addr_q[31:2], 2'b0};
wire [31:0] addr_byte_w = addr_q;

assign outport_joy_cyc_o          = 1'b1;
assign outport_joy_addr_o         = addr_word_w;
assign outport_joy_data_wr_o      = data_q;
assign outport_joy_we_o           = we_q;
assign outport_joy_sel_o          = sel_q;
assign outport_sio_cyc_o          = 1'b1;
assign outport_sio_addr_o         = addr_word_w;
assign outport_sio_data_wr_o      = data_q;
assign outport_sio_we_o           = we_q;
assign outport_sio_sel_o          = sel_q;
assign outport_dma_cyc_o          = 1'b1;
assign outport_dma_addr_o         = addr_word_w;
assign outport_dma_data_wr_o      = data_q;
assign outport_dma_we_o           = we_q;
assign outport_dma_sel_o          = sel_q;
assign outport_irqctrl_cyc_o      = 1'b1;
assign outport_irqctrl_addr_o     = addr_word_w;
assign outport_irqctrl_data_wr_o  = data_q;
assign outport_irqctrl_we_o       = we_q;
assign outport_irqctrl_sel_o      = sel_q;
assign outport_timers_addr_o      = addr_word_w;
assign outport_timers_data_wr_o   = data_q;
assign outport_timers_we_o        = we_q;
assign outport_cdrom_cyc_o        = 1'b1;
assign outport_cdrom_addr_o       = addr_byte_w;
assign outport_cdrom_data_wr_o    = data_q;
assign outport_cdrom_we_o         = we_q;
assign outport_cdrom_sel_o        = sel_q;
assign outport_gpu_addr_o         = addr_word_w;
assign outport_gpu_data_wr_o      = data_q;
assign outport_gpu_we_o           = we_q;
assign outport_spu_cyc_o          = 1'b1;
assign outport_spu_addr_o         = addr_word_w;
assign outport_spu_data_wr_o      = data_q;
assign outport_spu_we_o           = we_q;
assign outport_spu_sel_o          = sel_q;
assign outport_mdec_addr_o        = addr_word_w;
assign outport_mdec_data_wr_o     = data_q;
assign outport_mdec_we_o          = we_q;
assign outport_atcons_addr_o      = addr_word_w;
assign outport_atcons_data_wr_o   = data_q;
assign outport_atcons_we_o        = we_q;
assign outport_uart_addr_o        = addr_word_w;
assign outport_uart_data_wr_o     = data_q;
assign outport_uart_we_o          = we_q;

assign outport_joy_stb_o          = (state_q == STATE_ACCESS) & src_joy_w;
assign outport_sio_stb_o          = (state_q == STATE_ACCESS) & src_sio_w;
assign outport_dma_stb_o          = (state_q == STATE_ACCESS) & src_dma_w;
assign outport_irqctrl_stb_o      = (state_q == STATE_ACCESS) & src_irq_w;
assign outport_timers_stb_o       = (state_q == STATE_ACCESS) & src_tmr_w;
assign outport_cdrom_stb_o        = (state_q == STATE_ACCESS) & src_cdrom_w;
assign outport_gpu_stb_o          = (state_q == STATE_ACCESS) & src_gpu_w;
assign outport_spu_stb_o          = (state_q == STATE_ACCESS) & src_spu_w;
assign outport_mdec_stb_o         = (state_q == STATE_ACCESS) & src_mdec_w;
assign outport_atcons_stb_o       = (state_q == STATE_ACCESS) & src_atcons_w;
assign outport_uart_stb_o         = (state_q == STATE_ACCESS) & src_uart_w;

always @ *
begin
    output_stall_r = 1'b0;

    case (1'b1)
      src_joy_w     : output_stall_r = outport_joy_stall_i;
      src_sio_w     : output_stall_r = outport_sio_stall_i;
      src_dma_w     : output_stall_r = outport_dma_stall_i;
      src_irq_w     : output_stall_r = outport_irqctrl_stall_i;
      src_tmr_w     : output_stall_r = outport_timers_stall_i;
      src_cdrom_w   : output_stall_r = outport_cdrom_stall_i;
      src_gpu_w     : output_stall_r = outport_gpu_stall_i;
      src_spu_w     : output_stall_r = outport_spu_stall_i;
      src_mdec_w    : output_stall_r = outport_mdec_stall_i;
      src_atcons_w  : output_stall_r = outport_atcons_stall_i;
      src_uart_w    : output_stall_r = outport_uart_stall_i;
    endcase
end

//-----------------------------------------------------------------
// Response 
//-----------------------------------------------------------------
reg        outport_ack_r;
reg [31:0] outport_data_r;

always @ *
begin
    outport_ack_r  = 1'b0;
    outport_data_r = 32'b0;

    case (1'b1)
      src_joy_w     : outport_ack_r = outport_joy_ack_i;
      src_sio_w     : outport_ack_r = outport_sio_ack_i;
      src_dma_w     : outport_ack_r = outport_dma_ack_i;
      src_irq_w     : outport_ack_r = outport_irqctrl_ack_i;
      src_tmr_w     : outport_ack_r = outport_timers_ack_i;
      src_cdrom_w   : outport_ack_r = outport_cdrom_ack_i;
      src_gpu_w     : outport_ack_r = outport_gpu_ack_i;
      src_spu_w     : outport_ack_r = outport_spu_ack_i;
      src_mdec_w    : outport_ack_r = outport_mdec_ack_i;
      src_atcons_w  : outport_ack_r = outport_atcons_ack_i;
      src_uart_w    : outport_ack_r = outport_uart_ack_i;
      src_dummy_w   : outport_ack_r = 1'b1;
    endcase

    // TODO: re-align if required...
    case (1'b1)
      src_joy_w     : outport_data_r = outport_joy_data_rd_i;
      src_sio_w     : outport_data_r = outport_sio_data_rd_i;
      src_dma_w     : outport_data_r = outport_dma_data_rd_i;
      src_irq_w     : outport_data_r = outport_irqctrl_data_rd_i;
      src_tmr_w     : outport_data_r = outport_timers_data_rd_i;
      src_cdrom_w   : outport_data_r = outport_cdrom_data_rd_i;
      src_gpu_w     : outport_data_r = outport_gpu_data_rd_i;
      src_spu_w     : outport_data_r = outport_spu_data_rd_i;
      src_mdec_w    : outport_data_r = outport_mdec_data_rd_i;
      src_atcons_w  : outport_data_r = outport_atcons_data_rd_i;
      src_uart_w    : outport_data_r = outport_uart_data_rd_i;
    endcase    
end

assign inport_ack_o     = (state_q == STATE_RESP) & outport_ack_r;
assign inport_data_rd_o = outport_data_r;
assign inport_err_o     = (state_q == STATE_ERR);


endmodule
