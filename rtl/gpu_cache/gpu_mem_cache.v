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
module gpu_mem_cache
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
     parameter AXI_ID           = 13
    ,parameter VRAM_BASE        = 50331648
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(
    // Inputs
     input           clk_i
    ,input           rst_i
    ,input           gpu_command_i
    ,input  [  1:0]  gpu_size_i
    ,input           gpu_write_i
    ,input  [ 14:0]  gpu_addr_i
    ,input  [  2:0]  gpu_sub_addr_i
    ,input  [ 15:0]  gpu_write_mask_i
    ,input  [255:0]  gpu_data_out_i
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

    // Outputs
    ,output          gpu_busy_o
    ,output          gpu_data_in_valid_o
    ,output [255:0]  gpu_data_in_o
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
);



//-----------------------------------------------------------------
// This cache instance is 1 way set associative.
// The total size is 64KB.
// The replacement policy is a limited pseudo random scheme
// (between lines, toggling on line thrashing).
// The cache is a write through cache, with allocate on read.
//-----------------------------------------------------------------
// Number of ways
parameter GPU_CACHE_NUM_WAYS           = 1;

// Number of cache lines
parameter GPU_CACHE_NUM_LINES          = 2048;
parameter GPU_CACHE_LINE_ADDR_W        = 11;

// Line size (e.g. 32-bytes)
parameter GPU_CACHE_LINE_SIZE_W        = 5;
parameter GPU_CACHE_LINE_SIZE          = 32;
parameter GPU_CACHE_LINE_WORDS         = 8;

// Request -> tag address mapping
parameter GPU_CACHE_TAG_REQ_LINE_L     = 5;  // GPU_CACHE_LINE_SIZE_W
parameter GPU_CACHE_TAG_REQ_LINE_H     = 15; // GPU_CACHE_LINE_ADDR_W+GPU_CACHE_LINE_SIZE_W-1
parameter GPU_CACHE_TAG_REQ_LINE_W     = 11;  // GPU_CACHE_LINE_ADDR_W
`define GPU_CACHE_TAG_REQ_RNG          GPU_CACHE_TAG_REQ_LINE_H:GPU_CACHE_TAG_REQ_LINE_L

// Tag fields
`define GPU_CACHE_TAG_ADDR_RNG          15:0
parameter GPU_CACHE_TAG_ADDR_BITS       = 16;
parameter GPU_CACHE_TAG_VALID_BIT       = GPU_CACHE_TAG_ADDR_BITS;
parameter GPU_CACHE_TAG_DATA_W          = GPU_CACHE_TAG_VALID_BIT + 1;

// Tag compare bits
parameter GPU_CACHE_TAG_CMP_ADDR_L     = GPU_CACHE_TAG_REQ_LINE_H + 1;
parameter GPU_CACHE_TAG_CMP_ADDR_H     = 32-1;
parameter GPU_CACHE_TAG_CMP_ADDR_W     = GPU_CACHE_TAG_CMP_ADDR_H - GPU_CACHE_TAG_CMP_ADDR_L + 1;
`define   GPU_CACHE_TAG_CMP_ADDR_RNG   31:16

// Address mapping example:
//  31          16 15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00
// |--------------|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
//  +--------------------+  +--------------------+ 
//  |  Tag address.      |  |   Line address     | 
//  |                    |  |                    | 
//  |                    |  |                    |
//  |                    |  |                    |- GPU_CACHE_TAG_REQ_LINE_L
//  |                    |  |- GPU_CACHE_TAG_REQ_LINE_H
//  |                    |- GPU_CACHE_TAG_CMP_ADDR_L
//  |- GPU_CACHE_TAG_CMP_ADDR_H

//-----------------------------------------------------------------
// Helper functions
//-----------------------------------------------------------------
function [14:0] addr_twiddle;
input  [14:0]  addr;
begin
    addr_twiddle = {addr[14:13], addr[5:4], addr[12:6], addr[3:0]};
end
endfunction

function [14:0] addr_detwiddle;
input  [14:0]  addr;
begin
    addr_detwiddle = {addr[14:13], addr[10:4], addr[12:11], addr[3:0]};
end
endfunction

//-----------------------------------------------------------------
// Addresses
//-----------------------------------------------------------------
// Full address
wire [31:0]                      gpu_addr_w = {12'b0, addr_twiddle(gpu_addr_i), gpu_sub_addr_i, 2'b0};

// Tag addressing and match value
wire [GPU_CACHE_TAG_REQ_LINE_W-1:0] req_line_addr_w  = gpu_addr_w[`GPU_CACHE_TAG_REQ_RNG];

