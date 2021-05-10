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
module cdrom_ctrl
(
    // Inputs
     input           clk_i
    ,input           rst_i
    ,input  [ 31:0]  cfg_psf_addr_i
    ,input  [ 31:0]  cfg_psf_data_wr_i
    ,input           cfg_psf_stb_i
    ,input           cfg_psf_cyc_i
    ,input  [  3:0]  cfg_psf_sel_i
    ,input           cfg_psf_we_i
    ,input  [ 31:0]  cfg_int_addr_i
    ,input  [ 31:0]  cfg_int_data_wr_i
    ,input           cfg_int_stb_i
    ,input           cfg_int_we_i
    ,input           cdrom_p2m_accept_i
    ,input           cdrom_p2m_dma_en_i
    ,input  [ 31:0]  cdrom_p2m_dma_bs_i
    ,input  [ 31:0]  gpio_in_i
    ,input           axi_awready_i
    ,input           axi_wready_i
    ,input           axi_bvalid_i
    ,input  [  1:0]  axi_bresp_i
    ,input  [  3:0]  axi_bid_i
    ,input           axi_arready_i
    ,input           axi_rvalid_i
    ,input  [ 31:0]  axi_rdata_i
    ,input  [  1:0]  axi_rresp_i
    ,input  [  3:0]  axi_rid_i
    ,input           axi_rlast_i

    // Outputs
    ,output [ 31:0]  cfg_psf_data_rd_o
    ,output          cfg_psf_stall_o
    ,output          cfg_psf_ack_o
    ,output          cfg_psf_err_o
    ,output          irq_o
    ,output [ 31:0]  cfg_int_data_rd_o
    ,output          cfg_int_ack_o
    ,output          cfg_int_stall_o
    ,output          device_reset_o
    ,output          cdrom_p2m_dreq_o
    ,output          cdrom_p2m_valid_o
    ,output [ 31:0]  cdrom_p2m_data_o
    ,output [ 31:0]  gpio_out_o
    ,output          axi_awvalid_o
    ,output [ 31:0]  axi_awaddr_o
    ,output [  3:0]  axi_awid_o
    ,output [  7:0]  axi_awlen_o
    ,output [  1:0]  axi_awburst_o
    ,output [  2:0]  axi_awsize_o
    ,output          axi_wvalid_o
    ,output [ 31:0]  axi_wdata_o
    ,output [  3:0]  axi_wstrb_o
    ,output          axi_wlast_o
    ,output          axi_bready_o
    ,output          axi_arvalid_o
    ,output [ 31:0]  axi_araddr_o
    ,output [  3:0]  axi_arid_o
    ,output [  7:0]  axi_arlen_o
    ,output [  1:0]  axi_arburst_o
    ,output [  2:0]  axi_arsize_o
    ,output          axi_rready_o
);




//-----------------------------------------------------------------
// TODO:
// - Sound map stuff is non-existant
//-----------------------------------------------------------------

