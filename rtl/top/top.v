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
module top
(
     input                   clk100mhz
    ,output [3:0]            led
    ,output                  uart_rxd_out
    ,input                   uart_txd_in

    // DDR3 SDRAM
    ,output  wire            ddr3_reset_n
    ,output  wire    [0:0]   ddr3_cke
    ,output  wire    [0:0]   ddr3_ck_p
    ,output  wire    [0:0]   ddr3_ck_n
    ,output  wire    [0:0]   ddr3_cs_n
    ,output  wire            ddr3_ras_n
    ,output  wire            ddr3_cas_n
    ,output  wire            ddr3_we_n
    ,output  wire    [2:0]   ddr3_ba
    ,output  wire    [13:0]  ddr3_addr
    ,output  wire    [0:0]   ddr3_odt
    ,output  wire    [1:0]   ddr3_dm
    ,inout   wire    [1:0]   ddr3_dqs_p
    ,inout   wire    [1:0]   ddr3_dqs_n
    ,inout   wire    [15:0]  ddr3_dq

    // HDMI
    ,output [3:0]            tmds_out_p
    ,output [3:0]            tmds_out_n

    // SD Card
    , inout                  sd_dat3_cs
    , inout                  sd_cmd_mosi
    , inout                  sd_dat0_miso
    , inout                  sd_clk
    , inout                  sd_dat1
    , inout                  sd_dat2
    , inout                  sd_cd

    , input [3:0]            sw

    // Joystick
    , input                  joy_ack_i
    , output                 joy_sel_o
    , input                  joy_dat_i
    , output                 joy_clk_o
    , output                 joy_cmd_o

    , output [7:0]           debug_o
);

//-----------------------------------------------------------------
// Implementation
//-----------------------------------------------------------------
wire           clk0;
wire           clk1;
wire           clk_w;
wire           clk_sys_w;
wire           rst_sys_w;
wire           clk_dvi_w;

wire           axi_rvalid_w;
wire           axi_wlast_w;
wire           axi_rlast_w;
wire  [  3:0]  axi_arid_w;
wire  [  1:0]  axi_rresp_w;
wire           axi_wvalid_w;
wire  [  7:0]  axi_awlen_w;
wire  [  1:0]  axi_awburst_w;
wire  [  1:0]  axi_bresp_w;
wire  [ 255:0] axi_rdata_w;
wire           axi_arready_w;
wire           axi_awvalid_w;
wire  [ 31:0]  axi_araddr_w;
wire  [  1:0]  axi_arburst_w;
wire           axi_wready_w;
wire  [  7:0]  axi_arlen_w;
wire           axi_awready_w;
wire  [  3:0]  axi_bid_w;
wire  [ 31:0]  axi_wstrb_w;
wire  [  3:0]  axi_awid_w;
wire           axi_rready_w;
wire  [  3:0]  axi_rid_w;
wire           axi_arvalid_w;
wire  [ 31:0]  axi_awaddr_w;
wire           axi_bvalid_w;
wire           axi_bready_w;
wire  [255:0]  axi_wdata_w;

artix7_pll
u_pll
(
    .clkref_i(clk100mhz),
    .clkout0_o(clk0),     // 100
    .clkout1_o(clk1),     // 200
    .clkout2_o(clk_w),    // 25
    .clkout3_o(clk_dvi_w) // 125
);

reset_gen
u_rst_sys
(
     .clk_i(clk_sys_w)
    ,.rst_o(rst_sys_w)
);

//-----------------------------------------------------------------
// Lid switch
//-----------------------------------------------------------------
reg  lid_switch_q;
wire lid_switch_w;

resync 
u_resync
(
     .clk_i(clk_w)
    ,.rst_i(rst_sys_w)
    ,.async_i(sw[0])
    ,.sync_o(lid_switch_w)
);

always @ (posedge clk_w or posedge rst_sys_w)
if (rst_sys_w)
    lid_switch_q <= 1'b0;
else
    lid_switch_q <= lid_switch_w;

wire lid_opened_w =  lid_switch_w & ~lid_switch_q;
wire lid_closed_w = ~lid_switch_w &  lid_switch_q;

