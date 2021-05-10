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
module riscv_tcm_wb
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
     parameter BOOT_VECTOR      = 32'h80000000
    ,parameter CORE_ID          = 0
    ,parameter TCM_MEM_BASE     = 32'h80000000
    ,parameter NUM_PORTS        = 4
    ,parameter PORT_SEL_H       = 9
    ,parameter PORT_SEL_L       = 8
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(
    // Inputs
     input           clk_i
    ,input           rst_i
    ,input           rst_cpu_i
    ,input           axi_t_awvalid_i
    ,input  [ 31:0]  axi_t_awaddr_i
    ,input  [  3:0]  axi_t_awid_i
    ,input  [  7:0]  axi_t_awlen_i
    ,input  [  1:0]  axi_t_awburst_i
    ,input  [  2:0]  axi_t_awsize_i
    ,input           axi_t_wvalid_i
    ,input  [ 31:0]  axi_t_wdata_i
    ,input  [  3:0]  axi_t_wstrb_i
    ,input           axi_t_wlast_i
    ,input           axi_t_bready_i
    ,input           axi_t_arvalid_i
    ,input  [ 31:0]  axi_t_araddr_i
    ,input  [  3:0]  axi_t_arid_i
    ,input  [  7:0]  axi_t_arlen_i
    ,input  [  1:0]  axi_t_arburst_i
    ,input  [  2:0]  axi_t_arsize_i
    ,input           axi_t_rready_i
    ,input  [ 31:0]  intr_i
    ,input  [ 31:0]  peripheral0_data_rd_i
    ,input           peripheral0_ack_i
    ,input           peripheral0_stall_i
    ,input  [ 31:0]  peripheral1_data_rd_i
    ,input           peripheral1_ack_i
    ,input           peripheral1_stall_i
    ,input  [ 31:0]  peripheral2_data_rd_i
    ,input           peripheral2_ack_i
    ,input           peripheral2_stall_i
    ,input  [ 31:0]  peripheral3_data_rd_i
    ,input           peripheral3_ack_i
    ,input           peripheral3_stall_i

    // Outputs
    ,output          axi_t_awready_o
    ,output          axi_t_wready_o
    ,output          axi_t_bvalid_o
    ,output [  1:0]  axi_t_bresp_o
    ,output [  3:0]  axi_t_bid_o
    ,output          axi_t_arready_o
    ,output          axi_t_rvalid_o
    ,output [ 31:0]  axi_t_rdata_o
    ,output [  1:0]  axi_t_rresp_o
    ,output [  3:0]  axi_t_rid_o
    ,output          axi_t_rlast_o
    ,output [ 31:0]  peripheral0_addr_o
    ,output [ 31:0]  peripheral0_data_wr_o
    ,output          peripheral0_stb_o
    ,output          peripheral0_we_o
    ,output [ 31:0]  peripheral1_addr_o
    ,output [ 31:0]  peripheral1_data_wr_o
    ,output          peripheral1_stb_o
    ,output          peripheral1_we_o
    ,output [ 31:0]  peripheral2_addr_o
    ,output [ 31:0]  peripheral2_data_wr_o
    ,output          peripheral2_stb_o
    ,output          peripheral2_we_o
    ,output [ 31:0]  peripheral3_addr_o
    ,output [ 31:0]  peripheral3_data_wr_o
    ,output          peripheral3_stb_o
    ,output          peripheral3_we_o
);