// Data addressing
wire [GPU_CACHE_LINE_ADDR_W-1:0] req_data_addr_w = gpu_addr_w[GPU_CACHE_LINE_ADDR_W+5-1:5];

wire gpu_read_w  = gpu_command_i & ~gpu_write_i;
wire gpu_write_w = gpu_command_i &  gpu_write_i;
reg  gpu_accept_r;

wire         mem_data_in_valid_w;
wire         mem_busy_w;
wire [255:0] mem_data_in_w;

localparam GPU_CMDSZ_8_BYTE  = 2'd0;
localparam GPU_CMDSZ_32_BYTE = 2'd1;

//-----------------------------------------------------------------
// States
//-----------------------------------------------------------------
localparam STATE_W           = 2;
localparam STATE_FLUSH       = 2'd0;
localparam STATE_LOOKUP      = 2'd1;
localparam STATE_REFILL      = 2'd2;
localparam STATE_RELOOKUP    = 2'd3;

//-----------------------------------------------------------------
// Registers / Wires
//-----------------------------------------------------------------

// States
reg [STATE_W-1:0]           next_state_r;
reg [STATE_W-1:0]           state_q;


//-----------------------------------------------------------------
// Lookup validation
//-----------------------------------------------------------------
reg access_valid_q;

always @ (posedge clk_i )
if (rst_i)
    access_valid_q <= 1'b0;
else if ((gpu_read_w || gpu_write_w) && gpu_accept_r)
    access_valid_q <= 1'b1;
else
    access_valid_q <= 1'b0;

//-----------------------------------------------------------------
// Flopped request
//-----------------------------------------------------------------
reg [31:0]  access_addr_q;
reg [255:0] access_data_q;
reg [15:0]  access_mask_q;
reg         access_wr_q;
reg         access_rd_q;
reg         access_rd_8_q;
reg [1:0]   access_idx_q;

always @ (posedge clk_i )
if (rst_i)
begin
    access_addr_q <= 32'b0;
    access_data_q <= 256'b0;
    access_mask_q <= 16'b0;
    access_wr_q   <= 1'b0;
    access_rd_q   <= 1'b0;
    access_rd_8_q <= 1'b0;
    access_idx_q  <= 2'b0;
end
else if ((gpu_read_w || gpu_write_w) && gpu_accept_r)
begin
    access_addr_q <= gpu_addr_w;
    access_data_q <= gpu_data_out_i;
    access_mask_q <= gpu_write_mask_i;
    access_wr_q   <= gpu_write_w;
    access_rd_q   <= gpu_read_w;
    access_rd_8_q <= (gpu_size_i == GPU_CMDSZ_8_BYTE);
    access_idx_q  <= gpu_sub_addr_i[2:1];
end
else if (gpu_data_in_valid_o || (state_q == STATE_LOOKUP && next_state_r == STATE_LOOKUP))
begin
    access_addr_q <= 32'b0;
    access_data_q <= 256'b0;
    access_mask_q <= 16'b0;
    access_wr_q   <= 1'b0;
    access_rd_q   <= 1'b0;
    access_rd_8_q <= 1'b0;
    access_idx_q  <= 2'b0;
end

wire [GPU_CACHE_TAG_CMP_ADDR_W-1:0] req_addr_tag_cmp_w = access_addr_q[`GPU_CACHE_TAG_CMP_ADDR_RNG];

//-----------------------------------------------------------------
// TAG RAMS
//-----------------------------------------------------------------
reg [GPU_CACHE_TAG_REQ_LINE_W-1:0] tag_addr_r;

// Tag RAM address
always @ *
begin
    tag_addr_r = flush_addr_q;

    // Cache flush
    if (state_q == STATE_FLUSH)
        tag_addr_r = flush_addr_q;
    // Line refill / write
    else if (state_q == STATE_REFILL || state_q == STATE_RELOOKUP)
        tag_addr_r = access_addr_q[`GPU_CACHE_TAG_REQ_RNG];
    // Lookup
    else
        tag_addr_r = req_line_addr_w;
