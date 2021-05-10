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
module dma_channel
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
     parameter ENABLE_M2P       = 1
    ,parameter FORCE_M2P        = 0
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(
    // Inputs
     input           clk_i
    ,input           rst_i
    ,input           cfg_wr_i
    ,input  [  3:0]  cfg_addr_i
    ,input  [ 31:0]  cfg_data_in_i
    ,input           dreq_i
    ,input           desc_accept_i
    ,input           desc_valid_i
    ,input  [ 31:0]  desc_data_i
    ,input           req_accept_i
    ,input           sts_complete_i
    ,input  [ 31:0]  sts_length_i

    // Outputs
    ,output [ 31:0]  cfg_data_out_o
    ,output          enabled_o
    ,output [ 31:0]  block_size_o
    ,output          dreq_dir_o
    ,output          desc_fetch_o
    ,output [ 31:0]  desc_addr_o
    ,output          req_valid_o
    ,output [ 31:0]  req_addr_o
    ,output          req_dir_m2p_o
    ,output [ 31:0]  req_length_o
    ,output          req_mode_decr_o
    ,output          complete_o
    ,output          busy_o
);



reg       cfg8_addr_decr_q;

reg [1:0] cfg8_sync_mode_q;
localparam MODE0_IMM   = 2'd0;
localparam MODE1_BLOCK = 2'd1;
localparam MODE2_LIST  = 2'd2;
localparam MODE3_RES   = 2'd3;

localparam STATE_W           = 3;
localparam STATE_IDLE        = 3'd0;
localparam STATE_DESC_FETCH  = 3'd1;
localparam STATE_DESC_WAIT   = 3'd2;
localparam STATE_ACTIVATE    = 3'd3;
localparam STATE_EXECUTING   = 3'd4;
localparam STATE_COMPLETE    = 3'd5;

reg [STATE_W-1:0] state_q;

//-----------------------------------------------------------------
// Descriptor (link entry)
//-----------------------------------------------------------------
reg [31:0] desc_data_q;

always @ (posedge clk_i )
if (rst_i)
    desc_data_q <= 32'b0;
else if (desc_valid_i)
    desc_data_q <= desc_data_i;

//-----------------------------------------------------------------
// 1F801080h+N*10h - D#_MADR - DMA base address (Channel 0..6) (R/W)
//-----------------------------------------------------------------
reg [31:0] cfg0_madr_q;
reg [31:0] cfg0_madr_r;