wire  [ 31:0]  ifetch_pc_w;
wire  [ 31:0]  dport_tcm_data_rd_w;
wire           dport_tcm_cacheable_w;
wire           dport_flush_w;
wire  [  3:0]  dport_tcm_wr_w;
wire           ifetch_rd_w;
wire           dport_axi_accept_w;
wire           dport_cacheable_w;
wire           dport_tcm_flush_w;
wire  [ 10:0]  dport_resp_tag_w;
wire  [ 10:0]  dport_axi_resp_tag_w;
wire           ifetch_accept_w;
wire  [ 31:0]  dport_data_rd_w;
wire           dport_tcm_invalidate_w;
wire           dport_ack_w;
wire  [ 10:0]  dport_axi_req_tag_w;
wire  [ 31:0]  dport_data_wr_w;
wire           dport_invalidate_w;
wire  [ 10:0]  dport_tcm_req_tag_w;
wire  [ 31:0]  dport_tcm_addr_w;
wire           dport_axi_error_w;
wire           dport_tcm_ack_w;
wire           dport_tcm_rd_w;
wire  [ 10:0]  dport_tcm_resp_tag_w;
wire           dport_writeback_w;
wire  [ 31:0]  cpu_id_w = CORE_ID;
wire           dport_rd_w;
wire           dport_axi_ack_w;
wire           dport_axi_rd_w;
wire  [ 31:0]  dport_axi_data_rd_w;
wire           dport_axi_invalidate_w;
wire  [ 31:0]  boot_vector_w = BOOT_VECTOR;
wire  [ 31:0]  dport_addr_w;
wire           ifetch_error_w;
wire  [ 31:0]  dport_tcm_data_wr_w;
wire           ifetch_flush_w;
wire  [ 31:0]  dport_axi_addr_w;
wire           dport_error_w;
wire           dport_tcm_accept_w;
wire           ifetch_invalidate_w;
wire           dport_axi_writeback_w;
wire  [  3:0]  dport_wr_w;
wire           ifetch_valid_w;
wire  [ 31:0]  dport_axi_data_wr_w;
wire  [ 10:0]  dport_req_tag_w;
wire  [ 31:0]  ifetch_inst_w;
wire           dport_axi_cacheable_w;
wire           dport_tcm_writeback_w;
wire  [  3:0]  dport_axi_wr_w;
wire           dport_axi_flush_w;
wire           dport_tcm_error_w;
wire           dport_accept_w;


dport_wb
#(
     .PORT_SEL_H(PORT_SEL_H)
    ,.PORT_SEL_L(PORT_SEL_L)
    ,.PORT_SEL_W(2)
    ,.NUM_PORTS(NUM_PORTS)
)
u_io
(
    // Inputs
     .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.mem_addr_i(dport_axi_addr_w)
    ,.mem_data_wr_i(dport_axi_data_wr_w)
    ,.mem_rd_i(dport_axi_rd_w)
    ,.mem_wr_i(dport_axi_wr_w)
    ,.mem_cacheable_i(dport_axi_cacheable_w)
    ,.mem_req_tag_i(dport_axi_req_tag_w)
    ,.mem_invalidate_i(dport_axi_invalidate_w)
    ,.mem_writeback_i(dport_axi_writeback_w)
    ,.mem_flush_i(dport_axi_flush_w)
    ,.peripheral0_data_rd_i(peripheral0_data_rd_i)
    ,.peripheral0_ack_i(peripheral0_ack_i)
    ,.peripheral0_stall_i(peripheral0_stall_i)
    ,.peripheral1_data_rd_i(peripheral1_data_rd_i)
    ,.peripheral1_ack_i(peripheral1_ack_i)
    ,.peripheral1_stall_i(peripheral1_stall_i)
    ,.peripheral2_data_rd_i(peripheral2_data_rd_i)
    ,.peripheral2_ack_i(peripheral2_ack_i)
    ,.peripheral2_stall_i(peripheral2_stall_i)
    ,.peripheral3_data_rd_i(peripheral3_data_rd_i)
    ,.peripheral3_ack_i(peripheral3_ack_i)
    ,.peripheral3_stall_i(peripheral3_stall_i)

    // Outputs
    ,.mem_data_rd_o(dport_axi_data_rd_w)
    ,.mem_accept_o(dport_axi_accept_w)
    ,.mem_ack_o(dport_axi_ack_w)
    ,.mem_error_o(dport_axi_error_w)
    ,.mem_resp_tag_o(dport_axi_resp_tag_w)
    ,.peripheral0_addr_o(peripheral0_addr_o)
    ,.peripheral0_data_wr_o(peripheral0_data_wr_o)
    ,.peripheral0_stb_o(peripheral0_stb_o)
    ,.peripheral0_we_o(peripheral0_we_o)
    ,.peripheral1_addr_o(peripheral1_addr_o)
    ,.peripheral1_data_wr_o(peripheral1_data_wr_o)
    ,.peripheral1_stb_o(peripheral1_stb_o)
    ,.peripheral1_we_o(peripheral1_we_o)
    ,.peripheral2_addr_o(peripheral2_addr_o)
    ,.peripheral2_data_wr_o(peripheral2_data_wr_o)
    ,.peripheral2_stb_o(peripheral2_stb_o)
    ,.peripheral2_we_o(peripheral2_we_o)
    ,.peripheral3_addr_o(peripheral3_addr_o)
    ,.peripheral3_data_wr_o(peripheral3_data_wr_o)
    ,.peripheral3_stb_o(peripheral3_stb_o)
    ,.peripheral3_we_o(peripheral3_we_o)
);


