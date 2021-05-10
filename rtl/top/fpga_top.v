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
module fpga_top
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
     parameter CLK_FREQ         = 30000000
    ,parameter BAUDRATE         = 1000000
    ,parameter UART_SPEED       = 1000000
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(
    // Inputs
     input           clk_i
    ,input           clk_x5_i
    ,input           clk_sys_i
    ,input           rst_i
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
    ,input           dbg_txd_i
    ,input           uart_rx_i
    ,input           spi_miso_i
    ,input  [ 31:0]  gpio_in_i
    ,input           joy1_dat_i
    ,input           joy1_ack_i
    ,input           joy2_dat_i
    ,input           joy2_ack_i

    // Outputs
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
    ,output          dbg_rxd_o
    ,output          uart_tx_o
    ,output          dvi_red_o
    ,output          dvi_green_o
    ,output          dvi_blue_o
    ,output          dvi_clock_o
    ,output          cdrom_tx_o
    ,output          spi_clk_o
    ,output          spi_mosi_o
    ,output          spi_cs_o
    ,output [ 31:0]  gpio_out_o
    ,output          joy1_sel_o
    ,output          joy1_clk_o
    ,output          joy1_cmd_o
    ,output          joy2_sel_o
    ,output          joy2_clk_o
    ,output          joy2_cmd_o
);

wire           axi_64_rready_w;
wire  [  3:0]  axi_64_bid_w;
wire           axi_64_arvalid_w;
wire           axi_64_wlast_w;
wire  [  3:0]  axi_64_rid_w;
wire  [  3:0]  axi_64_awid_w;
wire  [ 31:0]  axi_64_araddr_w;
wire  [  1:0]  axi_64_awburst_w;
wire           axi_64_awvalid_w;
wire           axi_64_bvalid_w;
wire  [  7:0]  axi_64_arlen_w;
wire           axi_64_rlast_w;
wire  [  1:0]  axi_64_bresp_w;
wire           axi_64_rvalid_w;
wire           axi_64_wvalid_w;
wire           axi_64_bready_w;
wire  [255:0]  axi_64_wdata_w;
wire  [255:0]  axi_64_rdata_w;
wire  [  3:0]  axi_64_arid_w;
wire           axi_64_awready_w;
wire  [ 31:0]  axi_64_awaddr_w;
wire           axi_64_arready_w;
wire  [  7:0]  axi_64_awlen_w;
wire  [ 31:0]  axi_64_wstrb_w;
wire           axi_64_wready_w;
wire  [  1:0]  axi_64_arburst_w;
wire  [  1:0]  axi_64_rresp_w;


axi4_cdc256
u_cdc
(
    // Inputs
     .wr_clk_i(clk_i)
    ,.wr_rst_i(rst_i)
    ,.inport_awvalid_i(axi_64_awvalid_w)
    ,.inport_awaddr_i(axi_64_awaddr_w)
    ,.inport_awid_i(axi_64_awid_w)
    ,.inport_awlen_i(axi_64_awlen_w)
    ,.inport_awburst_i(axi_64_awburst_w)
    ,.inport_wvalid_i(axi_64_wvalid_w)
    ,.inport_wdata_i(axi_64_wdata_w)
    ,.inport_wstrb_i(axi_64_wstrb_w)
    ,.inport_wlast_i(axi_64_wlast_w)
    ,.inport_bready_i(axi_64_bready_w)
    ,.inport_arvalid_i(axi_64_arvalid_w)
    ,.inport_araddr_i(axi_64_araddr_w)
    ,.inport_arid_i(axi_64_arid_w)
    ,.inport_arlen_i(axi_64_arlen_w)
    ,.inport_arburst_i(axi_64_arburst_w)
    ,.inport_rready_i(axi_64_rready_w)
    ,.rd_clk_i(clk_sys_i)
    ,.rd_rst_i(rst_i)
    ,.outport_awready_i(axi_awready_i)
    ,.outport_wready_i(axi_wready_i)
    ,.outport_bvalid_i(axi_bvalid_i)
    ,.outport_bresp_i(axi_bresp_i)
    ,.outport_bid_i(axi_bid_i)
    ,.outport_arready_i(axi_arready_i)
    ,.outport_rvalid_i(axi_rvalid_i)
    ,.outport_rdata_i(axi_rdata_i)
    ,.outport_rresp_i(axi_rresp_i)
    ,.outport_rid_i(axi_rid_i)
    ,.outport_rlast_i(axi_rlast_i)

    // Outputs
    ,.inport_awready_o(axi_64_awready_w)
    ,.inport_wready_o(axi_64_wready_w)
    ,.inport_bvalid_o(axi_64_bvalid_w)
    ,.inport_bresp_o(axi_64_bresp_w)
    ,.inport_bid_o(axi_64_bid_w)
    ,.inport_arready_o(axi_64_arready_w)
    ,.inport_rvalid_o(axi_64_rvalid_w)
    ,.inport_rdata_o(axi_64_rdata_w)
    ,.inport_rresp_o(axi_64_rresp_w)
    ,.inport_rid_o(axi_64_rid_w)
    ,.inport_rlast_o(axi_64_rlast_w)
    ,.outport_awvalid_o(axi_awvalid_o)
    ,.outport_awaddr_o(axi_awaddr_o)
    ,.outport_awid_o(axi_awid_o)
    ,.outport_awlen_o(axi_awlen_o)
    ,.outport_awburst_o(axi_awburst_o)
    ,.outport_wvalid_o(axi_wvalid_o)
    ,.outport_wdata_o(axi_wdata_o)
    ,.outport_wstrb_o(axi_wstrb_o)
    ,.outport_wlast_o(axi_wlast_o)
    ,.outport_bready_o(axi_bready_o)
    ,.outport_arvalid_o(axi_arvalid_o)
    ,.outport_araddr_o(axi_araddr_o)
    ,.outport_arid_o(axi_arid_o)
    ,.outport_arlen_o(axi_arlen_o)
    ,.outport_arburst_o(axi_arburst_o)
    ,.outport_rready_o(axi_rready_o)
);