// Index selection
reg [1:0] cfg_index_q;
wire index0_w = (cfg_index_q == 2'd0);
wire index1_w = (cfg_index_q == 2'd1);
wire index2_w = (cfg_index_q == 2'd2);
wire index3_w = (cfg_index_q == 2'd3);

wire reg_write_w   = cfg_psf_stb_i && ~cfg_psf_stall_o &&  cfg_psf_we_i;
wire reg_read_w    = cfg_psf_stb_i && ~cfg_psf_stall_o && ~cfg_psf_we_i;

wire reg_addr0_3_w = ({cfg_psf_addr_i[7:2], 2'b0} == 8'd0);
wire addr_plus0_w  = cfg_psf_sel_i[0];
wire addr_plus1_w  = cfg_psf_sel_i[1];
wire addr_plus2_w  = cfg_psf_sel_i[2];
wire addr_plus3_w  = cfg_psf_sel_i[3];

wire [7:0] psf_wr_data0_w = cfg_psf_data_wr_i[7:0];
wire [7:0] psf_wr_data1_w = cfg_psf_data_wr_i[15:8];
wire [7:0] psf_wr_data2_w = cfg_psf_data_wr_i[23:16];
wire [7:0] psf_wr_data3_w = cfg_psf_data_wr_i[31:24];

wire addr1800_w = reg_addr0_3_w && addr_plus0_w;
wire addr1801_w = reg_addr0_3_w && addr_plus1_w;
wire addr1802_w = reg_addr0_3_w && addr_plus2_w;
wire addr1803_w = reg_addr0_3_w && addr_plus3_w;

// 1F801800h - Index/Status Register (Bit0-1 R/W)
wire reg0_write_w = reg_write_w && addr1800_w;
wire reg0_read_w  = reg_read_w  && addr1800_w;

// 1F801801h.Index0 - Command Register (W)
wire reg1_write_cmd_w   = reg_write_w && addr1801_w && index0_w;

// 1F801802h.Index0 - Parameter Fifo (W)
wire reg2_write_param_w = reg_write_w && addr1802_w && index0_w;

// 1F801803h.Index0 - Request Register (W)
wire reg3_write_req_w   = reg_write_w && addr1803_w && index0_w;

// 1F801802h.Index0..3 - Data Fifo - 8bit/16bit (R)
wire reg2_read_dat_fifo_w   = reg_read_w && addr1802_w;
wire reg2_read_dat_fifo8_w  = reg2_read_dat_fifo_w & addr_plus2_w & ~addr_plus3_w;
wire reg2_read_dat_fifo16_w = reg2_read_dat_fifo_w & addr_plus2_w &  addr_plus3_w;

// 1F801801h.Index1 - Response Fifo (R)
// 1F801801h.Index0,2,3 - Response Fifo (R) (Mirrors)
wire reg1_read_res_fifo_w = reg_read_w && addr1801_w;

// 1F801802h.Index1 - Interrupt Enable Register (W)
wire reg2_write_int_en_w = reg_write_w && addr1802_w && index1_w;

// 1F801803h.Index0 - Interrupt Enable Register (R)
// 1F801803h.Index2 - Interrupt Enable Register (R) (Mirror)
wire reg3_read_int_en_w = reg_read_w && addr1803_w && (index0_w || index2_w);

// 1F801803h.Index1 - Interrupt Flag Register (R/W)
wire reg3_write_int_flag_w = reg_write_w && addr1803_w && index1_w;

// 1F801803h.Index1 - Interrupt Flag Register (R)
// 1F801803h.Index3 - Interrupt Flag Register (R) (Mirror)
wire reg3_read_int_flag_w = reg_read_w && addr1803_w && (index1_w || index3_w);

// 1F801802h.Index2 - Audio Volume for Left-CD-Out to Left-SPU-Input (W)
wire reg2_write_audl_cdl_vol_w = reg_write_w && addr1802_w && index2_w;

// 1F801803h.Index2 - Audio Volume for Left-CD-Out to Right-SPU-Input (W)
wire reg3_write_audl_cdr_vol_w = reg_write_w && addr1803_w && index2_w;

// 1F801801h.Index3 - Audio Volume for Right-CD-Out to Right-SPU-Input (W)
wire reg1_write_audr_cdl_vol_w = reg_write_w && addr1801_w && index3_w;

// 1F801802h.Index3 - Audio Volume for Right-CD-Out to Left-SPU-Input (W)
wire reg2_write_audr_cdr_vol_w = reg_write_w && addr1802_w && index3_w;

// 1F801803h.Index3 - Audio Volume Apply Changes (by writing bit5=1)
wire reg3_write_apply_vol_w = reg_write_w && addr1803_w && index3_w;

// 1F801801h.Index1 - Sound Map Data Out (W)
wire reg1_write_snd_map_dat_w = reg_write_w && addr1801_w && index1_w;

// 1F801801h.Index2 - Sound Map Coding Info (W)
wire reg1_write_snd_map_cdi_w = reg_write_w && addr1801_w && index2_w;

// Custom (debug registers)

// 1F801804h - Debug register 0
wire reg_read_debug0_w = reg_read_w && (cfg_psf_addr_i[7:0] == 8'h04);

// 1F801808h - Debug register 1
wire reg_read_debug1_w = reg_read_w && (cfg_psf_addr_i[7:0] == 8'h08);

//-----------------------------------------------------------------
// INT access
//-----------------------------------------------------------------
wire        int_cmd_read_w;
wire        int_clear_busy_w;
wire        int_clear_param_fifo_w;
wire        int_clear_resp_fifo_w;
wire        int_clear_data_fifo_w;
wire        int_clear_cdrom_w;

wire        int_resp_fifo_push_w;
wire [7:0]  int_resp_fifo_in_w;
wire        int_resp_fifo_space_w;

wire        int_data_fifo_push_w;
wire [31:0] int_data_fifo_data_w;
wire        int_data_fifo_accept_w;

wire [7:0]  int_irq_raise_w;

wire [31:0] int_debug0_w;

//-----------------------------------------------------------------
// Status bits
//-----------------------------------------------------------------
wire sts_adpbusy_w; // ADPBUSY XA-ADPCM fifo empty  (0=Empty) ;set when playing XA-ADPCM sound
wire sts_prmempt_w; // PRMEMPT Parameter fifo empty (1=Empty) ;triggered before writing 1st byte
wire sts_prmwrdy_w; // PRMWRDY Parameter fifo full  (0=Full)  ;triggered after writing 16 bytes
wire sts_rslrrdy_w; // RSLRRDY Response fifo empty  (0=Empty) ;triggered after reading LAST byte
wire sts_drqsts_w;  // DRQSTS  Data fifo empty      (0=Empty) ;triggered after reading LAST byte
wire sts_busysts_w; // BUSYSTS Command/parameter transmission busy  (1=Busy)

assign sts_adpbusy_w = 1'b0; // TODO: set when playing XA-ADPCM sound?

//-----------------------------------------------------------------
// 1F801800h - Index/Status Register (Bit0-1 R/W) (Bit2-7 Read Only)
//-----------------------------------------------------------------
// 0-1 Index   Port 1F801801h-1F801803h index (0..3 = Index0..Index3)   (R/W)
always @ (posedge clk_i )
if (rst_i)
    cfg_index_q <= 2'b0;
else if (reg0_write_w)
    cfg_index_q <= cfg_psf_data_wr_i[1:0];

//-----------------------------------------------------------------
// 1F801801h.Index0 - Command Register (W)
//-----------------------------------------------------------------
reg [7:0] cmd_value_q;

always @ (posedge clk_i )
if (rst_i)
    cmd_value_q <= 8'b0;
else if (reg1_write_cmd_w)
    cmd_value_q <= psf_wr_data1_w;

reg cmd_pending_r;
reg cmd_pending_q;

reg sts_busy_r;
reg sts_busy_q;

always @ *
begin
    cmd_pending_r = cmd_pending_q;
    sts_busy_r    = sts_busy_q;

    // INT consumes command
    if (int_cmd_read_w)
        cmd_pending_r = 1'b0;

    // INT SW request to clear busy status
    if (int_clear_busy_w)
        sts_busy_r = 1'b0;

    // PSF writes command
    if (reg1_write_cmd_w)
    begin
        cmd_pending_r = 1'b1;
        sts_busy_r    = 1'b1;
    end
end

always @ (posedge clk_i )
if (rst_i)
begin
    cmd_pending_q <= 1'b0;
    sts_busy_q    <= 1'b0;
end
else if (device_reset_o)
begin
    cmd_pending_q <= 1'b0;
    sts_busy_q    <= 1'b0;
end
else
begin
    cmd_pending_q <= cmd_pending_r;
    sts_busy_q    <= sts_busy_r;
end

// BUSYSTS - command pending
assign sts_busysts_w = sts_busy_q;

//-----------------------------------------------------------------
// 1F801802h.Index0 - Parameter Fifo (W)
//-----------------------------------------------------------------
wire       param_fifo_valid_w;
wire [7:0] param_fifo_data_w;
wire       param_fifo_pop_w;
wire       param_fifo_space_w;
wire [4:0] param_fifo_level_w;
wire       param_fifo_reset_w;

cdrom_ctrl_fifo
#( // TODO: Check depth
     .WIDTH(8)
    ,.DEPTH(16)
    ,.ADDR_W(4)
)
u_param_fifo
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)

    ,.flush_i(param_fifo_reset_w | int_clear_param_fifo_w | device_reset_o)

    ,.push_i(reg2_write_param_w)
    ,.data_in_i(psf_wr_data2_w)
    ,.accept_o(param_fifo_space_w)

    ,.valid_o(param_fifo_valid_w)
    ,.data_out_o(param_fifo_data_w)
    ,.pop_i(param_fifo_pop_w)

    ,.level_o(param_fifo_level_w)
);

// PRMEMPT Parameter fifo empty (1=Empty)
assign sts_prmempt_w = ~param_fifo_valid_w; 

// PRMWRDY Parameter fifo full  (0=Full)
assign sts_prmwrdy_w = param_fifo_space_w;

//-----------------------------------------------------------------
// 1F801803h.Index0 - Request Register (W)
//-----------------------------------------------------------------
/*
  0-4 0    Not used (should be zero)
  5   SMEN Want Command Start Interrupt on Next Command (0=No change, 1=Yes)
  6   BFWR ...
  7   BFRD Want Data         (0=No/Reset Data Fifo, 1=Yes/Load Data Fifo)
*/

reg req_smen_q;
reg req_bfwr_q;
reg req_bfrd_q;

always @ (posedge clk_i )
if (rst_i)
    req_smen_q <= 1'b0;
else if (reg3_write_req_w)
    req_smen_q <= psf_wr_data3_w[5];

always @ (posedge clk_i )
if (rst_i)
    req_bfwr_q <= 1'b0;
else if (reg3_write_req_w)
    req_bfwr_q <= psf_wr_data3_w[6];

always @ (posedge clk_i )
if (rst_i)
    req_bfrd_q <= 1'b0;
else if (reg3_write_req_w)
    req_bfrd_q <= psf_wr_data3_w[7];

wire bfrd_clr_inhibit_w;

wire event_bfrd_rise_w = reg3_write_req_w & (!req_bfrd_q && psf_wr_data3_w[7]);
wire event_bfrd_fall_w = reg3_write_req_w & (req_bfrd_q  && !psf_wr_data3_w[7]);

// NOTE: Edge detecting behaviour needs checking...
wire data_fifo_reset_w = event_bfrd_fall_w && ~bfrd_clr_inhibit_w;

//-----------------------------------------------------------------
// Response FIFO
// 1F801801h.Index1 - Response Fifo (R)
// 1F801801h.Index0,2,3 - Response Fifo (R) (Mirrors)
//-----------------------------------------------------------------
wire       resp_fifo_valid_w;
wire [7:0] resp_fifo_data_w;
wire [4:0] resp_fifo_level_w;

cdrom_ctrl_fifo
#(
     .WIDTH(8)
    ,.DEPTH(16)
    ,.ADDR_W(4)
)
u_resp_fifo
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)

    ,.flush_i(int_clear_resp_fifo_w | device_reset_o)

    ,.push_i(int_resp_fifo_push_w)
    ,.data_in_i(int_resp_fifo_in_w)
    ,.accept_o(int_resp_fifo_space_w)

    ,.valid_o(resp_fifo_valid_w)
    ,.data_out_o(resp_fifo_data_w)
    ,.pop_i(reg1_read_res_fifo_w)

    ,.level_o(resp_fifo_level_w)
);

// RSLRRDY Response fifo empty (0=Empty)
assign sts_rslrrdy_w = resp_fifo_valid_w;

//-----------------------------------------------------------------
// Data FIFO (4KB / 1024x32)
//-----------------------------------------------------------------
wire        data_fifo_valid_w;
wire [31:0] data_fifo_out_w;
wire        data_fifo_pop_w;

cdrom_data_fifo
u_data_fifo
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)

    ,.flush_i(int_clear_data_fifo_w | data_fifo_reset_w | device_reset_o)

    ,.push_i(int_data_fifo_push_w)
    ,.data_in_i(int_data_fifo_data_w)
    ,.accept_o(int_data_fifo_accept_w)

    ,.valid_o(data_fifo_valid_w)
    ,.data_out_o(data_fifo_out_w)
    ,.pop_i(data_fifo_pop_w)
);

