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
module psf_gpu
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
     parameter AXI_ID           = 13
    ,parameter VRAM_BASE        = 50331648
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(
    // Inputs
     input           clk_i
    ,input           rst_i
    ,input  [ 31:0]  cfg_addr_i
    ,input  [ 31:0]  cfg_data_wr_i
    ,input           cfg_stb_i
    ,input           cfg_we_i
    ,input           axi_awready_i
    ,input           axi_wready_i
    ,input           axi_bvalid_i
    ,input  [  1:0]  axi_bresp_i
    ,input  [  3:0]  axi_bid_i
    ,input           axi_arready_i
    ,input           axi_rvalid_i
    ,input  [255:0]  axi_rdata_i
    ,input  [  1:0]  axi_rresp_i
    ,input  [  3:0]  axi_rid_i
    ,input           axi_rlast_i
    ,input           display_field_i
    ,input           display_hblank_i
    ,input           display_vblank_i
    ,input           gpu_m2p_valid_i
    ,input  [ 31:0]  gpu_m2p_data_i
    ,input           gpu_p2m_accept_i

    // Outputs
    ,output [ 31:0]  cfg_data_rd_o
    ,output          cfg_ack_o
    ,output          cfg_stall_o
    ,output          irq_o
    ,output          axi_awvalid_o
    ,output [ 31:0]  axi_awaddr_o
    ,output [  3:0]  axi_awid_o
    ,output [  7:0]  axi_awlen_o
    ,output [  1:0]  axi_awburst_o
    ,output          axi_wvalid_o
    ,output [255:0]  axi_wdata_o
    ,output [ 31:0]  axi_wstrb_o
    ,output          axi_wlast_o
    ,output          axi_bready_o
    ,output          axi_arvalid_o
    ,output [ 31:0]  axi_araddr_o
    ,output [  3:0]  axi_arid_o
    ,output [  7:0]  axi_arlen_o
    ,output [  1:0]  axi_arburst_o
    ,output          axi_rready_o
    ,output [  9:0]  display_res_x_o
    ,output [  8:0]  display_res_y_o
    ,output [  9:0]  display_x_o
    ,output [  8:0]  display_y_o
    ,output          display_interlaced_o
    ,output          display_pal_o
    ,output          gpu_m2p_dreq_o
    ,output          gpu_m2p_accept_o
    ,output          gpu_p2m_dreq_o
    ,output          gpu_p2m_valid_o
    ,output [ 31:0]  gpu_p2m_data_o
);



wire        cfg_sel_w      = cfg_stb_i & ~cfg_stall_o;
wire [31:0] cfg_data_rd_w;

//--------------------------------------
// Plumbing between GPU and Memory System
//--------------------------------------
wire          gpu_command_w;
wire [  1:0]  gpu_size_w;
wire          gpu_write_w;
wire [ 14:0]  gpu_addr_w;
wire [  2:0]  gpu_sub_addr_w;
wire [ 15:0]  gpu_write_mask_w;
wire [255:0]  gpu_data_out_w;
wire          gpu_busy_w;
wire          gpu_data_in_valid_w;
wire [255:0]  gpu_data_in_w;