psf_fpga
u_core
(
    // Inputs
     .clk_i(clk_i)
    ,.clk_x5_i(clk_x5_i)
    ,.rst_i(rst_i)
    ,.dbg_txd_i(dbg_txd_i)
    ,.uart_rx_i(uart_rx_i)
    ,.axi_awready_i(axi_64_awready_w)
    ,.axi_wready_i(axi_64_wready_w)
    ,.axi_bvalid_i(axi_64_bvalid_w)
    ,.axi_bresp_i(axi_64_bresp_w)
    ,.axi_bid_i(axi_64_bid_w)
    ,.axi_arready_i(axi_64_arready_w)
    ,.axi_rvalid_i(axi_64_rvalid_w)
    ,.axi_rdata_i(axi_64_rdata_w)
    ,.axi_rresp_i(axi_64_rresp_w)
    ,.axi_rid_i(axi_64_rid_w)
    ,.axi_rlast_i(axi_64_rlast_w)
    ,.spi_miso_i(spi_miso_i)
    ,.gpio_in_i(gpio_in_i)
    ,.joy1_dat_i(joy1_dat_i)
    ,.joy1_ack_i(joy1_ack_i)
    ,.joy2_dat_i(joy2_dat_i)
    ,.joy2_ack_i(joy2_ack_i)

    // Outputs
    ,.dbg_rxd_o(dbg_rxd_o)
    ,.uart_tx_o(uart_tx_o)
    ,.dvi_red_o(dvi_red_o)
    ,.dvi_green_o(dvi_green_o)
    ,.dvi_blue_o(dvi_blue_o)
    ,.dvi_clock_o(dvi_clock_o)
    ,.axi_awvalid_o(axi_64_awvalid_w)
    ,.axi_awaddr_o(axi_64_awaddr_w)
    ,.axi_awid_o(axi_64_awid_w)
    ,.axi_awlen_o(axi_64_awlen_w)
    ,.axi_awburst_o(axi_64_awburst_w)
    ,.axi_wvalid_o(axi_64_wvalid_w)
    ,.axi_wdata_o(axi_64_wdata_w)
    ,.axi_wstrb_o(axi_64_wstrb_w)
    ,.axi_wlast_o(axi_64_wlast_w)
    ,.axi_bready_o(axi_64_bready_w)
    ,.axi_arvalid_o(axi_64_arvalid_w)
    ,.axi_araddr_o(axi_64_araddr_w)
    ,.axi_arid_o(axi_64_arid_w)
    ,.axi_arlen_o(axi_64_arlen_w)
    ,.axi_arburst_o(axi_64_arburst_w)
    ,.axi_rready_o(axi_64_rready_w)
    ,.cdrom_tx_o(cdrom_tx_o)
    ,.spi_clk_o(spi_clk_o)
    ,.spi_mosi_o(spi_mosi_o)
    ,.spi_cs_o(spi_cs_o)
    ,.gpio_out_o(gpio_out_o)
    ,.joy1_sel_o(joy1_sel_o)
    ,.joy1_clk_o(joy1_clk_o)
    ,.joy1_cmd_o(joy1_cmd_o)
    ,.joy2_sel_o(joy2_sel_o)
    ,.joy2_clk_o(joy2_clk_o)
    ,.joy2_cmd_o(joy2_cmd_o)
);



endmodule
