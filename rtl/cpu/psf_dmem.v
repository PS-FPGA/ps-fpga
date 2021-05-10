//-----------------------------------------------------------------
//                          MPX Core
//                            V0.1
//                   github.com/ultraembedded
//                       Copyright 2020
//
//                   admin@ultra-embedded.com
//
//                     License: Apache 2.0
//-----------------------------------------------------------------
// Copyright 2020 Ultra-Embedded.com
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//     http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//-----------------------------------------------------------------
module psf_dmem
(
    // Inputs
     input           clk_i
    ,input           rst_i
    ,input  [ 31:0]  mem_addr_i
    ,input  [ 31:0]  mem_data_wr_i
    ,input           mem_rd_i
    ,input  [  3:0]  mem_wr_i
    ,input           mem_cacheable_i
    ,input  [ 10:0]  mem_req_tag_i
    ,input           mem_invalidate_i
    ,input           mem_writeback_i
    ,input           mem_flush_i
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
    ,output [ 31:0]  mem_data_rd_o
    ,output          mem_accept_o
    ,output          mem_ack_o
    ,output          mem_error_o
    ,output [ 10:0]  mem_resp_tag_o
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





// 1F800000h / 9F800000h  - 1KB Scratchpad
wire dmem_access_w = {1'b0, mem_addr_i[30:10], 10'b0} == 32'h1F800000;

// 1F801000h / 9F801000h / BF801000h - Main IO region
wire io_access_w   = {1'b0, mem_addr_i[30:12], 12'b0} == 32'h1F801000;

// Cache control register
wire cache_ctrl_w  = (mem_addr_i == 32'hFFFE0130);

//-----------------------------------------------------------------
// Response flops
//-----------------------------------------------------------------
reg dmem_access_q;

always @ (posedge clk_i )
if (rst_i)
    dmem_access_q <= 1'b0;
else
    dmem_access_q <= (mem_rd_i || mem_wr_i != 4'b0) && mem_accept_o && dmem_access_w;

reg posted_wr_q;

always @ (posedge clk_i )
if (rst_i)
    posted_wr_q <= 1'b0;
else
    posted_wr_q <= !io_access_w && (mem_wr_i != 4'b0) && mem_accept_o;

reg cache_ctrl_q;

always @ (posedge clk_i )
if (rst_i)
    cache_ctrl_q <= 1'b0;
else
    cache_ctrl_q <= (mem_rd_i || mem_wr_i != 4'b0) && mem_accept_o && cache_ctrl_w;

//-----------------------------------------------------------------
// Cache control
//-----------------------------------------------------------------
reg [31:0] reg_cache_ctrl_q;

always @ (posedge clk_i )
if (rst_i)
    reg_cache_ctrl_q <= 32'b0;
else if (mem_wr_i != 4'b0 && mem_accept_o && cache_ctrl_w)
    reg_cache_ctrl_q <= mem_data_wr_i;

//-----------------------------------------------------------------
// Scratchpad (1KB DMEM)
//-----------------------------------------------------------------
wire [31:0] dmem_read_data_w;

psf_dmem_ram
u_dmem
(
	 .clk_i(clk_i)
	,.rst_i(rst_i)

	,.addr_i(mem_addr_i[9:2])
    ,.data_i(mem_data_wr_i)
    ,.wr_i({4{dmem_access_w}} & mem_wr_i)

    ,.data_o(dmem_read_data_w)
);

assign mem_resp_tag_o = 11'b0; // Not used

//-------------------------------------------------------------
// Request FIFO
//-------------------------------------------------------------
wire          req_accept_w;

// Output accept
wire          write_complete_w;
wire          read_complete_w;

reg           request_pending_q;

wire          req_pop_w   = read_complete_w | write_complete_w;
wire          req_valid_w;
wire [72-1:0] req_w;

// Push on transaction and other FIFO not full
wire          req_push_w   = (mem_rd_i || mem_wr_i != 4'b0) && ~(dmem_access_w || cache_ctrl_w);

psf_dmem_fifo
#( 
    .WIDTH(32+32+4+2+1+1),
    .DEPTH(4),
    .ADDR_W(2)
)
u_req
(
    .clk_i(clk_i),
    .rst_i(rst_i),

    // Input side
    .data_in_i({mem_req_tag_i[1:0], ~io_access_w, mem_rd_i, mem_wr_i, mem_data_wr_i, mem_addr_i}),
    .push_i(req_push_w),
    .accept_o(req_accept_w),

    // Outputs
    .valid_o(req_valid_w),
    .data_out_o(req_w),
    .pop_i(req_pop_w)
);

assign mem_accept_o = dmem_access_w || cache_ctrl_w || req_accept_w;

wire request_in_progress_w = request_pending_q & ~(axi_rvalid_i || axi_bvalid_i);

//-------------------------------------------------------------
// Write Request
//-------------------------------------------------------------
wire [1:0] req_size_w      = req_w[71:70];
wire       req_is_posted_w = req_w[69];
wire       req_is_read_w   = ((req_valid_w & !request_in_progress_w) ? req_w[68] : 1'b0);
wire       req_is_write_w  = ((req_valid_w & !request_in_progress_w) ? ~req_w[68] : 1'b0);

reg awvalid_inhibit_q;
reg wvalid_inhibit_q;

wire wr_cmd_accepted_w  = (axi_awvalid_o && axi_awready_i) || awvalid_inhibit_q;
wire wr_data_accepted_w = (axi_wvalid_o  && axi_wready_i)  || wvalid_inhibit_q;

always @ (posedge clk_i )
if (rst_i)
    awvalid_inhibit_q <= 1'b0;
else if (axi_awvalid_o && axi_awready_i && !wr_data_accepted_w)
    awvalid_inhibit_q <= 1'b1;
else if (wr_data_accepted_w)
    awvalid_inhibit_q <= 1'b0;

always @ (posedge clk_i )
if (rst_i)
    wvalid_inhibit_q <= 1'b0;
else if (axi_wvalid_o && axi_wready_i && !wr_cmd_accepted_w)
    wvalid_inhibit_q <= 1'b1;
else if (wr_cmd_accepted_w)
    wvalid_inhibit_q <= 1'b0;

assign axi_awvalid_o = req_is_write_w && !awvalid_inhibit_q;
assign axi_awaddr_o  = req_w[31:0];
assign axi_wvalid_o  = req_is_write_w && !wvalid_inhibit_q;
assign axi_wdata_o   = req_w[63:32];
assign axi_wstrb_o   = req_w[67:64];
assign axi_awid_o    = 4'd8;
assign axi_awlen_o   = 8'b0;
assign axi_awburst_o = 2'b01;
assign axi_awsize_o  = 3'd2; // 32-bit (use write masks)
assign axi_wlast_o   = 1'b1;

assign axi_bready_o  = 1'b1;

assign write_complete_w = (awvalid_inhibit_q || axi_awready_i) &&
                          (wvalid_inhibit_q || axi_wready_i) && req_is_write_w;

//-------------------------------------------------------------
// Read Request
//-------------------------------------------------------------
assign axi_arvalid_o = req_is_read_w;
assign axi_araddr_o  = req_w[31:0];
assign axi_arid_o    = 4'd8;
assign axi_arlen_o   = 8'b0;
assign axi_arburst_o = 2'b01;
assign axi_arsize_o  = req_size_w[0] ? 3'd0 : // 8-bit
                       req_size_w[1] ? 3'd1 : // 16-bit
                                       3'd2;  // 32-bit

assign axi_rready_o  = 1'b1;

assign read_complete_w = axi_arvalid_o && axi_arready_i;

//-------------------------------------------------------------
// Outstanding Request Tracking
//-------------------------------------------------------------
always @ (posedge clk_i )
if (rst_i)
    request_pending_q <= 1'b0;
else if (write_complete_w || read_complete_w)
    request_pending_q <= 1'b1;
else if (axi_rvalid_i || axi_bvalid_i)
    request_pending_q <= 1'b0;

//-------------------------------------------------------------
// Outstanding request is posted write
//-------------------------------------------------------------
reg squash_wr_ack_q;

always @ (posedge clk_i )
if (rst_i)
    squash_wr_ack_q <= 1'b0;
else if (write_complete_w)
    squash_wr_ack_q <= req_is_write_w && req_is_posted_w;
else if (axi_bvalid_i)
    squash_wr_ack_q <= 1'b0;

//-------------------------------------------------------------
// ACK
//-------------------------------------------------------------
wire bvalid_w        = axi_bvalid_i & ~squash_wr_ack_q;
assign mem_ack_o     = posted_wr_q || cache_ctrl_q || dmem_access_q || bvalid_w || axi_rvalid_i;
assign mem_error_o   = bvalid_w     ? (axi_bresp_i != 2'b0) : 
                       axi_rvalid_i ? (axi_rresp_i != 2'b0) : 1'b0;

assign mem_data_rd_o = dmem_access_q ? dmem_read_data_w : 
                       cache_ctrl_q  ? reg_cache_ctrl_q :
                       axi_rdata_i;

endmodule

//-----------------------------------------------------------------
// psf_dmem_fifo: FIFO
//-----------------------------------------------------------------
module psf_dmem_fifo
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
    parameter WIDTH   = 8,
    parameter DEPTH   = 2,
    parameter ADDR_W  = 1
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(
    // Inputs
     input               clk_i
    ,input               rst_i
    ,input  [WIDTH-1:0]  data_in_i
    ,input               push_i
    ,input               pop_i

    // Outputs
    ,output [WIDTH-1:0]  data_out_o
    ,output              accept_o
    ,output              valid_o
);

//-----------------------------------------------------------------
// Local Params
//-----------------------------------------------------------------
localparam COUNT_W = ADDR_W + 1;

//-----------------------------------------------------------------
// Registers
//-----------------------------------------------------------------
reg [WIDTH-1:0]   ram_q[DEPTH-1:0];
reg [ADDR_W-1:0]  rd_ptr_q;
reg [ADDR_W-1:0]  wr_ptr_q;
reg [COUNT_W-1:0] count_q;

//-----------------------------------------------------------------
// Sequential
//-----------------------------------------------------------------
always @ (posedge clk_i )
if (rst_i)
begin
    count_q   <= {(COUNT_W) {1'b0}};
    rd_ptr_q  <= {(ADDR_W) {1'b0}};
    wr_ptr_q  <= {(ADDR_W) {1'b0}};
end
else
begin
    // Push
    if (push_i & accept_o)
    begin
        ram_q[wr_ptr_q] <= data_in_i;
        wr_ptr_q        <= wr_ptr_q + 1;
    end

    // Pop
    if (pop_i & valid_o)
        rd_ptr_q      <= rd_ptr_q + 1;

    // Count up
    if ((push_i & accept_o) & ~(pop_i & valid_o))
        count_q <= count_q + 1;
    // Count down
    else if (~(push_i & accept_o) & (pop_i & valid_o))
        count_q <= count_q - 1;
end

//-------------------------------------------------------------------
// Combinatorial
//-------------------------------------------------------------------
/* verilator lint_off WIDTH */
assign valid_o       = (count_q != 0);
assign accept_o      = (count_q != DEPTH);
/* verilator lint_on WIDTH */

assign data_out_o    = ram_q[rd_ptr_q];



endmodule