end

// Tag RAM write data
reg [GPU_CACHE_TAG_DATA_W-1:0] tag_data_in_r;
always @ *
begin
    tag_data_in_r = {(GPU_CACHE_TAG_DATA_W){1'b0}};

    // Cache flush
    if (state_q == STATE_FLUSH)
        tag_data_in_r = {(GPU_CACHE_TAG_DATA_W){1'b0}};
    // Line refill
    else if (state_q == STATE_REFILL)
    begin
        tag_data_in_r[GPU_CACHE_TAG_VALID_BIT] = 1'b1;
        tag_data_in_r[`GPU_CACHE_TAG_ADDR_RNG] = access_addr_q[`GPU_CACHE_TAG_CMP_ADDR_RNG];
    end
end

// Tag RAM write enable (way 0)
reg tag0_write_r;
always @ *
begin
    tag0_write_r = 1'b0;

    // Cache flush
    if (state_q == STATE_FLUSH)
        tag0_write_r = 1'b1;
    // Line refill
    else if (state_q == STATE_REFILL)
        tag0_write_r = mem_data_in_valid_w;
end

wire [GPU_CACHE_TAG_DATA_W-1:0] tag0_data_out_w;

gpu_mem_cache_tag_ram
u_tag0
(
  .clk_i(clk_i),
  .rst_i(rst_i),
  .addr_i(tag_addr_r),
  .data_i(tag_data_in_r),
  .wr_i(tag0_write_r),
  .data_o(tag0_data_out_w)
);

wire                               tag0_valid_w     = tag0_data_out_w[GPU_CACHE_TAG_VALID_BIT];
wire [GPU_CACHE_TAG_ADDR_BITS-1:0] tag0_addr_bits_w = tag0_data_out_w[`GPU_CACHE_TAG_ADDR_RNG];

// Tag hit?
wire                               tag0_hit_w = tag0_valid_w ? (tag0_addr_bits_w == req_addr_tag_cmp_w) : 1'b0;


wire tag_hit_any_w = 1'b0
                   | tag0_hit_w
                    ;

//-----------------------------------------------------------------
// DATA RAMS
//-----------------------------------------------------------------
reg [GPU_CACHE_LINE_ADDR_W-1:0] data_addr_r;

// Data RAM address
always @ *
begin
    data_addr_r = req_data_addr_w;

    // Line refill
    if (state_q == STATE_REFILL)
        data_addr_r = access_addr_q[GPU_CACHE_LINE_ADDR_W+5-1:5];
    // Lookup after refill
    else if (state_q == STATE_RELOOKUP)
        data_addr_r = access_addr_q[GPU_CACHE_LINE_ADDR_W+5-1:5];
    // Possible line update on write
    else if (access_valid_q && access_wr_q)
        data_addr_r = access_addr_q[GPU_CACHE_LINE_ADDR_W+5-1:5];
    // Lookup
    else
        data_addr_r = req_data_addr_w;
end


// Data RAM write enable (way 0)
reg [15:0] data0_write_r;
always @ *
begin
    data0_write_r = 16'b0;

    if (state_q == STATE_LOOKUP)
        data0_write_r = {16{access_wr_q}} & {16{access_valid_q & tag0_hit_w}} & access_mask_q;
    else if (state_q == STATE_REFILL)
        data0_write_r = mem_data_in_valid_w ? 16'hFFFF : 16'h0000;
end

wire [255:0] data0_data_out_w;
wire [255:0] data0_data_in_w = (state_q == STATE_REFILL) ? mem_data_in_w : access_data_q;

wire [31:0]  data0_write_en_w;

assign data0_write_en_w[0+1:0] = {2{data0_write_r[0]}};
assign data0_write_en_w[2+1:2] = {2{data0_write_r[1]}};
assign data0_write_en_w[4+1:4] = {2{data0_write_r[2]}};
assign data0_write_en_w[6+1:6] = {2{data0_write_r[3]}};
assign data0_write_en_w[8+1:8] = {2{data0_write_r[4]}};
assign data0_write_en_w[10+1:10] = {2{data0_write_r[5]}};
assign data0_write_en_w[12+1:12] = {2{data0_write_r[6]}};
assign data0_write_en_w[14+1:14] = {2{data0_write_r[7]}};
assign data0_write_en_w[16+1:16] = {2{data0_write_r[8]}};
assign data0_write_en_w[18+1:18] = {2{data0_write_r[9]}};
assign data0_write_en_w[20+1:20] = {2{data0_write_r[10]}};
assign data0_write_en_w[22+1:22] = {2{data0_write_r[11]}};
assign data0_write_en_w[24+1:24] = {2{data0_write_r[12]}};
assign data0_write_en_w[26+1:26] = {2{data0_write_r[13]}};
assign data0_write_en_w[28+1:28] = {2{data0_write_r[14]}};
assign data0_write_en_w[30+1:30] = {2{data0_write_r[15]}};

gpu_mem_cache_data_ram
u_data0_0
(
  .clk_i(clk_i),
  .rst_i(rst_i),
  .addr_i(data_addr_r),
  .data_i(data0_data_in_w[31:0]),
  .wr_i(data0_write_en_w[3:0]),
  .data_o(data0_data_out_w[31:0])
);

gpu_mem_cache_data_ram
u_data0_1
(
  .clk_i(clk_i),
  .rst_i(rst_i),
  .addr_i(data_addr_r),
  .data_i(data0_data_in_w[63:32]),
  .wr_i(data0_write_en_w[7:4]),
  .data_o(data0_data_out_w[63:32])
);

gpu_mem_cache_data_ram
u_data0_2
(
  .clk_i(clk_i),
  .rst_i(rst_i),
  .addr_i(data_addr_r),
  .data_i(data0_data_in_w[95:64]),
  .wr_i(data0_write_en_w[11:8]),
  .data_o(data0_data_out_w[95:64])
);

gpu_mem_cache_data_ram
u_data0_3
(
  .clk_i(clk_i),
  .rst_i(rst_i),
  .addr_i(data_addr_r),
  .data_i(data0_data_in_w[127:96]),
  .wr_i(data0_write_en_w[15:12]),
  .data_o(data0_data_out_w[127:96])
);

gpu_mem_cache_data_ram
u_data0_4
(
  .clk_i(clk_i),
  .rst_i(rst_i),
  .addr_i(data_addr_r),
  .data_i(data0_data_in_w[159:128]),
  .wr_i(data0_write_en_w[19:16]),
  .data_o(data0_data_out_w[159:128])
);

gpu_mem_cache_data_ram
u_data0_5
(
  .clk_i(clk_i),
  .rst_i(rst_i),
  .addr_i(data_addr_r),
  .data_i(data0_data_in_w[191:160]),
  .wr_i(data0_write_en_w[23:20]),
  .data_o(data0_data_out_w[191:160])
);

gpu_mem_cache_data_ram
u_data0_6
(
  .clk_i(clk_i),
  .rst_i(rst_i),
  .addr_i(data_addr_r),
  .data_i(data0_data_in_w[223:192]),
  .wr_i(data0_write_en_w[27:24]),
  .data_o(data0_data_out_w[223:192])
);

gpu_mem_cache_data_ram
u_data0_7
(
  .clk_i(clk_i),
  .rst_i(rst_i),
  .addr_i(data_addr_r),
  .data_i(data0_data_in_w[255:224]),
  .wr_i(data0_write_en_w[31:28]),
  .data_o(data0_data_out_w[255:224])
);


//-----------------------------------------------------------------
// Flush counter
//-----------------------------------------------------------------
reg [GPU_CACHE_TAG_REQ_LINE_W-1:0] flush_addr_q;

always @ (posedge clk_i )
if (rst_i)
    flush_addr_q <= {(GPU_CACHE_TAG_REQ_LINE_W){1'b0}};
else if (state_q == STATE_FLUSH)
    flush_addr_q <= flush_addr_q + 1;
else
    flush_addr_q <= {(GPU_CACHE_TAG_REQ_LINE_W){1'b0}};

//-----------------------------------------------------------------
// Replacement Policy
//----------------------------------------------------------------- 

//-----------------------------------------------------------------
// Output Result / Ack
//-----------------------------------------------------------------
assign gpu_data_in_valid_o = ((state_q == STATE_LOOKUP && access_rd_q) ? tag_hit_any_w : 1'b0) | mem_data_in_valid_w;

// Data output mux
reg [255:0] data_r;
always @ *
begin
    data_r = data0_data_out_w;

    // Read response to cache miss
    if (mem_data_in_valid_w)
        data_r = mem_data_in_w;
    // Cache access
    else
    begin
        case (1'b1)
        tag0_hit_w: data_r = data0_data_out_w;
        endcase
    end

    // Narrow read (8-byte read)
    if (access_rd_8_q)
    begin
        case (access_idx_q)
        2'd0: data_r = {192'b0, data_r[63:0]};
        2'd1: data_r = {192'b0, data_r[127:64]};
        2'd2: data_r = {192'b0, data_r[191:128]};
        2'd3: data_r = {192'b0, data_r[255:192]};
        endcase
    end
end

assign gpu_data_in_o  = data_r;

//-----------------------------------------------------------------
// Next State Logic
//-----------------------------------------------------------------
always @ *
begin
    next_state_r = state_q;

    case (state_q)
    //-----------------------------------------
    // STATE_FLUSH
    //-----------------------------------------
    STATE_FLUSH :
    begin
        if (flush_addr_q == {(GPU_CACHE_TAG_REQ_LINE_W){1'b1}})
            next_state_r = STATE_LOOKUP;
    end
    //-----------------------------------------
    // STATE_LOOKUP
    //-----------------------------------------
    STATE_LOOKUP :
    begin
        // Tried a lookup but no match found
        if (access_rd_q && !tag_hit_any_w)
            next_state_r = STATE_REFILL;
        // Read or Write
        else if (gpu_read_w || gpu_write_w)
            ;
    end
    //-----------------------------------------
    // STATE_REFILL
    //-----------------------------------------
    STATE_REFILL :
    begin
        // End of refill
        if (mem_data_in_valid_w)
            next_state_r = STATE_RELOOKUP;
    end
    //-----------------------------------------
    // STATE_RELOOKUP
    //-----------------------------------------
    STATE_RELOOKUP :
    begin
        next_state_r = STATE_LOOKUP;
    end
    default:
        ;
    endcase
end

// Update state
always @ (posedge clk_i )
if (rst_i)
    state_q   <= STATE_FLUSH;
else
    state_q   <= next_state_r;

// Pipeline requests of the same type
wire same_request_type_w = (gpu_read_w  == access_rd_q) && 
                           (gpu_write_w == access_wr_q);
wire no_requests_pending_w = (!access_rd_q && !access_wr_q);

wire can_accept_w = same_request_type_w | no_requests_pending_w;

always @ *
begin
    gpu_accept_r = 1'b0;

    if (state_q == STATE_LOOKUP)
    begin
        // Previous request missed
        if (next_state_r == STATE_REFILL)
            gpu_accept_r = 1'b0;
        // Write request - on AXI accept
        else if (gpu_write_w)
            gpu_accept_r = ~mem_busy_w && can_accept_w;
        // Misc (cached read / flush)
        else
            gpu_accept_r = can_accept_w;
    end
end

assign gpu_busy_o = ~gpu_accept_r;

//-----------------------------------------------------------------
// Memory Request
//-----------------------------------------------------------------
reg         mem_read_q;
wire        mem_command_w;
wire        mem_write_w;
wire [14:0] mem_addr_w;

always @ (posedge clk_i )
if (rst_i)
    mem_read_q   <= 1'b0;
else if (mem_command_w && !mem_write_w)
    mem_read_q   <= mem_busy_w;

wire refill_request_w   = (state_q == STATE_LOOKUP && next_state_r == STATE_REFILL);

assign mem_command_w    = (state_q == STATE_LOOKUP && gpu_write_w & can_accept_w) || (refill_request_w || mem_read_q);
assign mem_write_w      = ~(refill_request_w || mem_read_q);
assign mem_addr_w       = (refill_request_w || mem_read_q) ? addr_detwiddle(access_addr_q[14+5:5]) : gpu_addr_i;

//-----------------------------------------------------------------
// Debug
//-----------------------------------------------------------------
`ifdef verilator
reg [79:0] dbg_state;
always @ *
begin
    dbg_state = "-";

    case (state_q)
    STATE_FLUSH    : dbg_state = "FLUSH   ";
    STATE_LOOKUP   : dbg_state = "LOOKUP  ";
    STATE_REFILL   : dbg_state = "REFILL  ";
    STATE_RELOOKUP : dbg_state = "RELOOKUP";
    default:
        ;
    endcase
end

reg [31:0] stats_hits_q;
reg [31:0] stats_miss_q;
reg [31:0] stats_read_q;
reg [31:0] stats_write_q;
reg [31:0] stats_stalls_q;

always @ (posedge clk_i )
if (rst_i)
    stats_hits_q   <= 32'b0;
else if (state_q == STATE_LOOKUP && access_rd_q && tag_hit_any_w)
    stats_hits_q   <= stats_hits_q + 32'd1;

always @ (posedge clk_i )
if (rst_i)
    stats_miss_q   <= 32'b0;
else if (state_q == STATE_LOOKUP && access_rd_q && !tag_hit_any_w)
    stats_miss_q   <= stats_miss_q + 32'd1;

always @ (posedge clk_i )
if (rst_i)
    stats_read_q   <= 32'b0;
else if (gpu_read_w && gpu_accept_r)
    stats_read_q   <= stats_read_q + 32'd1;

always @ (posedge clk_i )
if (rst_i)
    stats_write_q   <= 32'b0;
else if (gpu_write_w && gpu_accept_r)
    stats_write_q   <= stats_write_q + 32'd1;

always @ (posedge clk_i )
if (rst_i)
    stats_stalls_q   <= 32'b0;
else if ((state_q != STATE_LOOKUP) || (gpu_command_i && gpu_busy_o))
    stats_stalls_q   <= stats_stalls_q + 32'd1;

`endif

//-----------------------------------------------------------------
//                      AXI Handing
//-----------------------------------------------------------------
wire write_busy_w;

gpu_mem_fetch
#(
     .AXI_ID(AXI_ID)
    ,.VRAM_BASE(VRAM_BASE)
)
u_fetch
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)

    ,.mem_command_i(mem_command_w)
    ,.mem_write_i(mem_write_w)
    ,.mem_addr_i(mem_addr_w)
    ,.mem_write_mask_i(gpu_write_mask_i)
    ,.mem_data_out_i(gpu_data_out_i)
    ,.mem_busy_o(mem_busy_w)
    ,.mem_data_in_valid_o(mem_data_in_valid_w)
    ,.mem_data_in_o(mem_data_in_w)

    ,.axi_awvalid_o(axi_awvalid_o)
    ,.axi_awaddr_o(axi_awaddr_o)
    ,.axi_awid_o(axi_awid_o)
    ,.axi_awlen_o(axi_awlen_o)
    ,.axi_awburst_o(axi_awburst_o)
    ,.axi_wvalid_o(axi_wvalid_o)
    ,.axi_wdata_o(axi_wdata_o)
    ,.axi_wstrb_o(axi_wstrb_o)
    ,.axi_wlast_o(axi_wlast_o)
    ,.axi_bready_o(axi_bready_o)
    ,.axi_arvalid_o(axi_arvalid_o)
    ,.axi_araddr_o(axi_araddr_o)
    ,.axi_arid_o(axi_arid_o)
    ,.axi_arlen_o(axi_arlen_o)
    ,.axi_arburst_o(axi_arburst_o)
    ,.axi_rready_o(axi_rready_o)
    ,.axi_awready_i(axi_awready_i)
    ,.axi_wready_i(axi_wready_i)
    ,.axi_bvalid_i(axi_bvalid_i)
    ,.axi_bresp_i(axi_bresp_i)
    ,.axi_bid_i(axi_bid_i)
    ,.axi_arready_i(axi_arready_i)
    ,.axi_rvalid_i(axi_rvalid_i)
    ,.axi_rdata_i(axi_rdata_i)
    ,.axi_rresp_i(axi_rresp_i)
    ,.axi_rid_i(axi_rid_i)
    ,.axi_rlast_i(axi_rlast_i)

    ,.busy_o(write_busy_w)
);

//-----------------------------------------------------------------
// Debug
//-----------------------------------------------------------------
`ifdef verilator
function [0:0] get_busy; /*verilator public*/
begin
    get_busy = write_busy_w;
end
endfunction
`endif


endmodule
