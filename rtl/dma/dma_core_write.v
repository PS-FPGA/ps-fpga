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
module dma_core_write
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
    ,input           req_mode_ot_i
    ,input           req_mode_ot_last_i
    ,input  [  2:0]  req_ch_i
    ,input           stream_valid_i
    ,input  [ 31:0]  stream_data_i

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
    ,output          stream_accept_o
);



localparam BUFFER_DEPTH   = 32;
localparam BUFFER_DEPTH_W = 5;
localparam BURST_BYTES    = 32;
localparam BURST_LEN      = BURST_BYTES / 4;

reg [31:0]  remaining_q;
reg [31:0]  awaddr_q;

//-----------------------------------------------------------------
// Request modes
//-----------------------------------------------------------------
reg req_mode_decr_q;
reg req_mode_ot_q;
reg req_mode_ot_last_q;

always @ (posedge clk_i )
if (rst_i)
    req_mode_decr_q  <= 1'b0;
else if (req_valid_i && req_accept_o)
    req_mode_decr_q <= req_mode_decr_i;

always @ (posedge clk_i )
if (rst_i)
    req_mode_ot_q  <= 1'b0;
else if (req_valid_i && req_accept_o)
    req_mode_ot_q <= req_mode_ot_i;

always @ (posedge clk_i )
if (rst_i)
    req_mode_ot_last_q  <= 1'b0;
else if (req_valid_i && req_accept_o)
    req_mode_ot_last_q <= req_mode_ot_last_i;

//-----------------------------------------------------------------
// Outstanding transaction tracking
//-----------------------------------------------------------------
reg [7:0] outstanding_q;
reg [7:0] outstanding_r;

wire      write_alloc_w;
wire      write_free_w = outport_bvalid_i && outport_bready_o;

always @ *
begin
    outstanding_r = outstanding_q;

    if (write_alloc_w)
        outstanding_r = outstanding_r + 1;

    if (write_free_w)
        outstanding_r = outstanding_r - 1;
end

always @ (posedge clk_i )
if (rst_i)
    outstanding_q <= 8'b0;
else
    outstanding_q <= outstanding_r;

localparam MAX_OUTSTANDING = 64;

wire limit_reached_w    = (outstanding_q >= MAX_OUTSTANDING);
wire no_resps_pending_w = ~(|outstanding_q);

//-----------------------------------------------------------------
// Input data
//-----------------------------------------------------------------
reg        data_valid_r;
reg [31:0] data_r;

reg [23:0] fill_q;

