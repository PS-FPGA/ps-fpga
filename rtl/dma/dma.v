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
module dma
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
     parameter AXI_ID           = 0
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
    ,input           cfg_cyc_i
    ,input  [  3:0]  cfg_sel_i
    ,input           cfg_we_i
    ,input           mem_awready_i
    ,input           mem_wready_i
    ,input           mem_bvalid_i
    ,input  [  1:0]  mem_bresp_i
    ,input  [  3:0]  mem_bid_i
    ,input           mem_arready_i
    ,input           mem_rvalid_i
    ,input  [ 31:0]  mem_rdata_i
    ,input  [  1:0]  mem_rresp_i
    ,input  [  3:0]  mem_rid_i
    ,input           mem_rlast_i
    ,input           mdec_p2m_dreq_i
    ,input           mdec_p2m_valid_i
    ,input  [ 31:0]  mdec_p2m_data_i
    ,input           mdec_m2p_dreq_i
    ,input           mdec_m2p_accept_i
    ,input           gpu_m2p_dreq_i
    ,input           gpu_m2p_accept_i
    ,input           gpu_p2m_dreq_i
    ,input           gpu_p2m_valid_i
    ,input  [ 31:0]  gpu_p2m_data_i
    ,input           cdrom_p2m_dreq_i
    ,input           cdrom_p2m_valid_i
    ,input  [ 31:0]  cdrom_p2m_data_i
    ,input           spu_m2p_dreq_i
    ,input           spu_m2p_accept_i
    ,input           spu_p2m_dreq_i
    ,input           spu_p2m_valid_i
    ,input  [ 31:0]  spu_p2m_data_i
    ,input           pio_m2p_dreq_i
    ,input           pio_m2p_accept_i
    ,input           pio_p2m_dreq_i
    ,input           pio_p2m_valid_i
    ,input  [ 31:0]  pio_p2m_data_i

    // Outputs
    ,output [ 31:0]  cfg_data_rd_o
    ,output          cfg_stall_o
    ,output          cfg_ack_o
    ,output          cfg_err_o
    ,output          irq_o
    ,output          cpu_inhibit_o
    ,output          mem_awvalid_o
    ,output [ 31:0]  mem_awaddr_o
    ,output [  3:0]  mem_awid_o
    ,output [  7:0]  mem_awlen_o
    ,output [  1:0]  mem_awburst_o
    ,output [  2:0]  mem_awsize_o
    ,output          mem_wvalid_o
    ,output [ 31:0]  mem_wdata_o
    ,output [  3:0]  mem_wstrb_o
    ,output          mem_wlast_o
    ,output          mem_bready_o
    ,output          mem_arvalid_o
    ,output [ 31:0]  mem_araddr_o
    ,output [  3:0]  mem_arid_o
    ,output [  7:0]  mem_arlen_o
    ,output [  1:0]  mem_arburst_o
    ,output [  2:0]  mem_arsize_o
    ,output          mem_rready_o
    ,output          mdec_p2m_accept_o
    ,output          mdec_m2p_valid_o
    ,output [ 31:0]  mdec_m2p_data_o
    ,output          gpu_m2p_valid_o
    ,output [ 31:0]  gpu_m2p_data_o
    ,output          gpu_p2m_accept_o
    ,output          cdrom_p2m_accept_o
    ,output          cdrom_p2m_dma_en_o
    ,output [ 31:0]  cdrom_p2m_dma_bs_o
    ,output          spu_m2p_valid_o
    ,output [ 31:0]  spu_m2p_data_o
    ,output          spu_p2m_accept_o
    ,output          pio_m2p_valid_o
    ,output [ 31:0]  pio_m2p_data_o
    ,output          pio_p2m_accept_o
);



wire         reg_write_w = cfg_stb_i && ~cfg_stall_o &&  cfg_we_i;
wire         reg_read_w  = cfg_stb_i && ~cfg_stall_o && ~cfg_we_i;
wire [3:0]   reg_mask_w  = cfg_sel_i;

wire          ch0_wr_w = cfg_stb_i && cfg_we_i && !cfg_stall_o && cfg_addr_i[7:4] == 4'd8;
wire [31:0]   ch0_data_rd_w;
wire          ch1_wr_w = cfg_stb_i && cfg_we_i && !cfg_stall_o && cfg_addr_i[7:4] == 4'd9;
wire [31:0]   ch1_data_rd_w;
wire          ch2_wr_w = cfg_stb_i && cfg_we_i && !cfg_stall_o && cfg_addr_i[7:4] == 4'd10;
wire [31:0]   ch2_data_rd_w;
wire          ch3_wr_w = cfg_stb_i && cfg_we_i && !cfg_stall_o && cfg_addr_i[7:4] == 4'd11;
wire [31:0]   ch3_data_rd_w;
wire          ch4_wr_w = cfg_stb_i && cfg_we_i && !cfg_stall_o && cfg_addr_i[7:4] == 4'd12;
wire [31:0]   ch4_data_rd_w;
wire          ch5_wr_w = cfg_stb_i && cfg_we_i && !cfg_stall_o && cfg_addr_i[7:4] == 4'd13;
wire [31:0]   ch5_data_rd_w;
wire          ch6_wr_w = cfg_stb_i && cfg_we_i && !cfg_stall_o && cfg_addr_i[7:4] == 4'd14;
wire [31:0]   ch6_data_rd_w;
wire [6:0]    complete_w;
wire [6:0]    busy_w;

wire          ch0_req_valid_w;
wire [ 31:0]  ch0_req_addr_w;
wire          ch0_req_dir_m2p_w;
wire [ 31:0]  ch0_req_length_w;
wire          ch0_req_mode_decr_w;
wire          ch0_req_accept_w;

wire          ch0_sts_complete_w;
wire [ 31:0]  ch0_sts_length_w;

wire          ch0_desc_fetch_w;
wire [ 31:0]  ch0_desc_addr_w;
wire          ch0_desc_accept_w;
wire          ch0_desc_valid_w;
wire [ 31:0]  ch0_desc_data_w;

wire          ch0_dir_w;
wire          ch1_req_valid_w;
wire [ 31:0]  ch1_req_addr_w;
wire          ch1_req_dir_m2p_w;
wire [ 31:0]  ch1_req_length_w;
wire          ch1_req_mode_decr_w;
wire          ch1_req_accept_w;

wire          ch1_sts_complete_w;
wire [ 31:0]  ch1_sts_length_w;

wire          ch1_desc_fetch_w;
wire [ 31:0]  ch1_desc_addr_w;
wire          ch1_desc_accept_w;
wire          ch1_desc_valid_w;
wire [ 31:0]  ch1_desc_data_w;

wire          ch1_dir_w;
wire          ch2_req_valid_w;
wire [ 31:0]  ch2_req_addr_w;
wire          ch2_req_dir_m2p_w;
wire [ 31:0]  ch2_req_length_w;
wire          ch2_req_mode_decr_w;
wire          ch2_req_accept_w;

wire          ch2_sts_complete_w;
wire [ 31:0]  ch2_sts_length_w;

wire          ch2_desc_fetch_w;
wire [ 31:0]  ch2_desc_addr_w;
wire          ch2_desc_accept_w;
wire          ch2_desc_valid_w;
wire [ 31:0]  ch2_desc_data_w;

wire          ch2_dir_w;
wire          ch3_req_valid_w;
wire [ 31:0]  ch3_req_addr_w;
wire          ch3_req_dir_m2p_w;
wire [ 31:0]  ch3_req_length_w;
wire          ch3_req_mode_decr_w;
wire          ch3_req_accept_w;

wire          ch3_sts_complete_w;
wire [ 31:0]  ch3_sts_length_w;

