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
module mdec
(
    // Inputs
     input           clk_i
    ,input           rst_i
    ,input  [ 31:0]  cfg_addr_i
    ,input  [ 31:0]  cfg_data_wr_i
    ,input           cfg_stb_i
    ,input           cfg_we_i
    ,input           m2p_valid_i
    ,input  [ 31:0]  m2p_data_i
    ,input           p2m_accept_i

    // Outputs
    ,output [ 31:0]  cfg_data_rd_o
    ,output          cfg_ack_o
    ,output          cfg_stall_o
    ,output          m2p_dreq_o
    ,output          m2p_accept_o
    ,output          p2m_dreq_o
    ,output          p2m_valid_o
    ,output [ 31:0]  p2m_data_o
);



wire [12:0] reg_addr_w  = {cfg_addr_i[12:2], 2'b0};
wire        reg_write_w = cfg_stb_i && ~cfg_stall_o &&  cfg_we_i;
wire        reg_read_w  = cfg_stb_i && ~cfg_stall_o && ~cfg_we_i;

// Registers:
// 1F801820h - MDEC0 - MDEC Command/Parameter Register (W)
// 1F801820h - MDEC0 - MDEC Data/Response Register (R)
wire addr_1F801820h_w = (reg_addr_w == 13'h1820);

// 1F801824h - MDEC1 - MDEC Control/Reset Register (W)
// 1F801824h - MDEC1 - MDEC Status Register (R)
wire addr_1F801824h_w = (reg_addr_w == 13'h1824);

// Debug registers
wire addr_1F801828h_w = (reg_addr_w == 13'h1828);
wire addr_1F80182ch_w = (reg_addr_w == 13'h182c);

//-------------------------------------------------------------------
// 1F801824h - MDEC1 - MDEC Control/Reset Register (W)
//-------------------------------------------------------------------
reg mdec1_reset_q;
reg mdec1_en_data_in_q;
reg mdec1_en_data_out_q;

always @ (posedge clk_i )
if (rst_i)
begin
    mdec1_reset_q       <= 1'b0;
    mdec1_en_data_in_q  <= 1'b0;
    mdec1_en_data_out_q <= 1'b0;
end
else if (reg_write_w && addr_1F801824h_w)
begin
    mdec1_reset_q       <= cfg_data_wr_i[31];
    mdec1_en_data_in_q  <= cfg_data_wr_i[30];
    mdec1_en_data_out_q <= cfg_data_wr_i[29];
end
else
    mdec1_reset_q       <= 1'b0;

//-------------------------------------------------------------------
// Command / Param FIFO
//-------------------------------------------------------------------
wire        cmd_push_w = (m2p_valid_i && m2p_accept_o) || (reg_write_w && addr_1F801820h_w);
wire [31:0] cmd_in_w   = (m2p_valid_i && m2p_accept_o) ? m2p_data_i : cfg_data_wr_i;
wire        cmd_space_w;

wire        cmd_valid_w;
wire [31:0] cmd_data_w;
wire        cmd_pop_w;
wire [5:0]  cmd_level_w;

mdec_fifo
#(
     .WIDTH(32)
    ,.DEPTH(32)
    ,.ADDR_W(5)
)
u_cmd_param
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)

    ,.flush_i(mdec1_reset_q)

    ,.push_i(cmd_push_w)
    ,.data_in_i(cmd_in_w)
    ,.accept_o(cmd_space_w)

    // Outputs
    ,.valid_o(cmd_valid_w)
    ,.data_out_o(cmd_data_w)
    ,.pop_i(cmd_pop_w)
    ,.level_o(cmd_level_w)
);

assign m2p_dreq_o        = mdec1_en_data_in_q && (cmd_level_w == 6'b0);
assign m2p_accept_o      = mdec1_en_data_in_q && cmd_space_w;

//-------------------------------------------------------------------
// Response FIFO
//-------------------------------------------------------------------
wire        resp_push_w;
wire [31:0] resp_in_w;
wire        resp_space_w;

wire        resp_valid_w;
wire [31:0] resp_data_w;
wire        resp_pop_w;
wire [5:0]  resp_level_w;

mdec_fifo
#(
     .WIDTH(32)
    ,.DEPTH(32)
    ,.ADDR_W(5)
)
u_resp_param
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)

    ,.flush_i(mdec1_reset_q)

    ,.push_i(resp_push_w)
    ,.data_in_i(resp_in_w)
    ,.accept_o(resp_space_w)

    // Outputs
    ,.valid_o(resp_valid_w)
    ,.data_out_o(resp_data_w)
    ,.pop_i(resp_pop_w)
    ,.level_o(resp_level_w)
);