// In SyncMode=0, the hardware doesn't update the MADR registers
// (it will contain the start address even during and after the transfer)
// (unless Chopping is enabled, in that case it does update MADR, same does probably
// also happen when getting interrupted by a higher priority DMA channel).
// In SyncMode=1 and SyncMode=2, the hardware does update MADR (it will contain the
// start address of the currently transferred block; at transfer end,
// it'll hold the end-address in SyncMode=1, or the 00FFFFFFh end-code in SyncMode=2)
// Note: Address bit0-1 are writeable, but any updated current/end addresses are
// word-aligned with bit0-1 forced to zero.
always @ *
begin
    cfg0_madr_r = cfg0_madr_q;

    // CPU register write
    if (cfg_wr_i && cfg_addr_i == 4'h0)
        cfg0_madr_r = {8'b0, cfg_data_in_i[23:0]};
    // Desc fetch issued
    else if (desc_fetch_o && desc_accept_i)
    begin
        // Skip past block_info (count | next_addr)
        if (cfg8_addr_decr_q)
            cfg0_madr_r = {cfg0_madr_r[31:2],2'b0} - 4;
        else
            cfg0_madr_r = {cfg0_madr_r[31:2],2'b0} + 4;
    end
    // End of segment transfer
    // TODO: 'SyncMode=0, the hardware doesn't update the MADR registers unless chopping enabled'
    else if (sts_complete_i)
    begin
        if (cfg8_sync_mode_q == MODE2_LIST)
        begin
            cfg0_madr_r = {8'b0, desc_data_q[23:0]};
        end
        else
        begin
            if (cfg8_addr_decr_q)
                cfg0_madr_r = {cfg0_madr_r[31:2],2'b0} - sts_length_i;
            else
                cfg0_madr_r = {cfg0_madr_r[31:2],2'b0} + sts_length_i;
        end
    end
end

always @ (posedge clk_i )
if (rst_i)
    cfg0_madr_q <= 32'b0;
else
    cfg0_madr_q <= cfg0_madr_r;

//-----------------------------------------------------------------
// 1F801084h+N*10h - D#_BCR - DMA Block Control (Channel 0..6) (R/W)
//-----------------------------------------------------------------
reg [16:0] cfg4_bs_q;
reg [16:0] cfg4_bs_r;

always @ *
begin
    cfg4_bs_r = cfg4_bs_q;

    // CPU register write
    // Note: 0=10000h
    if (cfg_wr_i && cfg_addr_i == 4'h4)
        cfg4_bs_r = {~(|cfg_data_in_i[15:0]), cfg_data_in_i[15:0]};
    // Descriptor fetch
    else if (state_q == STATE_DESC_WAIT && desc_valid_i)
        cfg4_bs_r = {9'b0, desc_data_i[31:24]};
end

always @ (posedge clk_i )
if (rst_i)
    cfg4_bs_q <= 17'b0;
else
    cfg4_bs_q <= cfg4_bs_r;

reg [16:0] cfg4_ba_q;
reg [16:0] cfg4_ba_r;

always @ *
begin
    cfg4_ba_r = cfg4_ba_q;

    // CPU register write
    // Note: 0=10000h
    if (cfg_wr_i && cfg_addr_i == 4'h4)
        cfg4_ba_r = {~(|cfg_data_in_i[31:16]), cfg_data_in_i[31:16]};
    // Transfer accepted
    else if (req_valid_o && req_accept_i)
        cfg4_ba_r = cfg4_ba_r - 17'd1;
end

always @ (posedge clk_i )
if (rst_i)
    cfg4_ba_q <= 17'b0;
else
    cfg4_ba_q <= cfg4_ba_r;

//-----------------------------------------------------------------
// 1F801088h+N*10h - D#_CHCR - DMA Channel Control (Channel 0..6) (R/W)
//-----------------------------------------------------------------
reg       cfg8_dir_m2p_q;
reg       cfg8_chop_mode_q;
reg [2:0] cfg8_dma_win_q;
reg [2:0] cfg8_cpu_win_q;

reg       cfg8_unknown0_q; // Pause?  (0=No, 1=Pause?)     (For SyncMode=0 only?)
reg       cfg8_unknown1_q;

wire      cfg_chrc_wr_w   = cfg_wr_i && (cfg_addr_i == 4'h8);

always @ (posedge clk_i )
if (rst_i)
begin
    cfg8_dir_m2p_q   <= 1'b0;
    cfg8_addr_decr_q <= 1'b0;
    cfg8_chop_mode_q <= 1'b0;
    cfg8_sync_mode_q <= 2'b0;
    cfg8_dma_win_q   <= 3'b0;
    cfg8_cpu_win_q   <= 3'b0;
    cfg8_unknown0_q  <= 1'b0;
    cfg8_unknown1_q  <= 1'b0;
end
else if (cfg_chrc_wr_w)
begin
    cfg8_dir_m2p_q   <= cfg_data_in_i[0];
    cfg8_addr_decr_q <= cfg_data_in_i[1];
    cfg8_chop_mode_q <= cfg_data_in_i[8];
    cfg8_sync_mode_q <= cfg_data_in_i[10:9];
    cfg8_dma_win_q   <= cfg_data_in_i[18:16];
    cfg8_cpu_win_q   <= cfg_data_in_i[22:20];
    cfg8_unknown0_q  <= cfg_data_in_i[29];
    cfg8_unknown1_q  <= cfg_data_in_i[30];
end

wire       cfg_dma_start_w   = cfg_chrc_wr_w && cfg_data_in_i[24];
wire       cfg_dma_trigger_w = cfg_chrc_wr_w && cfg_data_in_i[28];
wire [1:0] cfg_sync_mode_w   = cfg_chrc_wr_w ? cfg_data_in_i[10:9] : cfg8_sync_mode_q;

//-----------------------------------------------------------------
// Issue control
//-----------------------------------------------------------------
// TODO: Based on chop_mode, give access rights based on cpu/dma window...
// TODO: Add in suspected pause control here..
wire can_issue_w = 1'b1;

//-----------------------------------------------------------------
// Trigger
//-----------------------------------------------------------------
reg trigger_r;
reg trigger_q;

always @ *
begin
    trigger_r = trigger_q;

    // TODO: Check mode?
    if (state_q == STATE_ACTIVATE && dreq_i)
        trigger_r = 1'b1;

    // Start transfer, clear trigger
    if (req_valid_o && req_accept_i)
        trigger_r = 1'b0;

    // DMA channel not active
    if (state_q == STATE_IDLE)
        trigger_r = 1'b0;

    // Manual SW trigger
    if (cfg_dma_trigger_w)
        trigger_r = 1'b1;

    // TODO: Take into account chopping, etc..
end

always @ (posedge clk_i )
if (rst_i)
    trigger_q <= 1'b0;
else
    trigger_q <= trigger_r;

//-----------------------------------------------------------------
// State machine
//-----------------------------------------------------------------
reg [STATE_W-1:0] next_state_r;

always @ *
begin
    next_state_r = state_q;

    case (state_q)
    STATE_IDLE:
    begin
        if (cfg_dma_start_w)
            next_state_r = (cfg_sync_mode_w == MODE2_LIST) ? STATE_DESC_FETCH : STATE_ACTIVATE;
    end
    STATE_DESC_FETCH:
    begin
        if (desc_accept_i)
            next_state_r = STATE_DESC_WAIT;
    end
    STATE_DESC_WAIT:
    begin
        if (desc_valid_i)
            next_state_r = STATE_ACTIVATE;
    end
    STATE_ACTIVATE:
    begin
        if (req_valid_o && req_accept_i)
            next_state_r = STATE_EXECUTING;
    end
    STATE_EXECUTING:
    begin
        if (sts_complete_i)
            next_state_r = STATE_COMPLETE;
    end
    STATE_COMPLETE:
    begin
        // Immediate mode
        if (cfg8_sync_mode_q == MODE0_IMM)
            next_state_r = STATE_IDLE;
        // Block mode
        else if (cfg8_sync_mode_q == MODE1_BLOCK)
        begin
            // End of transfer
            if (cfg4_ba_q == 17'b0)
                next_state_r = STATE_IDLE;
            // TODO: Hack...
            else if (can_issue_w)
                next_state_r = STATE_ACTIVATE;
        end
        // Linked list mode
        else if (cfg8_sync_mode_q == MODE2_LIST)
        begin
            // End of list
            if (cfg0_madr_q[23:0] == 24'hffffff || cfg0_madr_q[23:0] == 24'h000000)
                next_state_r = STATE_IDLE;
            // Valid addr - more links to come
            else
                next_state_r = STATE_DESC_FETCH;
        end
    end
    default:
       ;
    endcase

    // START bit is not sticky, abort if cleared
    // NOTE: CPU will be held off during DMA activation so this is less risky
    if (cfg_chrc_wr_w && !cfg_dma_start_w)
        next_state_r = STATE_IDLE;
end

// Update state
always @ (posedge clk_i )
if (rst_i)
    state_q <= STATE_IDLE;
else
    state_q <= next_state_r;

//-----------------------------------------------------------------
// Additional info for targets which need it
//-----------------------------------------------------------------
assign enabled_o    = state_q != STATE_IDLE;
assign block_size_o = {15'b0, cfg4_bs_q};

//-----------------------------------------------------------------
// Descriptor fetch (linked list mode)
//-----------------------------------------------------------------
assign desc_fetch_o  = (state_q == STATE_DESC_FETCH);
assign desc_addr_o   = {8'b0, cfg0_madr_q[23:2], 2'b0};

//-----------------------------------------------------------------
// Request
//-----------------------------------------------------------------
assign req_valid_o     = (state_q == STATE_ACTIVATE) && trigger_q;
assign req_addr_o      = {8'b0, cfg0_madr_q[23:2], 2'b0};
assign req_dir_m2p_o   = ENABLE_M2P ? (cfg8_dir_m2p_q | FORCE_M2P) : 1'b0;
assign req_length_o    = {13'b0, cfg4_bs_q, 2'b0}; // bytes
assign req_mode_decr_o = cfg8_addr_decr_q;

assign dreq_dir_o      = ENABLE_M2P ? (cfg8_dir_m2p_q | FORCE_M2P) : 1'b0;

//-----------------------------------------------------------------
// Read mux
//-----------------------------------------------------------------
reg [31:0] data_r;

always @ *
begin
    data_r = 32'b0;

    case (cfg_addr_i)
    // Dx_MADR
    4'h0:
        data_r = cfg0_madr_q;
    // Dx_BCR
    4'h4:
        data_r = (cfg8_sync_mode_q == MODE2_LIST) ? 32'b0 : {cfg4_ba_q[15:0], cfg4_bs_q[15:0]};
    // Dx_CHCR
    4'h8:
    begin
        data_r[0]     = cfg8_dir_m2p_q;
        data_r[1]     = cfg8_addr_decr_q;
        data_r[8]     = cfg8_chop_mode_q;
        data_r[18:16] = cfg8_dma_win_q;
        data_r[22:20] = cfg8_cpu_win_q;
        data_r[24]    = (state_q != STATE_IDLE);
        data_r[29]    = cfg8_unknown0_q;
        data_r[30]    = cfg8_unknown1_q;
    end
    default: ;
    endcase
end

assign cfg_data_out_o = data_r;

// Completion (for interrupt)
assign complete_o     = (state_q == STATE_COMPLETE && next_state_r == STATE_IDLE);

assign busy_o         = (state_q != STATE_IDLE);

endmodule
