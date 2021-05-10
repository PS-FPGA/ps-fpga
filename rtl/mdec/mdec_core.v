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
module mdec_core
(
     input               clk_i
    ,input               rst_i

    // Abort request
    ,input               abort_i

    // Command / Param input
    ,input               req_valid_i
    ,input [31:0]        req_in_i
    ,output              req_accept_o
    ,input [5:0]         req_level_i

    // Decoded data output
    ,output              data_valid_o
    ,output [31:0]       data_out_o
    ,input               data_accept_i

    // Status
    ,output [15:0]       sts_param_count_o
    ,output [2:0]        sts_current_block_o
    ,output              sts_data_set_bit15_o
    ,output              sts_data_signed_o
    ,output [1:0]        sts_data_depth_o
    ,output              sts_busy_o

    // Debug
    ,output [2:0]        dbg_state_o
    ,output [31:0]       dbg_block_cnt_o
);

localparam CMD_NONE          = 3'd0;
localparam CMD_DECODE        = 3'd1;
localparam CMD_SET_DQT       = 3'd2;
localparam CMD_SET_IDCT      = 3'd3;

localparam MODE_4BIT         = 2'd0;
localparam MODE_8BIT         = 2'd1;
localparam MODE_24BIT        = 2'd2;
localparam MODE_15BIT        = 2'd3;

localparam STATE_W           = 3;
localparam STATE_IDLE        = 3'd0;
localparam STATE_SET_DQT     = 3'd1;
localparam STATE_SET_IDCT    = 3'd2;
localparam STATE_DECODE      = 3'd3;
localparam STATE_DRAIN       = 3'd4;

reg [STATE_W-1:0] state_q;
reg [31:0]        output_count_q;

//-----------------------------------------------------------------
// Decode mode
//-----------------------------------------------------------------
reg [1:0] mode_depth_q;

always @ (posedge clk_i )
if (rst_i)
    mode_depth_q <= 2'b0;
else if (abort_i)
    mode_depth_q <= 2'b0;
else if (state_q == STATE_IDLE && req_valid_i && req_in_i[31:29] == CMD_DECODE)
    mode_depth_q <= req_in_i[28:27];

reg mode_signed_q;

always @ (posedge clk_i )
if (rst_i)
    mode_signed_q <= 1'b0;
else if (abort_i)
    mode_signed_q <= 1'b0;
else if (state_q == STATE_IDLE && req_valid_i && req_in_i[31:29] == CMD_DECODE)
    mode_signed_q <= req_in_i[26];

reg mode_bit15_q;

always @ (posedge clk_i )
if (rst_i)
    mode_bit15_q <= 1'b0;
else if (abort_i)
    mode_bit15_q <= 1'b0;
else if (state_q == STATE_IDLE && req_valid_i && req_in_i[31:29] == CMD_DECODE)
    mode_bit15_q <= req_in_i[25];

assign sts_data_depth_o     = mode_depth_q;
assign sts_data_signed_o    = mode_signed_q;
assign sts_data_set_bit15_o = mode_bit15_q;

//-----------------------------------------------------------------
// Param counter
//-----------------------------------------------------------------
reg [15:0] param_count_q;

always @ (posedge clk_i )
if (rst_i)
    param_count_q <= 16'b0;
else if (abort_i)
begin
`ifdef verilator
    if (state_q != STATE_IDLE)
        $display("MDEC: Aborted transfer");
`endif
    param_count_q <= 16'b0;
end
else if (state_q == STATE_IDLE && req_valid_i)
begin
    case (req_in_i[31:29])
    CMD_DECODE:
    begin
`ifdef verilator
        $display("MDEC: Decode start 0x%x", req_in_i[15:0]);
`endif
        param_count_q <= req_in_i[15:0] - 16'd1;
    end
    CMD_SET_DQT:
    begin
`ifdef verilator
        $display("MDEC: Set DQT");
`endif
        // Mono
        if (!req_in_i[0])
            param_count_q <= 16'd15; // 64 / 4
        // Colour
        else
            param_count_q <= 16'd31; // 128 / 4
    end
    CMD_SET_IDCT:
    begin
`ifdef verilator
        $display("MDEC: Set IDCT");
`endif
        param_count_q <= 16'd31; // 64 / 2
    end
    default:
        ;
    endcase
end
else if (state_q == STATE_SET_DQT && req_valid_i)
    param_count_q <= param_count_q - 16'd1;
else if (state_q == STATE_SET_IDCT && req_valid_i)
    param_count_q <= param_count_q - 16'd1;
else if (state_q == STATE_DECODE && req_valid_i && req_accept_o)
    param_count_q <= param_count_q - 16'd1;
