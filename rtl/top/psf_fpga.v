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
module psf_fpga
(
    // Inputs
     input           clk_i
    ,input           clk_x5_i
    ,input           rst_i
    ,input           dbg_txd_i
    ,input           uart_rx_i
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
    ,input           spi_miso_i
    ,input  [ 31:0]  gpio_in_i
    ,input           joy1_dat_i
    ,input           joy1_ack_i
    ,input           joy2_dat_i
    ,input           joy2_ack_i

    // Outputs
    ,output          dbg_rxd_o
    ,output          uart_tx_o
    ,output          dvi_red_o
    ,output          dvi_green_o
    ,output          dvi_blue_o
    ,output          dvi_clock_o
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

wire           psf_axi_wlast_w;
wire           cdrom_axi_awvalid_w;
wire           display_axi_conv_rready_w;
wire           psf_axi_bready_w;
wire  [  7:0]  cdrom_axi_awlen_w;
wire  [  3:0]  display_axi_bid_w;
wire  [  1:0]  display_axi_awburst_w;
wire           display_dotclk_w;
wire           display_interlaced_w;
wire  [  1:0]  display_axi_bresp_w;
wire  [  3:0]  display_axi_rid_w;
wire  [255:0]  cdrom_axi_rdata_w;
wire  [  9:0]  display_x_w;
wire  [  8:0]  display_y_w;
wire  [  1:0]  gpu_axi_arburst_w;
wire           psf_axi_bvalid_w;
wire           gpu_axi_retime_wvalid_w;
wire  [ 31:0]  display_axi_conv_wdata_w;
wire  [  3:0]  cdrom_axi_awid_w;
wire           display_axi_wvalid_w;
wire  [ 31:0]  cdrom_axi_wstrb_w;
wire  [  3:0]  cdrom_axi_arid_w;
wire           gpu_axi_awready_w;
wire  [255:0]  gpu_axi_rdata_w;
wire  [  1:0]  display_axi_conv_arburst_w;
wire  [ 31:0]  spi_cfg_addr_w;
wire  [  7:0]  gpu_axi_awlen_w;
wire  [  3:0]  display_axi_conv_arid_w;
wire           display_axi_rready_w;
wire  [  3:0]  gpu_axi_arid_w;
wire           gpu_axi_retime_rvalid_w;
wire  [  3:0]  display_axi_conv_rid_w;
wire           psf_axi_awready_w;
wire           psf_axi_wvalid_w;
wire  [ 31:0]  spi_cfg_data_wr_w;
wire           cdrom_axi_rlast_w;
wire  [  7:0]  gpu_axi_arlen_w;
wire  [  3:0]  gpu_axi_retime_arid_w;
wire           display_pal_w;
wire           gpu_axi_retime_wready_w;
wire  [  1:0]  cdrom_axi_rresp_w;
wire  [255:0]  gpu_axi_wdata_w;
wire           gpu_axi_rvalid_w;
wire  [  7:0]  display_axi_awlen_w;
wire           gpu_axi_retime_rready_w;
wire           display_axi_conv_arvalid_w;
wire  [  3:0]  display_axi_conv_wstrb_w;
wire  [  1:0]  display_axi_rresp_w;
wire  [ 31:0]  display_axi_awaddr_w;
wire           display_axi_conv_arready_w;
wire  [255:0]  display_axi_rdata_w;
wire           psf_axi_arready_w;
wire           display_axi_conv_bready_w;
wire  [ 31:0]  psf_axi_awaddr_w;
wire  [  7:0]  psf_axi_awlen_w;
wire           display_axi_conv_wready_w;
wire           display_axi_rlast_w;
wire  [  2:0]  display_axi_conv_awsize_w;
wire           display_axi_arvalid_w;
wire  [  1:0]  display_axi_conv_awburst_w;
wire           cdrom_axi_wvalid_w;
wire           cdrom_axi_rvalid_w;
wire  [255:0]  cdrom_axi_wdata_w;
wire  [  7:0]  psf_axi_arlen_w;
wire  [  3:0]  display_axi_arid_w;
wire  [255:0]  psf_axi_wdata_w;
wire           gpu_axi_retime_bvalid_w;
wire  [  1:0]  gpu_axi_bresp_w;
wire  [  3:0]  display_axi_conv_awid_w;
wire  [  1:0]  psf_axi_bresp_w;
wire  [ 31:0]  cdrom_axi_araddr_w;
wire  [  7:0]  cdrom_axi_arlen_w;
wire           psf_axi_rlast_w;
wire           display_axi_conv_wvalid_w;
wire  [255:0]  psf_axi_rdata_w;
wire           spi_cfg_we_w;
wire  [  3:0]  gpu_axi_bid_w;
wire  [  1:0]  gpu_axi_awburst_w;
wire  [  1:0]  display_axi_conv_bresp_w;
wire           cdrom_axi_awready_w;
wire  [  3:0]  gpu_axi_rid_w;
wire           spi_cfg_stb_w;
wire           gpu_axi_wvalid_w;
wire           psf_axi_rvalid_w;
wire           display_vblank_w;
wire           display_axi_conv_awready_w;
wire  [ 31:0]  display_axi_araddr_w;
wire  [  1:0]  gpu_axi_retime_rresp_w;
wire           display_axi_rvalid_w;
wire           psf_axi_rready_w;
wire  [  1:0]  psf_axi_awburst_w;
wire  [  3:0]  psf_axi_rid_w;
wire  [  8:0]  display_res_y_w;
wire  [  9:0]  display_res_x_w;
wire           gpu_axi_rready_w;
wire  [  2:0]  display_axi_conv_arsize_w;
wire           display_axi_conv_wlast_w;
wire           display_axi_arready_w;
wire           display_axi_conv_rvalid_w;
wire  [255:0]  gpu_axi_retime_rdata_w;
wire  [  3:0]  gpu_axi_awid_w;
wire  [ 31:0]  psf_axi_araddr_w;
wire           display_axi_wready_w;
wire  [255:0]  display_axi_wdata_w;
wire  [ 31:0]  display_axi_conv_awaddr_w;
wire           display_axi_conv_rlast_w;
wire  [ 31:0]  gpu_axi_retime_awaddr_w;
wire           psf_axi_wready_w;
wire           display_axi_conv_awvalid_w;
wire  [255:0]  gpu_axi_retime_wdata_w;
wire  [ 31:0]  gpu_axi_wstrb_w;
wire  [  1:0]  gpu_axi_retime_awburst_w;
wire  [ 31:0]  gpu_axi_retime_wstrb_w;
wire           psf_axi_arvalid_w;
wire  [ 31:0]  spi_cfg_data_rd_w;
wire           spi_irq_w;
wire           cdrom_axi_bvalid_w;
wire           cdrom_axi_rready_w;
wire           gpu_axi_wlast_w;
wire  [  3:0]  psf_axi_arid_w;
wire  [  3:0]  display_axi_awid_w;
wire           gpu_axi_retime_wlast_w;
wire           gpu_axi_retime_awvalid_w;
wire  [  3:0]  display_axi_conv_bid_w;
wire  [  7:0]  gpu_axi_retime_arlen_w;
wire  [ 31:0]  psf_axi_wstrb_w;
wire  [  1:0]  display_axi_conv_rresp_w;
wire  [  1:0]  psf_axi_arburst_w;
wire  [ 31:0]  gpu_axi_retime_araddr_w;
wire           gpu_axi_awvalid_w;
wire           gpu_axi_retime_arvalid_w;
wire  [  3:0]  psf_axi_awid_w;
wire  [  1:0]  display_axi_arburst_w;
wire  [ 31:0]  display_axi_wstrb_w;
wire           gpu_axi_bvalid_w;
wire           gpu_axi_rlast_w;
wire  [  3:0]  cdrom_axi_bid_w;
wire  [  1:0]  cdrom_axi_bresp_w;
wire           display_axi_bready_w;
wire  [  1:0]  gpu_axi_retime_arburst_w;
wire           cdrom_axi_arready_w;
wire           spi_cfg_stall_w;
wire           display_axi_wlast_w;
wire           display_axi_awready_w;
wire  [ 31:0]  display_axi_conv_araddr_w;
wire           gpu_axi_retime_bready_w;
wire  [ 31:0]  cdrom_axi_awaddr_w;
wire           display_axi_bvalid_w;
wire  [ 31:0]  display_axi_conv_rdata_w;
wire           spi_cfg_ack_w;
wire  [  7:0]  display_axi_arlen_w;
wire           psf_axi_awvalid_w;
wire  [  1:0]  gpu_axi_rresp_w;
wire           cdrom_axi_bready_w;
wire           display_axi_awvalid_w;
wire  [  1:0]  cdrom_axi_arburst_w;
wire  [  1:0]  psf_axi_rresp_w;
wire           display_axi_conv_bvalid_w;
wire           cdrom_axi_arvalid_w;
wire           gpu_axi_retime_arready_w;
wire           gpu_axi_arvalid_w;
wire           display_field_w;
wire           gpu_axi_wready_w;
wire  [  3:0]  psf_axi_bid_w;
wire  [  1:0]  gpu_axi_retime_bresp_w;
wire           gpu_axi_retime_awready_w;
wire  [ 31:0]  gpu_axi_awaddr_w;
wire  [  3:0]  cdrom_axi_rid_w;
wire           gpu_axi_arready_w;
wire  [  3:0]  gpu_axi_retime_bid_w;
wire  [  7:0]  display_axi_conv_awlen_w;
wire  [  7:0]  gpu_axi_retime_awlen_w;
wire           gpu_axi_retime_rlast_w;
wire  [  3:0]  gpu_axi_retime_awid_w;
wire  [  3:0]  gpu_axi_retime_rid_w;
wire           gpu_axi_bready_w;
wire  [ 31:0]  gpu_axi_araddr_w;
wire           cdrom_axi_wlast_w;
wire           display_hblank_w;
wire  [  7:0]  display_axi_conv_arlen_w;
wire  [  1:0]  cdrom_axi_awburst_w;
wire           cdrom_axi_wready_w;


dvi_fb_psf
#(
     .VIDEO_FB_RAM('h3000000)
    ,.AXI_ID(14)
    ,.VIDEO_HEIGHT(480)
    ,.VIDEO_REFRESH(60)
    ,.VIDEO_WIDTH(640)
)
u_dvi
(
    // Inputs
     .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.clk_x5_i(clk_x5_i)
    ,.display_res_x_i(display_res_x_w)
    ,.display_res_y_i(display_res_y_w)
    ,.display_x_i(display_x_w)
    ,.display_y_i(display_y_w)
    ,.display_interlaced_i(display_interlaced_w)
    ,.display_pal_i(display_pal_w)
    ,.outport_awready_i(display_axi_conv_awready_w)
    ,.outport_wready_i(display_axi_conv_wready_w)
    ,.outport_bvalid_i(display_axi_conv_bvalid_w)
    ,.outport_bresp_i(display_axi_conv_bresp_w)
    ,.outport_bid_i(display_axi_conv_bid_w)
    ,.outport_arready_i(display_axi_conv_arready_w)
    ,.outport_rvalid_i(display_axi_conv_rvalid_w)
    ,.outport_rdata_i(display_axi_conv_rdata_w)
    ,.outport_rresp_i(display_axi_conv_rresp_w)
    ,.outport_rid_i(display_axi_conv_rid_w)
    ,.outport_rlast_i(display_axi_conv_rlast_w)

    // Outputs
    ,.display_field_o(display_field_w)
    ,.display_hblank_o(display_hblank_w)
    ,.display_vblank_o(display_vblank_w)
    ,.display_dotclk_o(display_dotclk_w)
    ,.outport_awvalid_o(display_axi_conv_awvalid_w)
    ,.outport_awaddr_o(display_axi_conv_awaddr_w)
    ,.outport_awid_o(display_axi_conv_awid_w)
    ,.outport_awlen_o(display_axi_conv_awlen_w)
    ,.outport_awburst_o(display_axi_conv_awburst_w)
    ,.outport_awsize_o(display_axi_conv_awsize_w)
    ,.outport_wvalid_o(display_axi_conv_wvalid_w)
    ,.outport_wdata_o(display_axi_conv_wdata_w)
    ,.outport_wstrb_o(display_axi_conv_wstrb_w)
    ,.outport_wlast_o(display_axi_conv_wlast_w)
    ,.outport_bready_o(display_axi_conv_bready_w)
    ,.outport_arvalid_o(display_axi_conv_arvalid_w)
    ,.outport_araddr_o(display_axi_conv_araddr_w)
    ,.outport_arid_o(display_axi_conv_arid_w)
    ,.outport_arlen_o(display_axi_conv_arlen_w)
    ,.outport_arburst_o(display_axi_conv_arburst_w)
    ,.outport_arsize_o(display_axi_conv_arsize_w)
    ,.outport_rready_o(display_axi_conv_rready_w)
    ,.dvi_red_o(dvi_red_o)
    ,.dvi_green_o(dvi_green_o)
    ,.dvi_blue_o(dvi_blue_o)
    ,.dvi_clock_o(dvi_clock_o)
);


psf_top
#(
     .CLK_FREQ('h1c9c380)
    ,.BAUDRATE('hf4240)
    ,.VRAM_BASE('h3000000)
    ,.UART_SPEED('hf4240)
)
u_psf
(
    // Inputs
     .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.dbg_txd_i(dbg_txd_i)
    ,.uart_rx_i(uart_rx_i)
    ,.axi_awready_i(psf_axi_awready_w)
    ,.axi_wready_i(psf_axi_wready_w)
    ,.axi_bvalid_i(psf_axi_bvalid_w)
    ,.axi_bresp_i(psf_axi_bresp_w)
    ,.axi_bid_i(psf_axi_bid_w)
    ,.axi_arready_i(psf_axi_arready_w)
    ,.axi_rvalid_i(psf_axi_rvalid_w)
    ,.axi_rdata_i(psf_axi_rdata_w)
    ,.axi_rresp_i(psf_axi_rresp_w)
    ,.axi_rid_i(psf_axi_rid_w)
    ,.axi_rlast_i(psf_axi_rlast_w)
    ,.axi_vram_awready_i(gpu_axi_awready_w)
    ,.axi_vram_wready_i(gpu_axi_wready_w)
    ,.axi_vram_bvalid_i(gpu_axi_bvalid_w)
    ,.axi_vram_bresp_i(gpu_axi_bresp_w)
    ,.axi_vram_bid_i(gpu_axi_bid_w)
    ,.axi_vram_arready_i(gpu_axi_arready_w)
    ,.axi_vram_rvalid_i(gpu_axi_rvalid_w)
    ,.axi_vram_rdata_i(gpu_axi_rdata_w)
    ,.axi_vram_rresp_i(gpu_axi_rresp_w)
    ,.axi_vram_rid_i(gpu_axi_rid_w)
    ,.axi_vram_rlast_i(gpu_axi_rlast_w)
    ,.axi_cdrom_awready_i(cdrom_axi_awready_w)
    ,.axi_cdrom_wready_i(cdrom_axi_wready_w)
    ,.axi_cdrom_bvalid_i(cdrom_axi_bvalid_w)
    ,.axi_cdrom_bresp_i(cdrom_axi_bresp_w)
    ,.axi_cdrom_bid_i(cdrom_axi_bid_w)
    ,.axi_cdrom_arready_i(cdrom_axi_arready_w)
    ,.axi_cdrom_rvalid_i(cdrom_axi_rvalid_w)
    ,.axi_cdrom_rdata_i(cdrom_axi_rdata_w)
    ,.axi_cdrom_rresp_i(cdrom_axi_rresp_w)
    ,.axi_cdrom_rid_i(cdrom_axi_rid_w)
    ,.axi_cdrom_rlast_i(cdrom_axi_rlast_w)
    ,.joy1_dat_i(joy1_dat_i)
    ,.joy1_ack_i(joy1_ack_i)
    ,.joy2_dat_i(joy2_dat_i)
    ,.joy2_ack_i(joy2_ack_i)
    ,.display_field_i(display_field_w)
    ,.display_hblank_i(display_hblank_w)
    ,.display_vblank_i(display_vblank_w)
    ,.display_dotclk_i(display_dotclk_w)
    ,.gpio_in_i(gpio_in_i)
    ,.cdrom_ext_cfg_data_rd_i(spi_cfg_data_rd_w)
    ,.cdrom_ext_cfg_ack_i(spi_cfg_ack_w)
    ,.cdrom_ext_cfg_stall_i(spi_cfg_stall_w)
    ,.cdrom_ext_irq_i(spi_irq_w)

    // Outputs
    ,.dbg_rxd_o(dbg_rxd_o)
    ,.uart_tx_o(uart_tx_o)
    ,.axi_awvalid_o(psf_axi_awvalid_w)
    ,.axi_awaddr_o(psf_axi_awaddr_w)
    ,.axi_awid_o(psf_axi_awid_w)
    ,.axi_awlen_o(psf_axi_awlen_w)
    ,.axi_awburst_o(psf_axi_awburst_w)
    ,.axi_wvalid_o(psf_axi_wvalid_w)
    ,.axi_wdata_o(psf_axi_wdata_w)
    ,.axi_wstrb_o(psf_axi_wstrb_w)
    ,.axi_wlast_o(psf_axi_wlast_w)
    ,.axi_bready_o(psf_axi_bready_w)
    ,.axi_arvalid_o(psf_axi_arvalid_w)
    ,.axi_araddr_o(psf_axi_araddr_w)
    ,.axi_arid_o(psf_axi_arid_w)
    ,.axi_arlen_o(psf_axi_arlen_w)
    ,.axi_arburst_o(psf_axi_arburst_w)
    ,.axi_rready_o(psf_axi_rready_w)
    ,.axi_vram_awvalid_o(gpu_axi_awvalid_w)
    ,.axi_vram_awaddr_o(gpu_axi_awaddr_w)
    ,.axi_vram_awid_o(gpu_axi_awid_w)
    ,.axi_vram_awlen_o(gpu_axi_awlen_w)
    ,.axi_vram_awburst_o(gpu_axi_awburst_w)
    ,.axi_vram_wvalid_o(gpu_axi_wvalid_w)
    ,.axi_vram_wdata_o(gpu_axi_wdata_w)
    ,.axi_vram_wstrb_o(gpu_axi_wstrb_w)
    ,.axi_vram_wlast_o(gpu_axi_wlast_w)
    ,.axi_vram_bready_o(gpu_axi_bready_w)
    ,.axi_vram_arvalid_o(gpu_axi_arvalid_w)
    ,.axi_vram_araddr_o(gpu_axi_araddr_w)
    ,.axi_vram_arid_o(gpu_axi_arid_w)
    ,.axi_vram_arlen_o(gpu_axi_arlen_w)
    ,.axi_vram_arburst_o(gpu_axi_arburst_w)
    ,.axi_vram_rready_o(gpu_axi_rready_w)
    ,.axi_cdrom_awvalid_o(cdrom_axi_awvalid_w)
    ,.axi_cdrom_awaddr_o(cdrom_axi_awaddr_w)
    ,.axi_cdrom_awid_o(cdrom_axi_awid_w)
    ,.axi_cdrom_awlen_o(cdrom_axi_awlen_w)
    ,.axi_cdrom_awburst_o(cdrom_axi_awburst_w)
    ,.axi_cdrom_wvalid_o(cdrom_axi_wvalid_w)
    ,.axi_cdrom_wdata_o(cdrom_axi_wdata_w)
    ,.axi_cdrom_wstrb_o(cdrom_axi_wstrb_w)
    ,.axi_cdrom_wlast_o(cdrom_axi_wlast_w)
    ,.axi_cdrom_bready_o(cdrom_axi_bready_w)
    ,.axi_cdrom_arvalid_o(cdrom_axi_arvalid_w)
    ,.axi_cdrom_araddr_o(cdrom_axi_araddr_w)
    ,.axi_cdrom_arid_o(cdrom_axi_arid_w)
    ,.axi_cdrom_arlen_o(cdrom_axi_arlen_w)
    ,.axi_cdrom_arburst_o(cdrom_axi_arburst_w)
    ,.axi_cdrom_rready_o(cdrom_axi_rready_w)
    ,.i2s_sck_o()
    ,.i2s_sdata_o()
    ,.i2s_ws_o()
    ,.joy1_sel_o(joy1_sel_o)
    ,.joy1_clk_o(joy1_clk_o)
    ,.joy1_cmd_o(joy1_cmd_o)
    ,.joy2_sel_o(joy2_sel_o)
    ,.joy2_clk_o(joy2_clk_o)
    ,.joy2_cmd_o(joy2_cmd_o)
    ,.display_res_x_o(display_res_x_w)
    ,.display_res_y_o(display_res_y_w)
    ,.display_x_o(display_x_w)
    ,.display_y_o(display_y_w)
    ,.display_interlaced_o(display_interlaced_w)
    ,.display_pal_o(display_pal_w)
    ,.cdrom_tx_o(cdrom_tx_o)
    ,.gpio_out_o(gpio_out_o)
    ,.cdrom_ext_cfg_addr_o(spi_cfg_addr_w)
    ,.cdrom_ext_cfg_data_wr_o(spi_cfg_data_wr_w)
    ,.cdrom_ext_cfg_stb_o(spi_cfg_stb_w)
    ,.cdrom_ext_cfg_we_o(spi_cfg_we_w)
);


axi4_upconv256
u_dvi_axi
(
    // Inputs
     .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.inport_awvalid_i(display_axi_conv_awvalid_w)
    ,.inport_awaddr_i(display_axi_conv_awaddr_w)
    ,.inport_awid_i(display_axi_conv_awid_w)
    ,.inport_awlen_i(display_axi_conv_awlen_w)
    ,.inport_awburst_i(display_axi_conv_awburst_w)
    ,.inport_awsize_i(display_axi_conv_awsize_w)
    ,.inport_wvalid_i(display_axi_conv_wvalid_w)
    ,.inport_wdata_i(display_axi_conv_wdata_w)
    ,.inport_wstrb_i(display_axi_conv_wstrb_w)
    ,.inport_wlast_i(display_axi_conv_wlast_w)
    ,.inport_bready_i(display_axi_conv_bready_w)
    ,.inport_arvalid_i(display_axi_conv_arvalid_w)
    ,.inport_araddr_i(display_axi_conv_araddr_w)
    ,.inport_arid_i(display_axi_conv_arid_w)
    ,.inport_arlen_i(display_axi_conv_arlen_w)
    ,.inport_arburst_i(display_axi_conv_arburst_w)
    ,.inport_arsize_i(display_axi_conv_arsize_w)
    ,.inport_rready_i(display_axi_conv_rready_w)
    ,.outport_awready_i(display_axi_awready_w)
    ,.outport_wready_i(display_axi_wready_w)
    ,.outport_bvalid_i(display_axi_bvalid_w)
    ,.outport_bresp_i(display_axi_bresp_w)
    ,.outport_bid_i(display_axi_bid_w)
    ,.outport_arready_i(display_axi_arready_w)
    ,.outport_rvalid_i(display_axi_rvalid_w)
    ,.outport_rdata_i(display_axi_rdata_w)
    ,.outport_rresp_i(display_axi_rresp_w)
    ,.outport_rid_i(display_axi_rid_w)
    ,.outport_rlast_i(display_axi_rlast_w)

    // Outputs
    ,.inport_awready_o(display_axi_conv_awready_w)
    ,.inport_wready_o(display_axi_conv_wready_w)
    ,.inport_bvalid_o(display_axi_conv_bvalid_w)
    ,.inport_bresp_o(display_axi_conv_bresp_w)
    ,.inport_bid_o(display_axi_conv_bid_w)
    ,.inport_arready_o(display_axi_conv_arready_w)
    ,.inport_rvalid_o(display_axi_conv_rvalid_w)
    ,.inport_rdata_o(display_axi_conv_rdata_w)
    ,.inport_rresp_o(display_axi_conv_rresp_w)
    ,.inport_rid_o(display_axi_conv_rid_w)
    ,.inport_rlast_o(display_axi_conv_rlast_w)
    ,.outport_awvalid_o(display_axi_awvalid_w)
    ,.outport_awaddr_o(display_axi_awaddr_w)
    ,.outport_awid_o(display_axi_awid_w)
    ,.outport_awlen_o(display_axi_awlen_w)
    ,.outport_awburst_o(display_axi_awburst_w)
    ,.outport_wvalid_o(display_axi_wvalid_w)
    ,.outport_wdata_o(display_axi_wdata_w)
    ,.outport_wstrb_o(display_axi_wstrb_w)
    ,.outport_wlast_o(display_axi_wlast_w)
    ,.outport_bready_o(display_axi_bready_w)
    ,.outport_arvalid_o(display_axi_arvalid_w)
    ,.outport_araddr_o(display_axi_araddr_w)
    ,.outport_arid_o(display_axi_arid_w)
    ,.outport_arlen_o(display_axi_arlen_w)
    ,.outport_arburst_o(display_axi_arburst_w)
    ,.outport_rready_o(display_axi_rready_w)
);


axi4_arb256
u_arb
(
    // Inputs
     .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.inport0_awvalid_i(psf_axi_awvalid_w)
    ,.inport0_awaddr_i(psf_axi_awaddr_w)
    ,.inport0_awid_i(psf_axi_awid_w)
    ,.inport0_awlen_i(psf_axi_awlen_w)
    ,.inport0_awburst_i(psf_axi_awburst_w)
    ,.inport0_wvalid_i(psf_axi_wvalid_w)
    ,.inport0_wdata_i(psf_axi_wdata_w)
    ,.inport0_wstrb_i(psf_axi_wstrb_w)
    ,.inport0_wlast_i(psf_axi_wlast_w)
    ,.inport0_bready_i(psf_axi_bready_w)
    ,.inport0_arvalid_i(psf_axi_arvalid_w)
    ,.inport0_araddr_i(psf_axi_araddr_w)
    ,.inport0_arid_i(psf_axi_arid_w)
    ,.inport0_arlen_i(psf_axi_arlen_w)
    ,.inport0_arburst_i(psf_axi_arburst_w)
    ,.inport0_rready_i(psf_axi_rready_w)
    ,.inport1_awvalid_i(gpu_axi_retime_awvalid_w)
    ,.inport1_awaddr_i(gpu_axi_retime_awaddr_w)
    ,.inport1_awid_i(gpu_axi_retime_awid_w)
    ,.inport1_awlen_i(gpu_axi_retime_awlen_w)
    ,.inport1_awburst_i(gpu_axi_retime_awburst_w)
    ,.inport1_wvalid_i(gpu_axi_retime_wvalid_w)
    ,.inport1_wdata_i(gpu_axi_retime_wdata_w)
    ,.inport1_wstrb_i(gpu_axi_retime_wstrb_w)
    ,.inport1_wlast_i(gpu_axi_retime_wlast_w)
    ,.inport1_bready_i(gpu_axi_retime_bready_w)
    ,.inport1_arvalid_i(gpu_axi_retime_arvalid_w)
    ,.inport1_araddr_i(gpu_axi_retime_araddr_w)
    ,.inport1_arid_i(gpu_axi_retime_arid_w)
    ,.inport1_arlen_i(gpu_axi_retime_arlen_w)
    ,.inport1_arburst_i(gpu_axi_retime_arburst_w)
    ,.inport1_rready_i(gpu_axi_retime_rready_w)
    ,.inport2_awvalid_i(display_axi_awvalid_w)
    ,.inport2_awaddr_i(display_axi_awaddr_w)
    ,.inport2_awid_i(display_axi_awid_w)
    ,.inport2_awlen_i(display_axi_awlen_w)
    ,.inport2_awburst_i(display_axi_awburst_w)
    ,.inport2_wvalid_i(display_axi_wvalid_w)
    ,.inport2_wdata_i(display_axi_wdata_w)
    ,.inport2_wstrb_i(display_axi_wstrb_w)
    ,.inport2_wlast_i(display_axi_wlast_w)
    ,.inport2_bready_i(display_axi_bready_w)
    ,.inport2_arvalid_i(display_axi_arvalid_w)
    ,.inport2_araddr_i(display_axi_araddr_w)
    ,.inport2_arid_i(display_axi_arid_w)
    ,.inport2_arlen_i(display_axi_arlen_w)
    ,.inport2_arburst_i(display_axi_arburst_w)
    ,.inport2_rready_i(display_axi_rready_w)
    ,.inport3_awvalid_i(cdrom_axi_awvalid_w)
    ,.inport3_awaddr_i(cdrom_axi_awaddr_w)
    ,.inport3_awid_i(cdrom_axi_awid_w)
    ,.inport3_awlen_i(cdrom_axi_awlen_w)
    ,.inport3_awburst_i(cdrom_axi_awburst_w)
    ,.inport3_wvalid_i(cdrom_axi_wvalid_w)
    ,.inport3_wdata_i(cdrom_axi_wdata_w)
    ,.inport3_wstrb_i(cdrom_axi_wstrb_w)
    ,.inport3_wlast_i(cdrom_axi_wlast_w)
    ,.inport3_bready_i(cdrom_axi_bready_w)
    ,.inport3_arvalid_i(cdrom_axi_arvalid_w)
    ,.inport3_araddr_i(cdrom_axi_araddr_w)
    ,.inport3_arid_i(cdrom_axi_arid_w)
    ,.inport3_arlen_i(cdrom_axi_arlen_w)
    ,.inport3_arburst_i(cdrom_axi_arburst_w)
    ,.inport3_rready_i(cdrom_axi_rready_w)
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
    ,.inport0_awready_o(psf_axi_awready_w)
    ,.inport0_wready_o(psf_axi_wready_w)
    ,.inport0_bvalid_o(psf_axi_bvalid_w)
    ,.inport0_bresp_o(psf_axi_bresp_w)
    ,.inport0_bid_o(psf_axi_bid_w)
    ,.inport0_arready_o(psf_axi_arready_w)
    ,.inport0_rvalid_o(psf_axi_rvalid_w)
    ,.inport0_rdata_o(psf_axi_rdata_w)
    ,.inport0_rresp_o(psf_axi_rresp_w)
    ,.inport0_rid_o(psf_axi_rid_w)
    ,.inport0_rlast_o(psf_axi_rlast_w)
    ,.inport1_awready_o(gpu_axi_retime_awready_w)
    ,.inport1_wready_o(gpu_axi_retime_wready_w)
    ,.inport1_bvalid_o(gpu_axi_retime_bvalid_w)
    ,.inport1_bresp_o(gpu_axi_retime_bresp_w)
    ,.inport1_bid_o(gpu_axi_retime_bid_w)
    ,.inport1_arready_o(gpu_axi_retime_arready_w)
    ,.inport1_rvalid_o(gpu_axi_retime_rvalid_w)
    ,.inport1_rdata_o(gpu_axi_retime_rdata_w)
    ,.inport1_rresp_o(gpu_axi_retime_rresp_w)
    ,.inport1_rid_o(gpu_axi_retime_rid_w)
    ,.inport1_rlast_o(gpu_axi_retime_rlast_w)
    ,.inport2_awready_o(display_axi_awready_w)
    ,.inport2_wready_o(display_axi_wready_w)
    ,.inport2_bvalid_o(display_axi_bvalid_w)
    ,.inport2_bresp_o(display_axi_bresp_w)
    ,.inport2_bid_o(display_axi_bid_w)
    ,.inport2_arready_o(display_axi_arready_w)
    ,.inport2_rvalid_o(display_axi_rvalid_w)
    ,.inport2_rdata_o(display_axi_rdata_w)
    ,.inport2_rresp_o(display_axi_rresp_w)
    ,.inport2_rid_o(display_axi_rid_w)
    ,.inport2_rlast_o(display_axi_rlast_w)
    ,.inport3_awready_o(cdrom_axi_awready_w)
    ,.inport3_wready_o(cdrom_axi_wready_w)
    ,.inport3_bvalid_o(cdrom_axi_bvalid_w)
    ,.inport3_bresp_o(cdrom_axi_bresp_w)
    ,.inport3_bid_o(cdrom_axi_bid_w)
    ,.inport3_arready_o(cdrom_axi_arready_w)
    ,.inport3_rvalid_o(cdrom_axi_rvalid_w)
    ,.inport3_rdata_o(cdrom_axi_rdata_w)
    ,.inport3_rresp_o(cdrom_axi_rresp_w)
    ,.inport3_rid_o(cdrom_axi_rid_w)
    ,.inport3_rlast_o(cdrom_axi_rlast_w)
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


spi_lite
#(
     .C_SCK_RATIO(5)
)
u_spi
(
    // Inputs
     .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.cfg_addr_i(spi_cfg_addr_w)
    ,.cfg_data_wr_i(spi_cfg_data_wr_w)
    ,.cfg_stb_i(spi_cfg_stb_w)
    ,.cfg_we_i(spi_cfg_we_w)
    ,.spi_miso_i(spi_miso_i)

    // Outputs
    ,.cfg_data_rd_o(spi_cfg_data_rd_w)
    ,.cfg_ack_o(spi_cfg_ack_w)
    ,.cfg_stall_o(spi_cfg_stall_w)
    ,.spi_clk_o(spi_clk_o)
    ,.spi_mosi_o(spi_mosi_o)
    ,.spi_cs_o(spi_cs_o)
    ,.intr_o(spi_irq_w)
);


axi4_retime256
#(
     .AXI4_RETIME_RD_RESP(1)
    ,.AXI4_RETIME_WR_RESP(1)
    ,.AXI4_RETIME_RD_REQ(1)
    ,.AXI4_RETIME_WR_REQ(1)
)
u_gpu_retime
(
    // Inputs
     .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.inport_awvalid_i(gpu_axi_awvalid_w)
    ,.inport_awaddr_i(gpu_axi_awaddr_w)
    ,.inport_awid_i(gpu_axi_awid_w)
    ,.inport_awlen_i(gpu_axi_awlen_w)
    ,.inport_awburst_i(gpu_axi_awburst_w)
    ,.inport_wvalid_i(gpu_axi_wvalid_w)
    ,.inport_wdata_i(gpu_axi_wdata_w)
    ,.inport_wstrb_i(gpu_axi_wstrb_w)
    ,.inport_wlast_i(gpu_axi_wlast_w)
    ,.inport_bready_i(gpu_axi_bready_w)
    ,.inport_arvalid_i(gpu_axi_arvalid_w)
    ,.inport_araddr_i(gpu_axi_araddr_w)
    ,.inport_arid_i(gpu_axi_arid_w)
    ,.inport_arlen_i(gpu_axi_arlen_w)
    ,.inport_arburst_i(gpu_axi_arburst_w)
    ,.inport_rready_i(gpu_axi_rready_w)
    ,.outport_awready_i(gpu_axi_retime_awready_w)
    ,.outport_wready_i(gpu_axi_retime_wready_w)
    ,.outport_bvalid_i(gpu_axi_retime_bvalid_w)
    ,.outport_bresp_i(gpu_axi_retime_bresp_w)
    ,.outport_bid_i(gpu_axi_retime_bid_w)
    ,.outport_arready_i(gpu_axi_retime_arready_w)
    ,.outport_rvalid_i(gpu_axi_retime_rvalid_w)
    ,.outport_rdata_i(gpu_axi_retime_rdata_w)
    ,.outport_rresp_i(gpu_axi_retime_rresp_w)
    ,.outport_rid_i(gpu_axi_retime_rid_w)
    ,.outport_rlast_i(gpu_axi_retime_rlast_w)

    // Outputs
    ,.inport_awready_o(gpu_axi_awready_w)
    ,.inport_wready_o(gpu_axi_wready_w)
    ,.inport_bvalid_o(gpu_axi_bvalid_w)
    ,.inport_bresp_o(gpu_axi_bresp_w)
    ,.inport_bid_o(gpu_axi_bid_w)
    ,.inport_arready_o(gpu_axi_arready_w)
    ,.inport_rvalid_o(gpu_axi_rvalid_w)
    ,.inport_rdata_o(gpu_axi_rdata_w)
    ,.inport_rresp_o(gpu_axi_rresp_w)
    ,.inport_rid_o(gpu_axi_rid_w)
    ,.inport_rlast_o(gpu_axi_rlast_w)
    ,.outport_awvalid_o(gpu_axi_retime_awvalid_w)
    ,.outport_awaddr_o(gpu_axi_retime_awaddr_w)
    ,.outport_awid_o(gpu_axi_retime_awid_w)
    ,.outport_awlen_o(gpu_axi_retime_awlen_w)
    ,.outport_awburst_o(gpu_axi_retime_awburst_w)
    ,.outport_wvalid_o(gpu_axi_retime_wvalid_w)
    ,.outport_wdata_o(gpu_axi_retime_wdata_w)
    ,.outport_wstrb_o(gpu_axi_retime_wstrb_w)
    ,.outport_wlast_o(gpu_axi_retime_wlast_w)
    ,.outport_bready_o(gpu_axi_retime_bready_w)
    ,.outport_arvalid_o(gpu_axi_retime_arvalid_w)
    ,.outport_araddr_o(gpu_axi_retime_araddr_w)
    ,.outport_arid_o(gpu_axi_retime_arid_w)
    ,.outport_arlen_o(gpu_axi_retime_arlen_w)
    ,.outport_arburst_o(gpu_axi_retime_arburst_w)
    ,.outport_rready_o(gpu_axi_retime_rready_w)
);



endmodule
