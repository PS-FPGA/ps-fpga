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
module dma_core_read
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
    ,input           outport_awready_i
    ,input           outport_wready_i
    ,input           outport_bvalid_i
    ,input  [  1:0]  outport_bresp_i
    ,input  [  3:0]  outport_bid_i
    ,input           outport_arready_i
    ,input           outport_rvalid_i
    ,input  [ 31:0]  outport_rdata_i
    ,input  [  1:0]  outport_rresp_i
    ,input  [  3:0]  outport_rid_i
    ,input           outport_rlast_i
    ,input           req_valid_i
    ,input  [ 31:0]  req_addr_i
    ,input  [ 31:0]  req_length_i
    ,input           req_mode_decr_i
    ,input  [  2:0]  req_ch_i
    ,input           stream_accept_i

    // Outputs
    ,output          outport_awvalid_o
    ,output [ 31:0]  outport_awaddr_o
    ,output [  3:0]  outport_awid_o
    ,output [  7:0]  outport_awlen_o
    ,output [  1:0]  outport_awburst_o
    ,output [  2:0]  outport_awsize_o
    ,output          outport_wvalid_o
    ,output [ 31:0]  outport_wdata_o
    ,output [  3:0]  outport_wstrb_o
    ,output          outport_wlast_o
    ,output          outport_bready_o
    ,output          outport_arvalid_o
    ,output [ 31:0]  outport_araddr_o
    ,output [  3:0]  outport_arid_o
    ,output [  7:0]  outport_arlen_o
    ,output [  1:0]  outport_arburst_o
    ,output [  2:0]  outport_arsize_o
    ,output          outport_rready_o
    ,output          req_accept_o
    ,output          sts_complete_o
    ,output [ 31:0]  sts_length_o
    ,output [  2:0]  sts_ch_o
    ,output          stream_valid_o
    ,output [ 31:0]  stream_data_o
);



localparam BUFFER_DEPTH   = 32;
localparam BUFFER_DEPTH_W = 5;
localparam BURST_LEN      = 32 / 4;

reg [31:0]  remaining_q;
reg [31:0]  remaining_r;

reg [15:0]  allocated_q;
reg [15:0]  allocated_r;

//-----------------------------------------------------------------
// FSM
//-----------------------------------------------------------------
localparam STATE_W          = 1;
localparam STATE_IDLE       = 1'd0;
localparam STATE_ACTIVE     = 1'd1;

reg [STATE_W-1:0] state_q;
reg [STATE_W-1:0] next_state_r;

always @ *
begin
    next_state_r = state_q;

    case (state_q)
    STATE_IDLE :
    begin
        if (req_valid_i)
            next_state_r  = STATE_ACTIVE;
    end
    STATE_ACTIVE:
    begin
        if (remaining_q == 32'b0 && allocated_q == 16'b0)
            next_state_r  = STATE_IDLE;
    end
    default:
        ;
    endcase
end

always @ (posedge clk_i )
if (rst_i)
    state_q <= STATE_IDLE;
else
    state_q <= next_state_r;

assign req_accept_o = (state_q == STATE_IDLE);

//-----------------------------------------------------------------
// Completion
//-----------------------------------------------------------------
reg [31:0] sts_length_q;

always @ (posedge clk_i )
if (rst_i)
    sts_length_q  <= 32'b0;
else if (req_valid_i && req_accept_o)
    sts_length_q <= req_length_i;

reg [2:0] sts_ch_q;

always @ (posedge clk_i )
if (rst_i)
    sts_ch_q  <= 3'b0;
else if (req_valid_i && req_accept_o)
    sts_ch_q <= req_ch_i;

reg sts_complete_q;

always @ (posedge clk_i )
if (rst_i)
    sts_complete_q  <= 1'b0;
else
    sts_complete_q <= (state_q == STATE_ACTIVE && next_state_r == STATE_IDLE);

assign sts_complete_o = sts_complete_q;
assign sts_length_o   = sts_length_q;
assign sts_ch_o       = sts_ch_q;