always @ *
begin
    data_valid_r = 1'b0;
    data_r       = 32'b0;

    if (req_mode_ot_q)
    begin
        data_valid_r = (remaining_q != 32'b0);
        data_r       = (remaining_q == 32'd4 && req_mode_ot_last_q) ? 32'h00FFFFFF : {8'b0, fill_q};
    end
    else
    begin
        data_valid_r = stream_valid_i & (remaining_q != 32'b0);
        data_r       = stream_data_i;
    end
end

//-----------------------------------------------------------------
// OT data fill state
//-----------------------------------------------------------------
always @ (posedge clk_i )
if (rst_i)
    fill_q  <= 24'b0;
else if (req_valid_i && req_accept_o)
    fill_q <= req_addr_i[23:0] - 24'd4;
else if (data_valid_r && fifo_accept_w)
    fill_q <= fill_q - 24'd4;

//-----------------------------------------------------------------
// Length tracking
//-----------------------------------------------------------------
always @ (posedge clk_i )
if (rst_i)
    remaining_q <= 32'b0;
else if (req_valid_i && req_accept_o)
    remaining_q <= req_length_i;
else if (data_valid_r && fifo_accept_w && (remaining_q != 32'b0))
    remaining_q <= remaining_q - 32'd4;

//-----------------------------------------------------------------
// Burst staging FIFO
//-----------------------------------------------------------------
wire        fifo_valid_w;
wire [31:0] fifo_data_w;
wire        fifo_pop_w;
wire [5:0]  fifo_level_w;

wire        fifo_accept_w;

dma_core_write_write_fifo
u_fifo_out
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)

    ,.push_i(data_valid_r)
    ,.data_in_i(data_r)
    ,.accept_o(fifo_accept_w)

    ,.valid_o(fifo_valid_w)
    ,.data_out_o(fifo_data_w)
    ,.pop_i(fifo_pop_w)

    ,.level_o(fifo_level_w)
);

assign stream_accept_o = fifo_accept_w & (remaining_q != 32'b0) && ~req_mode_ot_q;

//-----------------------------------------------------------------
// FSM
//-----------------------------------------------------------------
localparam STATE_W          = 2;
localparam STATE_IDLE       = 2'd0;
localparam STATE_ACTIVE     = 2'd1;
localparam STATE_WAIT_RESP  = 2'd2;

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
        if (~(|fifo_level_w) && ~(|remaining_q))
            next_state_r  = STATE_WAIT_RESP;
    end
    STATE_WAIT_RESP:
    begin
        if (no_resps_pending_w)
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
// Issue
//-----------------------------------------------------------------

// Wait for enough data to perform a complete burst with unless the address is not nicely
// aligned, or unless we are at the tail of the transfer.
wire addr_aligned_w   = ~(|(awaddr_q & (BURST_BYTES - 1)));
wire wait_for_burst_w = (|remaining_q) & addr_aligned_w & ~req_mode_decr_q;
wire issue_burst_w    = ~limit_reached_w & (fifo_level_w >= BURST_LEN) & addr_aligned_w & ~req_mode_decr_q;
wire issue_single_w   = ~limit_reached_w & ~wait_for_burst_w & ~issue_burst_w & fifo_valid_w;

wire request_accept_w;
assign fifo_pop_w     =  request_accept_w & (awvalid_w | wvalid_w);

reg [7:0]  burst_idx_q;

wire       awvalid_w = (issue_single_w | issue_burst_w) & (burst_idx_q == 8'd0);
wire [7:0] awlen_w   = issue_burst_w ? (BURST_LEN-1) : 8'd0;
wire       wvalid_w  = awvalid_w || (burst_idx_q != 8'd0);
wire       wlast_w   = awvalid_w ? issue_single_w : (burst_idx_q == (BURST_LEN-1));

wire [31:0] awlen_bytes_w = {22'b0, awlen_w, 2'b0};

always @ (posedge clk_i )
if (rst_i)
    awaddr_q <= 32'b0;
else if (req_valid_i && req_accept_o)
    awaddr_q <= req_addr_i;
else if (awvalid_w && request_accept_w && req_mode_decr_q)
    awaddr_q <= awaddr_q + awlen_bytes_w - 32'd4;
else if (awvalid_w && request_accept_w)
    awaddr_q <= awaddr_q + awlen_bytes_w + 32'd4;    

always @ (posedge clk_i )
if (rst_i)
    burst_idx_q <= 8'b0;
else if (wvalid_w && request_accept_w && wlast_w)
    burst_idx_q <= 8'b0;
else if (wvalid_w && request_accept_w)
    burst_idx_q <= burst_idx_q + 8'd1;


wire       outport_valid_w;
wire       outport_awvalid_w;
wire       outport_wvalid_w;
wire       outport_accept_w;


dma_fifo
#(
     .WIDTH(32 + 32 + 8 + 3)
    ,.DEPTH(2)
    ,.ADDR_W(1)
)
u_retime
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)

    ,.push_i(awvalid_w | wvalid_w)
    ,.data_in_i({awvalid_w, wvalid_w, wlast_w, awlen_w, fifo_data_w, awaddr_q})
    ,.accept_o(request_accept_w)

    // Outputs
    ,.valid_o(outport_valid_w)
    ,.data_out_o({outport_awvalid_w, outport_wvalid_w, outport_wlast_o, outport_awlen_o, outport_wdata_o, outport_awaddr_o})
    ,.pop_i(outport_accept_w)
);

assign write_alloc_w = awvalid_w & request_accept_w;

//-----------------------------------------------------------------
// AXI Write
//-----------------------------------------------------------------
reg outport_awvalid_q;
reg outport_wvalid_q;

always @ (posedge clk_i )
if (rst_i)
    outport_awvalid_q <= 1'b0;
else if (outport_accept_w)
    outport_awvalid_q <= 1'b0;
else if (outport_awvalid_o && outport_awready_i && (!outport_wready_i && !outport_wvalid_q))
    outport_awvalid_q <= 1'b1;

always @ (posedge clk_i )
if (rst_i)
    outport_wvalid_q <= 1'b0;
else if (outport_accept_w)
    outport_wvalid_q <= 1'b0;
else if (outport_wvalid_o && outport_wready_i && (!outport_awready_i && !outport_awvalid_q && outport_awvalid_w))
    outport_wvalid_q <= 1'b1;

assign outport_accept_w  = (outport_awvalid_q || outport_awready_i || !outport_awvalid_w) && 
                           (outport_wvalid_q  || outport_wready_i);

assign outport_awvalid_o = outport_valid_w & outport_awvalid_w & ~outport_awvalid_q;
assign outport_wvalid_o  = outport_valid_w & outport_wvalid_w  & ~outport_wvalid_q;

assign outport_awburst_o = 2'b01;
assign outport_awid_o    = AXI_ID;
assign outport_wstrb_o   = 4'hF;

assign outport_bready_o  = 1'b1;

// Unused
assign outport_arvalid_o = 1'b0;
assign outport_araddr_o  = 32'b0;
assign outport_arid_o    = 4'b0;
assign outport_arlen_o   = 8'b0;
assign outport_arburst_o = 2'b0;
assign outport_rready_o  = 1'b0;

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
    sts_complete_q <= (state_q == STATE_WAIT_RESP && next_state_r == STATE_IDLE);

assign sts_complete_o = sts_complete_q;
assign sts_length_o   = sts_length_q;
assign sts_ch_o       = sts_ch_q;

//-------------------------------------------------------------------
// Stats
//-------------------------------------------------------------------
`ifdef verilator
reg [31:0] stats_wr_singles_q;
reg [31:0] stats_wr_total_q;

always @ (posedge clk_i )
if (rst_i)
    stats_wr_singles_q   <= 32'b0;
else if (outport_awvalid_o && outport_awready_i && outport_awlen_o == 8'b0)
    stats_wr_singles_q   <= stats_wr_singles_q + 32'd1;

always @ (posedge clk_i )
if (rst_i)
    stats_wr_total_q   <= 32'b0;
else if (outport_awvalid_o && outport_awready_i)
    stats_wr_total_q   <= stats_wr_total_q + {24'b0, outport_awlen_o} + 32'd1;

`endif

endmodule