//-----------------------------------------------------------------
// DDR
//-----------------------------------------------------------------
arty_ddr256 u_ddr
(
    // Inputs
     .clk100_i(clk0)
    ,.clk200_i(clk1)
    ,.inport_awvalid_i(axi_awvalid_w)
    ,.inport_awaddr_i(axi_awaddr_w)
    ,.inport_awid_i(axi_awid_w)
    ,.inport_awlen_i(axi_awlen_w)
    ,.inport_awburst_i(axi_awburst_w)
    ,.inport_wvalid_i(axi_wvalid_w)
    ,.inport_wdata_i(axi_wdata_w)
    ,.inport_wstrb_i(axi_wstrb_w)
    ,.inport_wlast_i(axi_wlast_w)
    ,.inport_bready_i(axi_bready_w)
    ,.inport_arvalid_i(axi_arvalid_w)
    ,.inport_araddr_i(axi_araddr_w)
    ,.inport_arid_i(axi_arid_w)
    ,.inport_arlen_i(axi_arlen_w)
    ,.inport_arburst_i(axi_arburst_w)
    ,.inport_rready_i(axi_rready_w)

    // Outputs
    ,.clk_out_o(clk_sys_w)
    ,.rst_out_o()
    ,.inport_awready_o(axi_awready_w)
    ,.inport_wready_o(axi_wready_w)
    ,.inport_bvalid_o(axi_bvalid_w)
    ,.inport_bresp_o(axi_bresp_w)
    ,.inport_bid_o(axi_bid_w)
    ,.inport_arready_o(axi_arready_w)
    ,.inport_rvalid_o(axi_rvalid_w)
    ,.inport_rdata_o(axi_rdata_w)
    ,.inport_rresp_o(axi_rresp_w)
    ,.inport_rid_o(axi_rid_w)
    ,.inport_rlast_o(axi_rlast_w)
    ,.ddr_ck_p_o(ddr3_ck_p)
    ,.ddr_ck_n_o(ddr3_ck_n)
    ,.ddr_cke_o(ddr3_cke)
    ,.ddr_reset_n_o(ddr3_reset_n)
    ,.ddr_ras_n_o(ddr3_ras_n)
    ,.ddr_cas_n_o(ddr3_cas_n)
    ,.ddr_we_n_o(ddr3_we_n)
    ,.ddr_cs_n_o(ddr3_cs_n)
    ,.ddr_ba_o(ddr3_ba)
    ,.ddr_addr_o(ddr3_addr)
    ,.ddr_odt_o(ddr3_odt)
    ,.ddr_dm_o(ddr3_dm)
    ,.ddr_dqs_p_io(ddr3_dqs_p)
    ,.ddr_dqs_n_io(ddr3_dqs_n)
    ,.ddr_data_io(ddr3_dq)
);

//-----------------------------------------------------------------
// Core
//-----------------------------------------------------------------
wire         dbg_txd_w;
wire         uart_txd_w;

wire         dvi_red_w;
wire         dvi_green_w;
wire         dvi_blue_w;
wire         dvi_clock_w;

wire         cdrom_tx_w;

wire [31:0]  int_cpu_gpio_w;

wire joy2_sel_w;
wire joy2_clk_w;
wire joy2_cmd_w;

