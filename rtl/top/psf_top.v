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
module psf_top
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
     parameter CLK_FREQ         = 30000000
    ,parameter BAUDRATE         = 1000000
    ,parameter UART_SPEED       = 1000000
    ,parameter VRAM_BASE        = 50331648
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(
    // Inputs
     input           clk_i
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
    ,input           axi_vram_awready_i
    ,input           axi_vram_wready_i
    ,input           axi_vram_bvalid_i
    ,input  [  1:0]  axi_vram_bresp_i
    ,input  [  3:0]  axi_vram_bid_i
    ,input           axi_vram_arready_i
    ,input           axi_vram_rvalid_i
    ,input  [255:0]  axi_vram_rdata_i
    ,input  [  1:0]  axi_vram_rresp_i
    ,input  [  3:0]  axi_vram_rid_i
    ,input           axi_vram_rlast_i
    ,input           axi_cdrom_awready_i
    ,input           axi_cdrom_wready_i
    ,input           axi_cdrom_bvalid_i
    ,input  [  1:0]  axi_cdrom_bresp_i
    ,input  [  3:0]  axi_cdrom_bid_i
    ,input           axi_cdrom_arready_i
    ,input           axi_cdrom_rvalid_i
    ,input  [255:0]  axi_cdrom_rdata_i
    ,input  [  1:0]  axi_cdrom_rresp_i
    ,input  [  3:0]  axi_cdrom_rid_i
    ,input           axi_cdrom_rlast_i
    ,input           joy1_dat_i
    ,input           joy1_ack_i
    ,input           joy2_dat_i
    ,input           joy2_ack_i
    ,input           display_field_i
    ,input           display_hblank_i
    ,input           display_vblank_i
    ,input           display_dotclk_i
    ,input  [ 31:0]  gpio_in_i
    ,input  [ 31:0]  cdrom_ext_cfg_data_rd_i
    ,input           cdrom_ext_cfg_ack_i
    ,input           cdrom_ext_cfg_stall_i
    ,input           cdrom_ext_irq_i

    // Outputs
    ,output          dbg_rxd_o
    ,output          uart_tx_o
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
    ,output          axi_vram_awvalid_o
    ,output [ 31:0]  axi_vram_awaddr_o
    ,output [  3:0]  axi_vram_awid_o
    ,output [  7:0]  axi_vram_awlen_o
    ,output [  1:0]  axi_vram_awburst_o
    ,output          axi_vram_wvalid_o
    ,output [255:0]  axi_vram_wdata_o
    ,output [ 31:0]  axi_vram_wstrb_o
    ,output          axi_vram_wlast_o
    ,output          axi_vram_bready_o
    ,output          axi_vram_arvalid_o
    ,output [ 31:0]  axi_vram_araddr_o
    ,output [  3:0]  axi_vram_arid_o
    ,output [  7:0]  axi_vram_arlen_o
    ,output [  1:0]  axi_vram_arburst_o
    ,output          axi_vram_rready_o
    ,output          axi_cdrom_awvalid_o
    ,output [ 31:0]  axi_cdrom_awaddr_o
    ,output [  3:0]  axi_cdrom_awid_o
    ,output [  7:0]  axi_cdrom_awlen_o
    ,output [  1:0]  axi_cdrom_awburst_o
    ,output          axi_cdrom_wvalid_o
    ,output [255:0]  axi_cdrom_wdata_o
    ,output [ 31:0]  axi_cdrom_wstrb_o
    ,output          axi_cdrom_wlast_o
    ,output          axi_cdrom_bready_o
    ,output          axi_cdrom_arvalid_o
    ,output [ 31:0]  axi_cdrom_araddr_o
    ,output [  3:0]  axi_cdrom_arid_o
    ,output [  7:0]  axi_cdrom_arlen_o
    ,output [  1:0]  axi_cdrom_arburst_o
    ,output          axi_cdrom_rready_o
    ,output          i2s_sck_o
    ,output          i2s_sdata_o
    ,output          i2s_ws_o
    ,output          joy1_sel_o
    ,output          joy1_clk_o
    ,output          joy1_cmd_o
    ,output          joy2_sel_o
    ,output          joy2_clk_o
    ,output          joy2_cmd_o
    ,output [  9:0]  display_res_x_o
    ,output [  8:0]  display_res_y_o
    ,output [  9:0]  display_x_o
    ,output [  8:0]  display_y_o
    ,output          display_interlaced_o
    ,output          display_pal_o
    ,output          cdrom_tx_o
    ,output [ 31:0]  gpio_out_o
    ,output [ 31:0]  cdrom_ext_cfg_addr_o
    ,output [ 31:0]  cdrom_ext_cfg_data_wr_o
    ,output          cdrom_ext_cfg_stb_o
    ,output          cdrom_ext_cfg_we_o
);

