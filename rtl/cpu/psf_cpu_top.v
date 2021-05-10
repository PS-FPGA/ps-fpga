//-----------------------------------------------------------------
//                          MPX Core
//                            V0.1
//                   github.com/ultraembedded
//                       Copyright 2020
//
//                   admin@ultra-embedded.com
//
//                     License: Apache 2.0
//-----------------------------------------------------------------
// Copyright 2020 Ultra-Embedded.com
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//     http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//-----------------------------------------------------------------
module psf_cpu_top
(
    // Inputs
     input           clk_i
    ,input           rst_i
    ,input           mem_d_awready_i
    ,input           mem_d_wready_i
    ,input           mem_d_bvalid_i
    ,input  [  1:0]  mem_d_bresp_i
    ,input  [  3:0]  mem_d_bid_i
    ,input           mem_d_arready_i
    ,input           mem_d_rvalid_i
    ,input  [ 31:0]  mem_d_rdata_i
    ,input  [  1:0]  mem_d_rresp_i
    ,input  [  3:0]  mem_d_rid_i
    ,input           mem_d_rlast_i
    ,input           mem_i_awready_i
    ,input           mem_i_wready_i
    ,input           mem_i_bvalid_i
    ,input  [  1:0]  mem_i_bresp_i
    ,input  [  3:0]  mem_i_bid_i
    ,input           mem_i_arready_i
    ,input           mem_i_rvalid_i
    ,input  [ 31:0]  mem_i_rdata_i
    ,input  [  1:0]  mem_i_rresp_i
    ,input  [  3:0]  mem_i_rid_i
    ,input           mem_i_rlast_i
    ,input  [  5:0]  intr_i
    ,input           nmi_i
    ,input  [  5:0]  debug_src_i

    // Outputs
    ,output          mem_d_awvalid_o
    ,output [ 31:0]  mem_d_awaddr_o
    ,output [  3:0]  mem_d_awid_o
    ,output [  7:0]  mem_d_awlen_o
    ,output [  1:0]  mem_d_awburst_o
    ,output [  2:0]  mem_d_awsize_o
    ,output          mem_d_wvalid_o
    ,output [ 31:0]  mem_d_wdata_o
    ,output [  3:0]  mem_d_wstrb_o
    ,output          mem_d_wlast_o
    ,output          mem_d_bready_o
    ,output          mem_d_arvalid_o
    ,output [ 31:0]  mem_d_araddr_o
    ,output [  3:0]  mem_d_arid_o
    ,output [  7:0]  mem_d_arlen_o
    ,output [  1:0]  mem_d_arburst_o
    ,output [  2:0]  mem_d_arsize_o
    ,output          mem_d_rready_o
    ,output          mem_i_awvalid_o
    ,output [ 31:0]  mem_i_awaddr_o
    ,output [  3:0]  mem_i_awid_o
    ,output [  7:0]  mem_i_awlen_o
    ,output [  1:0]  mem_i_awburst_o
    ,output [  2:0]  mem_i_awsize_o
    ,output          mem_i_wvalid_o
    ,output [ 31:0]  mem_i_wdata_o
    ,output [  3:0]  mem_i_wstrb_o
    ,output          mem_i_wlast_o
    ,output          mem_i_bready_o
    ,output          mem_i_arvalid_o
    ,output [ 31:0]  mem_i_araddr_o
    ,output [  3:0]  mem_i_arid_o
    ,output [  7:0]  mem_i_arlen_o
    ,output [  1:0]  mem_i_arburst_o
    ,output [  2:0]  mem_i_arsize_o
    ,output          mem_i_rready_o
    ,output [ 31:0]  debug_o
);



