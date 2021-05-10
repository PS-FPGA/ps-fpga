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
module psf_iop_int
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
     parameter CLK_FREQ         = 30000000
    ,parameter BAUDRATE         = 1000000
    ,parameter C_SCK_RATIO      = 5
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(
    // Inputs
     input           clk_i
    ,input           rst_i
    ,input           rst_cpu_i
    ,input           rx_i
    ,input  [ 31:0]  cfg_addr_i
    ,input  [ 31:0]  cfg_data_wr_i
    ,input           cfg_stb_i
    ,input           cfg_cyc_i
    ,input  [  3:0]  cfg_sel_i
    ,input           cfg_we_i
    ,input           cdrom_p2m_accept_i
    ,input           cdrom_p2m_dma_en_i
    ,input  [ 31:0]  cdrom_p2m_dma_bs_i
    ,input  [ 31:0]  ext_cfg_data_rd_i
    ,input           ext_cfg_ack_i
    ,input           ext_cfg_stall_i
    ,input           ext_irq_i
    ,input           axi_i_awready_i
    ,input           axi_i_wready_i
    ,input           axi_i_bvalid_i
    ,input  [  1:0]  axi_i_bresp_i
    ,input  [  3:0]  axi_i_bid_i
    ,input           axi_i_arready_i
    ,input           axi_i_rvalid_i
    ,input  [ 31:0]  axi_i_rdata_i
    ,input  [  1:0]  axi_i_rresp_i
    ,input  [  3:0]  axi_i_rid_i
    ,input           axi_i_rlast_i
    ,input  [ 31:0]  gpio_in_i

    // Outputs
    ,output          tx_o
    ,output [ 31:0]  cfg_data_rd_o
    ,output          cfg_stall_o
    ,output          cfg_ack_o
    ,output          cfg_err_o
    ,output          irq_o
    ,output          cdrom_p2m_dreq_o
    ,output          cdrom_p2m_valid_o
    ,output [ 31:0]  cdrom_p2m_data_o
    ,output [ 31:0]  ext_cfg_addr_o
    ,output [ 31:0]  ext_cfg_data_wr_o
    ,output          ext_cfg_stb_o
    ,output          ext_cfg_we_o
    ,output          device_reset_o
    ,output          axi_i_awvalid_o
    ,output [ 31:0]  axi_i_awaddr_o
    ,output [  3:0]  axi_i_awid_o
    ,output [  7:0]  axi_i_awlen_o
    ,output [  1:0]  axi_i_awburst_o
    ,output [  2:0]  axi_i_awsize_o
    ,output          axi_i_wvalid_o
    ,output [ 31:0]  axi_i_wdata_o
    ,output [  3:0]  axi_i_wstrb_o
    ,output          axi_i_wlast_o
    ,output          axi_i_bready_o
    ,output          axi_i_arvalid_o
    ,output [ 31:0]  axi_i_araddr_o
    ,output [  3:0]  axi_i_arid_o
    ,output [  7:0]  axi_i_arlen_o
    ,output [  1:0]  axi_i_arburst_o
    ,output [  2:0]  axi_i_arsize_o
    ,output          axi_i_rready_o
    ,output [ 31:0]  gpio_out_o
);

wire           peripheral2_ack_w;
wire  [ 31:0]  peripheral2_data_wr_w;
wire           peripheral2_stb_w;
wire  [ 31:0]  peripheral2_addr_w;
wire  [ 31:0]  peripheral1_addr_w;
wire           peripheral1_stall_w;
wire           peripheral1_ack_w;
wire           peripheral0_stb_w;
wire           irq_w;
wire           peripheral2_we_w;
wire           peripheral0_ack_w;
wire  [ 31:0]  peripheral1_data_rd_w;
wire           peripheral0_stall_w;
wire  [ 31:0]  peripheral0_data_rd_w;
wire           peripheral1_stb_w;
wire  [ 31:0]  peripheral2_data_rd_w;
wire           irq1_w;
wire  [ 31:0]  peripheral0_data_wr_w;
wire  [ 31:0]  peripheral0_addr_w;
wire           peripheral1_we_w;
wire           peripheral2_stall_w;
wire  [ 31:0]  irq_cpu_w;
wire           peripheral0_we_w;
wire  [ 31:0]  peripheral1_data_wr_w;