fpga_top
u_top
(
     .clk_i(clk_w)
    ,.clk_sys_i(clk_sys_w)
    ,.clk_x5_i(clk_dvi_w)
    ,.rst_i(rst_sys_w)

    ,.dbg_rxd_o(dbg_txd_w)
    ,.dbg_txd_i(uart_txd_in)

    ,.uart_tx_o(uart_txd_w)
    ,.uart_rx_i(uart_txd_in)

    // DVI
    ,.dvi_red_o(dvi_red_w)
    ,.dvi_green_o(dvi_green_w)
    ,.dvi_blue_o(dvi_blue_w)
    ,.dvi_clock_o(dvi_clock_w)

    // DDR AXI
    ,.axi_awvalid_o(axi_awvalid_w)
    ,.axi_awaddr_o(axi_awaddr_w)
    ,.axi_awid_o(axi_awid_w)
    ,.axi_awlen_o(axi_awlen_w)
    ,.axi_awburst_o(axi_awburst_w)
    ,.axi_wvalid_o(axi_wvalid_w)
    ,.axi_wdata_o(axi_wdata_w)
    ,.axi_wstrb_o(axi_wstrb_w)
    ,.axi_wlast_o(axi_wlast_w)
    ,.axi_bready_o(axi_bready_w)
    ,.axi_arvalid_o(axi_arvalid_w)
    ,.axi_araddr_o(axi_araddr_w)
    ,.axi_arid_o(axi_arid_w)
    ,.axi_arlen_o(axi_arlen_w)
    ,.axi_arburst_o(axi_arburst_w)
    ,.axi_rready_o(axi_rready_w)    
    ,.axi_awready_i(axi_awready_w)
    ,.axi_wready_i(axi_wready_w)
    ,.axi_bvalid_i(axi_bvalid_w)
    ,.axi_bresp_i(axi_bresp_w)
    ,.axi_bid_i(axi_bid_w)
    ,.axi_arready_i(axi_arready_w)
    ,.axi_rvalid_i(axi_rvalid_w)
    ,.axi_rdata_i(axi_rdata_w)
    ,.axi_rresp_i(axi_rresp_w)
    ,.axi_rid_i(axi_rid_w)
    ,.axi_rlast_i(axi_rlast_w)

    // CDROM related
    ,.cdrom_tx_o(cdrom_tx_w)
    ,.gpio_out_o(int_cpu_gpio_w)
    ,.gpio_in_i({30'b0, lid_closed_w, lid_opened_w})

    ,.spi_clk_o(sd_clk)
    ,.spi_mosi_o(sd_cmd_mosi)
    ,.spi_miso_i(sd_dat0_miso)
    ,.spi_cs_o(sd_dat3_cs)

    // Joystick / MC
    ,.joy1_sel_o(joy_sel_o)
    ,.joy1_clk_o(joy_clk_o)
    ,.joy1_cmd_o(joy_cmd_o)
    ,.joy1_dat_i(joy_dat_i)
    ,.joy1_ack_i(joy_ack_i)

    ,.joy2_sel_o(joy2_sel_w)
    ,.joy2_clk_o(joy2_clk_w)
    ,.joy2_cmd_o(joy2_cmd_w)
    ,.joy2_dat_i(1'b1)
    ,.joy2_ack_i(1'b1)
);


assign sd_dat1 = 1'bz;
assign sd_dat2 = 1'bz;
assign sd_cd   = 1'bz;

// Xilinx placement pragmas:
//synthesis attribute IOB of txd_q is "TRUE"
reg txd_q;

always @ (posedge clk_w or posedge rst_sys_w)
if (rst_sys_w)
    txd_q <= 1'b1;
else
    txd_q <= dbg_txd_w & uart_txd_w & cdrom_tx_w;

// 'OR' two UARTs together
assign uart_rxd_out  = txd_q;

assign led     = int_cpu_gpio_w[3:0];

reg [2:0] dbg_q;

always @ (posedge clk_w or posedge rst_sys_w)
if (rst_sys_w)
    dbg_q <= 3'b0;
else
    dbg_q <= int_cpu_gpio_w[31:29];

assign debug_o = {joy2_cmd_w, joy2_clk_w, joy2_sel_w, joy_ack_i, joy_dat_i, joy_sel_o, joy_cmd_o , joy_clk_o};

OBUFDS u_buf_b
(
    .O(tmds_out_p[0]),
    .OB(tmds_out_n[0]),
    .I(dvi_blue_w)
);

OBUFDS u_buf_g
(
    .O(tmds_out_p[1]),
    .OB(tmds_out_n[1]),
    .I(dvi_green_w)
);

OBUFDS u_buf_r
(
    .O(tmds_out_p[2]),
    .OB(tmds_out_n[2]),
    .I(dvi_red_w)
);

OBUFDS u_buf_c
(
    .O(tmds_out_p[3]),
    .OB(tmds_out_n[3]),
    .I(dvi_clock_w)
);

endmodule