wire           cpu_d_arready_w;
wire           cpu_d_mem_rvalid_w;
wire           spu_m2p_valid_w;
wire           wb_joy_err_w;
wire           wb_uart_we_w;
wire  [  1:0]  cpu_d_rresp_w;
wire           remap_axi_arvalid_w;
wire           cpu_d_bvalid_w;
wire  [ 31:0]  wb_sio_data_wr_w;
wire           wb_dma_err_w;
wire           irq_timer2_w;
wire           irq_timer0_w;
wire           irq_timer1_w;
wire  [ 31:0]  mdec_p2m_data_w;
wire           wb_spu_stall_w;
wire           remap_axi_arready_w;
wire           cpu_i_wvalid_w;
wire           cpu_d_io_we_w;
wire           wb_timers_ack_w;
wire  [ 31:0]  cdrom_upconv_rdata_w;
wire  [  1:0]  mem_arb_rresp_w;
wire  [ 31:0]  debug_config_w;
wire           mdec_m2p_accept_w;
wire  [ 31:0]  wb_timers_addr_w;
wire           irq_spu_w;
wire  [  1:0]  dma_mem_awburst_w;
wire           timer_vblank_w;
wire  [  3:0]  wb_spu_sel_w;
wire  [  2:0]  dma_mem_awsize_w;
wire  [  2:0]  cpu_i_awsize_w;
wire  [  1:0]  remap_axi_bresp_w;
wire           dma_mem_arready_w;
wire           wb_dma_cyc_w;
wire           mdec_m2p_valid_w;
wire  [ 31:0]  cpu_d_io_addr_w;
wire           dbg_axi_awvalid_w;
wire           wb_mdec_we_w;
wire  [ 31:0]  remap_axi_araddr_w;
wire           gpu_p2m_valid_w;
wire           wb_uart_ack_w;
wire           cdrom_p2m_dma_en_w;
wire           spu_p2m_dreq_w;
wire           wb_spu_ack_w;
wire           wb_dma_stall_w;
wire           irq_sio_w;
wire  [  7:0]  cdrom_upconv_arlen_w;
wire           dbg_axi_awready_w;
wire           remap_axi_wready_w;
wire  [  1:0]  remap_axi_rresp_w;
wire           wb_irqctrl_we_w;
wire  [  7:0]  remap_axi_awlen_w;
wire  [ 31:0]  debug_monitor_w;
wire  [  3:0]  wb_joy_sel_w;
wire           mem_arb_rvalid_w;
wire           wb_gpu_we_w;
wire           wb_spu_cyc_w;
wire           wb_cdrom_stb_w;
wire           cpu_i_wlast_w;
wire           remap_axi_wlast_w;
wire           wb_cdrom_we_w;
wire           cpu_d_wlast_w;
wire  [  2:0]  mem_arb_awsize_w;
wire           wb_timers_stall_w;
wire  [ 31:0]  mdec_m2p_data_w;
wire  [ 31:0]  spu_m2p_data_w;
wire  [  3:0]  cdrom_upconv_arid_w;
wire           remap_axi_wvalid_w;
wire           dma_mem_wready_w;
wire  [  1:0]  cpu_d_mem_rresp_w;
wire           cpu_d_mem_awready_w;
wire  [  7:0]  cpu_d_mem_arlen_w;
wire  [ 31:0]  cpu_i_rdata_w;
wire  [  2:0]  dbg_axi_awsize_w;
wire  [ 31:0]  wb_mdec_data_wr_w;
wire  [  3:0]  mem_arb_bid_w;
wire  [ 31:0]  cpu_i_araddr_w;
wire  [  3:0]  remap_axi_arid_w;
wire  [ 31:0]  wb_atcons_data_wr_w;
wire           mem_arb_wlast_w;
wire  [  7:0]  cpu_i_arlen_w;
wire  [ 31:0]  cpu_d_awaddr_w;
wire  [ 31:0]  dbg_axi_awaddr_w;
wire  [ 31:0]  cpu_d_mem_awaddr_w;
wire           wb_sio_ack_w;
wire           wb_joy_we_w;
wire  [  3:0]  remap_axi_bid_w;
wire           wb_spu_stb_w;
wire           event_debug_w;
wire           wb_cdrom_cyc_w;
wire  [  3:0]  remap_axi_rid_w;
wire           dma_mem_rvalid_w;
wire           mdec_p2m_accept_w;
wire  [  2:0]  cdrom_upconv_awsize_w;
wire  [ 31:0]  mem_arb_awaddr_w;
wire           wb_dma_we_w;
wire           dma_mem_awvalid_w;
wire           cdrom_p2m_dreq_w;
wire  [  3:0]  dma_mem_arid_w;
wire           spu_m2p_dreq_w;
wire           cpu_i_rlast_w;
wire           cpu_d_awvalid_w;
wire           mem_arb_awready_w;
wire  [  3:0]  cpu_i_bid_w;
wire  [ 31:0]  cpu_d_io_data_rd_w;
wire           cpu_nmi_w;
wire           gpu_p2m_dreq_w;
wire  [  3:0]  cpu_i_rid_w;
wire  [ 31:0]  wb_timers_data_wr_w;
wire  [  3:0]  dma_mem_rid_w;
wire  [ 31:0]  wb_atcons_data_rd_w;
wire           cdrom_upconv_arready_w;
wire  [ 31:0]  cpu_d_araddr_w;
wire           mem_arb_arready_w;
wire  [  1:0]  dbg_axi_awburst_w;
wire  [  3:0]  dma_mem_wstrb_w;
wire  [  3:0]  cdrom_upconv_wstrb_w;
wire           gpu_p2m_accept_w;
wire           cpu_d_io_stb_w;
wire  [ 31:0]  dma_mem_wdata_w;
wire           mem_arb_bvalid_w;
wire  [  1:0]  remap_axi_arburst_w;
wire           cpu_i_awvalid_w;
wire  [ 31:0]  cdrom_upconv_awaddr_w;
wire  [  1:0]  dbg_axi_bresp_w;
wire  [  3:0]  wb_cdrom_sel_w;
wire  [ 31:0]  wb_dma_data_rd_w;
wire  [ 31:0]  cpu_d_mem_wdata_w;
wire           cpu_d_io_err_w;
wire           wb_sio_we_w;
wire           cpu_i_arvalid_w;
wire  [ 31:0]  wb_irqctrl_addr_w;
wire           gpu_vblank_w;
wire  [  1:0]  mem_arb_arburst_w;
wire           gpu_hblank_w;
wire           cpu_d_io_cyc_w;
wire           remap_axi_awready_w;
wire           cdrom_p2m_accept_w;
wire           cpu_d_arvalid_w;
wire  [  2:0]  cpu_d_mem_arsize_w;
wire           dma_mem_wlast_w;
wire  [  2:0]  dma_mem_arsize_w;
wire  [  3:0]  cpu_d_io_sel_w;
wire  [  3:0]  cpu_i_wstrb_w;
wire           cdrom_upconv_bvalid_w;
wire  [ 31:0]  wb_spu_addr_w;
wire  [  2:0]  cpu_i_arsize_w;
wire  [ 31:0]  wb_gpu_data_rd_w;
wire  [ 31:0]  dbg_axi_araddr_w;
wire  [ 31:0]  wb_spu_data_rd_w;
wire           irq_dma_w;
wire           cpu_d_mem_bready_w;
wire           timer_hblank_w;
wire           cpu_d_mem_wvalid_w;
wire  [  3:0]  remap_axi_awid_w;
wire           cpu_d_wvalid_w;
wire           dbg_axi_wvalid_w;
wire           wb_atcons_ack_w;
wire           wb_joy_stb_w;
wire           wb_cdrom_err_w;
wire           wb_cdrom_ack_w;
wire  [ 31:0]  spu_p2m_data_w;
wire           wb_sio_cyc_w;
wire  [ 31:0]  cpu_i_awaddr_w;
wire  [  3:0]  cpu_d_mem_rid_w;
wire           cdrom_upconv_wvalid_w;
wire  [ 31:0]  wb_joy_addr_w;
wire  [ 31:0]  remap_axi_awaddr_w;
wire  [ 31:0]  wb_dma_addr_w;
wire  [ 31:0]  wb_cdrom_addr_w;
wire           cpu_d_rlast_w;
wire           cpu_d_mem_arready_w;
wire           cpu_inhibit_w;
wire  [  3:0]  cpu_d_rid_w;
wire  [  1:0]  dma_mem_rresp_w;
wire  [  3:0]  cpu_d_wstrb_w;
wire           cpu_d_bready_w;
wire  [  7:0]  cpu_d_arlen_w;
wire           wb_atcons_we_w;
wire  [ 31:0]  wb_cdrom_data_wr_w;
wire  [  3:0]  cdrom_upconv_awid_w;
wire  [  1:0]  cpu_d_mem_arburst_w;
wire           mdec_m2p_dreq_w;
wire  [ 31:0]  remap_axi_wdata_w;
wire  [  3:0]  mem_arb_arid_w;
wire  [  7:0]  cdrom_upconv_awlen_w;
wire           mem_arb_rlast_w;
wire  [ 31:0]  cdrom_upconv_wdata_w;
wire           wb_irqctrl_stall_w;
wire           cpu_d_mem_arvalid_w;
wire  [ 31:0]  wb_joy_data_wr_w;
wire  [ 31:0]  debug_cpu_w;
wire  [ 31:0]  wb_irqctrl_data_wr_w;
wire  [  1:0]  cpu_i_bresp_w;
wire           wb_joy_stall_w;
wire  [  3:0]  mem_arb_awid_w;
wire  [ 31:0]  wb_sio_data_rd_w;
wire           mem_arb_arvalid_w;
wire  [  3:0]  dma_mem_bid_w;
wire           mem_arb_wready_w;
wire  [  1:0]  cpu_d_bresp_w;
wire           cpu_i_bvalid_w;
wire  [  7:0]  mem_arb_awlen_w;
wire           cdrom_upconv_rvalid_w;
wire  [  2:0]  cpu_d_awsize_w;
wire           remap_axi_bvalid_w;
wire  [  2:0]  remap_axi_awsize_w;
wire  [  2:0]  cpu_d_mem_awsize_w;
wire           cpu_i_awready_w;
wire           wb_atcons_stall_w;
wire           wb_uart_stb_w;
wire  [ 31:0]  wb_irqctrl_data_rd_w;
wire  [  7:0]  remap_axi_arlen_w;
wire  [  2:0]  remap_axi_arsize_w;
wire  [  1:0]  mem_arb_bresp_w;
wire  [  3:0]  cpu_d_mem_bid_w;
wire  [ 31:0]  cpu_d_wdata_w;
wire           dma_mem_rlast_w;
wire           mem_arb_wvalid_w;
wire  [ 31:0]  wb_dma_data_wr_w;
wire           mem_arb_rready_w;
wire  [  3:0]  cpu_d_arid_w;
wire           cpu_i_arready_w;
wire           rst_cpu_w;
wire  [  3:0]  cpu_i_arid_w;
wire  [ 31:0]  cdrom_upconv_araddr_w;
wire           wb_joy_cyc_w;
wire           cpu_i_rready_w;
wire  [ 31:0]  mem_arb_araddr_w;
wire  [  1:0]  cdrom_upconv_awburst_w;
wire           mdec_p2m_dreq_w;
wire  [ 31:0]  cpu_d_mem_rdata_w;
wire  [  1:0]  cpu_i_arburst_w;
wire           wb_irqctrl_stb_w;
wire           wb_spu_err_w;
wire           dbg_axi_bvalid_w;
wire           sio_rxd_w;
wire  [  3:0]  cpu_d_mem_wstrb_w;
wire           remap_axi_rready_w;
wire           wb_dma_ack_w;
wire  [  1:0]  mem_arb_awburst_w;
wire  [  3:0]  wb_dma_sel_w;
wire           wb_joy_ack_w;
wire           wb_mdec_stb_w;
wire           cdrom_upconv_awready_w;
wire           cdrom_upconv_wready_w;
wire           mem_arb_bready_w;
wire  [  7:0]  mem_arb_arlen_w;
wire  [ 31:0]  wb_spu_data_wr_w;
wire           cpu_d_mem_awvalid_w;
wire  [  7:0]  dbg_axi_awlen_w;
wire  [ 31:0]  wb_uart_data_rd_w;
wire           wb_spu_we_w;
wire  [ 31:0]  cpu_d_rdata_w;
wire  [  3:0]  cpu_d_mem_arid_w;
wire  [ 31:0]  dma_mem_araddr_w;
wire  [ 31:0]  wb_mdec_data_rd_w;
wire  [ 31:0]  wb_gpu_addr_w;
wire  [ 31:0]  wb_atcons_addr_w;
wire  [ 31:0]  enable_w;
wire  [  2:0]  cpu_d_arsize_w;
wire  [ 31:0]  wb_cdrom_data_rd_w;
wire           wb_sio_stall_w;
wire           cpu_d_mem_wlast_w;
wire           cdrom_upconv_wlast_w;
wire           dma_mem_bvalid_w;
wire           cpu_d_io_stall_w;
wire           wb_timers_we_w;
wire  [  1:0]  cpu_d_awburst_w;
wire           gpu_m2p_accept_w;
wire  [  3:0]  dbg_axi_rid_w;
wire  [  7:0]  dma_mem_awlen_w;
wire  [  2:0]  mem_arb_arsize_w;
wire  [  2:0]  dbg_axi_arsize_w;
wire  [  1:0]  dbg_axi_rresp_w;
wire  [ 31:0]  wb_joy_data_rd_w;
wire  [ 31:0]  wb_gpu_data_wr_w;
wire           cpu_d_mem_wready_w;
wire           cpu_i_rvalid_w;
wire           dbg_axi_rlast_w;
wire           dbg_axi_rready_w;
wire           spu_p2m_valid_w;
wire           dma_mem_wvalid_w;
wire           wb_uart_stall_w;
wire  [  7:0]  dbg_axi_arlen_w;
wire  [ 31:0]  wb_uart_addr_w;
wire  [ 31:0]  cpu_d_io_data_wr_w;
wire           cdrom_upconv_rready_w;
wire  [  3:0]  dbg_axi_bid_w;
wire  [  3:0]  cpu_d_bid_w;
wire           cpu_d_rvalid_w;
wire           cdrom_upconv_rlast_w;
wire  [ 31:0]  cpu_d_mem_araddr_w;
wire  [  3:0]  cpu_i_awid_w;
wire  [ 31:0]  dma_mem_rdata_w;
wire  [  1:0]  cpu_i_awburst_w;
wire  [  3:0]  cdrom_upconv_bid_w;
wire  [ 31:0]  cpu_i_wdata_w;
wire  [  3:0]  dbg_axi_arid_w;
wire  [ 31:0]  cdrom_p2m_dma_bs_w;
wire           cdrom_upconv_bready_w;
wire  [  1:0]  dma_mem_arburst_w;
wire  [ 31:0]  remap_axi_rdata_w;
wire           dbg_axi_wlast_w;
wire           cpu_d_rready_w;
wire           wb_cdrom_stall_w;
wire  [  7:0]  cpu_d_mem_awlen_w;
wire           timer_pal_w;
wire           wb_mdec_ack_w;
wire  [ 31:0]  mem_arb_rdata_w;
wire           mem_arb_awvalid_w;
wire           wb_irqctrl_cyc_w;
wire           wb_dma_stb_w;
wire           dma_mem_arvalid_w;
wire           cpu_d_mem_rready_w;
wire           cdrom_p2m_valid_w;
wire  [  1:0]  cpu_d_mem_awburst_w;
wire           wb_sio_stb_w;
wire  [  3:0]  remap_axi_wstrb_w;
wire           mdec_p2m_valid_w;
wire  [ 31:0]  wb_mdec_addr_w;
wire           gpu_m2p_valid_w;
wire           cpu_d_io_ack_w;
wire           dma_mem_awready_w;
wire           spu_p2m_accept_w;
wire  [  1:0]  remap_axi_awburst_w;
wire  [  5:0]  cpu_intr_w;
wire           wb_atcons_stb_w;
wire           dbg_axi_arready_w;
wire  [  3:0]  cpu_d_awid_w;
wire           irq_gpu_w;
wire  [  3:0]  dbg_axi_awid_w;
wire  [  3:0]  mem_arb_wstrb_w;
wire  [  3:0]  wb_irqctrl_sel_w;
wire           cpu_i_bready_w;
wire  [ 31:0]  cdrom_p2m_data_w;
wire           remap_axi_rvalid_w;
wire           wb_mdec_stall_w;
wire  [  1:0]  cdrom_upconv_bresp_w;
wire  [  1:0]  cdrom_upconv_rresp_w;
wire           dbg_axi_arvalid_w;
wire           cdrom_upconv_arvalid_w;
wire           wb_sio_err_w;
wire           wb_gpu_ack_w;
wire  [ 31:0]  dbg_axi_rdata_w;
wire  [ 31:0]  wb_uart_data_wr_w;
wire  [ 31:0]  dbg_axi_wdata_w;
wire           remap_axi_awvalid_w;
wire  [  3:0]  dbg_axi_wstrb_w;
wire  [  1:0]  cpu_d_mem_bresp_w;
wire  [  3:0]  cdrom_upconv_rid_w;
wire           wb_gpu_stall_w;
wire           cdrom_upconv_awvalid_w;
wire           wb_gpu_stb_w;
wire           spu_m2p_accept_w;
wire           irq_cdrom_w;
wire  [  2:0]  cdrom_upconv_arsize_w;
wire           gpu_m2p_dreq_w;
wire  [  1:0]  dbg_axi_arburst_w;
wire           dbg_axi_bready_w;
wire           dbg_axi_rvalid_w;
wire           cpu_d_mem_bvalid_w;
wire  [  7:0]  cpu_i_awlen_w;
wire           wb_timers_stb_w;
wire  [ 31:0]  gpu_m2p_data_w;
wire  [  1:0]  cpu_d_arburst_w;
wire  [ 31:0]  gpu_p2m_data_w;
wire           irq_vblank_w;
wire  [ 31:0]  wb_timers_data_rd_w;
wire  [  1:0]  dma_mem_bresp_w;
wire  [ 31:0]  mem_arb_wdata_w;
wire           cpu_d_mem_rlast_w;
wire           dma_mem_bready_w;
wire  [  3:0]  dma_mem_awid_w;
wire           event_magic_w;
wire           irq_joy_w;
wire           wb_irqctrl_err_w;
wire  [  7:0]  dma_mem_arlen_w;
wire           remap_axi_rlast_w;
wire           dbg_axi_wready_w;
wire  [  5:0]  debug_cpu_src_w;
wire  [  3:0]  mem_arb_rid_w;
wire           cpu_i_wready_w;
wire  [  3:0]  wb_sio_sel_w;
wire  [ 31:0]  dma_mem_awaddr_w;
wire           cpu_d_wready_w;
wire           dma_mem_rready_w;
wire  [  7:0]  cpu_d_awlen_w;
wire           cpu_d_awready_w;
wire  [  1:0]  cpu_i_rresp_w;
wire           remap_axi_bready_w;
wire  [  3:0]  cpu_d_mem_awid_w;
wire           wb_irqctrl_ack_w;
wire  [  1:0]  cdrom_upconv_arburst_w;
wire  [ 31:0]  wb_sio_addr_w;