// DRQSTS / Data fifo empty = 0
assign sts_drqsts_w = data_fifo_valid_w;

//-----------------------------------------------------------------
// Data FIFO unroller
//-----------------------------------------------------------------
reg [1:0] data_idx_q;
reg [1:0] data_idx_r;

wire data_consume1_w = reg2_read_dat_fifo_w & reg2_read_dat_fifo8_w;
wire data_consume2_w = reg2_read_dat_fifo_w & reg2_read_dat_fifo16_w;

always @ *
begin
    data_idx_r = data_idx_q;

    if (data_consume2_w)
        data_idx_r = data_idx_r + 2'd2;
    else if (data_consume1_w)
        data_idx_r = data_idx_r + 2'd1;

    if (int_clear_data_fifo_w || device_reset_o)
        data_idx_r = 2'b0;
end

always @ (posedge clk_i )
if (rst_i)
    data_idx_q <= 2'b0;
else
    data_idx_q <= data_idx_r;

// Re-aligned FIFO data for PSF CPU access (8 / 16-bit)
reg [15:0] psf_fifo_data_r;

always @ *
begin
    psf_fifo_data_r = 16'b0;

    case (data_idx_q)
    2'd0:    psf_fifo_data_r = data_fifo_out_w[15:0];
    2'd1:    psf_fifo_data_r = data_fifo_out_w[23:8];
    2'd2:    psf_fifo_data_r = data_fifo_out_w[31:16];
    default: psf_fifo_data_r = {8'b0, data_fifo_out_w[31:24]};
    endcase
end

wire psf_data_pop_w = (data_idx_q == 2'd3 && (data_consume1_w || data_consume2_w)) || 
                      (data_idx_q == 2'd2 && data_consume2_w);

wire dma_data_pop_w    = cdrom_p2m_accept_i && cdrom_p2m_dma_en_i;

assign data_fifo_pop_w = dma_data_pop_w | psf_data_pop_w; 

//-----------------------------------------------------------------
// Data FIFO Level
//-----------------------------------------------------------------
reg [15:0] data_level_r;
reg [15:0] data_level_q;

always @ *
begin
    data_level_r = data_level_q;

    if (data_fifo_valid_w && data_fifo_pop_w)
        data_level_r = data_level_r - 16'd1;

    if (int_data_fifo_push_w && int_data_fifo_accept_w)
        data_level_r = data_level_r + 16'd1;

    if (int_clear_data_fifo_w || device_reset_o)
        data_level_r = 16'b0;
end

always @ (posedge clk_i )
if (rst_i)
    data_level_q <= 16'b0;
else
    data_level_q <= data_level_r;

wire data_level_half_w = data_level_q < 16'd512;

//-----------------------------------------------------------------
// DMA data interface
//-----------------------------------------------------------------
wire dma_dreq_inhibit_w;

assign cdrom_p2m_valid_o = cdrom_p2m_dma_en_i & data_fifo_valid_w;
assign cdrom_p2m_data_o  = data_fifo_out_w;

reg cdrom_p2m_dreq_q;

// TODO: Check signal timing between DMA block turnaround and data_level_q update..
always @ (posedge clk_i )
if (rst_i)
    cdrom_p2m_dreq_q <= 1'b0;
else
    cdrom_p2m_dreq_q <= cdrom_p2m_dma_en_i && ({16'b0, data_level_q} >= cdrom_p2m_dma_bs_i) && ~dma_dreq_inhibit_w;

assign cdrom_p2m_dreq_o = cdrom_p2m_dreq_q;

//-----------------------------------------------------------------
// 1F801802h.Index2 - Audio Volume for Left-CD-Out to Left-SPU-Input (W)
// 1F801803h.Index2 - Audio Volume for Left-CD-Out to Right-SPU-Input (W)
// 1F801801h.Index3 - Audio Volume for Right-CD-Out to Right-SPU-Input (W)
// 1F801802h.Index3 - Audio Volume for Right-CD-Out to Left-SPU-Input (W)
//-----------------------------------------------------------------
reg [7:0] audl_cdl_vol_q;

always @ (posedge clk_i )
if (rst_i)
    audl_cdl_vol_q <= 8'b0;
else if (reg2_write_audl_cdl_vol_w)
    audl_cdl_vol_q <= psf_wr_data2_w;

reg [7:0] audl_cdr_vol_q;

always @ (posedge clk_i )
if (rst_i)
    audl_cdr_vol_q <= 8'b0;
else if (reg3_write_audl_cdr_vol_w)
    audl_cdr_vol_q <= psf_wr_data3_w;

reg [7:0] audr_cdl_vol_q;

always @ (posedge clk_i )
if (rst_i)
    audr_cdl_vol_q <= 8'b0;
else if (reg1_write_audr_cdl_vol_w)
    audr_cdl_vol_q <= psf_wr_data1_w;

reg [7:0] audr_cdr_vol_q;

always @ (posedge clk_i )
if (rst_i)
    audr_cdr_vol_q <= 8'b0;
else if (reg2_write_audr_cdr_vol_w)
    audr_cdr_vol_q <= psf_wr_data2_w;

//-----------------------------------------------------------------
// 1F801801h.Index1 - Sound Map Data Out (W)
// 1F801801h.Index2 - Sound Map Coding Info (W)
//-----------------------------------------------------------------
reg [7:0] snd_map_dat_q;

always @ (posedge clk_i )
if (rst_i)
    snd_map_dat_q <= 8'b0;
else if (reg1_write_snd_map_dat_w)
    snd_map_dat_q <= psf_wr_data1_w;

reg [7:0] snd_map_cdi_q;

always @ (posedge clk_i )
if (rst_i)
    snd_map_cdi_q <= 8'b0;
else if (reg1_write_snd_map_cdi_w)
    snd_map_cdi_q <= psf_wr_data1_w;

// TODO: Read side

//-----------------------------------------------------------------
// 1F801803h.Index3 - Audio Volume Apply Changes
//-----------------------------------------------------------------
reg snd_adpmute_q;

always @ (posedge clk_i )
if (rst_i)
    snd_adpmute_q <= 1'b0;
else if (reg3_write_apply_vol_w)
    snd_adpmute_q <= psf_wr_data3_w[0];

reg snd_chngatv_q;

always @ (posedge clk_i )
if (rst_i)
    snd_chngatv_q <= 1'b0;
else if (reg3_write_apply_vol_w)
    snd_chngatv_q <= psf_wr_data3_w[5];
// Self clearing...
else
    snd_chngatv_q <= 1'b0;

//-----------------------------------------------------------------
// 1F801802h.Index1 - Interrupt Enable Register (W)
//-----------------------------------------------------------------
reg [4:0] int_en_q;

always @ (posedge clk_i )
if (rst_i)
    int_en_q <= 5'b0;
else if (reg2_write_int_en_w)
    int_en_q <= psf_wr_data2_w[4:0];

//-----------------------------------------------------------------
// 1F801803h.Index1 - Interrupt Flag Register (R/W)
//-----------------------------------------------------------------
reg [4:0] int_sts_q;
reg [4:0] int_sts_r;

always @ *
begin
    int_sts_r = int_sts_q;

    if (reg3_write_int_flag_w)
        int_sts_r = int_sts_r & ~psf_wr_data3_w[4:0];

    int_sts_r = int_sts_r | int_irq_raise_w[4:0];
end

always @ (posedge clk_i )
if (rst_i)
    int_sts_q <= 5'b0;
else
    int_sts_q <= int_sts_r;

reg chprst_q;
reg chprst_written_q;

// Chip reset
always @ (posedge clk_i )
if (rst_i)
begin
    chprst_q         <= 1'b1;
    chprst_written_q <= 1'b0;
end
else if (reg3_write_int_flag_w)
begin
    chprst_q         <= psf_wr_data3_w[7];
    chprst_written_q <= 1'b1;
end
else if (int_clear_cdrom_w)
    chprst_q         <= 1'b1;
else if (chprst_written_q)
    chprst_q         <= 1'b0;

assign device_reset_o = chprst_q;

reg clrprm_q;

// Clear param FIFO
always @ (posedge clk_i )
if (rst_i)
    clrprm_q <= 1'b0;
else if (reg3_write_int_flag_w)
    clrprm_q <= psf_wr_data3_w[6];
else
    clrprm_q <= 1'b0;

assign param_fifo_reset_w = clrprm_q;

//-----------------------------------------------------------------
// IRQ (output to PSF)
//-----------------------------------------------------------------
reg irq_q;

always @ (posedge clk_i )
if (rst_i)
    irq_q <= 1'b0;
else
    irq_q <= |(int_en_q & int_sts_q);

assign irq_o = irq_q;

//-----------------------------------------------------------------
// PSF read response
//-----------------------------------------------------------------
reg [31:0] psf_data_rd_r;

always @ *
begin
    psf_data_rd_r = 32'b0;

    // 1F801800h - Index/Status Register
    if (reg0_read_w)
    begin
        /*  0-1 Index   Port 1F801801h-1F801803h index (0..3 = Index0..Index3)   (R/W)
            2   ADPBUSY XA-ADPCM fifo empty  (0=Empty) ;set when playing XA-ADPCM sound
            3   PRMEMPT Parameter fifo empty (1=Empty) ;triggered before writing 1st byte
            4   PRMWRDY Parameter fifo full  (0=Full)  ;triggered after writing 16 bytes
            5   RSLRRDY Response fifo empty  (0=Empty) ;triggered after reading LAST byte
            6   DRQSTS  Data fifo empty      (0=Empty) ;triggered after reading LAST byte
            7   BUSYSTS Command/parameter transmission busy  (1=Busy)
        */    
        psf_data_rd_r[1:0] = cfg_index_q;
        psf_data_rd_r[2]   = sts_adpbusy_w;
        psf_data_rd_r[3]   = sts_prmempt_w;
        psf_data_rd_r[4]   = sts_prmwrdy_w;
        psf_data_rd_r[5]   = sts_rslrrdy_w;
        psf_data_rd_r[6]   = sts_drqsts_w;
        psf_data_rd_r[7]   = sts_busysts_w;
    end

    // 1F801802h.Index0..3 - Data Fifo - 8bit/16bit (R)
    if (reg2_read_dat_fifo_w)
        psf_data_rd_r[31:16] = psf_fifo_data_r[15:0];

    // 1F801801h.Index1 - Response Fifo (R)
    // 1F801801h.Index0,2,3 - Response Fifo (R) (Mirrors)
    if (reg1_read_res_fifo_w)
        psf_data_rd_r[15:8] = resp_fifo_data_w;

    // 1F801803h.Index0 - Interrupt Enable Register (R)
    // 1F801803h.Index2 - Interrupt Enable Register (R) (Mirror)
    if (reg3_read_int_en_w)
        psf_data_rd_r[31:24] = {3'b111, int_en_q};

    // 1F801803h.Index1 - Interrupt Flag Register (R/W)
    if (reg3_read_int_flag_w)
        psf_data_rd_r[31:24] = {3'b111, int_sts_q};

    // 1F801804h - Debug register 0
    if (reg_read_debug0_w)
        psf_data_rd_r = int_debug0_w;

    // 1F801808h - Debug register 1
    if (reg_read_debug1_w)
        psf_data_rd_r = 32'b0;
end

reg [31:0] psf_data_rd_q;

always @ (posedge clk_i )
if (rst_i)
    psf_data_rd_q <= 32'b0;
else
    psf_data_rd_q <= psf_data_rd_r;

assign cfg_psf_data_rd_o = psf_data_rd_q;

reg psf_ack_q;

always @ (posedge clk_i )
if (rst_i)
    psf_ack_q <= 1'b0;
else if (cfg_psf_stb_i && ~cfg_psf_stall_o)
    psf_ack_q <= 1'b1;
else
    psf_ack_q <= 1'b0;

assign cfg_psf_ack_o     = psf_ack_q;
assign cfg_psf_stall_o   = psf_ack_q;
assign cfg_psf_err_o     = 1'b0;

//-----------------------------------------------------------------
// INT CPU Register Block
//-----------------------------------------------------------------
wire [3:0]   dma_status_level_w;
wire [31:0]  dma_fifo_data_w;
wire         dma_fetch_accept_w;
wire         dma_fetch_w;
wire [31:0]  dma_fetch_addr_w;
wire         dma_fifo_pop_w;

cdrom_int_regs
u_int_regs
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)

    ,.cfg_addr_i(cfg_int_addr_i)
    ,.cfg_data_wr_i(cfg_int_data_wr_i)
    ,.cfg_stb_i(cfg_int_stb_i)
    ,.cfg_we_i(cfg_int_we_i)
    ,.cfg_data_rd_o(cfg_int_data_rd_o)
    ,.cfg_ack_o(cfg_int_ack_o)
    ,.cfg_stall_o(cfg_int_stall_o)

    ,.command_valid_i(cmd_pending_q)
    ,.command_data_i(cmd_value_q)

    ,.param_valid_i(param_fifo_valid_w)
    ,.param_data_i(param_fifo_data_w)

    ,.vol_audl_cdl_i(audl_cdl_vol_q)
    ,.vol_audl_cdr_i(audl_cdr_vol_q)
    ,.vol_audr_cdl_i(audr_cdl_vol_q)
    ,.vol_audr_cdr_i(audr_cdr_vol_q)

    ,.status_adpmute_i(snd_adpmute_q)
    ,.status_smen_i(req_smen_q)
    ,.status_bfwr_i(req_bfwr_q)
    ,.status_bfrd_i(req_bfrd_q)
    ,.status_intf_i({3'b0, int_sts_q})

    ,.event_command_wr_i(reg1_write_cmd_w)
    ,.event_param_wr_i(reg2_write_param_w)
    ,.event_request_wr_i(reg3_write_req_w)
    ,.event_vol_apply_i(snd_chngatv_q)
    ,.event_snd_map_dat_wr_i(reg1_write_snd_map_dat_w)
    ,.event_snd_map_cdi_wr_i(reg1_write_snd_map_cdi_w)
    ,.event_bfrd_rise_i(event_bfrd_rise_w)

    ,.fifo_status_param_empty_i(~param_fifo_valid_w)
    ,.fifo_status_param_full_i(~param_fifo_space_w)
    ,.fifo_status_response_empty_i(~resp_fifo_valid_w)
    ,.fifo_status_response_full_i(~int_resp_fifo_space_w)
    ,.fifo_status_data_empty_i(~data_fifo_valid_w)
    ,.fifo_status_data_full_i(~int_data_fifo_accept_w)
    ,.fifo_status_data_half_i(data_level_half_w)

    ,.fifo_level_param_i({3'b0, param_fifo_level_w})
    ,.fifo_level_response_i({3'b0, resp_fifo_level_w})
    ,.fifo_level_data_i(data_level_q)

    ,.command_rd_o(int_cmd_read_w)
    ,.param_rd_o(param_fifo_pop_w)

    ,.response_wr_o(int_resp_fifo_push_w)
    ,.response_data_o(int_resp_fifo_in_w)

    ,.data_wr_o(int_data_fifo_push_w)
    ,.data_data_o(int_data_fifo_data_w)

    ,.dma_dreq_inhibit_o(dma_dreq_inhibit_w)
    ,.bfrd_clear_inhibit_o(bfrd_clr_inhibit_w)

    ,.int_raise_o(int_irq_raise_w)

    ,.clear_busy_o(int_clear_busy_w)
    ,.clear_param_fifo_o(int_clear_param_fifo_w)
    ,.clear_resp_fifo_o(int_clear_resp_fifo_w)
    ,.clear_data_fifo_o(int_clear_data_fifo_w)
    ,.clear_cdrom_o(int_clear_cdrom_w)

    ,.gpio_o(gpio_out_o)
    ,.gpio_i(gpio_in_i)

    ,.dma_status_level_i(dma_status_level_w)
    ,.dma_fifo_data_i(dma_fifo_data_w)
    ,.dma_fetch_accept_i(dma_fetch_accept_w)
    ,.dma_fetch_o(dma_fetch_w)
    ,.dma_fetch_addr_o(dma_fetch_addr_w)
    ,.dma_fifo_pop_o(dma_fifo_pop_w)

    ,.debug0_o(int_debug0_w)
);

//-----------------------------------------------------------------
// Data prefetch port
//-----------------------------------------------------------------
cdrom_ctrl_fifo
#(
     .WIDTH(32)
    ,.DEPTH(8)
    ,.ADDR_W(3)
)
u_fetch_fifo
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)

    ,.flush_i(1'b0)

    ,.push_i(axi_rvalid_i & axi_rready_o)
    ,.data_in_i(axi_rdata_i)
    ,.accept_o()

    ,.valid_o()
    ,.data_out_o(dma_fifo_data_w)
    ,.pop_i(dma_fifo_pop_w)

    ,.level_o(dma_status_level_w)
);

assign axi_arvalid_o = dma_fetch_w;
assign axi_araddr_o  = dma_fetch_addr_w;
assign axi_arid_o    = 4'd15;
assign axi_arlen_o   = 8'd7; // 32-bytes
assign axi_arburst_o = 2'd1;
assign axi_rready_o  = 1'b1;

assign dma_fetch_accept_w = axi_arready_i;

// Unused
assign axi_awvalid_o = 1'b0;
assign axi_awaddr_o  = 32'b0;
assign axi_awid_o    = 4'b0;
assign axi_awlen_o   = 8'b0;
assign axi_awburst_o = 2'd1;
assign axi_wvalid_o  = 1'b0;
assign axi_wdata_o   = 32'b0;
assign axi_wstrb_o   = 4'b0;
assign axi_wlast_o   = 1'b0;
assign axi_bready_o  = 1'b1;

//-----------------------------------------------------------------
// Debug
//-----------------------------------------------------------------
`ifdef verilator
reg [31:0] dbg_cycle_q;

always @ (posedge clk_i )
if (rst_i)
    dbg_cycle_q <= 32'b0;
else
    dbg_cycle_q <= dbg_cycle_q + 32'd1;

always @ (posedge clk_i )
begin
    if (reg1_write_cmd_w)
        $display("[CDROM_CTRL]: Write comand %02x @ %0d", psf_wr_data1_w, dbg_cycle_q);

    if (reg2_write_param_w)
        $display("[CDROM_CTRL]: Write param %02x @ %0d", psf_wr_data2_w, dbg_cycle_q);

    if (reg3_write_req_w)
        $display("[CDROM_CTRL]: Write request %02x @ %0d", psf_wr_data3_w, dbg_cycle_q);

    if (reg2_write_int_en_w)
        $display("[CDROM_CTRL]: Write int en %02x @ %0d", psf_wr_data2_w, dbg_cycle_q);

    if (reg3_write_int_flag_w)
        $display("[CDROM_CTRL]: Write int ack %02x @ %0d", psf_wr_data3_w, dbg_cycle_q);

    if (reg1_read_res_fifo_w)
        $display("[CDROM_CTRL]: Read resp FIFO %02x @ %0d", resp_fifo_data_w, dbg_cycle_q);

    if (reg3_read_int_en_w)
        $display("[CDROM_CTRL]: Read int en %02x @ %0d", {3'b111, int_en_q}, dbg_cycle_q);

    if (reg3_read_int_flag_w)
        $display("[CDROM_CTRL]: Read int flag %02x @ %0d", {3'b111, int_sts_q}, dbg_cycle_q);

    if (reg2_read_dat_fifo_w)
        $display("[CDROM_CTRL]: CPU data read %02x @ %0d", psf_fifo_data_r[7:0], dbg_cycle_q);
end
`endif


endmodule