gpu 
u_core
(
     .clk           (clk_i)
    ,.i_nrst        (~rst_i)

    ,.DIP_AllowDither(1'b1)
    ,.DIP_ForceDither(1'b0)
    ,.DIP_Allow480i(1'b1)
    ,.DIP_ForceInterlaceField(1'b0)

    ,.IRQRequest     (irq_o)

    // --------------------------------------
    // DMA
    // --------------------------------------
    ,.gpu_m2p_dreq_i(gpu_m2p_dreq_o)
    ,.gpu_m2p_valid_o(gpu_m2p_valid_i)
    ,.gpu_m2p_data_o(gpu_m2p_data_i)
    ,.gpu_m2p_accept_i(gpu_m2p_accept_o)
    ,.gpu_p2m_dreq_i(gpu_p2m_dreq_o)
    ,.gpu_p2m_valid_i(gpu_p2m_valid_o)
    ,.gpu_p2m_data_i(gpu_p2m_data_o)
    ,.gpu_p2m_accept_o(gpu_p2m_accept_i)

    // --------------------------------------
    // Memory Interface
    // --------------------------------------
    ,.o_command      (gpu_command_w)
    ,.i_busy         (gpu_busy_w)
    ,.o_commandSize  (gpu_size_w)
    
    ,.o_write        (gpu_write_w)
    ,.o_adr          (gpu_addr_w)
    ,.o_subadr       (gpu_sub_addr_w)
    ,.o_writeMask    (gpu_write_mask_w)

    ,.i_dataIn       (gpu_data_in_w)
    ,.i_dataInValid  (gpu_data_in_valid_w)
    ,.o_dataOut      (gpu_data_out_w)

    // --------------------------------------
    //   Display Controller
    // --------------------------------------
    ,.display_res_x_o(display_res_x_o)
    ,.display_res_y_o(display_res_y_o)
    ,.display_x_o(display_x_o)
    ,.display_y_o(display_y_o)
    ,.display_interlaced_o(display_interlaced_o)
    ,.display_pal_o(display_pal_o)
    ,.display_field_i(display_field_i)
    ,.display_hblank_i(display_hblank_i)
    ,.display_vblank_i(display_vblank_i)    
    
    // --------------------------------------
    //   CPU Bus
    // --------------------------------------
    ,.gpuAdr         (cfg_addr_i[3:2])
    ,.gpuSel         (cfg_sel_w)
    ,.write          (cfg_sel_w & cfg_we_i)
    ,.read           (cfg_sel_w & ~cfg_we_i)
    ,.cpuDataIn      (cfg_data_wr_i)
    ,.cpuDataOut     (cfg_data_rd_o)
    ,.validDataOut   () // X - make out own version (ack_q) for now...
);

reg ack_q;

always @ (posedge clk_i )
if (rst_i)
    ack_q <= 1'b0;
else if (cfg_sel_w)
    ack_q <= 1'b1;
else
    ack_q <= 1'b0;

assign cfg_ack_o     = ack_q;
assign cfg_stall_o   = ack_q;

//-----------------------------------------------------------------
// GPU Mem Cache
//-----------------------------------------------------------------
gpu_mem_cache
#(
     .AXI_ID(AXI_ID)
    ,.VRAM_BASE(VRAM_BASE)
)
u_cache
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)

    ,.gpu_command_i(gpu_command_w)
    ,.gpu_size_i(gpu_size_w)
    ,.gpu_write_i(gpu_write_w)
    ,.gpu_addr_i(gpu_addr_w)
    ,.gpu_sub_addr_i(gpu_sub_addr_w)
    ,.gpu_write_mask_i(gpu_write_mask_w)
    ,.gpu_data_out_i(gpu_data_out_w)
    ,.gpu_busy_o(gpu_busy_w)
    ,.gpu_data_in_valid_o(gpu_data_in_valid_w)
    ,.gpu_data_in_o(gpu_data_in_w)

    ,.axi_awvalid_o(axi_awvalid_o)
    ,.axi_awaddr_o(axi_awaddr_o)
    ,.axi_awid_o(axi_awid_o)
    ,.axi_awlen_o(axi_awlen_o)
    ,.axi_awburst_o(axi_awburst_o)
    ,.axi_wvalid_o(axi_wvalid_o)
    ,.axi_wdata_o(axi_wdata_o)
    ,.axi_wstrb_o(axi_wstrb_o)
    ,.axi_wlast_o(axi_wlast_o)
    ,.axi_bready_o(axi_bready_o)
    ,.axi_arvalid_o(axi_arvalid_o)
    ,.axi_araddr_o(axi_araddr_o)
    ,.axi_arid_o(axi_arid_o)
    ,.axi_arlen_o(axi_arlen_o)
    ,.axi_arburst_o(axi_arburst_o)
    ,.axi_rready_o(axi_rready_o)
    ,.axi_awready_i(axi_awready_i)
    ,.axi_wready_i(axi_wready_i)
    ,.axi_bvalid_i(axi_bvalid_i)
    ,.axi_bresp_i(axi_bresp_i)
    ,.axi_bid_i(axi_bid_i)
    ,.axi_arready_i(axi_arready_i)
    ,.axi_rvalid_i(axi_rvalid_i)
    ,.axi_rdata_i(axi_rdata_i)
    ,.axi_rresp_i(axi_rresp_i)
    ,.axi_rid_i(axi_rid_i)
    ,.axi_rlast_i(axi_rlast_i)
);

`ifdef verilator
function [0:0] invalidate_cache; /*verilator public*/
integer i;
begin
    for (i=0;i<1024;i=i+1)
    begin
    	u_cache.u_tag0.ram[i] = 0;
    end

    invalidate_cache = 1'b1;
end
endfunction
`endif


endmodule