else if (state_q == STATE_DRAIN && output_count_q == 32'd0)
begin
    param_count_q <= 16'hFFFF;
`ifdef verilator
    $display("MDEC: Transfer completed");
`endif
end

//-----------------------------------------------------------------
// Unroll
//-----------------------------------------------------------------
reg half_sel_q;

always @ (posedge clk_i )
if (rst_i)
    half_sel_q <= 1'b0;
else if (state_q == STATE_IDLE)
    half_sel_q <= 1'b0;
else if ((state_q == STATE_DECODE) && req_valid_i)
    half_sel_q <= ~half_sel_q;

wire        data_valid_w = (state_q == STATE_DECODE) && req_valid_i;
wire [15:0] data_in_w    = half_sel_q ? req_in_i[31:16] : req_in_i[15:0];

//-----------------------------------------------------------------
// RLE decoder
//-----------------------------------------------------------------
reg [5:0]  entries_q;
wire       is_ac_w        = (entries_q != 6'd0);
wire [6:0] inc_len_w      = is_ac_w ? ({1'b0, data_in_w[15:10]} + 7'd1) : 7'd1;
wire [6:0] entries_next_w = {1'b0, entries_q} + inc_len_w;

always @ (posedge clk_i )
if (rst_i)
    entries_q <= 6'b0;
else if (state_q == STATE_IDLE)
    entries_q <= 6'b0;
else if (data_valid_w)
begin
    if (entries_next_w >= 7'd64 || data_in_w == 16'hFE00)
        entries_q <= 6'b0;
    else
        entries_q <= entries_next_w[5:0];
end

wire eob_detect_w = (entries_q != 6'b0) && data_valid_w && (entries_next_w >= 7'd64 || data_in_w == 16'hFE00);

reg [2:0]  block_idx_q;
reg [31:0] output_count_r;

wire [31:0] output_size_w = (mode_depth_q == MODE_4BIT || mode_depth_q == MODE_8BIT) ? 32'd32 :
                            (mode_depth_q == MODE_24BIT) ? 32'd192 : 32'd128; // div 4 for words

wire last_subblock_w = (mode_depth_q == MODE_4BIT || mode_depth_q == MODE_8BIT || block_idx_q == 3'd5);

always @ *
begin
    output_count_r = output_count_q;

    if (state_q == STATE_DECODE)
    begin
        if (eob_detect_w && last_subblock_w)
            output_count_r = output_count_r + output_size_w;
    end
    
    if (data_valid_o && data_accept_i)
        output_count_r = output_count_r - 32'd1;
end

always @ (posedge clk_i )
if (rst_i)
    output_count_q <= 32'b0;
else if (abort_i)
    output_count_q <= 32'b0;
else
    output_count_q <= output_count_r;

reg [31:0] dbg_block_count_q;

always @ (posedge clk_i )
if (rst_i)
    dbg_block_count_q <= 32'b0;
else if (eob_detect_w)
    dbg_block_count_q <= dbg_block_count_q + 32'd1;

assign dbg_block_cnt_o = dbg_block_count_q;

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
        if (req_valid_i)
        begin
            case (req_in_i[31:29])
            CMD_DECODE:   next_state_r = STATE_DECODE;
            CMD_SET_DQT:  next_state_r = STATE_SET_DQT;
            CMD_SET_IDCT: next_state_r = STATE_SET_IDCT;
            default:
                ;
            endcase
        end
    end
    STATE_SET_DQT, STATE_SET_IDCT:
    begin
        if (param_count_q == 16'd0 && req_valid_i)
            next_state_r = STATE_IDLE;
    end
    STATE_DECODE:
    begin
        if (param_count_q == 16'd0 && req_valid_i && half_sel_q)
            next_state_r = STATE_DRAIN;
    end
    STATE_DRAIN:
    begin
        if (output_count_q == 32'd0)
            next_state_r = STATE_IDLE;
    end
    default:
       ;
    endcase

    // Abort request
    if (abort_i)
        next_state_r = STATE_IDLE;
end

// Update state
always @ (posedge clk_i )
if (rst_i)
    state_q <= STATE_IDLE;
else
    state_q <= next_state_r;

assign dbg_state_o = state_q;

//-----------------------------------------------------------------
// Block Index
//-----------------------------------------------------------------
always @ (posedge clk_i )
if (rst_i)
    block_idx_q <= 3'b0;
else if (abort_i)
    block_idx_q <= 3'b0;
else if (state_q == STATE_DECODE && eob_detect_w)
begin
    if (mode_depth_q == MODE_4BIT || mode_depth_q == MODE_8BIT)
        block_idx_q <= 3'b0;
    else if (block_idx_q == 3'd5)
        block_idx_q <= 3'b0;
    else
        block_idx_q <= block_idx_q + 3'd1;
end

//-----------------------------------------------------------------
// Current block
//-----------------------------------------------------------------
reg [2:0] current_block_q;

always @ (posedge clk_i )
if (rst_i)
    current_block_q <= 3'd4;
else if (abort_i)
    current_block_q <= 3'd4;
else if (state_q == STATE_DECODE && eob_detect_w)
    current_block_q <= 3'd0;

//-----------------------------------------------------------------
// Status
//-----------------------------------------------------------------
assign sts_busy_o          = (state_q != STATE_IDLE);
assign sts_param_count_o   = param_count_q;
assign req_accept_o        = (state_q != STATE_DRAIN) && !((state_q == STATE_DECODE) && ~half_sel_q);

// TODO: This might work if the output image size is known and the DMA is setup to sink it.
assign data_valid_o        = (output_count_q != 32'b0);
assign data_out_o          = 32'h7FFF7FFF;
assign sts_current_block_o = current_block_q;

endmodule