//-----------------------------------------------------------------
// FIFO allocation
//-----------------------------------------------------------------
always @ *
begin
    allocated_r = allocated_q;

    // Pop
    if (stream_valid_o && stream_accept_i)
        allocated_r = allocated_r - 16'd1;

    // Push
    if (outport_arvalid_o && outport_arready_i)
        allocated_r = allocated_r + {8'b0, outport_arlen_o} + 16'd1;
end

always @ (posedge clk_i )
if (rst_i)
    allocated_q  <= 16'b0;
else
    allocated_q  <= allocated_r;

//-----------------------------------------------------------------
// Request modes
//-----------------------------------------------------------------
reg req_mode_decr_q;

always @ (posedge clk_i )
if (rst_i)
    req_mode_decr_q  <= 1'b0;
else if (req_valid_i && req_accept_o)
    req_mode_decr_q <= req_mode_decr_i;

//-----------------------------------------------------------------
// AXI Fetch
//-----------------------------------------------------------------
// Calculate number of bytes being fetch
wire [31:0] fetch_bytes_w = {22'b0, (outport_arlen_o + 8'd1), 2'b0};

reg         arvalid_q;
reg [31:0]  araddr_q;
reg [31:0]  araddr_r;

wire [31:0] remain_words_w   = {2'b0, remaining_r[31:2]};
wire [31:0] max_words_w      = (remain_words_w > BURST_LEN && (araddr_r & ((BURST_LEN*4)-1)) == 32'd0 && !req_mode_decr_q) ? BURST_LEN : 1;
wire        fifo_space_w     = (BUFFER_DEPTH - allocated_r) > BURST_LEN;

always @ *
begin
    remaining_r = remaining_q;

    if (outport_arvalid_o && outport_arready_i)
    begin
        if (remaining_r > fetch_bytes_w)
            remaining_r = remaining_r - fetch_bytes_w;
        else
            remaining_r = 32'b0;
    end
end

always @ (posedge clk_i )
if (rst_i)
    remaining_q <= 32'b0;
else if (req_valid_i && req_accept_o)
    remaining_q <= req_length_i;
else if (outport_arvalid_o && outport_arready_i)
    remaining_q <= remaining_r;

reg arvalid_r;

always @ *
begin
    arvalid_r = arvalid_q;

    // Read accept
    if (outport_arready_i)
        arvalid_r = 1'b0;

    // Read not busy, space for another?
    if (!arvalid_r)
        arvalid_r = fifo_space_w && remaining_r != 32'b0;
end

always @ (posedge clk_i )
if (rst_i)
    arvalid_q <= 1'b0;
else
    arvalid_q <= arvalid_r;

assign outport_arvalid_o = arvalid_q;

always @ *
begin
    araddr_r = araddr_q;

    if (outport_arvalid_o && outport_arready_i)
        araddr_r = req_mode_decr_q ? (araddr_q - fetch_bytes_w) : (araddr_q + fetch_bytes_w);
end

always @ (posedge clk_i )
if (rst_i)
    araddr_q <= 32'b0;
else if (req_valid_i && req_accept_o)
    araddr_q <= req_addr_i;
else
    araddr_q <= araddr_r;

reg [7:0] arlen_q;

always @ (posedge clk_i )
if (rst_i)
    arlen_q <= 8'b0;
else
    arlen_q <= max_words_w[7:0] - 1;

assign outport_araddr_o  = araddr_q;
assign outport_arburst_o = 2'b01;
assign outport_arid_o    = AXI_ID;
assign outport_arlen_o   = arlen_q;

assign outport_rready_o  = 1'b1;

// Unused
assign outport_awvalid_o = 1'b0;
assign outport_awaddr_o  = 32'b0;
assign outport_awid_o    = 4'b0;
assign outport_awlen_o   = 8'b0;
assign outport_awburst_o = 2'b0;
assign outport_wvalid_o  = 1'b0;
assign outport_wdata_o   = 32'b0;
assign outport_wstrb_o   = 4'b0;
assign outport_wlast_o   = 1'b0;
assign outport_bready_o  = 1'b0;

//-----------------------------------------------------------------
// Fetch FIFO
//-----------------------------------------------------------------
dma_core_read_read_fifo
u_fifo_in
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)

    ,.push_i(outport_rvalid_i)
    ,.data_in_i(outport_rdata_i)
    ,.accept_o()

    ,.valid_o(stream_valid_o)
    ,.data_out_o(stream_data_o)
    ,.pop_i(stream_accept_i)
);

//-------------------------------------------------------------------
// Stats
//-------------------------------------------------------------------
`ifdef verilator
reg [31:0] stats_rd_singles_q;
reg [31:0] stats_rd_total_q;

always @ (posedge clk_i )
if (rst_i)
    stats_rd_singles_q   <= 32'b0;
else if (outport_arvalid_o && outport_arready_i && outport_arlen_o == 8'b0)
    stats_rd_singles_q   <= stats_rd_singles_q + 32'd1;

always @ (posedge clk_i )
if (rst_i)
    stats_rd_total_q   <= 32'b0;
else if (outport_arvalid_o && outport_arready_i)
    stats_rd_total_q   <= stats_rd_total_q + {24'b0, outport_arlen_o} + 32'd1;

`endif

endmodule