mdec
u_mdec
(
    // Inputs
     .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.cfg_addr_i(wb_mdec_addr_w)
    ,.cfg_data_wr_i(wb_mdec_data_wr_w)
    ,.cfg_stb_i(wb_mdec_stb_w)
    ,.cfg_we_i(wb_mdec_we_w)
    ,.m2p_valid_i(mdec_m2p_valid_w)
    ,.m2p_data_i(mdec_m2p_data_w)
    ,.p2m_accept_i(mdec_p2m_accept_w)

    // Outputs
    ,.cfg_data_rd_o(wb_mdec_data_rd_w)
    ,.cfg_ack_o(wb_mdec_ack_w)
    ,.cfg_stall_o(wb_mdec_stall_w)
    ,.m2p_dreq_o(mdec_m2p_dreq_w)
    ,.m2p_accept_o(mdec_m2p_accept_w)
    ,.p2m_dreq_o(mdec_p2m_dreq_w)
    ,.p2m_valid_o(mdec_p2m_valid_w)
    ,.p2m_data_o(mdec_p2m_data_w)
);


mem_arb
u_mem_arb
(
    // Inputs
     .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.inport0_awvalid_i(dma_mem_awvalid_w)
    ,.inport0_awaddr_i(dma_mem_awaddr_w)
    ,.inport0_awid_i(dma_mem_awid_w)
    ,.inport0_awlen_i(dma_mem_awlen_w)
    ,.inport0_awburst_i(dma_mem_awburst_w)
    ,.inport0_awsize_i(dma_mem_awsize_w)
    ,.inport0_wvalid_i(dma_mem_wvalid_w)
    ,.inport0_wdata_i(dma_mem_wdata_w)
    ,.inport0_wstrb_i(dma_mem_wstrb_w)
    ,.inport0_wlast_i(dma_mem_wlast_w)
    ,.inport0_bready_i(dma_mem_bready_w)
    ,.inport0_arvalid_i(dma_mem_arvalid_w)
    ,.inport0_araddr_i(dma_mem_araddr_w)
    ,.inport0_arid_i(dma_mem_arid_w)
    ,.inport0_arlen_i(dma_mem_arlen_w)
    ,.inport0_arburst_i(dma_mem_arburst_w)
    ,.inport0_arsize_i(dma_mem_arsize_w)
    ,.inport0_rready_i(dma_mem_rready_w)
    ,.inport1_awvalid_i(cpu_i_awvalid_w)
    ,.inport1_awaddr_i(cpu_i_awaddr_w)
    ,.inport1_awid_i(cpu_i_awid_w)
    ,.inport1_awlen_i(cpu_i_awlen_w)
    ,.inport1_awburst_i(cpu_i_awburst_w)
    ,.inport1_awsize_i(cpu_i_awsize_w)
    ,.inport1_wvalid_i(cpu_i_wvalid_w)
    ,.inport1_wdata_i(cpu_i_wdata_w)
    ,.inport1_wstrb_i(cpu_i_wstrb_w)
    ,.inport1_wlast_i(cpu_i_wlast_w)
    ,.inport1_bready_i(cpu_i_bready_w)
    ,.inport1_arvalid_i(cpu_i_arvalid_w)
    ,.inport1_araddr_i(cpu_i_araddr_w)
    ,.inport1_arid_i(cpu_i_arid_w)
    ,.inport1_arlen_i(cpu_i_arlen_w)
    ,.inport1_arburst_i(cpu_i_arburst_w)
    ,.inport1_arsize_i(cpu_i_arsize_w)
    ,.inport1_rready_i(cpu_i_rready_w)
    ,.inport2_awvalid_i(cpu_d_mem_awvalid_w)
    ,.inport2_awaddr_i(cpu_d_mem_awaddr_w)
    ,.inport2_awid_i(cpu_d_mem_awid_w)
    ,.inport2_awlen_i(cpu_d_mem_awlen_w)
    ,.inport2_awburst_i(cpu_d_mem_awburst_w)
    ,.inport2_awsize_i(cpu_d_mem_awsize_w)
    ,.inport2_wvalid_i(cpu_d_mem_wvalid_w)
    ,.inport2_wdata_i(cpu_d_mem_wdata_w)
    ,.inport2_wstrb_i(cpu_d_mem_wstrb_w)
    ,.inport2_wlast_i(cpu_d_mem_wlast_w)
    ,.inport2_bready_i(cpu_d_mem_bready_w)
    ,.inport2_arvalid_i(cpu_d_mem_arvalid_w)
    ,.inport2_araddr_i(cpu_d_mem_araddr_w)
    ,.inport2_arid_i(cpu_d_mem_arid_w)
    ,.inport2_arlen_i(cpu_d_mem_arlen_w)
    ,.inport2_arburst_i(cpu_d_mem_arburst_w)
    ,.inport2_arsize_i(cpu_d_mem_arsize_w)
    ,.inport2_rready_i(cpu_d_mem_rready_w)
    ,.inport3_awvalid_i(dbg_axi_awvalid_w)
    ,.inport3_awaddr_i(dbg_axi_awaddr_w)
    ,.inport3_awid_i(dbg_axi_awid_w)
    ,.inport3_awlen_i(dbg_axi_awlen_w)
    ,.inport3_awburst_i(dbg_axi_awburst_w)
    ,.inport3_awsize_i(dbg_axi_awsize_w)
    ,.inport3_wvalid_i(dbg_axi_wvalid_w)
    ,.inport3_wdata_i(dbg_axi_wdata_w)
    ,.inport3_wstrb_i(dbg_axi_wstrb_w)
    ,.inport3_wlast_i(dbg_axi_wlast_w)
    ,.inport3_bready_i(dbg_axi_bready_w)
    ,.inport3_arvalid_i(dbg_axi_arvalid_w)
    ,.inport3_araddr_i(dbg_axi_araddr_w)
    ,.inport3_arid_i(dbg_axi_arid_w)
    ,.inport3_arlen_i(dbg_axi_arlen_w)
    ,.inport3_arburst_i(dbg_axi_arburst_w)
    ,.inport3_arsize_i(dbg_axi_arsize_w)
    ,.inport3_rready_i(dbg_axi_rready_w)
    ,.outport_awready_i(mem_arb_awready_w)
    ,.outport_wready_i(mem_arb_wready_w)
    ,.outport_bvalid_i(mem_arb_bvalid_w)
    ,.outport_bresp_i(mem_arb_bresp_w)
    ,.outport_bid_i(mem_arb_bid_w)
    ,.outport_arready_i(mem_arb_arready_w)
    ,.outport_rvalid_i(mem_arb_rvalid_w)
    ,.outport_rdata_i(mem_arb_rdata_w)
    ,.outport_rresp_i(mem_arb_rresp_w)
    ,.outport_rid_i(mem_arb_rid_w)
    ,.outport_rlast_i(mem_arb_rlast_w)

    // Outputs
    ,.inport0_awready_o(dma_mem_awready_w)
    ,.inport0_wready_o(dma_mem_wready_w)
    ,.inport0_bvalid_o(dma_mem_bvalid_w)
    ,.inport0_bresp_o(dma_mem_bresp_w)
    ,.inport0_bid_o(dma_mem_bid_w)
    ,.inport0_arready_o(dma_mem_arready_w)
    ,.inport0_rvalid_o(dma_mem_rvalid_w)
    ,.inport0_rdata_o(dma_mem_rdata_w)
    ,.inport0_rresp_o(dma_mem_rresp_w)
    ,.inport0_rid_o(dma_mem_rid_w)
    ,.inport0_rlast_o(dma_mem_rlast_w)
    ,.inport1_awready_o(cpu_i_awready_w)
    ,.inport1_wready_o(cpu_i_wready_w)
    ,.inport1_bvalid_o(cpu_i_bvalid_w)
    ,.inport1_bresp_o(cpu_i_bresp_w)
    ,.inport1_bid_o(cpu_i_bid_w)
    ,.inport1_arready_o(cpu_i_arready_w)
    ,.inport1_rvalid_o(cpu_i_rvalid_w)
    ,.inport1_rdata_o(cpu_i_rdata_w)
    ,.inport1_rresp_o(cpu_i_rresp_w)
    ,.inport1_rid_o(cpu_i_rid_w)
    ,.inport1_rlast_o(cpu_i_rlast_w)
    ,.inport2_awready_o(cpu_d_mem_awready_w)
    ,.inport2_wready_o(cpu_d_mem_wready_w)
    ,.inport2_bvalid_o(cpu_d_mem_bvalid_w)
    ,.inport2_bresp_o(cpu_d_mem_bresp_w)
    ,.inport2_bid_o(cpu_d_mem_bid_w)
    ,.inport2_arready_o(cpu_d_mem_arready_w)
    ,.inport2_rvalid_o(cpu_d_mem_rvalid_w)
    ,.inport2_rdata_o(cpu_d_mem_rdata_w)
    ,.inport2_rresp_o(cpu_d_mem_rresp_w)
    ,.inport2_rid_o(cpu_d_mem_rid_w)
    ,.inport2_rlast_o(cpu_d_mem_rlast_w)
    ,.inport3_awready_o(dbg_axi_awready_w)
    ,.inport3_wready_o(dbg_axi_wready_w)
    ,.inport3_bvalid_o(dbg_axi_bvalid_w)
    ,.inport3_bresp_o(dbg_axi_bresp_w)
    ,.inport3_bid_o(dbg_axi_bid_w)
    ,.inport3_arready_o(dbg_axi_arready_w)
    ,.inport3_rvalid_o(dbg_axi_rvalid_w)
    ,.inport3_rdata_o(dbg_axi_rdata_w)
    ,.inport3_rresp_o(dbg_axi_rresp_w)
    ,.inport3_rid_o(dbg_axi_rid_w)
    ,.inport3_rlast_o(dbg_axi_rlast_w)
    ,.outport_awvalid_o(mem_arb_awvalid_w)
    ,.outport_awaddr_o(mem_arb_awaddr_w)
    ,.outport_awid_o(mem_arb_awid_w)
    ,.outport_awlen_o(mem_arb_awlen_w)
    ,.outport_awburst_o(mem_arb_awburst_w)
    ,.outport_awsize_o(mem_arb_awsize_w)
    ,.outport_wvalid_o(mem_arb_wvalid_w)
    ,.outport_wdata_o(mem_arb_wdata_w)
    ,.outport_wstrb_o(mem_arb_wstrb_w)
    ,.outport_wlast_o(mem_arb_wlast_w)
    ,.outport_bready_o(mem_arb_bready_w)
    ,.outport_arvalid_o(mem_arb_arvalid_w)
    ,.outport_araddr_o(mem_arb_araddr_w)
    ,.outport_arid_o(mem_arb_arid_w)
    ,.outport_arlen_o(mem_arb_arlen_w)
    ,.outport_arburst_o(mem_arb_arburst_w)
    ,.outport_arsize_o(mem_arb_arsize_w)
    ,.outport_rready_o(mem_arb_rready_w)
);