wire          ch3_desc_fetch_w;
wire [ 31:0]  ch3_desc_addr_w;
wire          ch3_desc_accept_w;
wire          ch3_desc_valid_w;
wire [ 31:0]  ch3_desc_data_w;

wire          ch3_dir_w;
wire          ch4_req_valid_w;
wire [ 31:0]  ch4_req_addr_w;
wire          ch4_req_dir_m2p_w;
wire [ 31:0]  ch4_req_length_w;
wire          ch4_req_mode_decr_w;
wire          ch4_req_accept_w;

wire          ch4_sts_complete_w;
wire [ 31:0]  ch4_sts_length_w;

wire          ch4_desc_fetch_w;
wire [ 31:0]  ch4_desc_addr_w;
wire          ch4_desc_accept_w;
wire          ch4_desc_valid_w;
wire [ 31:0]  ch4_desc_data_w;

wire          ch4_dir_w;
wire          ch5_req_valid_w;
wire [ 31:0]  ch5_req_addr_w;
wire          ch5_req_dir_m2p_w;
wire [ 31:0]  ch5_req_length_w;
wire          ch5_req_mode_decr_w;
wire          ch5_req_accept_w;

wire          ch5_sts_complete_w;
wire [ 31:0]  ch5_sts_length_w;

wire          ch5_desc_fetch_w;
wire [ 31:0]  ch5_desc_addr_w;
wire          ch5_desc_accept_w;
wire          ch5_desc_valid_w;
wire [ 31:0]  ch5_desc_data_w;

wire          ch5_dir_w;
wire          ch6_req_valid_w;
wire [ 31:0]  ch6_req_addr_w;
wire          ch6_req_dir_m2p_w;
wire [ 31:0]  ch6_req_length_w;
wire          ch6_req_mode_decr_w;
wire          ch6_req_accept_w;

wire          ch6_sts_complete_w;
wire [ 31:0]  ch6_sts_length_w;

wire          ch6_desc_fetch_w;
wire [ 31:0]  ch6_desc_addr_w;
wire          ch6_desc_accept_w;
wire          ch6_desc_valid_w;
wire [ 31:0]  ch6_desc_data_w;

wire          ch6_dir_w;

wire          ch0_dreq_w = mdec_m2p_dreq_i;
wire          ch1_dreq_w = mdec_p2m_dreq_i;
wire          ch2_dreq_w = ch2_dir_w ? gpu_m2p_dreq_i : gpu_p2m_dreq_i;
wire          ch3_dreq_w = cdrom_p2m_dreq_i;
wire          ch4_dreq_w = ch4_dir_w ? spu_m2p_dreq_i : spu_p2m_dreq_i;
wire          ch5_dreq_w = ch5_dir_w ? pio_m2p_dreq_i : pio_p2m_dreq_i;
wire          ch6_dreq_w = 1'b0;