assign p2m_dreq_o        = mdec1_en_data_out_q && (resp_level_w == 6'd32);
assign p2m_valid_o       = mdec1_en_data_out_q && resp_valid_w;
assign p2m_data_o        = resp_data_w;

assign resp_pop_w        = (mdec1_en_data_out_q && p2m_accept_i) || (reg_read_w && addr_1F801820h_w);

reg [31:0] dbg_written_q;

always @ (posedge clk_i )
if (rst_i)
    dbg_written_q <= 32'b0;
else if (resp_valid_w && resp_pop_w)
    dbg_written_q <= dbg_written_q + 32'd1;

//-------------------------------------------------------------------
// MDEC Core
//-------------------------------------------------------------------
wire [15:0] sts_param_count_w;
wire [2:0]  sts_current_block_w;
wire        sts_data_set_bit15_w;
wire        sts_data_signed_w;
wire [1:0]  sts_data_depth_w;
wire        sts_busy_w;

wire [2:0]  dbg_state_w;
wire [31:0] dbg_block_cnt_w;

mdec_core
u_core
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)

    ,.abort_i(mdec1_reset_q)

    ,.req_valid_i(cmd_valid_w)
    ,.req_in_i(cmd_data_w)
    ,.req_accept_o(cmd_pop_w)
    ,.req_level_i(cmd_level_w)

    ,.data_valid_o(resp_push_w)
    ,.data_out_o(resp_in_w)
    ,.data_accept_i(resp_space_w)

    ,.sts_param_count_o(sts_param_count_w)
    ,.sts_current_block_o(sts_current_block_w)
    ,.sts_data_set_bit15_o(sts_data_set_bit15_w)
    ,.sts_data_signed_o(sts_data_signed_w)
    ,.sts_data_depth_o(sts_data_depth_w)
    ,.sts_busy_o(sts_busy_w)

    // Debug
    ,.dbg_state_o(dbg_state_w)
    ,.dbg_block_cnt_o(dbg_block_cnt_w)
);

//-------------------------------------------------------------------
// Read mux
//-------------------------------------------------------------------
reg [31:0] data_r;
always @ *
begin
    data_r = 32'b0;

    if (addr_1F801820h_w)
        data_r = resp_data_w;
    else if (addr_1F801824h_w)
    begin
        // 31    Data-Out Fifo Empty (0=No, 1=Empty)
        data_r[31] = ~resp_valid_w;

        // 30    Data-In Fifo Full   (0=No, 1=Full, or Last word received)
        // TODO: This needs work....
        data_r[30] = ~cmd_space_w;

        // 29    Command Busy  (0=Ready, 1=Busy receiving or processing parameters)
        data_r[29] = sts_busy_w;

        // 28    Data-In Request  (set when DMA0 enabled and ready to receive data)
        data_r[28] = m2p_dreq_o;

        // 27    Data-Out Request (set when DMA1 enabled and ready to send data)
        data_r[27] = p2m_dreq_o;

        // 26-25 Data Output Depth  (0=4bit, 1=8bit, 2=24bit, 3=15bit)
        data_r[26:25] = sts_data_depth_w;

        // 24    Data Output Signed (0=Unsigned, 1=Signed)
        data_r[24] = sts_data_signed_w;

        // 23    Data Output Bit15  (0=Clear, 1=Set) (for 15bit depth only)
        data_r[23] = sts_data_set_bit15_w;

        // 18-16 Current Block (0..3=Y1..Y4, 4=Cr, 5=Cb) (or for mono: always 4=Y)
        data_r[18:16] = sts_current_block_w;

        // 15-0  Number of Parameter Words remaining minus 1  (FFFFh=None)
        data_r[15:0] = sts_param_count_w;
    end
    // Debug 0
    else if (addr_1F801828h_w)
    begin
        data_r = {dbg_state_w, dbg_block_cnt_w[28:0]};
    end
    // Debug 1
    else if (addr_1F80182ch_w)
    begin
        data_r = dbg_written_q;
    end
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
assign cfg_stall_o   = ack_q;

`ifdef verilator
always @ (posedge clk_i)
if (m2p_valid_i && m2p_accept_o)
begin
    $display("[MDEC_M2P] %08x", m2p_data_i);
end
always @ (posedge clk_i)
if (p2m_valid_o && p2m_accept_i)
begin
    $display("[MDEC_P2M] %08x", p2m_data_o);
end
`endif


endmodule