uart_lite
#(
     .CLK_FREQ(CLK_FREQ)
    ,.BAUDRATE(BAUDRATE)
)
u_uart
(
    // Inputs
     .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.cfg_addr_i(peripheral1_addr_w)
    ,.cfg_data_wr_i(peripheral1_data_wr_w)
    ,.cfg_stb_i(peripheral1_stb_w)
    ,.cfg_we_i(peripheral1_we_w)
    ,.rx_i(rx_i)

    // Outputs
    ,.cfg_data_rd_o(peripheral1_data_rd_w)
    ,.cfg_ack_o(peripheral1_ack_w)
    ,.cfg_stall_o(peripheral1_stall_w)
    ,.tx_o(tx_o)
    ,.intr_o(irq1_w)
);


riscv_tcm_wb
#(
     .CORE_ID(0)
    ,.PORT_SEL_H(9)
    ,.PORT_SEL_L(8)
    ,.NUM_PORTS(4)
    ,.BOOT_VECTOR('h80000000)
    ,.TCM_MEM_BASE('h80000000)
)
u_cpu
(
    // Inputs
     .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.rst_cpu_i(rst_cpu_i)
    ,.axi_t_awvalid_i(1'b0)
    ,.axi_t_awaddr_i(32'b0)
    ,.axi_t_awid_i(4'b0)
    ,.axi_t_awlen_i(8'b0)
    ,.axi_t_awburst_i(2'b0)
    ,.axi_t_awsize_i(3'b0)
    ,.axi_t_wvalid_i(1'b0)
    ,.axi_t_wdata_i(32'b0)
    ,.axi_t_wstrb_i(4'b0)
    ,.axi_t_wlast_i(1'b0)
    ,.axi_t_bready_i(1'b0)
    ,.axi_t_arvalid_i(1'b0)
    ,.axi_t_araddr_i(32'b0)
    ,.axi_t_arid_i(4'b0)
    ,.axi_t_arlen_i(8'b0)
    ,.axi_t_arburst_i(2'b0)
    ,.axi_t_arsize_i(3'b0)
    ,.axi_t_rready_i(1'b0)
    ,.intr_i(irq_cpu_w)
    ,.peripheral0_data_rd_i(peripheral0_data_rd_w)
    ,.peripheral0_ack_i(peripheral0_ack_w)
    ,.peripheral0_stall_i(peripheral0_stall_w)
    ,.peripheral1_data_rd_i(peripheral1_data_rd_w)
    ,.peripheral1_ack_i(peripheral1_ack_w)
    ,.peripheral1_stall_i(peripheral1_stall_w)
    ,.peripheral2_data_rd_i(peripheral2_data_rd_w)
    ,.peripheral2_ack_i(peripheral2_ack_w)
    ,.peripheral2_stall_i(peripheral2_stall_w)
    ,.peripheral3_data_rd_i(ext_cfg_data_rd_i)
    ,.peripheral3_ack_i(ext_cfg_ack_i)
    ,.peripheral3_stall_i(ext_cfg_stall_i)

    // Outputs
    ,.axi_t_awready_o()
    ,.axi_t_wready_o()
    ,.axi_t_bvalid_o()
    ,.axi_t_bresp_o()
    ,.axi_t_bid_o()
    ,.axi_t_arready_o()
    ,.axi_t_rvalid_o()
    ,.axi_t_rdata_o()
    ,.axi_t_rresp_o()
    ,.axi_t_rid_o()
    ,.axi_t_rlast_o()
    ,.peripheral0_addr_o(peripheral0_addr_w)
    ,.peripheral0_data_wr_o(peripheral0_data_wr_w)
    ,.peripheral0_stb_o(peripheral0_stb_w)
    ,.peripheral0_we_o(peripheral0_we_w)
    ,.peripheral1_addr_o(peripheral1_addr_w)
    ,.peripheral1_data_wr_o(peripheral1_data_wr_w)
    ,.peripheral1_stb_o(peripheral1_stb_w)
    ,.peripheral1_we_o(peripheral1_we_w)
    ,.peripheral2_addr_o(peripheral2_addr_w)
    ,.peripheral2_data_wr_o(peripheral2_data_wr_w)
    ,.peripheral2_stb_o(peripheral2_stb_w)
    ,.peripheral2_we_o(peripheral2_we_w)
    ,.peripheral3_addr_o(ext_cfg_addr_o)
    ,.peripheral3_data_wr_o(ext_cfg_data_wr_o)
    ,.peripheral3_stb_o(ext_cfg_stb_o)
    ,.peripheral3_we_o(ext_cfg_we_o)
);


irq_ctrl
u_irq_ctrl
(
    // Inputs
     .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.cfg_addr_i(peripheral0_addr_w)
    ,.cfg_data_wr_i(peripheral0_data_wr_w)
    ,.cfg_stb_i(peripheral0_stb_w)
    ,.cfg_we_i(peripheral0_we_w)
    ,.interrupt0_i(1'b0)
    ,.interrupt1_i(irq1_w)
    ,.interrupt2_i(1'b0)
    ,.interrupt3_i(ext_irq_i)

    // Outputs
    ,.cfg_data_rd_o(peripheral0_data_rd_w)
    ,.cfg_ack_o(peripheral0_ack_w)
    ,.cfg_stall_o(peripheral0_stall_w)
    ,.intr_o(irq_w)
);


cdrom_ctrl
u_cdrom_regs
(
    // Inputs
     .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.cfg_psf_addr_i(cfg_addr_i)
    ,.cfg_psf_data_wr_i(cfg_data_wr_i)
    ,.cfg_psf_stb_i(cfg_stb_i)
    ,.cfg_psf_cyc_i(cfg_cyc_i)
    ,.cfg_psf_sel_i(cfg_sel_i)
    ,.cfg_psf_we_i(cfg_we_i)
    ,.cfg_int_addr_i(peripheral2_addr_w)
    ,.cfg_int_data_wr_i(peripheral2_data_wr_w)
    ,.cfg_int_stb_i(peripheral2_stb_w)
    ,.cfg_int_we_i(peripheral2_we_w)
    ,.cdrom_p2m_accept_i(cdrom_p2m_accept_i)
    ,.cdrom_p2m_dma_en_i(cdrom_p2m_dma_en_i)
    ,.cdrom_p2m_dma_bs_i(cdrom_p2m_dma_bs_i)
    ,.gpio_in_i(gpio_in_i)
    ,.axi_awready_i(axi_i_awready_i)
    ,.axi_wready_i(axi_i_wready_i)
    ,.axi_bvalid_i(axi_i_bvalid_i)
    ,.axi_bresp_i(axi_i_bresp_i)
    ,.axi_bid_i(axi_i_bid_i)
    ,.axi_arready_i(axi_i_arready_i)
    ,.axi_rvalid_i(axi_i_rvalid_i)
    ,.axi_rdata_i(axi_i_rdata_i)
    ,.axi_rresp_i(axi_i_rresp_i)
    ,.axi_rid_i(axi_i_rid_i)
    ,.axi_rlast_i(axi_i_rlast_i)

    // Outputs
    ,.cfg_psf_data_rd_o(cfg_data_rd_o)
    ,.cfg_psf_stall_o(cfg_stall_o)
    ,.cfg_psf_ack_o(cfg_ack_o)
    ,.cfg_psf_err_o(cfg_err_o)
    ,.irq_o(irq_o)
    ,.cfg_int_data_rd_o(peripheral2_data_rd_w)
    ,.cfg_int_ack_o(peripheral2_ack_w)
    ,.cfg_int_stall_o(peripheral2_stall_w)
    ,.device_reset_o(device_reset_o)
    ,.cdrom_p2m_dreq_o(cdrom_p2m_dreq_o)
    ,.cdrom_p2m_valid_o(cdrom_p2m_valid_o)
    ,.cdrom_p2m_data_o(cdrom_p2m_data_o)
    ,.gpio_out_o(gpio_out_o)
    ,.axi_awvalid_o(axi_i_awvalid_o)
    ,.axi_awaddr_o(axi_i_awaddr_o)
    ,.axi_awid_o(axi_i_awid_o)
    ,.axi_awlen_o(axi_i_awlen_o)
    ,.axi_awburst_o(axi_i_awburst_o)
    ,.axi_awsize_o(axi_i_awsize_o)
    ,.axi_wvalid_o(axi_i_wvalid_o)
    ,.axi_wdata_o(axi_i_wdata_o)
    ,.axi_wstrb_o(axi_i_wstrb_o)
    ,.axi_wlast_o(axi_i_wlast_o)
    ,.axi_bready_o(axi_i_bready_o)
    ,.axi_arvalid_o(axi_i_arvalid_o)
    ,.axi_araddr_o(axi_i_araddr_o)
    ,.axi_arid_o(axi_i_arid_o)
    ,.axi_arlen_o(axi_i_arlen_o)
    ,.axi_arburst_o(axi_i_arburst_o)
    ,.axi_arsize_o(axi_i_arsize_o)
    ,.axi_rready_o(axi_i_rready_o)
);


assign irq_cpu_w = {31'b0, irq_w};


endmodule
