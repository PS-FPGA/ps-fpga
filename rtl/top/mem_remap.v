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
module mem_remap
(
    // Inputs
     input           inport_awvalid_i
    ,input  [ 31:0]  inport_awaddr_i
    ,input  [  3:0]  inport_awid_i
    ,input  [  7:0]  inport_awlen_i
    ,input  [  1:0]  inport_awburst_i
    ,input  [  2:0]  inport_awsize_i
    ,input           inport_wvalid_i
    ,input  [ 31:0]  inport_wdata_i
    ,input  [  3:0]  inport_wstrb_i
    ,input           inport_wlast_i
    ,input           inport_bready_i
    ,input           inport_arvalid_i
    ,input  [ 31:0]  inport_araddr_i
    ,input  [  3:0]  inport_arid_i
    ,input  [  7:0]  inport_arlen_i
    ,input  [  1:0]  inport_arburst_i
    ,input  [  2:0]  inport_arsize_i
    ,input           inport_rready_i
    ,input           outport_awready_i
    ,input           outport_wready_i
    ,input           outport_bvalid_i
    ,input  [  1:0]  outport_bresp_i
    ,input  [  3:0]  outport_bid_i
    ,input           outport_arready_i
    ,input           outport_rvalid_i
    ,input  [ 31:0]  outport_rdata_i
    ,input  [  1:0]  outport_rresp_i
    ,input  [  3:0]  outport_rid_i
    ,input           outport_rlast_i

    // Outputs
    ,output          inport_awready_o
    ,output          inport_wready_o
    ,output          inport_bvalid_o
    ,output [  1:0]  inport_bresp_o
    ,output [  3:0]  inport_bid_o
    ,output          inport_arready_o
    ,output          inport_rvalid_o
    ,output [ 31:0]  inport_rdata_o
    ,output [  1:0]  inport_rresp_o
    ,output [  3:0]  inport_rid_o
    ,output          inport_rlast_o
    ,output          outport_awvalid_o
    ,output [ 31:0]  outport_awaddr_o
    ,output [  3:0]  outport_awid_o
    ,output [  7:0]  outport_awlen_o
    ,output [  1:0]  outport_awburst_o
    ,output [  2:0]  outport_awsize_o
    ,output          outport_wvalid_o
    ,output [ 31:0]  outport_wdata_o
    ,output [  3:0]  outport_wstrb_o
    ,output          outport_wlast_o
    ,output          outport_bready_o
    ,output          outport_arvalid_o
    ,output [ 31:0]  outport_araddr_o
    ,output [  3:0]  outport_arid_o
    ,output [  7:0]  outport_arlen_o
    ,output [  1:0]  outport_arburst_o
    ,output [  2:0]  outport_arsize_o
    ,output          outport_rready_o
);



//  KUSEG     KSEG0     KSEG1
//  00000000h 80000000h A0000000h  2048K  Main RAM (first 64K reserved for BIOS)
//  1F000000h 9F000000h BF000000h  8192K  Expansion Region 1 (ROM/RAM)
//  1F800000h 9F800000h    --      1K     Scratchpad (D-Cache used as Fast RAM)
//  1F801000h 9F801000h BF801000h  8K     I/O Ports
//  1F802000h 9F802000h BF802000h  8K     Expansion Region 2 (I/O Ports)
//  1FA00000h 9FA00000h BFA00000h  2048K  Expansion Region 3 (SRAM BIOS region for DTL cards)
//  1FC00000h 9FC00000h BFC00000h  512K   BIOS ROM (Kernel) (4096K max)
//        FFFE0000h (KSEG2)        0.5K   I/O Ports (Cache Control)

//--------------------------------------------------------------------
// Write address remapping
//--------------------------------------------------------------------  
reg [31:0] awaddr_r;

always @ *
begin
    awaddr_r = inport_awaddr_i;

    // Debugger - no translate
    if (inport_awid_i == 4'hC)
        awaddr_r = inport_awaddr_i;
    // Direct VRAM access
    else if (inport_awaddr_i[31:24] == 8'h03)
        awaddr_r = inport_awaddr_i;
    // 0x00000000 - 0x00FFFFFF -> 0x00000000 [16MB]
    // 0x1F000000 - 0x1FFFFFFF -> 0x01000000 [16MB]
    else if (|inport_awaddr_i[28:24])
        awaddr_r[31:24] = 8'h01;
    // Main RAM (2MB mirrored)
    else if (!inport_awaddr_i[23])
        awaddr_r[31:21] = 11'b0;
    else
        awaddr_r[31:29] = 3'b0;
end

assign outport_awaddr_o  = awaddr_r;

//--------------------------------------------------------------------
// Read address remapping
//--------------------------------------------------------------------  
reg [31:0] araddr_r;

always @ *
begin
    araddr_r = inport_araddr_i;

    // Debugger - no translate
    if (inport_arid_i == 4'hC)
        araddr_r = inport_araddr_i;
    // Direct VRAM access
    else if (inport_araddr_i[31:24] == 8'h03)
        araddr_r = inport_araddr_i;
    // 0x00000000 - 0x00FFFFFF -> 0x00000000 [16MB]
    // 0x1F000000 - 0x1FFFFFFF -> 0x01000000 [16MB]
    else if (|inport_araddr_i[28:24])
        araddr_r[31:24] = 8'h01;
    // Main RAM (2MB mirrored)
    else if (!inport_araddr_i[23])
        araddr_r[31:21] = 11'b0;
    else
        araddr_r[31:29] = 3'b0;
end

assign outport_araddr_o  = araddr_r;

//--------------------------------------------------------------------
// Straight through
//--------------------------------------------------------------------  
// In -> Out
assign outport_awvalid_o = inport_awvalid_i;
assign outport_awid_o    = inport_awid_i;
assign outport_awlen_o   = inport_awlen_i;
assign outport_awburst_o = inport_awburst_i;
assign outport_wvalid_o  = inport_wvalid_i;
assign outport_wdata_o   = inport_wdata_i;
assign outport_wstrb_o   = inport_wstrb_i;
assign outport_wlast_o   = inport_wlast_i;
assign outport_bready_o  = inport_bready_i;
assign outport_arvalid_o = inport_arvalid_i;
assign outport_arid_o    = inport_arid_i;
assign outport_arlen_o   = inport_arlen_i;
assign outport_arburst_o = inport_arburst_i;
assign outport_rready_o  = inport_rready_i;

// Out -> In
assign inport_awready_o  = outport_awready_i;
assign inport_wready_o   = outport_wready_i;
assign inport_bvalid_o   = outport_bvalid_i;
assign inport_bresp_o    = outport_bresp_i;
assign inport_bid_o      = outport_bid_i;
assign inport_arready_o  = outport_arready_i;
assign inport_rvalid_o   = outport_rvalid_i;
assign inport_rdata_o    = outport_rdata_i;
assign inport_rresp_o    = outport_rresp_i;
assign inport_rid_o      = outport_rid_i;
assign inport_rlast_o    = outport_rlast_i;


endmodule