spu
u_spu
(
    // Inputs
     .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.cfg_addr_i(wb_spu_addr_w)
    ,.cfg_data_wr_i(wb_spu_data_wr_w)
    ,.cfg_stb_i(wb_spu_stb_w)
    ,.cfg_cyc_i(wb_spu_cyc_w)
    ,.cfg_sel_i(wb_spu_sel_w)
    ,.cfg_we_i(wb_spu_we_w)
    ,.m2p_valid_i(spu_m2p_valid_w)
    ,.m2p_data_i(spu_m2p_data_w)
    ,.p2m_accept_i(spu_p2m_accept_w)

    // Outputs
    ,.cfg_data_rd_o(wb_spu_data_rd_w)
    ,.cfg_stall_o(wb_spu_stall_w)
    ,.cfg_ack_o(wb_spu_ack_w)
    ,.cfg_err_o(wb_spu_err_w)
    ,.irq_o(irq_spu_w)
    ,.m2p_dreq_o(spu_m2p_dreq_w)
    ,.m2p_accept_o(spu_m2p_accept_w)
    ,.p2m_dreq_o(spu_p2m_dreq_w)
    ,.p2m_valid_o(spu_p2m_valid_w)
    ,.p2m_data_o(spu_p2m_data_w)
);


axi4_upconv256
u_cdrom_conv
(
    // Inputs
     .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.inport_awvalid_i(cdrom_upconv_awvalid_w)
    ,.inport_awaddr_i(cdrom_upconv_awaddr_w)
    ,.inport_awid_i(cdrom_upconv_awid_w)
    ,.inport_awlen_i(cdrom_upconv_awlen_w)
    ,.inport_awburst_i(cdrom_upconv_awburst_w)
    ,.inport_awsize_i(cdrom_upconv_awsize_w)
    ,.inport_wvalid_i(cdrom_upconv_wvalid_w)
    ,.inport_wdata_i(cdrom_upconv_wdata_w)
    ,.inport_wstrb_i(cdrom_upconv_wstrb_w)
    ,.inport_wlast_i(cdrom_upconv_wlast_w)
    ,.inport_bready_i(cdrom_upconv_bready_w)
    ,.inport_arvalid_i(cdrom_upconv_arvalid_w)
    ,.inport_araddr_i(cdrom_upconv_araddr_w)
    ,.inport_arid_i(cdrom_upconv_arid_w)
    ,.inport_arlen_i(cdrom_upconv_arlen_w)
    ,.inport_arburst_i(cdrom_upconv_arburst_w)
    ,.inport_arsize_i(cdrom_upconv_arsize_w)
    ,.inport_rready_i(cdrom_upconv_rready_w)
    ,.outport_awready_i(axi_cdrom_awready_i)
    ,.outport_wready_i(axi_cdrom_wready_i)
    ,.outport_bvalid_i(axi_cdrom_bvalid_i)
    ,.outport_bresp_i(axi_cdrom_bresp_i)
    ,.outport_bid_i(axi_cdrom_bid_i)
    ,.outport_arready_i(axi_cdrom_arready_i)
    ,.outport_rvalid_i(axi_cdrom_rvalid_i)
    ,.outport_rdata_i(axi_cdrom_rdata_i)
    ,.outport_rresp_i(axi_cdrom_rresp_i)
    ,.outport_rid_i(axi_cdrom_rid_i)
    ,.outport_rlast_i(axi_cdrom_rlast_i)

    // Outputs
    ,.inport_awready_o(cdrom_upconv_awready_w)
    ,.inport_wready_o(cdrom_upconv_wready_w)
    ,.inport_bvalid_o(cdrom_upconv_bvalid_w)
    ,.inport_bresp_o(cdrom_upconv_bresp_w)
    ,.inport_bid_o(cdrom_upconv_bid_w)
    ,.inport_arready_o(cdrom_upconv_arready_w)
    ,.inport_rvalid_o(cdrom_upconv_rvalid_w)
    ,.inport_rdata_o(cdrom_upconv_rdata_w)
    ,.inport_rresp_o(cdrom_upconv_rresp_w)
    ,.inport_rid_o(cdrom_upconv_rid_w)
    ,.inport_rlast_o(cdrom_upconv_rlast_w)
    ,.outport_awvalid_o(axi_cdrom_awvalid_o)
    ,.outport_awaddr_o(axi_cdrom_awaddr_o)
    ,.outport_awid_o(axi_cdrom_awid_o)
    ,.outport_awlen_o(axi_cdrom_awlen_o)
    ,.outport_awburst_o(axi_cdrom_awburst_o)
    ,.outport_wvalid_o(axi_cdrom_wvalid_o)
    ,.outport_wdata_o(axi_cdrom_wdata_o)
    ,.outport_wstrb_o(axi_cdrom_wstrb_o)
    ,.outport_wlast_o(axi_cdrom_wlast_o)
    ,.outport_bready_o(axi_cdrom_bready_o)
    ,.outport_arvalid_o(axi_cdrom_arvalid_o)
    ,.outport_araddr_o(axi_cdrom_araddr_o)
    ,.outport_arid_o(axi_cdrom_arid_o)
    ,.outport_arlen_o(axi_cdrom_arlen_o)
    ,.outport_arburst_o(axi_cdrom_arburst_o)
    ,.outport_rready_o(axi_cdrom_rready_o)
);