riscv_core
#(
     .ISR_VECTOR(16)
)
u_core
(
    // Inputs
     .clk_i(clk_i)
    ,.rst_i(rst_cpu_i)
    ,.mem_d_data_rd_i(dport_data_rd_w)
    ,.mem_d_accept_i(dport_accept_w)
    ,.mem_d_ack_i(dport_ack_w)
    ,.mem_d_error_i(dport_error_w)
    ,.mem_d_resp_tag_i(dport_resp_tag_w)
    ,.mem_i_accept_i(ifetch_accept_w)
    ,.mem_i_valid_i(ifetch_valid_w)
    ,.mem_i_error_i(ifetch_error_w)
    ,.mem_i_inst_i(ifetch_inst_w)
    ,.intr_i(intr_i[0:0])
    ,.reset_vector_i(boot_vector_w)
    ,.cpu_id_i(cpu_id_w)

    // Outputs
    ,.mem_d_addr_o(dport_addr_w)
    ,.mem_d_data_wr_o(dport_data_wr_w)
    ,.mem_d_rd_o(dport_rd_w)
    ,.mem_d_wr_o(dport_wr_w)
    ,.mem_d_cacheable_o(dport_cacheable_w)
    ,.mem_d_req_tag_o(dport_req_tag_w)
    ,.mem_d_invalidate_o(dport_invalidate_w)
    ,.mem_d_writeback_o(dport_writeback_w)
    ,.mem_d_flush_o(dport_flush_w)
    ,.mem_i_rd_o(ifetch_rd_w)
    ,.mem_i_flush_o(ifetch_flush_w)
    ,.mem_i_invalidate_o(ifetch_invalidate_w)
    ,.mem_i_pc_o(ifetch_pc_w)
);


dport_mux
#(
     .TCM_MEM_BASE(TCM_MEM_BASE)
)
u_dmux
(
    // Inputs
     .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.mem_addr_i(dport_addr_w)
    ,.mem_data_wr_i(dport_data_wr_w)
    ,.mem_rd_i(dport_rd_w)
    ,.mem_wr_i(dport_wr_w)
    ,.mem_cacheable_i(dport_cacheable_w)
    ,.mem_req_tag_i(dport_req_tag_w)
    ,.mem_invalidate_i(dport_invalidate_w)
    ,.mem_writeback_i(dport_writeback_w)
    ,.mem_flush_i(dport_flush_w)
    ,.mem_tcm_data_rd_i(dport_tcm_data_rd_w)
    ,.mem_tcm_accept_i(dport_tcm_accept_w)
    ,.mem_tcm_ack_i(dport_tcm_ack_w)
    ,.mem_tcm_error_i(dport_tcm_error_w)
    ,.mem_tcm_resp_tag_i(dport_tcm_resp_tag_w)
    ,.mem_ext_data_rd_i(dport_axi_data_rd_w)
    ,.mem_ext_accept_i(dport_axi_accept_w)
    ,.mem_ext_ack_i(dport_axi_ack_w)
    ,.mem_ext_error_i(dport_axi_error_w)
    ,.mem_ext_resp_tag_i(dport_axi_resp_tag_w)

    // Outputs
    ,.mem_data_rd_o(dport_data_rd_w)
    ,.mem_accept_o(dport_accept_w)
    ,.mem_ack_o(dport_ack_w)
    ,.mem_error_o(dport_error_w)
    ,.mem_resp_tag_o(dport_resp_tag_w)
    ,.mem_tcm_addr_o(dport_tcm_addr_w)
    ,.mem_tcm_data_wr_o(dport_tcm_data_wr_w)
    ,.mem_tcm_rd_o(dport_tcm_rd_w)
    ,.mem_tcm_wr_o(dport_tcm_wr_w)
    ,.mem_tcm_cacheable_o(dport_tcm_cacheable_w)
    ,.mem_tcm_req_tag_o(dport_tcm_req_tag_w)
    ,.mem_tcm_invalidate_o(dport_tcm_invalidate_w)
    ,.mem_tcm_writeback_o(dport_tcm_writeback_w)
    ,.mem_tcm_flush_o(dport_tcm_flush_w)
    ,.mem_ext_addr_o(dport_axi_addr_w)
    ,.mem_ext_data_wr_o(dport_axi_data_wr_w)
    ,.mem_ext_rd_o(dport_axi_rd_w)
    ,.mem_ext_wr_o(dport_axi_wr_w)
    ,.mem_ext_cacheable_o(dport_axi_cacheable_w)
    ,.mem_ext_req_tag_o(dport_axi_req_tag_w)
    ,.mem_ext_invalidate_o(dport_axi_invalidate_w)
    ,.mem_ext_writeback_o(dport_axi_writeback_w)
    ,.mem_ext_flush_o(dport_axi_flush_w)
);