`include "mpx_defs.v"

//-------------------------------------------------------------
// ICACHE
//-------------------------------------------------------------
wire          icache_rd_w;
wire          icache_flush_w;
wire          icache_invalidate_w;
wire [ 31:0]  icache_pc_w;
wire          icache_accept_w;
wire          icache_valid_w;
wire          icache_error_w;
wire [ 31:0]  icache_inst_w;

wire [ 31:0]  mem_i_araddr_w;

icache
u_icache
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)

    ,.req_rd_i(icache_rd_w)
    ,.req_flush_i(icache_flush_w)
    ,.req_invalidate_i(icache_invalidate_w)
    ,.req_pc_i(icache_pc_w)
    ,.req_accept_o(icache_accept_w)
    ,.req_valid_o(icache_valid_w)
    ,.req_error_o(icache_error_w)
    ,.req_inst_o(icache_inst_w)

    ,.axi_awvalid_o(mem_i_awvalid_o)
    ,.axi_awaddr_o(mem_i_awaddr_o)
    ,.axi_awid_o(mem_i_awid_o)
    ,.axi_awlen_o(mem_i_awlen_o)
    ,.axi_awburst_o(mem_i_awburst_o)
    ,.axi_awsize_o()
    ,.axi_wvalid_o(mem_i_wvalid_o)
    ,.axi_wdata_o(mem_i_wdata_o)
    ,.axi_wstrb_o(mem_i_wstrb_o)
    ,.axi_wlast_o(mem_i_wlast_o)
    ,.axi_bready_o(mem_i_bready_o)
    ,.axi_arvalid_o(mem_i_arvalid_o)
    ,.axi_araddr_o(mem_i_araddr_w)
    ,.axi_arid_o(mem_i_arid_o)
    ,.axi_arlen_o(mem_i_arlen_o)
    ,.axi_arburst_o(mem_i_arburst_o)
    ,.axi_arsize_o()
    ,.axi_rready_o(mem_i_rready_o)
    ,.axi_awready_i(mem_i_awready_i)
    ,.axi_wready_i(mem_i_wready_i)
    ,.axi_bvalid_i(mem_i_bvalid_i)
    ,.axi_bresp_i(mem_i_bresp_i)
    ,.axi_bid_i(mem_i_bid_i)
    ,.axi_arready_i(mem_i_arready_i)
    ,.axi_rvalid_i(mem_i_rvalid_i)
    ,.axi_rdata_i(mem_i_rdata_i)
    ,.axi_rresp_i(mem_i_rresp_i)
    ,.axi_rid_i(mem_i_rid_i)
    ,.axi_rlast_i(mem_i_rlast_i)
);

// Tie off segment bits
assign mem_i_araddr_o = {3'b0, mem_i_araddr_w[28:0]};

assign mem_i_arsize_o = 3'd2;
assign mem_i_awsize_o = 3'd2;

reg [31:0] debug_q;
always @ (posedge clk_i)
    debug_q <= icache_pc_w;
assign debug_o = debug_q;

`ifdef verilator
wire [24:0] v_masked_pc_w = icache_pc_w[24:0];
wire        v_bios_call_w = (v_masked_pc_w == 25'ha0) | (v_masked_pc_w == 25'hb0) | (v_masked_pc_w == 25'hc0);
`endif

//-------------------------------------------------------------
// L1M/Scratchpad
//-------------------------------------------------------------
wire [ 31:0]  dcache_addr_w;
wire [ 31:0]  dcache_data_wr_w;
wire          dcache_rd_w;
wire [  3:0]  dcache_wr_w;
wire          dcache_cacheable_w;
wire [ 10:0]  dcache_req_tag_w;
wire          dcache_invalidate_w;
wire          dcache_writeback_w;
wire          dcache_flush_w;
wire [ 31:0]  dcache_data_rd_w;
wire          dcache_accept_w;
wire          dcache_ack_w;
wire          dcache_error_w;
wire [ 10:0]  dcache_resp_tag_w;

wire [ 31:0]  mem_d_awaddr_w;
wire [ 31:0]  mem_d_araddr_w;

psf_dmem
u_dmem
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)

    ,.mem_addr_i(dcache_addr_w)
    ,.mem_data_wr_i(dcache_data_wr_w)
    ,.mem_rd_i(dcache_rd_w)
    ,.mem_wr_i(dcache_wr_w)
    ,.mem_cacheable_i(dcache_cacheable_w)
    ,.mem_req_tag_i(dcache_req_tag_w)
    ,.mem_invalidate_i(dcache_invalidate_w)
    ,.mem_writeback_i(dcache_writeback_w)
    ,.mem_flush_i(icache_flush_w) // Tied to common cache flush
    ,.mem_data_rd_o(dcache_data_rd_w)
    ,.mem_accept_o(dcache_accept_w)
    ,.mem_ack_o(dcache_ack_w)
    ,.mem_error_o(dcache_error_w)
    ,.mem_resp_tag_o(dcache_resp_tag_w)

    ,.axi_awvalid_o(mem_d_awvalid_o)
    ,.axi_awaddr_o(mem_d_awaddr_w)
    ,.axi_awid_o(mem_d_awid_o)
    ,.axi_awlen_o(mem_d_awlen_o)
    ,.axi_awburst_o(mem_d_awburst_o)
    ,.axi_awsize_o(mem_d_awsize_o)
    ,.axi_wvalid_o(mem_d_wvalid_o)
    ,.axi_wdata_o(mem_d_wdata_o)
    ,.axi_wstrb_o(mem_d_wstrb_o)
    ,.axi_wlast_o(mem_d_wlast_o)
    ,.axi_bready_o(mem_d_bready_o)
    ,.axi_arvalid_o(mem_d_arvalid_o)
    ,.axi_araddr_o(mem_d_araddr_w)
    ,.axi_arid_o(mem_d_arid_o)
    ,.axi_arlen_o(mem_d_arlen_o)
    ,.axi_arburst_o(mem_d_arburst_o)
    ,.axi_arsize_o(mem_d_arsize_o)
    ,.axi_rready_o(mem_d_rready_o)
    ,.axi_awready_i(mem_d_awready_i)
    ,.axi_wready_i(mem_d_wready_i)
    ,.axi_bvalid_i(mem_d_bvalid_i)
    ,.axi_bresp_i(mem_d_bresp_i)
    ,.axi_bid_i(mem_d_bid_i)
    ,.axi_arready_i(mem_d_arready_i)
    ,.axi_rvalid_i(mem_d_rvalid_i)
    ,.axi_rdata_i(mem_d_rdata_i)
    ,.axi_rresp_i(mem_d_rresp_i)
    ,.axi_rid_i(mem_d_rid_i)
    ,.axi_rlast_i(mem_d_rlast_i)
);

// Tie off segment bits
assign mem_d_awaddr_o = {3'b0, mem_d_awaddr_w[28:0]};
assign mem_d_araddr_o = {3'b0, mem_d_araddr_w[28:0]};

//-------------------------------------------------------------
// CPU Core
//-------------------------------------------------------------
wire [31:0] cop0_status_w;
wire [31:0] mem_d_addr_w;

wire        cop2_valid_w;
wire [31:0] cop2_opcode_w;
wire        cop2_reg_write_w;
wire [5:0]  cop2_reg_waddr_w;
wire [31:0] cop2_reg_wdata_w;
wire [5:0]  cop2_reg_raddr_w;
wire [31:0] cop2_reg_rdata_w;
wire        cop2_accept_w;

mpx_core
u_cpu
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)

    ,.intr_i(intr_i)

`ifdef BOOT_RESTORE_FW
    ,.reset_vector_i(32'hbfb00000)
`else
    ,.reset_vector_i(32'hbfc00000)
`endif
    ,.exception_vector_i(cop0_status_w[22] ? 32'hbfc00180 : 32'h80000080)

    // Instruction Fetch
    ,.mem_i_rd_o(icache_rd_w)
    ,.mem_i_flush_o(icache_flush_w)
    ,.mem_i_invalidate_o(icache_invalidate_w)
    ,.mem_i_pc_o(icache_pc_w)
    ,.mem_i_accept_i(icache_accept_w)
    ,.mem_i_valid_i(icache_valid_w)
    ,.mem_i_error_i(icache_error_w)
    ,.mem_i_inst_i(icache_inst_w)

    // GTE
    ,.cop2_valid_o(cop2_valid_w)
    ,.cop2_opcode_o(cop2_opcode_w)
    ,.cop2_reg_write_o(cop2_reg_write_w)
    ,.cop2_reg_waddr_o(cop2_reg_waddr_w)
    ,.cop2_reg_wdata_o(cop2_reg_wdata_w)
    ,.cop2_reg_raddr_o(cop2_reg_raddr_w)
    ,.cop2_accept_i(cop2_accept_w)
    ,.cop2_reg_rdata_i(cop2_reg_rdata_w)

    ,.cop0_status_o(cop0_status_w)

    // Data Access
    ,.mem_d_addr_o(mem_d_addr_w)
    ,.mem_d_data_wr_o(dcache_data_wr_w)
    ,.mem_d_rd_o(dcache_rd_w)
    ,.mem_d_wr_o(dcache_wr_w)
    ,.mem_d_cacheable_o(dcache_cacheable_w)
    ,.mem_d_req_tag_o(dcache_req_tag_w)
    ,.mem_d_invalidate_o(dcache_invalidate_w)
    ,.mem_d_writeback_o(dcache_writeback_w)
    ,.mem_d_flush_o(dcache_flush_w)
    ,.mem_d_data_rd_i(cop0_status_w[16] ? 32'h00000000 : dcache_data_rd_w)
    ,.mem_d_accept_i(dcache_accept_w)
    ,.mem_d_ack_i(dcache_ack_w)
    ,.mem_d_error_i(dcache_error_w)
    ,.mem_d_resp_tag_i(dcache_resp_tag_w)

    // Fault monitor
    ,.nmi_i(nmi_i)
    ,.nmi_vector_i(32'hbfb00000)
);

// Cache swap mode - direct accesses to dead address
// TODO: FIXME
assign dcache_addr_w = cop0_status_w[16] ? 32'h00000000 : mem_d_addr_w;

//-------------------------------------------------------------
// GTE
//-------------------------------------------------------------
psf_gte
u_gte
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)

    ,.cop_valid_i(cop2_valid_w)
    ,.cop_opcode_i(cop2_opcode_w)
    ,.cop_reg_write_i(cop2_reg_write_w)
    ,.cop_reg_waddr_i(cop2_reg_waddr_w)
    ,.cop_reg_wdata_i(cop2_reg_wdata_w)
    ,.cop_reg_raddr_i(cop2_reg_raddr_w)

    ,.cop_accept_o(cop2_accept_w)
    ,.cop_reg_rdata_o(cop2_reg_rdata_w)
);


endmodule