dma
#(
     .AXI_ID(0)
)
u_dma
(
    // Inputs
     .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.cfg_addr_i(wb_dma_addr_w)
    ,.cfg_data_wr_i(wb_dma_data_wr_w)
    ,.cfg_stb_i(wb_dma_stb_w)
    ,.cfg_cyc_i(wb_dma_cyc_w)
    ,.cfg_sel_i(wb_dma_sel_w)
    ,.cfg_we_i(wb_dma_we_w)
    ,.mem_awready_i(dma_mem_awready_w)
    ,.mem_wready_i(dma_mem_wready_w)
    ,.mem_bvalid_i(dma_mem_bvalid_w)
    ,.mem_bresp_i(dma_mem_bresp_w)
    ,.mem_bid_i(dma_mem_bid_w)
    ,.mem_arready_i(dma_mem_arready_w)
    ,.mem_rvalid_i(dma_mem_rvalid_w)
    ,.mem_rdata_i(dma_mem_rdata_w)
    ,.mem_rresp_i(dma_mem_rresp_w)
    ,.mem_rid_i(dma_mem_rid_w)
    ,.mem_rlast_i(dma_mem_rlast_w)
    ,.mdec_p2m_dreq_i(mdec_p2m_dreq_w)
    ,.mdec_p2m_valid_i(mdec_p2m_valid_w)
    ,.mdec_p2m_data_i(mdec_p2m_data_w)
    ,.mdec_m2p_dreq_i(mdec_m2p_dreq_w)
    ,.mdec_m2p_accept_i(mdec_m2p_accept_w)
    ,.gpu_m2p_dreq_i(gpu_m2p_dreq_w)
    ,.gpu_m2p_accept_i(gpu_m2p_accept_w)
    ,.gpu_p2m_dreq_i(gpu_p2m_dreq_w)
    ,.gpu_p2m_valid_i(gpu_p2m_valid_w)
    ,.gpu_p2m_data_i(gpu_p2m_data_w)
    ,.cdrom_p2m_dreq_i(cdrom_p2m_dreq_w)
    ,.cdrom_p2m_valid_i(cdrom_p2m_valid_w)
    ,.cdrom_p2m_data_i(cdrom_p2m_data_w)
    ,.spu_m2p_dreq_i(spu_m2p_dreq_w)
    ,.spu_m2p_accept_i(spu_m2p_accept_w)
    ,.spu_p2m_dreq_i(spu_p2m_dreq_w)
    ,.spu_p2m_valid_i(spu_p2m_valid_w)
    ,.spu_p2m_data_i(spu_p2m_data_w)
    ,.pio_m2p_dreq_i(1'b0)
    ,.pio_m2p_accept_i(1'b0)
    ,.pio_p2m_dreq_i(1'b0)
    ,.pio_p2m_valid_i(1'b0)
    ,.pio_p2m_data_i(32'b0)

    // Outputs
    ,.cfg_data_rd_o(wb_dma_data_rd_w)
    ,.cfg_stall_o(wb_dma_stall_w)
    ,.cfg_ack_o(wb_dma_ack_w)
    ,.cfg_err_o(wb_dma_err_w)
    ,.irq_o(irq_dma_w)
    ,.cpu_inhibit_o(cpu_inhibit_w)
    ,.mem_awvalid_o(dma_mem_awvalid_w)
    ,.mem_awaddr_o(dma_mem_awaddr_w)
    ,.mem_awid_o(dma_mem_awid_w)
    ,.mem_awlen_o(dma_mem_awlen_w)
    ,.mem_awburst_o(dma_mem_awburst_w)
    ,.mem_awsize_o(dma_mem_awsize_w)
    ,.mem_wvalid_o(dma_mem_wvalid_w)
    ,.mem_wdata_o(dma_mem_wdata_w)
    ,.mem_wstrb_o(dma_mem_wstrb_w)
    ,.mem_wlast_o(dma_mem_wlast_w)
    ,.mem_bready_o(dma_mem_bready_w)
    ,.mem_arvalid_o(dma_mem_arvalid_w)
    ,.mem_araddr_o(dma_mem_araddr_w)
    ,.mem_arid_o(dma_mem_arid_w)
    ,.mem_arlen_o(dma_mem_arlen_w)
    ,.mem_arburst_o(dma_mem_arburst_w)
    ,.mem_arsize_o(dma_mem_arsize_w)
    ,.mem_rready_o(dma_mem_rready_w)
    ,.mdec_p2m_accept_o(mdec_p2m_accept_w)
    ,.mdec_m2p_valid_o(mdec_m2p_valid_w)
    ,.mdec_m2p_data_o(mdec_m2p_data_w)
    ,.gpu_m2p_valid_o(gpu_m2p_valid_w)
    ,.gpu_m2p_data_o(gpu_m2p_data_w)
    ,.gpu_p2m_accept_o(gpu_p2m_accept_w)
    ,.cdrom_p2m_accept_o(cdrom_p2m_accept_w)
    ,.cdrom_p2m_dma_en_o(cdrom_p2m_dma_en_w)
    ,.cdrom_p2m_dma_bs_o(cdrom_p2m_dma_bs_w)
    ,.spu_m2p_valid_o(spu_m2p_valid_w)
    ,.spu_m2p_data_o(spu_m2p_data_w)
    ,.spu_p2m_accept_o(spu_p2m_accept_w)
    ,.pio_m2p_valid_o()
    ,.pio_m2p_data_o()
    ,.pio_p2m_accept_o()
);


dbg_bridge
#(
     .CLK_FREQ(CLK_FREQ)
    ,.GPIO_ADDRESS('hf0000000)
    ,.AXI_ID(12)
    ,.STS_ADDRESS('hf0000004)
    ,.UART_SPEED(UART_SPEED)
)
u_dbg
(
    // Inputs
     .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.uart_rxd_i(dbg_txd_i)
    ,.mem_awready_i(dbg_axi_awready_w)
    ,.mem_wready_i(dbg_axi_wready_w)
    ,.mem_bvalid_i(dbg_axi_bvalid_w)
    ,.mem_bresp_i(dbg_axi_bresp_w)
    ,.mem_bid_i(dbg_axi_bid_w)
    ,.mem_arready_i(dbg_axi_arready_w)
    ,.mem_rvalid_i(dbg_axi_rvalid_w)
    ,.mem_rdata_i(dbg_axi_rdata_w)
    ,.mem_rresp_i(dbg_axi_rresp_w)
    ,.mem_rid_i(dbg_axi_rid_w)
    ,.mem_rlast_i(dbg_axi_rlast_w)
    ,.gpio_inputs_i(debug_monitor_w)

    // Outputs
    ,.uart_txd_o(dbg_rxd_o)
    ,.mem_awvalid_o(dbg_axi_awvalid_w)
    ,.mem_awaddr_o(dbg_axi_awaddr_w)
    ,.mem_awid_o(dbg_axi_awid_w)
    ,.mem_awlen_o(dbg_axi_awlen_w)
    ,.mem_awburst_o(dbg_axi_awburst_w)
    ,.mem_awsize_o(dbg_axi_awsize_w)
    ,.mem_wvalid_o(dbg_axi_wvalid_w)
    ,.mem_wdata_o(dbg_axi_wdata_w)
    ,.mem_wstrb_o(dbg_axi_wstrb_w)
    ,.mem_wlast_o(dbg_axi_wlast_w)
    ,.mem_bready_o(dbg_axi_bready_w)
    ,.mem_arvalid_o(dbg_axi_arvalid_w)
    ,.mem_araddr_o(dbg_axi_araddr_w)
    ,.mem_arid_o(dbg_axi_arid_w)
    ,.mem_arlen_o(dbg_axi_arlen_w)
    ,.mem_arburst_o(dbg_axi_arburst_w)
    ,.mem_arsize_o(dbg_axi_arsize_w)
    ,.mem_rready_o(dbg_axi_rready_w)
    ,.gpio_outputs_o(enable_w)
);


cdrom
#(
     .CLK_FREQ(CLK_FREQ)
    ,.BAUDRATE(BAUDRATE)
    ,.C_SCK_RATIO(5)
)
u_cdrom
(
    // Inputs
     .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.rx_i(1'b0)
    ,.cfg_addr_i(wb_cdrom_addr_w)
    ,.cfg_data_wr_i(wb_cdrom_data_wr_w)
    ,.cfg_stb_i(wb_cdrom_stb_w)
    ,.cfg_cyc_i(wb_cdrom_cyc_w)
    ,.cfg_sel_i(wb_cdrom_sel_w)
    ,.cfg_we_i(wb_cdrom_we_w)
    ,.cdrom_p2m_accept_i(cdrom_p2m_accept_w)
    ,.cdrom_p2m_dma_en_i(cdrom_p2m_dma_en_w)
    ,.cdrom_p2m_dma_bs_i(cdrom_p2m_dma_bs_w)
    ,.gpio_in_i(gpio_in_i)
    ,.ext_cfg_data_rd_i(cdrom_ext_cfg_data_rd_i)
    ,.ext_cfg_ack_i(cdrom_ext_cfg_ack_i)
    ,.ext_cfg_stall_i(cdrom_ext_cfg_stall_i)
    ,.ext_irq_i(cdrom_ext_irq_i)
    ,.axi_i_awready_i(cdrom_upconv_awready_w)
    ,.axi_i_wready_i(cdrom_upconv_wready_w)
    ,.axi_i_bvalid_i(cdrom_upconv_bvalid_w)
    ,.axi_i_bresp_i(cdrom_upconv_bresp_w)
    ,.axi_i_bid_i(cdrom_upconv_bid_w)
    ,.axi_i_arready_i(cdrom_upconv_arready_w)
    ,.axi_i_rvalid_i(cdrom_upconv_rvalid_w)
    ,.axi_i_rdata_i(cdrom_upconv_rdata_w)
    ,.axi_i_rresp_i(cdrom_upconv_rresp_w)
    ,.axi_i_rid_i(cdrom_upconv_rid_w)
    ,.axi_i_rlast_i(cdrom_upconv_rlast_w)

    // Outputs
    ,.tx_o(cdrom_tx_o)
    ,.cfg_data_rd_o(wb_cdrom_data_rd_w)
    ,.cfg_stall_o(wb_cdrom_stall_w)
    ,.cfg_ack_o(wb_cdrom_ack_w)
    ,.cfg_err_o(wb_cdrom_err_w)
    ,.irq_o(irq_cdrom_w)
    ,.cdrom_p2m_dreq_o(cdrom_p2m_dreq_w)
    ,.cdrom_p2m_valid_o(cdrom_p2m_valid_w)
    ,.cdrom_p2m_data_o(cdrom_p2m_data_w)
    ,.gpio_out_o(gpio_out_o)
    ,.ext_cfg_addr_o(cdrom_ext_cfg_addr_o)
    ,.ext_cfg_data_wr_o(cdrom_ext_cfg_data_wr_o)
    ,.ext_cfg_stb_o(cdrom_ext_cfg_stb_o)
    ,.ext_cfg_we_o(cdrom_ext_cfg_we_o)
    ,.axi_i_awvalid_o(cdrom_upconv_awvalid_w)
    ,.axi_i_awaddr_o(cdrom_upconv_awaddr_w)
    ,.axi_i_awid_o(cdrom_upconv_awid_w)
    ,.axi_i_awlen_o(cdrom_upconv_awlen_w)
    ,.axi_i_awburst_o(cdrom_upconv_awburst_w)
    ,.axi_i_awsize_o(cdrom_upconv_awsize_w)
    ,.axi_i_wvalid_o(cdrom_upconv_wvalid_w)
    ,.axi_i_wdata_o(cdrom_upconv_wdata_w)
    ,.axi_i_wstrb_o(cdrom_upconv_wstrb_w)
    ,.axi_i_wlast_o(cdrom_upconv_wlast_w)
    ,.axi_i_bready_o(cdrom_upconv_bready_w)
    ,.axi_i_arvalid_o(cdrom_upconv_arvalid_w)
    ,.axi_i_araddr_o(cdrom_upconv_araddr_w)
    ,.axi_i_arid_o(cdrom_upconv_arid_w)
    ,.axi_i_arlen_o(cdrom_upconv_arlen_w)
    ,.axi_i_arburst_o(cdrom_upconv_arburst_w)
    ,.axi_i_arsize_o(cdrom_upconv_arsize_w)
    ,.axi_i_rready_o(cdrom_upconv_rready_w)
);


timer_module
u_timers
(
    // Inputs
     .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.cfg_addr_i(wb_timers_addr_w)
    ,.cfg_data_wr_i(wb_timers_data_wr_w)
    ,.cfg_stb_i(wb_timers_stb_w)
    ,.cfg_we_i(wb_timers_we_w)
    ,.dotclk_i(display_dotclk_i)
    ,.hblank_i(timer_hblank_w)
    ,.vblank_i(timer_vblank_w)
    ,.mode_pal_i(timer_pal_w)

    // Outputs
    ,.cfg_data_rd_o(wb_timers_data_rd_w)
    ,.cfg_ack_o(wb_timers_ack_w)
    ,.cfg_stall_o(wb_timers_stall_w)
    ,.irq_timer0_o(irq_timer0_w)
    ,.irq_timer1_o(irq_timer1_w)
    ,.irq_timer2_o(irq_timer2_w)
);


debug_mux
u_debug_mux
(
    // Inputs
     .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.debug_cpu_i(debug_cpu_w)
    ,.config_i(debug_config_w)

    // Outputs
    ,.debug_cpu_src_o(debug_cpu_src_w)
    ,.monitor_o(debug_monitor_w)
);


iomux
u_iomux
(
    // Inputs
     .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.inport_addr_i(cpu_d_io_addr_w)
    ,.inport_data_wr_i(cpu_d_io_data_wr_w)
    ,.inport_stb_i(cpu_d_io_stb_w)
    ,.inport_cyc_i(cpu_d_io_cyc_w)
    ,.inport_sel_i(cpu_d_io_sel_w)
    ,.inport_we_i(cpu_d_io_we_w)
    ,.outport_joy_data_rd_i(wb_joy_data_rd_w)
    ,.outport_joy_stall_i(wb_joy_stall_w)
    ,.outport_joy_ack_i(wb_joy_ack_w)
    ,.outport_joy_err_i(wb_joy_err_w)
    ,.outport_sio_data_rd_i(wb_sio_data_rd_w)
    ,.outport_sio_stall_i(wb_sio_stall_w)
    ,.outport_sio_ack_i(wb_sio_ack_w)
    ,.outport_sio_err_i(wb_sio_err_w)
    ,.outport_dma_data_rd_i(wb_dma_data_rd_w)
    ,.outport_dma_stall_i(wb_dma_stall_w)
    ,.outport_dma_ack_i(wb_dma_ack_w)
    ,.outport_dma_err_i(wb_dma_err_w)
    ,.outport_irqctrl_data_rd_i(wb_irqctrl_data_rd_w)
    ,.outport_irqctrl_stall_i(wb_irqctrl_stall_w)
    ,.outport_irqctrl_ack_i(wb_irqctrl_ack_w)
    ,.outport_irqctrl_err_i(wb_irqctrl_err_w)
    ,.outport_timers_data_rd_i(wb_timers_data_rd_w)
    ,.outport_timers_ack_i(wb_timers_ack_w)
    ,.outport_timers_stall_i(wb_timers_stall_w)
    ,.outport_spu_data_rd_i(wb_spu_data_rd_w)
    ,.outport_spu_stall_i(wb_spu_stall_w)
    ,.outport_spu_ack_i(wb_spu_ack_w)
    ,.outport_spu_err_i(wb_spu_err_w)
    ,.outport_cdrom_data_rd_i(wb_cdrom_data_rd_w)
    ,.outport_cdrom_stall_i(wb_cdrom_stall_w)
    ,.outport_cdrom_ack_i(wb_cdrom_ack_w)
    ,.outport_cdrom_err_i(wb_cdrom_err_w)
    ,.outport_gpu_data_rd_i(wb_gpu_data_rd_w)
    ,.outport_gpu_ack_i(wb_gpu_ack_w)
    ,.outport_gpu_stall_i(wb_gpu_stall_w)
    ,.outport_mdec_data_rd_i(wb_mdec_data_rd_w)
    ,.outport_mdec_ack_i(wb_mdec_ack_w)
    ,.outport_mdec_stall_i(wb_mdec_stall_w)
    ,.outport_atcons_data_rd_i(wb_atcons_data_rd_w)
    ,.outport_atcons_ack_i(wb_atcons_ack_w)
    ,.outport_atcons_stall_i(wb_atcons_stall_w)
    ,.outport_uart_data_rd_i(wb_uart_data_rd_w)
    ,.outport_uart_ack_i(wb_uart_ack_w)
    ,.outport_uart_stall_i(wb_uart_stall_w)

    // Outputs
    ,.inport_data_rd_o(cpu_d_io_data_rd_w)
    ,.inport_stall_o(cpu_d_io_stall_w)
    ,.inport_ack_o(cpu_d_io_ack_w)
    ,.inport_err_o(cpu_d_io_err_w)
    ,.outport_joy_addr_o(wb_joy_addr_w)
    ,.outport_joy_data_wr_o(wb_joy_data_wr_w)
    ,.outport_joy_stb_o(wb_joy_stb_w)
    ,.outport_joy_cyc_o(wb_joy_cyc_w)
    ,.outport_joy_sel_o(wb_joy_sel_w)
    ,.outport_joy_we_o(wb_joy_we_w)
    ,.outport_sio_addr_o(wb_sio_addr_w)
    ,.outport_sio_data_wr_o(wb_sio_data_wr_w)
    ,.outport_sio_stb_o(wb_sio_stb_w)
    ,.outport_sio_cyc_o(wb_sio_cyc_w)
    ,.outport_sio_sel_o(wb_sio_sel_w)
    ,.outport_sio_we_o(wb_sio_we_w)
    ,.outport_dma_addr_o(wb_dma_addr_w)
    ,.outport_dma_data_wr_o(wb_dma_data_wr_w)
    ,.outport_dma_stb_o(wb_dma_stb_w)
    ,.outport_dma_cyc_o(wb_dma_cyc_w)
    ,.outport_dma_sel_o(wb_dma_sel_w)
    ,.outport_dma_we_o(wb_dma_we_w)
    ,.outport_irqctrl_addr_o(wb_irqctrl_addr_w)
    ,.outport_irqctrl_data_wr_o(wb_irqctrl_data_wr_w)
    ,.outport_irqctrl_stb_o(wb_irqctrl_stb_w)
    ,.outport_irqctrl_cyc_o(wb_irqctrl_cyc_w)
    ,.outport_irqctrl_sel_o(wb_irqctrl_sel_w)
    ,.outport_irqctrl_we_o(wb_irqctrl_we_w)
    ,.outport_timers_addr_o(wb_timers_addr_w)
    ,.outport_timers_data_wr_o(wb_timers_data_wr_w)
    ,.outport_timers_stb_o(wb_timers_stb_w)
    ,.outport_timers_we_o(wb_timers_we_w)
    ,.outport_spu_addr_o(wb_spu_addr_w)
    ,.outport_spu_data_wr_o(wb_spu_data_wr_w)
    ,.outport_spu_stb_o(wb_spu_stb_w)
    ,.outport_spu_cyc_o(wb_spu_cyc_w)
    ,.outport_spu_sel_o(wb_spu_sel_w)
    ,.outport_spu_we_o(wb_spu_we_w)
    ,.outport_cdrom_addr_o(wb_cdrom_addr_w)
    ,.outport_cdrom_data_wr_o(wb_cdrom_data_wr_w)
    ,.outport_cdrom_stb_o(wb_cdrom_stb_w)
    ,.outport_cdrom_cyc_o(wb_cdrom_cyc_w)
    ,.outport_cdrom_sel_o(wb_cdrom_sel_w)
    ,.outport_cdrom_we_o(wb_cdrom_we_w)
    ,.outport_gpu_addr_o(wb_gpu_addr_w)
    ,.outport_gpu_data_wr_o(wb_gpu_data_wr_w)
    ,.outport_gpu_stb_o(wb_gpu_stb_w)
    ,.outport_gpu_we_o(wb_gpu_we_w)
    ,.outport_mdec_addr_o(wb_mdec_addr_w)
    ,.outport_mdec_data_wr_o(wb_mdec_data_wr_w)
    ,.outport_mdec_stb_o(wb_mdec_stb_w)
    ,.outport_mdec_we_o(wb_mdec_we_w)
    ,.outport_atcons_addr_o(wb_atcons_addr_w)
    ,.outport_atcons_data_wr_o(wb_atcons_data_wr_w)
    ,.outport_atcons_stb_o(wb_atcons_stb_w)
    ,.outport_atcons_we_o(wb_atcons_we_w)
    ,.outport_uart_addr_o(wb_uart_addr_w)
    ,.outport_uart_data_wr_o(wb_uart_data_wr_w)
    ,.outport_uart_stb_o(wb_uart_stb_w)
    ,.outport_uart_we_o(wb_uart_we_w)
);


ctrl_mc_io
u_joy
(
    // Inputs
     .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.cfg_addr_i(wb_joy_addr_w)
    ,.cfg_data_wr_i(wb_joy_data_wr_w)
    ,.cfg_stb_i(wb_joy_stb_w)
    ,.cfg_cyc_i(wb_joy_cyc_w)
    ,.cfg_sel_i(wb_joy_sel_w)
    ,.cfg_we_i(wb_joy_we_w)
    ,.joy1_dat_i(joy1_dat_i)
    ,.joy1_ack_i(joy1_ack_i)
    ,.joy2_dat_i(joy2_dat_i)
    ,.joy2_ack_i(joy2_ack_i)

    // Outputs
    ,.cfg_data_rd_o(wb_joy_data_rd_w)
    ,.cfg_stall_o(wb_joy_stall_w)
    ,.cfg_ack_o(wb_joy_ack_w)
    ,.cfg_err_o(wb_joy_err_w)
    ,.irq_o(irq_joy_w)
    ,.event_magic_o(event_magic_w)
    ,.event_debug_o(event_debug_w)
    ,.joy1_sel_o(joy1_sel_o)
    ,.joy1_clk_o(joy1_clk_o)
    ,.joy1_cmd_o(joy1_cmd_o)
    ,.joy2_sel_o(joy2_sel_o)
    ,.joy2_clk_o(joy2_clk_o)
    ,.joy2_cmd_o(joy2_cmd_o)
);


uart_scons
#(
     .CLK_FREQ(CLK_FREQ)
    ,.BAUDRATE(BAUDRATE)
)
u_atcons
(
    // Inputs
     .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.cfg_addr_i(wb_atcons_addr_w)
    ,.cfg_data_wr_i(wb_atcons_data_wr_w)
    ,.cfg_stb_i(wb_atcons_stb_w)
    ,.cfg_we_i(wb_atcons_we_w)
    ,.rx_i(1'b0)

    // Outputs
    ,.cfg_data_rd_o(wb_atcons_data_rd_w)
    ,.cfg_ack_o(wb_atcons_ack_w)
    ,.cfg_stall_o(wb_atcons_stall_w)
    ,.tx_o()
    ,.intr_o()
);


l2_cache
#(
     .AXI_ID(0)
)
u_l2_cache
(
    // Inputs
     .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.dbg_mode_i(rst_cpu_w)
    ,.inport_awvalid_i(remap_axi_awvalid_w)
    ,.inport_awaddr_i(remap_axi_awaddr_w)
    ,.inport_awid_i(remap_axi_awid_w)
    ,.inport_awlen_i(remap_axi_awlen_w)
    ,.inport_awburst_i(remap_axi_awburst_w)
    ,.inport_awsize_i(remap_axi_awsize_w)
    ,.inport_wvalid_i(remap_axi_wvalid_w)
    ,.inport_wdata_i(remap_axi_wdata_w)
    ,.inport_wstrb_i(remap_axi_wstrb_w)
    ,.inport_wlast_i(remap_axi_wlast_w)
    ,.inport_bready_i(remap_axi_bready_w)
    ,.inport_arvalid_i(remap_axi_arvalid_w)
    ,.inport_araddr_i(remap_axi_araddr_w)
    ,.inport_arid_i(remap_axi_arid_w)
    ,.inport_arlen_i(remap_axi_arlen_w)
    ,.inport_arburst_i(remap_axi_arburst_w)
    ,.inport_arsize_i(remap_axi_arsize_w)
    ,.inport_rready_i(remap_axi_rready_w)
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
    ,.inport_awready_o(remap_axi_awready_w)
    ,.inport_wready_o(remap_axi_wready_w)
    ,.inport_bvalid_o(remap_axi_bvalid_w)
    ,.inport_bresp_o(remap_axi_bresp_w)
    ,.inport_bid_o(remap_axi_bid_w)
    ,.inport_arready_o(remap_axi_arready_w)
    ,.inport_rvalid_o(remap_axi_rvalid_w)
    ,.inport_rdata_o(remap_axi_rdata_w)
    ,.inport_rresp_o(remap_axi_rresp_w)
    ,.inport_rid_o(remap_axi_rid_w)
    ,.inport_rlast_o(remap_axi_rlast_w)
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


irq_module
u_irqctrl
(
    // Inputs
     .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.cfg_addr_i(wb_irqctrl_addr_w)
    ,.cfg_data_wr_i(wb_irqctrl_data_wr_w)
    ,.cfg_stb_i(wb_irqctrl_stb_w)
    ,.cfg_cyc_i(wb_irqctrl_cyc_w)
    ,.cfg_sel_i(wb_irqctrl_sel_w)
    ,.cfg_we_i(wb_irqctrl_we_w)
    ,.irq0_gpu_vbl_i(irq_vblank_w)
    ,.irq1_gpu_cmd_i(irq_gpu_w)
    ,.irq2_cdrom_i(irq_cdrom_w)
    ,.irq3_dma_i(irq_dma_w)
    ,.irq4_timer0_i(irq_timer0_w)
    ,.irq5_timer1_i(irq_timer1_w)
    ,.irq6_timer2_i(irq_timer2_w)
    ,.irq7_memcard_i(irq_joy_w)
    ,.irq8_sio_i(irq_sio_w)
    ,.irq9_spu_i(irq_spu_w)
    ,.irq10_lightpen_i(1'b0)

    // Outputs
    ,.cfg_data_rd_o(wb_irqctrl_data_rd_w)
    ,.cfg_stall_o(wb_irqctrl_stall_w)
    ,.cfg_ack_o(wb_irqctrl_ack_w)
    ,.cfg_err_o(wb_irqctrl_err_w)
    ,.intr_o(cpu_intr_w)
);


mem_remap
u_mem_remap
(
    // Inputs
     .inport_awvalid_i(mem_arb_awvalid_w)
    ,.inport_awaddr_i(mem_arb_awaddr_w)
    ,.inport_awid_i(mem_arb_awid_w)
    ,.inport_awlen_i(mem_arb_awlen_w)
    ,.inport_awburst_i(mem_arb_awburst_w)
    ,.inport_awsize_i(mem_arb_awsize_w)
    ,.inport_wvalid_i(mem_arb_wvalid_w)
    ,.inport_wdata_i(mem_arb_wdata_w)
    ,.inport_wstrb_i(mem_arb_wstrb_w)
    ,.inport_wlast_i(mem_arb_wlast_w)
    ,.inport_bready_i(mem_arb_bready_w)
    ,.inport_arvalid_i(mem_arb_arvalid_w)
    ,.inport_araddr_i(mem_arb_araddr_w)
    ,.inport_arid_i(mem_arb_arid_w)
    ,.inport_arlen_i(mem_arb_arlen_w)
    ,.inport_arburst_i(mem_arb_arburst_w)
    ,.inport_arsize_i(mem_arb_arsize_w)
    ,.inport_rready_i(mem_arb_rready_w)
    ,.outport_awready_i(remap_axi_awready_w)
    ,.outport_wready_i(remap_axi_wready_w)
    ,.outport_bvalid_i(remap_axi_bvalid_w)
    ,.outport_bresp_i(remap_axi_bresp_w)
    ,.outport_bid_i(remap_axi_bid_w)
    ,.outport_arready_i(remap_axi_arready_w)
    ,.outport_rvalid_i(remap_axi_rvalid_w)
    ,.outport_rdata_i(remap_axi_rdata_w)
    ,.outport_rresp_i(remap_axi_rresp_w)
    ,.outport_rid_i(remap_axi_rid_w)
    ,.outport_rlast_i(remap_axi_rlast_w)

    // Outputs
    ,.inport_awready_o(mem_arb_awready_w)
    ,.inport_wready_o(mem_arb_wready_w)
    ,.inport_bvalid_o(mem_arb_bvalid_w)
    ,.inport_bresp_o(mem_arb_bresp_w)
    ,.inport_bid_o(mem_arb_bid_w)
    ,.inport_arready_o(mem_arb_arready_w)
    ,.inport_rvalid_o(mem_arb_rvalid_w)
    ,.inport_rdata_o(mem_arb_rdata_w)
    ,.inport_rresp_o(mem_arb_rresp_w)
    ,.inport_rid_o(mem_arb_rid_w)
    ,.inport_rlast_o(mem_arb_rlast_w)
    ,.outport_awvalid_o(remap_axi_awvalid_w)
    ,.outport_awaddr_o(remap_axi_awaddr_w)
    ,.outport_awid_o(remap_axi_awid_w)
    ,.outport_awlen_o(remap_axi_awlen_w)
    ,.outport_awburst_o(remap_axi_awburst_w)
    ,.outport_awsize_o(remap_axi_awsize_w)
    ,.outport_wvalid_o(remap_axi_wvalid_w)
    ,.outport_wdata_o(remap_axi_wdata_w)
    ,.outport_wstrb_o(remap_axi_wstrb_w)
    ,.outport_wlast_o(remap_axi_wlast_w)
    ,.outport_bready_o(remap_axi_bready_w)
    ,.outport_arvalid_o(remap_axi_arvalid_w)
    ,.outport_araddr_o(remap_axi_araddr_w)
    ,.outport_arid_o(remap_axi_arid_w)
    ,.outport_arlen_o(remap_axi_arlen_w)
    ,.outport_arburst_o(remap_axi_arburst_w)
    ,.outport_arsize_o(remap_axi_arsize_w)
    ,.outport_rready_o(remap_axi_rready_w)
);


uart_boot
#(
     .CLK_FREQ(CLK_FREQ)
    ,.BAUDRATE(BAUDRATE)
)
u_uart_boot
(
    // Inputs
     .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.cfg_addr_i(wb_uart_addr_w)
    ,.cfg_data_wr_i(wb_uart_data_wr_w)
    ,.cfg_stb_i(wb_uart_stb_w)
    ,.cfg_we_i(wb_uart_we_w)
    ,.rx_i(uart_rx_i)

    // Outputs
    ,.cfg_data_rd_o(wb_uart_data_rd_w)
    ,.cfg_ack_o(wb_uart_ack_w)
    ,.cfg_stall_o(wb_uart_stall_w)
    ,.tx_o(uart_tx_o)
);


axi4_wb_tap
#(
     .WB_PORT_MASK('h1ffff000)
    ,.WB_PORT_ADDR0('h1f801000)
    ,.WB_PORT_ADDR1('h1f802000)
)
u_io_tap
(
    // Inputs
     .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.inhibit_i(cpu_inhibit_w)
    ,.inport_awvalid_i(cpu_d_awvalid_w)
    ,.inport_awaddr_i(cpu_d_awaddr_w)
    ,.inport_awid_i(cpu_d_awid_w)
    ,.inport_awlen_i(cpu_d_awlen_w)
    ,.inport_awburst_i(cpu_d_awburst_w)
    ,.inport_awsize_i(cpu_d_awsize_w)
    ,.inport_wvalid_i(cpu_d_wvalid_w)
    ,.inport_wdata_i(cpu_d_wdata_w)
    ,.inport_wstrb_i(cpu_d_wstrb_w)
    ,.inport_wlast_i(cpu_d_wlast_w)
    ,.inport_bready_i(cpu_d_bready_w)
    ,.inport_arvalid_i(cpu_d_arvalid_w)
    ,.inport_araddr_i(cpu_d_araddr_w)
    ,.inport_arid_i(cpu_d_arid_w)
    ,.inport_arlen_i(cpu_d_arlen_w)
    ,.inport_arburst_i(cpu_d_arburst_w)
    ,.inport_arsize_i(cpu_d_arsize_w)
    ,.inport_rready_i(cpu_d_rready_w)
    ,.outport_awready_i(cpu_d_mem_awready_w)
    ,.outport_wready_i(cpu_d_mem_wready_w)
    ,.outport_bvalid_i(cpu_d_mem_bvalid_w)
    ,.outport_bresp_i(cpu_d_mem_bresp_w)
    ,.outport_bid_i(cpu_d_mem_bid_w)
    ,.outport_arready_i(cpu_d_mem_arready_w)
    ,.outport_rvalid_i(cpu_d_mem_rvalid_w)
    ,.outport_rdata_i(cpu_d_mem_rdata_w)
    ,.outport_rresp_i(cpu_d_mem_rresp_w)
    ,.outport_rid_i(cpu_d_mem_rid_w)
    ,.outport_rlast_i(cpu_d_mem_rlast_w)
    ,.outport_wb_data_rd_i(cpu_d_io_data_rd_w)
    ,.outport_wb_stall_i(cpu_d_io_stall_w)
    ,.outport_wb_ack_i(cpu_d_io_ack_w)
    ,.outport_wb_err_i(cpu_d_io_err_w)

    // Outputs
    ,.inport_awready_o(cpu_d_awready_w)
    ,.inport_wready_o(cpu_d_wready_w)
    ,.inport_bvalid_o(cpu_d_bvalid_w)
    ,.inport_bresp_o(cpu_d_bresp_w)
    ,.inport_bid_o(cpu_d_bid_w)
    ,.inport_arready_o(cpu_d_arready_w)
    ,.inport_rvalid_o(cpu_d_rvalid_w)
    ,.inport_rdata_o(cpu_d_rdata_w)
    ,.inport_rresp_o(cpu_d_rresp_w)
    ,.inport_rid_o(cpu_d_rid_w)
    ,.inport_rlast_o(cpu_d_rlast_w)
    ,.outport_awvalid_o(cpu_d_mem_awvalid_w)
    ,.outport_awaddr_o(cpu_d_mem_awaddr_w)
    ,.outport_awid_o(cpu_d_mem_awid_w)
    ,.outport_awlen_o(cpu_d_mem_awlen_w)
    ,.outport_awburst_o(cpu_d_mem_awburst_w)
    ,.outport_awsize_o(cpu_d_mem_awsize_w)
    ,.outport_wvalid_o(cpu_d_mem_wvalid_w)
    ,.outport_wdata_o(cpu_d_mem_wdata_w)
    ,.outport_wstrb_o(cpu_d_mem_wstrb_w)
    ,.outport_wlast_o(cpu_d_mem_wlast_w)
    ,.outport_bready_o(cpu_d_mem_bready_w)
    ,.outport_arvalid_o(cpu_d_mem_arvalid_w)
    ,.outport_araddr_o(cpu_d_mem_araddr_w)
    ,.outport_arid_o(cpu_d_mem_arid_w)
    ,.outport_arlen_o(cpu_d_mem_arlen_w)
    ,.outport_arburst_o(cpu_d_mem_arburst_w)
    ,.outport_arsize_o(cpu_d_mem_arsize_w)
    ,.outport_rready_o(cpu_d_mem_rready_w)
    ,.outport_wb_addr_o(cpu_d_io_addr_w)
    ,.outport_wb_data_wr_o(cpu_d_io_data_wr_w)
    ,.outport_wb_stb_o(cpu_d_io_stb_w)
    ,.outport_wb_cyc_o(cpu_d_io_cyc_w)
    ,.outport_wb_sel_o(cpu_d_io_sel_w)
    ,.outport_wb_we_o(cpu_d_io_we_w)
);


psf_cpu_top
u_cpu
(
    // Inputs
     .clk_i(clk_i)
    ,.rst_i(rst_cpu_w)
    ,.mem_d_awready_i(cpu_d_awready_w)
    ,.mem_d_wready_i(cpu_d_wready_w)
    ,.mem_d_bvalid_i(cpu_d_bvalid_w)
    ,.mem_d_bresp_i(cpu_d_bresp_w)
    ,.mem_d_bid_i(cpu_d_bid_w)
    ,.mem_d_arready_i(cpu_d_arready_w)
    ,.mem_d_rvalid_i(cpu_d_rvalid_w)
    ,.mem_d_rdata_i(cpu_d_rdata_w)
    ,.mem_d_rresp_i(cpu_d_rresp_w)
    ,.mem_d_rid_i(cpu_d_rid_w)
    ,.mem_d_rlast_i(cpu_d_rlast_w)
    ,.mem_i_awready_i(cpu_i_awready_w)
    ,.mem_i_wready_i(cpu_i_wready_w)
    ,.mem_i_bvalid_i(cpu_i_bvalid_w)
    ,.mem_i_bresp_i(cpu_i_bresp_w)
    ,.mem_i_bid_i(cpu_i_bid_w)
    ,.mem_i_arready_i(cpu_i_arready_w)
    ,.mem_i_rvalid_i(cpu_i_rvalid_w)
    ,.mem_i_rdata_i(cpu_i_rdata_w)
    ,.mem_i_rresp_i(cpu_i_rresp_w)
    ,.mem_i_rid_i(cpu_i_rid_w)
    ,.mem_i_rlast_i(cpu_i_rlast_w)
    ,.intr_i(cpu_intr_w)
    ,.nmi_i(cpu_nmi_w)
    ,.debug_src_i(debug_cpu_src_w)

    // Outputs
    ,.mem_d_awvalid_o(cpu_d_awvalid_w)
    ,.mem_d_awaddr_o(cpu_d_awaddr_w)
    ,.mem_d_awid_o(cpu_d_awid_w)
    ,.mem_d_awlen_o(cpu_d_awlen_w)
    ,.mem_d_awburst_o(cpu_d_awburst_w)
    ,.mem_d_awsize_o(cpu_d_awsize_w)
    ,.mem_d_wvalid_o(cpu_d_wvalid_w)
    ,.mem_d_wdata_o(cpu_d_wdata_w)
    ,.mem_d_wstrb_o(cpu_d_wstrb_w)
    ,.mem_d_wlast_o(cpu_d_wlast_w)
    ,.mem_d_bready_o(cpu_d_bready_w)
    ,.mem_d_arvalid_o(cpu_d_arvalid_w)
    ,.mem_d_araddr_o(cpu_d_araddr_w)
    ,.mem_d_arid_o(cpu_d_arid_w)
    ,.mem_d_arlen_o(cpu_d_arlen_w)
    ,.mem_d_arburst_o(cpu_d_arburst_w)
    ,.mem_d_arsize_o(cpu_d_arsize_w)
    ,.mem_d_rready_o(cpu_d_rready_w)
    ,.mem_i_awvalid_o(cpu_i_awvalid_w)
    ,.mem_i_awaddr_o(cpu_i_awaddr_w)
    ,.mem_i_awid_o(cpu_i_awid_w)
    ,.mem_i_awlen_o(cpu_i_awlen_w)
    ,.mem_i_awburst_o(cpu_i_awburst_w)
    ,.mem_i_awsize_o(cpu_i_awsize_w)
    ,.mem_i_wvalid_o(cpu_i_wvalid_w)
    ,.mem_i_wdata_o(cpu_i_wdata_w)
    ,.mem_i_wstrb_o(cpu_i_wstrb_w)
    ,.mem_i_wlast_o(cpu_i_wlast_w)
    ,.mem_i_bready_o(cpu_i_bready_w)
    ,.mem_i_arvalid_o(cpu_i_arvalid_w)
    ,.mem_i_araddr_o(cpu_i_araddr_w)
    ,.mem_i_arid_o(cpu_i_arid_w)
    ,.mem_i_arlen_o(cpu_i_arlen_w)
    ,.mem_i_arburst_o(cpu_i_arburst_w)
    ,.mem_i_arsize_o(cpu_i_arsize_w)
    ,.mem_i_rready_o(cpu_i_rready_w)
    ,.debug_o(debug_cpu_w)
);


sio
u_sio
(
    // Inputs
     .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.cfg_addr_i(wb_sio_addr_w)
    ,.cfg_data_wr_i(wb_sio_data_wr_w)
    ,.cfg_stb_i(wb_sio_stb_w)
    ,.cfg_cyc_i(wb_sio_cyc_w)
    ,.cfg_sel_i(wb_sio_sel_w)
    ,.cfg_we_i(wb_sio_we_w)
    ,.sio_rx_i(sio_rxd_w)

    // Outputs
    ,.cfg_data_rd_o(wb_sio_data_rd_w)
    ,.cfg_stall_o(wb_sio_stall_w)
    ,.cfg_ack_o(wb_sio_ack_w)
    ,.cfg_err_o(wb_sio_err_w)
    ,.irq_o(irq_sio_w)
    ,.sio_tx_o()
);


psf_gpu
#(
     .AXI_ID(13)
    ,.VRAM_BASE(VRAM_BASE)
)
u_gpu
(
    // Inputs
     .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.cfg_addr_i(wb_gpu_addr_w)
    ,.cfg_data_wr_i(wb_gpu_data_wr_w)
    ,.cfg_stb_i(wb_gpu_stb_w)
    ,.cfg_we_i(wb_gpu_we_w)
    ,.axi_awready_i(axi_vram_awready_i)
    ,.axi_wready_i(axi_vram_wready_i)
    ,.axi_bvalid_i(axi_vram_bvalid_i)
    ,.axi_bresp_i(axi_vram_bresp_i)
    ,.axi_bid_i(axi_vram_bid_i)
    ,.axi_arready_i(axi_vram_arready_i)
    ,.axi_rvalid_i(axi_vram_rvalid_i)
    ,.axi_rdata_i(axi_vram_rdata_i)
    ,.axi_rresp_i(axi_vram_rresp_i)
    ,.axi_rid_i(axi_vram_rid_i)
    ,.axi_rlast_i(axi_vram_rlast_i)
    ,.display_field_i(display_field_i)
    ,.display_hblank_i(gpu_hblank_w)
    ,.display_vblank_i(gpu_vblank_w)
    ,.gpu_m2p_valid_i(gpu_m2p_valid_w)
    ,.gpu_m2p_data_i(gpu_m2p_data_w)
    ,.gpu_p2m_accept_i(gpu_p2m_accept_w)

    // Outputs
    ,.cfg_data_rd_o(wb_gpu_data_rd_w)
    ,.cfg_ack_o(wb_gpu_ack_w)
    ,.cfg_stall_o(wb_gpu_stall_w)
    ,.irq_o(irq_gpu_w)
    ,.axi_awvalid_o(axi_vram_awvalid_o)
    ,.axi_awaddr_o(axi_vram_awaddr_o)
    ,.axi_awid_o(axi_vram_awid_o)
    ,.axi_awlen_o(axi_vram_awlen_o)
    ,.axi_awburst_o(axi_vram_awburst_o)
    ,.axi_wvalid_o(axi_vram_wvalid_o)
    ,.axi_wdata_o(axi_vram_wdata_o)
    ,.axi_wstrb_o(axi_vram_wstrb_o)
    ,.axi_wlast_o(axi_vram_wlast_o)
    ,.axi_bready_o(axi_vram_bready_o)
    ,.axi_arvalid_o(axi_vram_arvalid_o)
    ,.axi_araddr_o(axi_vram_araddr_o)
    ,.axi_arid_o(axi_vram_arid_o)
    ,.axi_arlen_o(axi_vram_arlen_o)
    ,.axi_arburst_o(axi_vram_arburst_o)
    ,.axi_rready_o(axi_vram_rready_o)
    ,.display_res_x_o(display_res_x_o)
    ,.display_res_y_o(display_res_y_o)
    ,.display_x_o(display_x_o)
    ,.display_y_o(display_y_o)
    ,.display_interlaced_o(display_interlaced_o)
    ,.display_pal_o(display_pal_o)
    ,.gpu_m2p_dreq_o(gpu_m2p_dreq_w)
    ,.gpu_m2p_accept_o(gpu_m2p_accept_w)
    ,.gpu_p2m_dreq_o(gpu_p2m_dreq_w)
    ,.gpu_p2m_valid_o(gpu_p2m_valid_w)
    ,.gpu_p2m_data_o(gpu_p2m_data_w)
);


reg reset_initial_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    reset_initial_q <= 1'b1;
else
    reset_initial_q <= 1'b0;

assign rst_cpu_w       = reset_initial_q | ~enable_w[0];

assign gpu_hblank_w    = display_hblank_i;
assign timer_hblank_w  = display_hblank_i;
assign gpu_vblank_w    = display_vblank_i;
assign timer_vblank_w  = display_vblank_i;
assign irq_vblank_w    = display_vblank_i;
assign timer_pal_w     = display_pal_o;


assign debug_config_w  = enable_w;

reg dump_pending_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    dump_pending_q <= 1'b0;
else if (enable_w[2] || event_debug_w)
    dump_pending_q <= 1'b1;

reg vblank_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    vblank_q <= 1'b0;
else
    vblank_q <= display_vblank_i;

wire vblank_rise_w = display_vblank_i & ~vblank_q;

reg nmi_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    nmi_q <= 1'b0;
else if ((dump_pending_q && vblank_rise_w) || enable_w[3])
    nmi_q <= 1'b1;

assign cpu_nmi_w  = nmi_q;

// TODO: Not connected yet...
assign sio_rxd_w  = 1'b1;

endmodule