tcm_mem
u_tcm
(
    // Inputs
     .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.mem_i_rd_i(ifetch_rd_w)
    ,.mem_i_flush_i(ifetch_flush_w)
    ,.mem_i_invalidate_i(ifetch_invalidate_w)
    ,.mem_i_pc_i(ifetch_pc_w)
    ,.mem_d_addr_i(dport_tcm_addr_w)
    ,.mem_d_data_wr_i(dport_tcm_data_wr_w)
    ,.mem_d_rd_i(dport_tcm_rd_w)
    ,.mem_d_wr_i(dport_tcm_wr_w)
    ,.mem_d_cacheable_i(dport_tcm_cacheable_w)
    ,.mem_d_req_tag_i(dport_tcm_req_tag_w)
    ,.mem_d_invalidate_i(dport_tcm_invalidate_w)
    ,.mem_d_writeback_i(dport_tcm_writeback_w)
    ,.mem_d_flush_i(dport_tcm_flush_w)
    ,.axi_awvalid_i(axi_t_awvalid_i)
    ,.axi_awaddr_i(axi_t_awaddr_i)
    ,.axi_awid_i(axi_t_awid_i)
    ,.axi_awlen_i(axi_t_awlen_i)
    ,.axi_awburst_i(axi_t_awburst_i)
    ,.axi_awsize_i(axi_t_awsize_i)
    ,.axi_wvalid_i(axi_t_wvalid_i)
    ,.axi_wdata_i(axi_t_wdata_i)
    ,.axi_wstrb_i(axi_t_wstrb_i)
    ,.axi_wlast_i(axi_t_wlast_i)
    ,.axi_bready_i(axi_t_bready_i)
    ,.axi_arvalid_i(axi_t_arvalid_i)
    ,.axi_araddr_i(axi_t_araddr_i)
    ,.axi_arid_i(axi_t_arid_i)
    ,.axi_arlen_i(axi_t_arlen_i)
    ,.axi_arburst_i(axi_t_arburst_i)
    ,.axi_arsize_i(axi_t_arsize_i)
    ,.axi_rready_i(axi_t_rready_i)

    // Outputs
    ,.mem_i_accept_o(ifetch_accept_w)
    ,.mem_i_valid_o(ifetch_valid_w)
    ,.mem_i_error_o(ifetch_error_w)
    ,.mem_i_inst_o(ifetch_inst_w)
    ,.mem_d_data_rd_o(dport_tcm_data_rd_w)
    ,.mem_d_accept_o(dport_tcm_accept_w)
    ,.mem_d_ack_o(dport_tcm_ack_w)
    ,.mem_d_error_o(dport_tcm_error_w)
    ,.mem_d_resp_tag_o(dport_tcm_resp_tag_w)
    ,.axi_awready_o(axi_t_awready_o)
    ,.axi_wready_o(axi_t_wready_o)
    ,.axi_bvalid_o(axi_t_bvalid_o)
    ,.axi_bresp_o(axi_t_bresp_o)
    ,.axi_bid_o(axi_t_bid_o)
    ,.axi_arready_o(axi_t_arready_o)
    ,.axi_rvalid_o(axi_t_rvalid_o)
    ,.axi_rdata_o(axi_t_rdata_o)
    ,.axi_rresp_o(axi_t_rresp_o)
    ,.axi_rid_o(axi_t_rid_o)
    ,.axi_rlast_o(axi_t_rlast_o)
);



endmodule
