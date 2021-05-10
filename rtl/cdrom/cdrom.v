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
module cdrom
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
    ,input  [ 31:0]  gpio_in_i
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
    ,output [ 31:0]  gpio_out_o
    ,output [ 31:0]  ext_cfg_addr_o
    ,output [ 31:0]  ext_cfg_data_wr_o
    ,output          ext_cfg_stb_o
    ,output          ext_cfg_we_o
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
);

wire           rst_cpu_w;


psf_iop_int
#(
     .CLK_FREQ(CLK_FREQ)
    ,.BAUDRATE(BAUDRATE)
    ,.C_SCK_RATIO(C_SCK_RATIO)
)
u_int
(
    // Inputs
     .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.rst_cpu_i(rst_cpu_w)
    ,.rx_i(rx_i)
    ,.cfg_addr_i(cfg_addr_i)
    ,.cfg_data_wr_i(cfg_data_wr_i)
    ,.cfg_stb_i(cfg_stb_i)
    ,.cfg_cyc_i(cfg_cyc_i)
    ,.cfg_sel_i(cfg_sel_i)
    ,.cfg_we_i(cfg_we_i)
    ,.cdrom_p2m_accept_i(cdrom_p2m_accept_i)
    ,.cdrom_p2m_dma_en_i(cdrom_p2m_dma_en_i)
    ,.cdrom_p2m_dma_bs_i(cdrom_p2m_dma_bs_i)
    ,.ext_cfg_data_rd_i(ext_cfg_data_rd_i)
    ,.ext_cfg_ack_i(ext_cfg_ack_i)
    ,.ext_cfg_stall_i(ext_cfg_stall_i)
    ,.ext_irq_i(ext_irq_i)
    ,.axi_i_awready_i(axi_i_awready_i)
    ,.axi_i_wready_i(axi_i_wready_i)
    ,.axi_i_bvalid_i(axi_i_bvalid_i)
    ,.axi_i_bresp_i(axi_i_bresp_i)
    ,.axi_i_bid_i(axi_i_bid_i)
    ,.axi_i_arready_i(axi_i_arready_i)
    ,.axi_i_rvalid_i(axi_i_rvalid_i)
    ,.axi_i_rdata_i(axi_i_rdata_i)
    ,.axi_i_rresp_i(axi_i_rresp_i)
    ,.axi_i_rid_i(axi_i_rid_i)
    ,.axi_i_rlast_i(axi_i_rlast_i)
    ,.gpio_in_i(gpio_in_i)

    // Outputs
    ,.tx_o(tx_o)
    ,.cfg_data_rd_o(cfg_data_rd_o)
    ,.cfg_stall_o(cfg_stall_o)
    ,.cfg_ack_o(cfg_ack_o)
    ,.cfg_err_o(cfg_err_o)
    ,.irq_o(irq_o)
    ,.cdrom_p2m_dreq_o(cdrom_p2m_dreq_o)
    ,.cdrom_p2m_valid_o(cdrom_p2m_valid_o)
    ,.cdrom_p2m_data_o(cdrom_p2m_data_o)
    ,.ext_cfg_addr_o(ext_cfg_addr_o)
    ,.ext_cfg_data_wr_o(ext_cfg_data_wr_o)
    ,.ext_cfg_stb_o(ext_cfg_stb_o)
    ,.ext_cfg_we_o(ext_cfg_we_o)
    ,.device_reset_o(rst_cpu_w)
    ,.axi_i_awvalid_o(axi_i_awvalid_o)
    ,.axi_i_awaddr_o(axi_i_awaddr_o)
    ,.axi_i_awid_o(axi_i_awid_o)
    ,.axi_i_awlen_o(axi_i_awlen_o)
    ,.axi_i_awburst_o(axi_i_awburst_o)
    ,.axi_i_awsize_o(axi_i_awsize_o)
    ,.axi_i_wvalid_o(axi_i_wvalid_o)
    ,.axi_i_wdata_o(axi_i_wdata_o)
    ,.axi_i_wstrb_o(axi_i_wstrb_o)
    ,.axi_i_wlast_o(axi_i_wlast_o)
    ,.axi_i_bready_o(axi_i_bready_o)
    ,.axi_i_arvalid_o(axi_i_arvalid_o)
    ,.axi_i_araddr_o(axi_i_araddr_o)
    ,.axi_i_arid_o(axi_i_arid_o)
    ,.axi_i_arlen_o(axi_i_arlen_o)
    ,.axi_i_arburst_o(axi_i_arburst_o)
    ,.axi_i_arsize_o(axi_i_arsize_o)
    ,.axi_i_rready_o(axi_i_rready_o)
    ,.gpio_out_o(gpio_out_o)
);



endmodule