//-----------------------------------------------------------------
// DMA: CH0
//-----------------------------------------------------------------
dma_channel
#(
     .ENABLE_M2P(1)
    ,.FORCE_M2P(1)
)
u_ch0
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)

    // Register access
    ,.cfg_wr_i(ch0_wr_w)
    ,.cfg_addr_i({cfg_addr_i[3:2], 2'b0})
    ,.cfg_data_in_i(cfg_data_wr_i)
    ,.cfg_data_out_o(ch0_data_rd_w)

    // Transfer request
    ,.req_valid_o(ch0_req_valid_w)
    ,.req_addr_o(ch0_req_addr_w)
    ,.req_dir_m2p_o(ch0_req_dir_m2p_w)
    ,.req_length_o(ch0_req_length_w)
    ,.req_mode_decr_o(ch0_req_mode_decr_w)
    ,.req_accept_i(ch0_req_accept_w)

    // Transfer status
    ,.sts_complete_i(ch0_sts_complete_w)
    ,.sts_length_i(ch0_sts_length_w)

    // Peripheral data request
    ,.dreq_i(ch0_dreq_w)
    ,.dreq_dir_o(ch0_dir_w)

    // Additional info
    ,.enabled_o()
    ,.block_size_o()

    // Desc fetch
    ,.desc_fetch_o(ch0_desc_fetch_w)
    ,.desc_addr_o(ch0_desc_addr_w)
    ,.desc_accept_i(ch0_desc_accept_w)
    ,.desc_valid_i(ch0_desc_valid_w)
    ,.desc_data_i(ch0_desc_data_w)

    ,.complete_o(complete_w[0])
    ,.busy_o(busy_w[0])
);
//-----------------------------------------------------------------
// DMA: CH1
//-----------------------------------------------------------------
dma_channel
#(
     .ENABLE_M2P(0)
    ,.FORCE_M2P(0)
)
u_ch1
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)

    // Register access
    ,.cfg_wr_i(ch1_wr_w)
    ,.cfg_addr_i({cfg_addr_i[3:2], 2'b0})
    ,.cfg_data_in_i(cfg_data_wr_i)
    ,.cfg_data_out_o(ch1_data_rd_w)

    // Transfer request
    ,.req_valid_o(ch1_req_valid_w)
    ,.req_addr_o(ch1_req_addr_w)
    ,.req_dir_m2p_o(ch1_req_dir_m2p_w)
    ,.req_length_o(ch1_req_length_w)
    ,.req_mode_decr_o(ch1_req_mode_decr_w)
    ,.req_accept_i(ch1_req_accept_w)

    // Transfer status
    ,.sts_complete_i(ch1_sts_complete_w)
    ,.sts_length_i(ch1_sts_length_w)

    // Peripheral data request
    ,.dreq_i(ch1_dreq_w)
    ,.dreq_dir_o(ch1_dir_w)

    // Additional info
    ,.enabled_o()
    ,.block_size_o()

    // Desc fetch
    ,.desc_fetch_o(ch1_desc_fetch_w)
    ,.desc_addr_o(ch1_desc_addr_w)
    ,.desc_accept_i(ch1_desc_accept_w)
    ,.desc_valid_i(ch1_desc_valid_w)
    ,.desc_data_i(ch1_desc_data_w)

    ,.complete_o(complete_w[1])
    ,.busy_o(busy_w[1])
);
//-----------------------------------------------------------------
// DMA: CH2
//-----------------------------------------------------------------
dma_channel
#(
     .ENABLE_M2P(1)
    ,.FORCE_M2P(0)
)
u_ch2
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)

    // Register access
    ,.cfg_wr_i(ch2_wr_w)
    ,.cfg_addr_i({cfg_addr_i[3:2], 2'b0})
    ,.cfg_data_in_i(cfg_data_wr_i)
    ,.cfg_data_out_o(ch2_data_rd_w)

    // Transfer request
    ,.req_valid_o(ch2_req_valid_w)
    ,.req_addr_o(ch2_req_addr_w)
    ,.req_dir_m2p_o(ch2_req_dir_m2p_w)
    ,.req_length_o(ch2_req_length_w)
    ,.req_mode_decr_o(ch2_req_mode_decr_w)
    ,.req_accept_i(ch2_req_accept_w)

    // Transfer status
    ,.sts_complete_i(ch2_sts_complete_w)
    ,.sts_length_i(ch2_sts_length_w)

    // Peripheral data request
    ,.dreq_i(ch2_dreq_w)
    ,.dreq_dir_o(ch2_dir_w)

    // Additional info
    ,.enabled_o()
    ,.block_size_o()

    // Desc fetch
    ,.desc_fetch_o(ch2_desc_fetch_w)
    ,.desc_addr_o(ch2_desc_addr_w)
    ,.desc_accept_i(ch2_desc_accept_w)
    ,.desc_valid_i(ch2_desc_valid_w)
    ,.desc_data_i(ch2_desc_data_w)

    ,.complete_o(complete_w[2])
    ,.busy_o(busy_w[2])
);
//-----------------------------------------------------------------
// DMA: CH3
//-----------------------------------------------------------------
dma_channel
#(
     .ENABLE_M2P(0)
    ,.FORCE_M2P(0)
)
u_ch3
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)

    // Register access
    ,.cfg_wr_i(ch3_wr_w)
    ,.cfg_addr_i({cfg_addr_i[3:2], 2'b0})
    ,.cfg_data_in_i(cfg_data_wr_i)
    ,.cfg_data_out_o(ch3_data_rd_w)

    // Transfer request
    ,.req_valid_o(ch3_req_valid_w)
    ,.req_addr_o(ch3_req_addr_w)
    ,.req_dir_m2p_o(ch3_req_dir_m2p_w)
    ,.req_length_o(ch3_req_length_w)
    ,.req_mode_decr_o(ch3_req_mode_decr_w)
    ,.req_accept_i(ch3_req_accept_w)

    // Transfer status
    ,.sts_complete_i(ch3_sts_complete_w)
    ,.sts_length_i(ch3_sts_length_w)

    // Peripheral data request
    ,.dreq_i(ch3_dreq_w)
    ,.dreq_dir_o(ch3_dir_w)

    // Additional info
    ,.enabled_o(cdrom_p2m_dma_en_o)
    ,.block_size_o(cdrom_p2m_dma_bs_o)

    // Desc fetch
    ,.desc_fetch_o(ch3_desc_fetch_w)
    ,.desc_addr_o(ch3_desc_addr_w)
    ,.desc_accept_i(ch3_desc_accept_w)
    ,.desc_valid_i(ch3_desc_valid_w)
    ,.desc_data_i(ch3_desc_data_w)

    ,.complete_o(complete_w[3])
    ,.busy_o(busy_w[3])
);
//-----------------------------------------------------------------
// DMA: CH4
//-----------------------------------------------------------------
dma_channel
#(
     .ENABLE_M2P(1)
    ,.FORCE_M2P(0)
)
u_ch4
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)

    // Register access
    ,.cfg_wr_i(ch4_wr_w)
    ,.cfg_addr_i({cfg_addr_i[3:2], 2'b0})
    ,.cfg_data_in_i(cfg_data_wr_i)
    ,.cfg_data_out_o(ch4_data_rd_w)

    // Transfer request
    ,.req_valid_o(ch4_req_valid_w)
    ,.req_addr_o(ch4_req_addr_w)
    ,.req_dir_m2p_o(ch4_req_dir_m2p_w)
    ,.req_length_o(ch4_req_length_w)
    ,.req_mode_decr_o(ch4_req_mode_decr_w)
    ,.req_accept_i(ch4_req_accept_w)

    // Transfer status
    ,.sts_complete_i(ch4_sts_complete_w)
    ,.sts_length_i(ch4_sts_length_w)

    // Peripheral data request
    ,.dreq_i(ch4_dreq_w)
    ,.dreq_dir_o(ch4_dir_w)

    // Additional info
    ,.enabled_o()
    ,.block_size_o()

    // Desc fetch
    ,.desc_fetch_o(ch4_desc_fetch_w)
    ,.desc_addr_o(ch4_desc_addr_w)
    ,.desc_accept_i(ch4_desc_accept_w)
    ,.desc_valid_i(ch4_desc_valid_w)
    ,.desc_data_i(ch4_desc_data_w)

    ,.complete_o(complete_w[4])
    ,.busy_o(busy_w[4])
);
//-----------------------------------------------------------------
// DMA: CH5
//-----------------------------------------------------------------
dma_channel
#(
     .ENABLE_M2P(1)
    ,.FORCE_M2P(0)
)
u_ch5
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)

    // Register access
    ,.cfg_wr_i(ch5_wr_w)
    ,.cfg_addr_i({cfg_addr_i[3:2], 2'b0})
    ,.cfg_data_in_i(cfg_data_wr_i)
    ,.cfg_data_out_o(ch5_data_rd_w)

    // Transfer request
    ,.req_valid_o(ch5_req_valid_w)
    ,.req_addr_o(ch5_req_addr_w)
    ,.req_dir_m2p_o(ch5_req_dir_m2p_w)
    ,.req_length_o(ch5_req_length_w)
    ,.req_mode_decr_o(ch5_req_mode_decr_w)
    ,.req_accept_i(ch5_req_accept_w)

    // Transfer status
    ,.sts_complete_i(ch5_sts_complete_w)
    ,.sts_length_i(ch5_sts_length_w)

    // Peripheral data request
    ,.dreq_i(ch5_dreq_w)
    ,.dreq_dir_o(ch5_dir_w)

    // Additional info
    ,.enabled_o()
    ,.block_size_o()

    // Desc fetch
    ,.desc_fetch_o(ch5_desc_fetch_w)
    ,.desc_addr_o(ch5_desc_addr_w)
    ,.desc_accept_i(ch5_desc_accept_w)
    ,.desc_valid_i(ch5_desc_valid_w)
    ,.desc_data_i(ch5_desc_data_w)

    ,.complete_o(complete_w[5])
    ,.busy_o(busy_w[5])
);
//-----------------------------------------------------------------
// DMA: CH6
//-----------------------------------------------------------------
dma_channel
#(
     .ENABLE_M2P(0)
    ,.FORCE_M2P(0)
)
u_ch6
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)

    // Register access
    ,.cfg_wr_i(ch6_wr_w)
    ,.cfg_addr_i({cfg_addr_i[3:2], 2'b0})
    ,.cfg_data_in_i(cfg_data_wr_i)
    ,.cfg_data_out_o(ch6_data_rd_w)

    // Transfer request
    ,.req_valid_o(ch6_req_valid_w)
    ,.req_addr_o(ch6_req_addr_w)
    ,.req_dir_m2p_o(ch6_req_dir_m2p_w)
    ,.req_length_o(ch6_req_length_w)
    ,.req_mode_decr_o(ch6_req_mode_decr_w)
    ,.req_accept_i(ch6_req_accept_w)

    // Transfer status
    ,.sts_complete_i(ch6_sts_complete_w)
    ,.sts_length_i(ch6_sts_length_w)

    // Peripheral data request
    ,.dreq_i(ch6_dreq_w)
    ,.dreq_dir_o(ch6_dir_w)

    // Additional info
    ,.enabled_o()
    ,.block_size_o()

    // Desc fetch
    ,.desc_fetch_o(ch6_desc_fetch_w)
    ,.desc_addr_o(ch6_desc_addr_w)
    ,.desc_accept_i(ch6_desc_accept_w)
    ,.desc_valid_i(ch6_desc_valid_w)
    ,.desc_data_i(ch6_desc_data_w)

    ,.complete_o(complete_w[6])
    ,.busy_o(busy_w[6])
);

//-----------------------------------------------------------------
// 1F8010F0h - DPCR - DMA Control Register (R/W)
//-----------------------------------------------------------------
reg [31:0] cfg_dpcr_q;
reg [31:0] cfg_dpcr_r;

wire       addr_10F0_w = {cfg_addr_i[7:2], 2'b0} == 8'hF0;

always @ *
begin
    cfg_dpcr_r = cfg_dpcr_q;

    if (reg_write_w && addr_10F0_w && reg_mask_w[0])
        cfg_dpcr_r[7:0] = cfg_data_wr_i[7:0];

    if (reg_write_w && addr_10F0_w && reg_mask_w[1])
        cfg_dpcr_r[15:8] = cfg_data_wr_i[15:8];

    if (reg_write_w && addr_10F0_w && reg_mask_w[2])
        cfg_dpcr_r[23:16] = cfg_data_wr_i[23:16];

    if (reg_write_w && addr_10F0_w && reg_mask_w[3])
        cfg_dpcr_r[31:24] = cfg_data_wr_i[31:24];
end

always @ (posedge clk_i )
if (rst_i)
    cfg_dpcr_q <= 32'h07654321;
else
    cfg_dpcr_q <= cfg_dpcr_r;

// 0-2   DMA0, MDECin  Priority      (0..7; 0=Highest, 7=Lowest)
// 3     DMA0, MDECin  Master Enable (0=Disable, 1=Enable)
wire ch0_master_en_w = cfg_dpcr_q[3];
// 4-6   DMA1, MDECout Priority      (0..7; 0=Highest, 7=Lowest)
// 7     DMA1, MDECout Master Enable (0=Disable, 1=Enable)
wire ch1_master_en_w = cfg_dpcr_q[7];
// 8-10  DMA2, GPU     Priority      (0..7; 0=Highest, 7=Lowest)
// 11    DMA2, GPU     Master Enable (0=Disable, 1=Enable)
wire ch2_master_en_w = cfg_dpcr_q[11];
// 12-14 DMA3, CDROM   Priority      (0..7; 0=Highest, 7=Lowest)
// 15    DMA3, CDROM   Master Enable (0=Disable, 1=Enable)
wire ch3_master_en_w = cfg_dpcr_q[15];
// 16-18 DMA4, SPU     Priority      (0..7; 0=Highest, 7=Lowest)
// 19    DMA4, SPU     Master Enable (0=Disable, 1=Enable)
wire ch4_master_en_w = cfg_dpcr_q[19];
// 20-22 DMA5, PIO     Priority      (0..7; 0=Highest, 7=Lowest)
// 23    DMA5, PIO     Master Enable (0=Disable, 1=Enable)
wire ch5_master_en_w = cfg_dpcr_q[23];
// 24-26 DMA6, OTC     Priority      (0..7; 0=Highest, 7=Lowest)
// 27    DMA6, OTC     Master Enable (0=Disable, 1=Enable)
wire ch6_master_en_w = cfg_dpcr_q[27];

//-----------------------------------------------------------------
// 1F8010F4h - DICR - DMA Interrupt Register (R/W)
//-----------------------------------------------------------------
reg [31:0] cfg_dicr_q;
reg [31:0] cfg_dicr_r;

wire       addr_10F4_w = {cfg_addr_i[7:2], 2'b0} == 8'hF4;

// 16-22 IRQ Enable for DMA0..DMA6         (0=None, 1=Enable)
wire [6:0] cfg_dicr_irq_en_w    = cfg_dicr_q[22:16];
  
// 23 IRQ Master Enable for DMA0..DMA6  (0=None, 1=Enable)
wire       cfg_dicr_master_en_w = cfg_dicr_q[23];

// IRQ flags in Bit(24+n) are set upon DMAn completion - but caution - they are set ONLY if enabled in Bit(16+n).
wire [6:0] ch_irq_masked_w = cfg_dicr_irq_en_w & complete_w;

always @ *
begin
    cfg_dicr_r = cfg_dicr_q;

    // Global IRQ output [b15=1 OR (b23=1 AND (b16-22 AND b24-30)>0)]
    cfg_dicr_r[31] = cfg_dicr_q[15] | (cfg_dicr_master_en_w & (|(cfg_dicr_irq_en_w & cfg_dicr_r[30:24])));

    // CPU write
    if (reg_write_w && addr_10F4_w)
    begin
        // 0-5   Unknown  (read/write-able)
        if (reg_mask_w[0])
            cfg_dicr_r[4:0]   = cfg_data_wr_i[4:0];

        // Force IRQ (sets bit31) (0=None, 1=Force Bit31=1)
        if (reg_mask_w[1])
            cfg_dicr_r[15]    = cfg_data_wr_i[15];

        if (reg_mask_w[2])
        begin
            // IRQ Enable for DMA0..DMA6 (0=None, 1=Enable)
            cfg_dicr_r[22:16] = cfg_data_wr_i[22:16];

            // IRQ Master Enable for DMA0..DMA6  (0=None, 1=Enable)
            cfg_dicr_r[23]    = cfg_data_wr_i[23];
        end

        // 24-30 IRQ Flags for DMA0..DMA6 (0=None, 1=IRQ) (Write 1 to reset)
        if (reg_mask_w[3])
            cfg_dicr_r[30:24] = cfg_dicr_r[30:24] & ~cfg_data_wr_i[30:24];
    end

    // 6-14  Not used (always zero)
    cfg_dicr_r[14:6] = 9'b0;

    // Add in new completion IRQs
    cfg_dicr_r[30:24] = cfg_dicr_r[30:24] | ch_irq_masked_w;
end

always @ (posedge clk_i )
if (rst_i)
    cfg_dicr_q <= 32'b0;
else
    cfg_dicr_q <= cfg_dicr_r;

reg irq_q;

always @ (posedge clk_i )
if (rst_i)
    irq_q <= 1'b0;
else
    irq_q <= cfg_dicr_r[31];

assign irq_o = irq_q;

//-----------------------------------------------------------------
// Read mux
//-----------------------------------------------------------------
// DMA Registers
//   1F80108xh      DMA0 channel 0 - MDECin
//   1F80109xh      DMA1 channel 1 - MDECout
//   1F8010Axh      DMA2 channel 2 - GPU (lists + image data)
//   1F8010Bxh      DMA3 channel 3 - CDROM
//   1F8010Cxh      DMA4 channel 4 - SPU
//   1F8010Dxh      DMA5 channel 5 - PIO (Expansion Port)
//   1F8010Exh      DMA6 channel 6 - OTC (reverse clear OT) (GPU related)
//   1F8010F0h      DPCR - DMA Control register
//   1F8010F4h      DICR - DMA Interrupt register
//   1F8010F8h      unknown (TODO)
//   1F8010FCh      unknown (TODO)

reg [31:0] data_r;
always @ *
begin
    data_r = 32'b0;

    case (cfg_addr_i[7:4])
    4'd8: data_r = ch0_data_rd_w;
    4'd9: data_r = ch1_data_rd_w;
    4'd10: data_r = ch2_data_rd_w;
    4'd11: data_r = ch3_data_rd_w;
    4'd12: data_r = ch4_data_rd_w;
    4'd13: data_r = ch5_data_rd_w;
    4'd14: data_r = ch6_data_rd_w;
    4'hF:
    begin
        case ({cfg_addr_i[3:2], 2'b0})
        4'h0: data_r = cfg_dpcr_q;
        4'h4: data_r = cfg_dicr_q;
        default: ;
        endcase
    end
    default: ;
    endcase
end

reg [31:0] data_q;

always @ (posedge clk_i )
if (rst_i)
    data_q <= 32'b0;
else
    data_q <= data_r;

assign cfg_data_rd_o = data_q;

reg ack_q;

always @ (posedge clk_i )
if (rst_i)
    ack_q <= 1'b0;
else if (cfg_stb_i && ~cfg_stall_o)
    ack_q <= 1'b1;
else
    ack_q <= 1'b0;

assign cfg_ack_o     = ack_q;
assign cfg_err_o     = 1'b0;
assign cfg_stall_o   = ack_q;

//-----------------------------------------------------------------
// Arbitration: M2P
//-----------------------------------------------------------------
reg           m2p_req_r;
reg [ 31:0]   m2p_req_addr_r;
reg [ 31:0]   m2p_req_length_r;
reg           m2p_req_mode_decr_r;
reg [ 2:0]    m2p_req_ch_r;
wire          m2p_req_accept_w;

wire [6:0]    m2p_request_w;
wire [6:0]    m2p_grant_w;
reg  [6:0]    m2p_grant_q;

assign        m2p_request_w[0] = (ch0_req_valid_w & ch0_req_dir_m2p_w & ch0_master_en_w);
assign        m2p_request_w[1] = (ch1_req_valid_w & ch1_req_dir_m2p_w & ch1_master_en_w);
assign        m2p_request_w[2] = (ch2_req_valid_w & ch2_req_dir_m2p_w & ch2_master_en_w);
assign        m2p_request_w[3] = (ch3_req_valid_w & ch3_req_dir_m2p_w & ch3_master_en_w);
assign        m2p_request_w[4] = (ch4_req_valid_w & ch4_req_dir_m2p_w & ch4_master_en_w);
assign        m2p_request_w[5] = (ch5_req_valid_w & ch5_req_dir_m2p_w & ch5_master_en_w);
assign        m2p_request_w[6] = (ch6_req_valid_w & ch6_req_dir_m2p_w & ch6_master_en_w);

// TODO: Switch to fancy priority based arb (based on DPCR)
dma_rr_arb
u_m2p_arb
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)

    ,.hold_i(1'b0)
    ,.request_i(m2p_request_w)

    ,.grant_o(m2p_grant_w)
);

always @ *
begin
    m2p_req_r           = 1'b0;
    m2p_req_addr_r      = 32'b0;
    m2p_req_length_r    = 32'b0;
    m2p_req_mode_decr_r = 1'b0;
    m2p_req_ch_r        = 3'b0;

    case (1'b1)
    m2p_grant_w[0]:
    begin
        m2p_req_r           = ch0_req_valid_w & ch0_req_dir_m2p_w;
        m2p_req_addr_r      = ch0_req_addr_w;
        m2p_req_length_r    = ch0_req_length_w;
        m2p_req_mode_decr_r = ch0_req_mode_decr_w;
        m2p_req_ch_r        = 3'd0;
    end
    m2p_grant_w[1]:
    begin
        m2p_req_r           = ch1_req_valid_w & ch1_req_dir_m2p_w;
        m2p_req_addr_r      = ch1_req_addr_w;
        m2p_req_length_r    = ch1_req_length_w;
        m2p_req_mode_decr_r = ch1_req_mode_decr_w;
        m2p_req_ch_r        = 3'd1;
    end
    m2p_grant_w[2]:
    begin
        m2p_req_r           = ch2_req_valid_w & ch2_req_dir_m2p_w;
        m2p_req_addr_r      = ch2_req_addr_w;
        m2p_req_length_r    = ch2_req_length_w;
        m2p_req_mode_decr_r = ch2_req_mode_decr_w;
        m2p_req_ch_r        = 3'd2;
    end
    m2p_grant_w[3]:
    begin
        m2p_req_r           = ch3_req_valid_w & ch3_req_dir_m2p_w;
        m2p_req_addr_r      = ch3_req_addr_w;
        m2p_req_length_r    = ch3_req_length_w;
        m2p_req_mode_decr_r = ch3_req_mode_decr_w;
        m2p_req_ch_r        = 3'd3;
    end
    m2p_grant_w[4]:
    begin
        m2p_req_r           = ch4_req_valid_w & ch4_req_dir_m2p_w;
        m2p_req_addr_r      = ch4_req_addr_w;
        m2p_req_length_r    = ch4_req_length_w;
        m2p_req_mode_decr_r = ch4_req_mode_decr_w;
        m2p_req_ch_r        = 3'd4;
    end
    m2p_grant_w[5]:
    begin
        m2p_req_r           = ch5_req_valid_w & ch5_req_dir_m2p_w;
        m2p_req_addr_r      = ch5_req_addr_w;
        m2p_req_length_r    = ch5_req_length_w;
        m2p_req_mode_decr_r = ch5_req_mode_decr_w;
        m2p_req_ch_r        = 3'd5;
    end
    m2p_grant_w[6]:
    begin
        m2p_req_r           = ch6_req_valid_w & ch6_req_dir_m2p_w;
        m2p_req_addr_r      = ch6_req_addr_w;
        m2p_req_length_r    = ch6_req_length_w;
        m2p_req_mode_decr_r = ch6_req_mode_decr_w;
        m2p_req_ch_r        = 3'd6;
    end
    endcase
end

//-----------------------------------------------------------------
// Memory -> Peripheral output stream routing
//-----------------------------------------------------------------
wire        m2p_stream_valid_w;
wire [31:0] m2p_stream_data_w;

wire        m2p_stream_accept_w = (m2p_grant_q[0] & mdec_m2p_accept_i) |
                                  (m2p_grant_q[2] & gpu_m2p_accept_i)  |
                                  (m2p_grant_q[4] & spu_m2p_accept_i)  |
                                  (m2p_grant_q[5] & pio_m2p_accept_i);

assign mdec_m2p_valid_o = m2p_stream_valid_w & m2p_grant_q[0];
assign mdec_m2p_data_o  = m2p_stream_data_w;

assign gpu_m2p_valid_o  = m2p_stream_valid_w & m2p_grant_q[2];
assign gpu_m2p_data_o   = m2p_stream_data_w;

assign spu_m2p_valid_o  = m2p_stream_valid_w & m2p_grant_q[4];
assign spu_m2p_data_o   = m2p_stream_data_w;

assign pio_m2p_valid_o  = m2p_stream_valid_w & m2p_grant_q[5];
assign pio_m2p_data_o   = m2p_stream_data_w;

//-----------------------------------------------------------------
// Memory -> Peripheral transfer core
//-----------------------------------------------------------------
wire          m2p_sts_complete_w;
wire [31:0]   m2p_sts_length_w;

wire          dma_arvalid_w;
wire [ 31:0]  dma_araddr_w;
wire [  3:0]  dma_arid_w;
wire [  7:0]  dma_arlen_w;
wire [  1:0]  dma_arburst_w;
wire          dma_rready_w;
wire          dma_arready_w;
wire          dma_rvalid_w;
wire [ 31:0]  dma_rdata_w;
wire [  1:0]  dma_rresp_w;
wire [  3:0]  dma_rid_w;
wire          dma_rlast_w;

dma_core_read
#(
     .AXI_ID(AXI_ID)
)
u_flow_read
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)

    // Request
    ,.req_valid_i(m2p_req_r)
    ,.req_addr_i(m2p_req_addr_r)
    ,.req_length_i(m2p_req_length_r)
    ,.req_mode_decr_i(m2p_req_mode_decr_r)
    ,.req_ch_i(m2p_req_ch_r)
    ,.req_accept_o(m2p_req_accept_w)

    // Status
    ,.sts_complete_o(m2p_sts_complete_w)
    ,.sts_length_o(m2p_sts_length_w)
    ,.sts_ch_o()

    // Output stream to peripheral
    ,.stream_valid_o(m2p_stream_valid_w)
    ,.stream_data_o(m2p_stream_data_w)
    ,.stream_accept_i(m2p_stream_accept_w)

    // Memory access
    ,.outport_arvalid_o(dma_arvalid_w)
    ,.outport_araddr_o(dma_araddr_w)
    ,.outport_arid_o(dma_arid_w)
    ,.outport_arlen_o(dma_arlen_w)
    ,.outport_arburst_o(dma_arburst_w)
    ,.outport_arsize_o()
    ,.outport_rready_o(dma_rready_w)
    ,.outport_arready_i(dma_arready_w)
    ,.outport_rvalid_i(dma_rvalid_w)
    ,.outport_rdata_i(dma_rdata_w)
    ,.outport_rresp_i(dma_rresp_w)
    ,.outport_rid_i(dma_rid_w)
    ,.outport_rlast_i(dma_rlast_w)

    // Unused write port
    ,.outport_awvalid_o()
    ,.outport_awaddr_o()
    ,.outport_awid_o()
    ,.outport_awlen_o()
    ,.outport_awburst_o()
    ,.outport_awsize_o()
    ,.outport_wvalid_o()
    ,.outport_wdata_o()
    ,.outport_wstrb_o()
    ,.outport_wlast_o()
    ,.outport_bready_o()
    ,.outport_awready_i(1'b0)
    ,.outport_wready_i(1'b0)
    ,.outport_bvalid_i(1'b0)
    ,.outport_bresp_i(2'b0)
    ,.outport_bid_i(4'b0)
);

// Hold arbitration choice whilst transfer in-progress
always @ (posedge clk_i )
if (rst_i)
    m2p_grant_q <= 7'b0;
else if (m2p_req_r && m2p_req_accept_w)
    m2p_grant_q <= m2p_grant_w;
else if (m2p_sts_complete_w)
    m2p_grant_q <= 7'b0;

//-----------------------------------------------------------------
// Arbitration: P2M
//-----------------------------------------------------------------
reg           p2m_req_r;
reg [ 31:0]   p2m_req_addr_r;
reg [ 31:0]   p2m_req_length_r;
reg           p2m_req_mode_decr_r;
reg [ 2:0]    p2m_req_ch_r;
wire          p2m_req_accept_w;

wire [6:0]    p2m_request_w;
wire [6:0]    p2m_grant_w;
reg  [6:0]    p2m_grant_q;

assign        p2m_request_w[0] = (ch0_req_valid_w & ~ch0_req_dir_m2p_w & ch0_master_en_w);
assign        p2m_request_w[1] = (ch1_req_valid_w & ~ch1_req_dir_m2p_w & ch1_master_en_w);
assign        p2m_request_w[2] = (ch2_req_valid_w & ~ch2_req_dir_m2p_w & ch2_master_en_w);
assign        p2m_request_w[3] = (ch3_req_valid_w & ~ch3_req_dir_m2p_w & ch3_master_en_w);
assign        p2m_request_w[4] = (ch4_req_valid_w & ~ch4_req_dir_m2p_w & ch4_master_en_w);
assign        p2m_request_w[5] = (ch5_req_valid_w & ~ch5_req_dir_m2p_w & ch5_master_en_w);
assign        p2m_request_w[6] = (ch6_req_valid_w & ~ch6_req_dir_m2p_w & ch6_master_en_w);

// TODO: Switch to fancy priority based arb (based on DPCR)
dma_rr_arb
u_p2m_arb
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)

    ,.hold_i(1'b0)
    ,.request_i(p2m_request_w)

    ,.grant_o(p2m_grant_w)
);

always @ *
begin
    p2m_req_r           = 1'b0;
    p2m_req_addr_r      = 32'b0;
    p2m_req_length_r    = 32'b0;
    p2m_req_mode_decr_r = 1'b0;
    p2m_req_ch_r        = 3'b0;

    case (1'b1)
    p2m_grant_w[0]:
    begin
        p2m_req_r           = ch0_req_valid_w & ~ch0_req_dir_m2p_w;
        p2m_req_addr_r      = ch0_req_addr_w;
        p2m_req_length_r    = ch0_req_length_w;
        p2m_req_mode_decr_r = ch0_req_mode_decr_w;
        p2m_req_ch_r        = 3'd0;
    end
    p2m_grant_w[1]:
    begin
        p2m_req_r           = ch1_req_valid_w & ~ch1_req_dir_m2p_w;
        p2m_req_addr_r      = ch1_req_addr_w;
        p2m_req_length_r    = ch1_req_length_w;
        p2m_req_mode_decr_r = ch1_req_mode_decr_w;
        p2m_req_ch_r        = 3'd1;
    end
    p2m_grant_w[2]:
    begin
        p2m_req_r           = ch2_req_valid_w & ~ch2_req_dir_m2p_w;
        p2m_req_addr_r      = ch2_req_addr_w;
        p2m_req_length_r    = ch2_req_length_w;
        p2m_req_mode_decr_r = ch2_req_mode_decr_w;
        p2m_req_ch_r        = 3'd2;
    end
    p2m_grant_w[3]:
    begin
        p2m_req_r           = ch3_req_valid_w & ~ch3_req_dir_m2p_w;
        p2m_req_addr_r      = ch3_req_addr_w;
        p2m_req_length_r    = ch3_req_length_w;
        p2m_req_mode_decr_r = ch3_req_mode_decr_w;
        p2m_req_ch_r        = 3'd3;
    end
    p2m_grant_w[4]:
    begin
        p2m_req_r           = ch4_req_valid_w & ~ch4_req_dir_m2p_w;
        p2m_req_addr_r      = ch4_req_addr_w;
        p2m_req_length_r    = ch4_req_length_w;
        p2m_req_mode_decr_r = ch4_req_mode_decr_w;
        p2m_req_ch_r        = 3'd4;
    end
    p2m_grant_w[5]:
    begin
        p2m_req_r           = ch5_req_valid_w & ~ch5_req_dir_m2p_w;
        p2m_req_addr_r      = ch5_req_addr_w;
        p2m_req_length_r    = ch5_req_length_w;
        p2m_req_mode_decr_r = ch5_req_mode_decr_w;
        p2m_req_ch_r        = 3'd5;
    end
    p2m_grant_w[6]:
    begin
        p2m_req_r           = ch6_req_valid_w & ~ch6_req_dir_m2p_w;
        p2m_req_addr_r      = ch6_req_addr_w;
        p2m_req_length_r    = ch6_req_length_w;
        p2m_req_mode_decr_r = 1'b1; // Fixed mode for OT channel
        p2m_req_ch_r        = 3'd6;
    end
    endcase
end

//-----------------------------------------------------------------
// Peripheral -> Memory input stream routing
//-----------------------------------------------------------------
reg         p2m_stream_valid_r;
reg [31:0]  p2m_stream_data_r;
wire        p2m_stream_accept_w;

always @ *
begin
    p2m_stream_valid_r  = 1'b0;
    p2m_stream_data_r   = 32'b0;

    case (1'b1)
    p2m_grant_q[1]:
    begin
        p2m_stream_valid_r  = mdec_p2m_valid_i;
        p2m_stream_data_r   = mdec_p2m_data_i;
    end
    p2m_grant_q[2]:
    begin
        p2m_stream_valid_r  = gpu_p2m_valid_i;
        p2m_stream_data_r   = gpu_p2m_data_i;
    end
    p2m_grant_q[3]:
    begin
        p2m_stream_valid_r  = cdrom_p2m_valid_i;
        p2m_stream_data_r   = cdrom_p2m_data_i;
    end
    p2m_grant_q[4]:
    begin
        p2m_stream_valid_r  = spu_p2m_valid_i;
        p2m_stream_data_r   = spu_p2m_data_i;
    end
    p2m_grant_q[5]:
    begin
        p2m_stream_valid_r  = pio_p2m_valid_i;
        p2m_stream_data_r   = pio_p2m_data_i;
    end
    endcase
end

assign mdec_p2m_accept_o  = p2m_grant_q[1] & p2m_stream_accept_w;
assign gpu_p2m_accept_o   = p2m_grant_q[2] & p2m_stream_accept_w;
assign cdrom_p2m_accept_o = p2m_grant_q[3] & p2m_stream_accept_w;
assign spu_p2m_accept_o   = p2m_grant_q[4] & p2m_stream_accept_w;
assign pio_p2m_accept_o   = p2m_grant_q[5] & p2m_stream_accept_w;

//-----------------------------------------------------------------
// Peripheral -> Memory transfer core
//-----------------------------------------------------------------
wire        p2m_sts_complete_w;
wire [31:0] p2m_sts_length_w;

dma_core_write
#(
     .AXI_ID(AXI_ID)
)
u_flow_write
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)

    // Transfer request
    ,.req_valid_i(p2m_req_r)
    ,.req_addr_i(p2m_req_addr_r)
    ,.req_length_i(p2m_req_length_r)
    ,.req_mode_decr_i(p2m_req_mode_decr_r)
    ,.req_mode_ot_i(p2m_req_ch_r == 3'd6)
    ,.req_mode_ot_last_i(p2m_req_ch_r == 3'd6) // TODO: Will need tweaking for chopped mode
    ,.req_ch_i(p2m_req_ch_r)
    ,.req_accept_o(p2m_req_accept_w)

    // Completion status
    ,.sts_complete_o(p2m_sts_complete_w)
    ,.sts_length_o(p2m_sts_length_w)
    ,.sts_ch_o()

    // Input stream from peripheral
    ,.stream_valid_i(p2m_stream_valid_r)
    ,.stream_data_i(p2m_stream_data_r)
    ,.stream_accept_o(p2m_stream_accept_w)

    // Memory access
    ,.outport_awvalid_o(mem_awvalid_o)
    ,.outport_awaddr_o(mem_awaddr_o)
    ,.outport_awid_o(mem_awid_o)
    ,.outport_awlen_o(mem_awlen_o)
    ,.outport_awburst_o(mem_awburst_o)
    ,.outport_awsize_o()
    ,.outport_wvalid_o(mem_wvalid_o)
    ,.outport_wdata_o(mem_wdata_o)
    ,.outport_wstrb_o(mem_wstrb_o)
    ,.outport_wlast_o(mem_wlast_o)
    ,.outport_bready_o(mem_bready_o)
    ,.outport_awready_i(mem_awready_i)
    ,.outport_wready_i(mem_wready_i)
    ,.outport_bvalid_i(mem_bvalid_i)
    ,.outport_bresp_i(mem_bresp_i)
    ,.outport_bid_i(mem_bid_i)

    // Unused read port
    ,.outport_arvalid_o()
    ,.outport_araddr_o()
    ,.outport_arid_o()
    ,.outport_arlen_o()
    ,.outport_arburst_o()
    ,.outport_arsize_o()
    ,.outport_rready_o()
    ,.outport_arready_i(1'b0)
    ,.outport_rvalid_i(1'b0)
    ,.outport_rdata_i(32'b0)
    ,.outport_rresp_i(2'b0)
    ,.outport_rid_i(4'b0)
    ,.outport_rlast_i(1'b0)
);

// Hold arbitration choice whilst transfer in-progress
always @ (posedge clk_i )
if (rst_i)
    p2m_grant_q <= 7'b0;
else if (p2m_req_r && p2m_req_accept_w)
    p2m_grant_q <= p2m_grant_w;
else if (p2m_sts_complete_w)
    p2m_grant_q <= 7'b0;

//-----------------------------------------------------------------
// Transfer request accept
//-----------------------------------------------------------------
assign ch0_req_accept_w = ch0_req_dir_m2p_w ? (m2p_grant_w[0] & m2p_req_accept_w) :
                                                      (p2m_grant_w[0] & p2m_req_accept_w);
assign ch1_req_accept_w = ch1_req_dir_m2p_w ? (m2p_grant_w[1] & m2p_req_accept_w) :
                                                      (p2m_grant_w[1] & p2m_req_accept_w);
assign ch2_req_accept_w = ch2_req_dir_m2p_w ? (m2p_grant_w[2] & m2p_req_accept_w) :
                                                      (p2m_grant_w[2] & p2m_req_accept_w);
assign ch3_req_accept_w = ch3_req_dir_m2p_w ? (m2p_grant_w[3] & m2p_req_accept_w) :
                                                      (p2m_grant_w[3] & p2m_req_accept_w);
assign ch4_req_accept_w = ch4_req_dir_m2p_w ? (m2p_grant_w[4] & m2p_req_accept_w) :
                                                      (p2m_grant_w[4] & p2m_req_accept_w);
assign ch5_req_accept_w = ch5_req_dir_m2p_w ? (m2p_grant_w[5] & m2p_req_accept_w) :
                                                      (p2m_grant_w[5] & p2m_req_accept_w);
assign ch6_req_accept_w = ch6_req_dir_m2p_w ? (m2p_grant_w[6] & m2p_req_accept_w) :
                                                      (p2m_grant_w[6] & p2m_req_accept_w);

//-----------------------------------------------------------------
// Status / completion routing
//-----------------------------------------------------------------
assign ch0_sts_complete_w = (m2p_sts_complete_w & m2p_grant_q[0]) |
                                (p2m_sts_complete_w & p2m_grant_q[0]);
assign ch0_sts_length_w   = (m2p_sts_complete_w & m2p_grant_q[0]) ? m2p_sts_length_w : p2m_sts_length_w;
assign ch1_sts_complete_w = (m2p_sts_complete_w & m2p_grant_q[1]) |
                                (p2m_sts_complete_w & p2m_grant_q[1]);
assign ch1_sts_length_w   = (m2p_sts_complete_w & m2p_grant_q[1]) ? m2p_sts_length_w : p2m_sts_length_w;
assign ch2_sts_complete_w = (m2p_sts_complete_w & m2p_grant_q[2]) |
                                (p2m_sts_complete_w & p2m_grant_q[2]);
assign ch2_sts_length_w   = (m2p_sts_complete_w & m2p_grant_q[2]) ? m2p_sts_length_w : p2m_sts_length_w;
assign ch3_sts_complete_w = (m2p_sts_complete_w & m2p_grant_q[3]) |
                                (p2m_sts_complete_w & p2m_grant_q[3]);
assign ch3_sts_length_w   = (m2p_sts_complete_w & m2p_grant_q[3]) ? m2p_sts_length_w : p2m_sts_length_w;
assign ch4_sts_complete_w = (m2p_sts_complete_w & m2p_grant_q[4]) |
                                (p2m_sts_complete_w & p2m_grant_q[4]);
assign ch4_sts_length_w   = (m2p_sts_complete_w & m2p_grant_q[4]) ? m2p_sts_length_w : p2m_sts_length_w;
assign ch5_sts_complete_w = (m2p_sts_complete_w & m2p_grant_q[5]) |
                                (p2m_sts_complete_w & p2m_grant_q[5]);
assign ch5_sts_length_w   = (m2p_sts_complete_w & m2p_grant_q[5]) ? m2p_sts_length_w : p2m_sts_length_w;
assign ch6_sts_complete_w = (m2p_sts_complete_w & m2p_grant_q[6]) |
                                (p2m_sts_complete_w & p2m_grant_q[6]);
assign ch6_sts_length_w   = (m2p_sts_complete_w & m2p_grant_q[6]) ? m2p_sts_length_w : p2m_sts_length_w;

//-----------------------------------------------------------------
// 2 port AXI arbiter for muxing link descriptor word fetches in
//-----------------------------------------------------------------
dma_axi4_rd_arb
#(
     .PORT_SEL_H(0)
    ,.PORT_SEL_L(0)
)
u_axi_arb
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)

    // DMA read channel
    ,.inport0_arvalid_i(dma_arvalid_w)
    ,.inport0_araddr_i(dma_araddr_w)
    ,.inport0_arid_i(AXI_ID + 0)
    ,.inport0_arlen_i(dma_arlen_w)
    ,.inport0_arburst_i(dma_arburst_w)
    ,.inport0_rready_i(dma_rready_w)
    ,.inport0_arready_o(dma_arready_w)
    ,.inport0_rvalid_o(dma_rvalid_w)
    ,.inport0_rdata_o(dma_rdata_w)
    ,.inport0_rresp_o(dma_rresp_w)
    ,.inport0_rid_o(dma_rid_w)
    ,.inport0_rlast_o(dma_rlast_w)

    // GPU link list fetch port
    ,.inport1_arvalid_i(ch2_desc_fetch_w)
    ,.inport1_araddr_i(ch2_desc_addr_w)
    ,.inport1_arid_i(AXI_ID + 1)
    ,.inport1_arlen_i(8'b0)
    ,.inport1_arburst_i(2'b01)
    ,.inport1_rready_i(1'b1)
    ,.inport1_arready_o(ch2_desc_accept_w)
    ,.inport1_rvalid_o(ch2_desc_valid_w)
    ,.inport1_rdata_o(ch2_desc_data_w)
    ,.inport1_rresp_o()
    ,.inport1_rid_o()
    ,.inport1_rlast_o()

    ,.outport_arvalid_o(mem_arvalid_o)
    ,.outport_araddr_o(mem_araddr_o)
    ,.outport_arid_o(mem_arid_o)
    ,.outport_arlen_o(mem_arlen_o)
    ,.outport_arburst_o(mem_arburst_o)
    ,.outport_rready_o(mem_rready_o)
    ,.outport_arready_i(mem_arready_i)
    ,.outport_rvalid_i(mem_rvalid_i)
    ,.outport_rdata_i(mem_rdata_i)
    ,.outport_rresp_i(mem_rresp_i)
    ,.outport_rid_i(mem_rid_i)
    ,.outport_rlast_i(mem_rlast_i)
);

assign mem_awsize_o = 3'd2;
assign mem_arsize_o = 3'd2;

//-----------------------------------------------------------------
// CPU inhibit
//-----------------------------------------------------------------
// Apparently, the DMA being active stops the CPU from doing useful work.
// This seems unconscionable to designers of modern SoCs, but that's
// the behaviour we need to mimic.

wire p2m_busy_w = (|p2m_grant_q);
wire m2p_busy_w = (|m2p_grant_q);

reg dma_active_q;
reg dma_active_r;

always @ *
begin
    dma_active_r = dma_active_q;

    // DMA activate
    if ((p2m_req_r && p2m_req_accept_w) || (m2p_req_r && m2p_req_accept_w))
        dma_active_r = 1'b1;
    // DMA now in-active
    else if (!p2m_busy_w && !m2p_busy_w)
        dma_active_r = 1'b0;
end

always @ (posedge clk_i )
if (rst_i)
    dma_active_q <= 1'b0;
else
    dma_active_q <= dma_active_r;

assign cpu_inhibit_o = dma_active_q;

//-----------------------------------------------------------------
// Simulation Only
//-----------------------------------------------------------------
`ifdef verilator
reg [31:0] dbg_cycle_q;

always @ (posedge clk_i )
if (rst_i)
    dbg_cycle_q <= 32'b0;
else
    dbg_cycle_q <= dbg_cycle_q + 32'd1;

always @ (posedge clk_i)
begin
    if (p2m_req_r && p2m_req_accept_w && ~p2m_busy_w)
    begin
        case (p2m_req_ch_r)
        3'd1: $display("[DMA] Activating transfer CH1 (MDEC) (peripheral -> memory) %d bytes @ %0d", p2m_req_length_r, dbg_cycle_q);
        3'd2: $display("[DMA] Activating transfer CH2 (GPU) (peripheral -> memory) %d bytes @ %0d", p2m_req_length_r, dbg_cycle_q);
        3'd3: $display("[DMA] Activating transfer CH3 (CDROM) (peripheral -> memory) %d bytes @ %0d", p2m_req_length_r, dbg_cycle_q);
        3'd4: $display("[DMA] Activating transfer CH4 (SPU) (peripheral -> memory) %d bytes @ %0d", p2m_req_length_r, dbg_cycle_q);
        3'd5: $display("[DMA] Activating transfer CH5 (PIO) (peripheral -> memory) %d bytes @ %0d", p2m_req_length_r, dbg_cycle_q);
        3'd6: $display("[DMA] Activating transfer CH6 (GPU-OTC) (peripheral -> memory) %d bytes @ %0d", p2m_req_length_r, dbg_cycle_q);
        default : ;
        endcase
    end
    if (p2m_sts_complete_w)
    begin
        case (1'b1)
        p2m_grant_q[1]: $display("[DMA] Transfer complete CH1 (MDEC) (peripheral -> memory) @ %0d", dbg_cycle_q);
        p2m_grant_q[2]: $display("[DMA] Transfer complete CH2 (GPU) (peripheral -> memory) @ %0d", dbg_cycle_q);
        p2m_grant_q[3]: $display("[DMA] Transfer complete CH3 (CDROM) (peripheral -> memory) @ %0d", dbg_cycle_q);
        p2m_grant_q[4]: $display("[DMA] Transfer complete CH4 (SPU) (peripheral -> memory) @ %0d", dbg_cycle_q);
        p2m_grant_q[5]: $display("[DMA] Transfer complete CH5 (PIO) (peripheral -> memory) @ %0d", dbg_cycle_q);
        p2m_grant_q[6]: $display("[DMA] Transfer complete CH6 (GPU-OTC) (peripheral -> memory) @ %0d", dbg_cycle_q);
        endcase
    end

    if (m2p_req_r && m2p_req_accept_w && ~m2p_busy_w)
    begin
        case (m2p_req_ch_r)
        3'd0: $display("[DMA] Activating transfer CH0 (MDEC) (memory -> peripheral) %d bytes @ %0d", m2p_req_length_r, dbg_cycle_q);
        3'd2: $display("[DMA] Activating transfer CH2 (GPU) (memory -> peripheral) %d bytes @ %0d", m2p_req_length_r, dbg_cycle_q);
        3'd4: $display("[DMA] Activating transfer CH4 (SPU) (memory -> peripheral) %d bytes @ %0d", m2p_req_length_r, dbg_cycle_q);
        3'd5: $display("[DMA] Activating transfer CH5 (PIO) (memory -> peripheral) %d bytes @ %0d", m2p_req_length_r, dbg_cycle_q);
        default : ;
        endcase
    end
    if (m2p_sts_complete_w)
    begin
        case (1'b1)
        m2p_grant_q[0]: $display("[DMA] Transfer complete CH0 (MDEC) (memory -> peripheral) @ %0d", dbg_cycle_q);
        m2p_grant_q[2]: $display("[DMA] Transfer complete CH2 (GPU) (memory -> peripheral) @ %0d", dbg_cycle_q);
        m2p_grant_q[4]: $display("[DMA] Transfer complete CH4 (SPU) (memory -> peripheral) @ %0d", dbg_cycle_q);
        m2p_grant_q[5]: $display("[DMA] Transfer complete CH5 (PIO) (memory -> peripheral) @ %0d", dbg_cycle_q);
        endcase
    end
end

`endif

//-------------------------------------------------------------
// Simulation Helpers
//-------------------------------------------------------------
`ifdef verilator

function [0:0] get_m2p_valid; /*verilator public*/
begin
    get_m2p_valid = m2p_stream_valid_w & m2p_stream_accept_w;
end
endfunction
function [31:0] get_m2p_data; /*verilator public*/
begin
    get_m2p_data = m2p_stream_data_w;
end
endfunction
function [6:0] get_m2p_chan; /*verilator public*/
begin
    get_m2p_chan = m2p_grant_q;
end
endfunction

function [0:0] get_p2m_valid; /*verilator public*/
begin
    get_p2m_valid = p2m_stream_valid_r & p2m_stream_accept_w;
end
endfunction
function [31:0] get_p2m_data; /*verilator public*/
begin
    get_p2m_data = p2m_stream_data_r;
end
endfunction
function [6:0] get_p2m_chan; /*verilator public*/
begin
    get_p2m_chan = p2m_grant_q;
end
endfunction

`endif


endmodule
