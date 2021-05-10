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
module axi4_upconv256
(
    // Inputs
     input           clk_i
    ,input           rst_i
    ,input           inport_awvalid_i
    ,input  [ 31:0]  inport_awaddr_i
    ,input  [  3:0]  inport_awid_i
    ,input  [  7:0]  inport_awlen_i
    ,input  [  1:0]  inport_awburst_i
    ,input  [  2:0]  inport_awsize_i
    ,input           inport_wvalid_i
    ,input  [ 31:0]  inport_wdata_i
    ,input  [  3:0]  inport_wstrb_i
    ,input           inport_wlast_i
    ,input           inport_bready_i
    ,input           inport_arvalid_i
    ,input  [ 31:0]  inport_araddr_i
    ,input  [  3:0]  inport_arid_i
    ,input  [  7:0]  inport_arlen_i
    ,input  [  1:0]  inport_arburst_i
    ,input  [  2:0]  inport_arsize_i
    ,input           inport_rready_i
    ,input           outport_awready_i
    ,input           outport_wready_i
    ,input           outport_bvalid_i
    ,input  [  1:0]  outport_bresp_i
    ,input  [  3:0]  outport_bid_i
    ,input           outport_arready_i
    ,input           outport_rvalid_i
    ,input  [255:0]  outport_rdata_i
    ,input  [  1:0]  outport_rresp_i
    ,input  [  3:0]  outport_rid_i
    ,input           outport_rlast_i

    // Outputs
    ,output          inport_awready_o
    ,output          inport_wready_o
    ,output          inport_bvalid_o
    ,output [  1:0]  inport_bresp_o
    ,output [  3:0]  inport_bid_o
    ,output          inport_arready_o
    ,output          inport_rvalid_o
    ,output [ 31:0]  inport_rdata_o
    ,output [  1:0]  inport_rresp_o
    ,output [  3:0]  inport_rid_o
    ,output          inport_rlast_o
    ,output          outport_awvalid_o
    ,output [ 31:0]  outport_awaddr_o
    ,output [  3:0]  outport_awid_o
    ,output [  7:0]  outport_awlen_o
    ,output [  1:0]  outport_awburst_o
    ,output          outport_wvalid_o
    ,output [255:0]  outport_wdata_o
    ,output [ 31:0]  outport_wstrb_o
    ,output          outport_wlast_o
    ,output          outport_bready_o
    ,output          outport_arvalid_o
    ,output [ 31:0]  outport_araddr_o
    ,output [  3:0]  outport_arid_o
    ,output [  7:0]  outport_arlen_o
    ,output [  1:0]  outport_arburst_o
    ,output          outport_rready_o
);




//-------------------------------------------------------------
// Limited Upconverter:
// - Support 4 byte reads / writes (with byte mask).
// - Support 32-byte burst read / write with 'aligned' addresses
// - Support INCR bursts only
//-------------------------------------------------------------

//-----------------------------------------------------------------
// Write Command Request
//-----------------------------------------------------------------
wire [43:0] write_cmd_req_out_w;
wire        req_awvalid_w;
wire        req_awready_w;

axi4_upconv256_fifo
#(
    .WIDTH(32+4+8),
    .DEPTH(2),
    .ADDR_W(1)
)
u_write_cmd_req
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)

    ,.push_i(inport_awvalid_i)
    ,.data_in_i({inport_awaddr_i, inport_awid_i, inport_awlen_i})
    ,.accept_o(inport_awready_o)

    ,.valid_o(req_awvalid_w)
    ,.data_out_o(write_cmd_req_out_w)
    ,.pop_i(req_awready_w)
);

wire [31:0] req_awaddr_w;
wire [7:0]  req_awlen_w;
wire [3:0]  req_awid_w;

assign {req_awaddr_w, req_awid_w, req_awlen_w} = write_cmd_req_out_w;

//-----------------------------------------------------------------
// Write Data Request
//-----------------------------------------------------------------
wire        wvalid_w;
wire [31:0] wdata_w;
wire [3:0]  wstrb_w;
wire        wlast_w;
wire        wready_w;

axi4_upconv256_fifo
#(
    .WIDTH(32+4+1),
    .DEPTH(2),
    .ADDR_W(1)
)
u_write_data_req
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)

    ,.push_i(inport_wvalid_i)
    ,.data_in_i({inport_wdata_i, inport_wstrb_i, inport_wlast_i})
    ,.accept_o(inport_wready_o)

    ,.valid_o(wvalid_w)
    ,.data_out_o({wdata_w, wstrb_w, wlast_w})
    ,.pop_i(wready_w)
);

//-----------------------------------------------------------------
// Write roll
//-----------------------------------------------------------------
wire        req_valid_w;
wire        req_pop_w;

axi4_upconv256_dfifo
#(
     .DEPTH(2)
    ,.ADDR_W(1)
)
u_write_data
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)

    ,.awvalid_i(req_awvalid_w)
    ,.awaddr_i(req_awaddr_w)
    ,.awid_i(req_awid_w)
    ,.awready_o(req_awready_w)

    ,.wvalid_i(wvalid_w)
    ,.wdata_i(wdata_w)
    ,.wstrb_i(wstrb_w)
    ,.wlast_i(wlast_w)
    ,.wready_o(wready_w)

    ,.valid_o(req_valid_w)
    ,.awaddr_o(outport_awaddr_o)
    ,.awid_o(outport_awid_o)
    ,.wdata_o(outport_wdata_o)
    ,.wstrb_o(outport_wstrb_o)
    ,.pop_i(req_pop_w)
);

//-----------------------------------------------------------------
// Write Request Output
//-----------------------------------------------------------------
reg awvalid_q;
reg wvalid_q;

wire wr_cmd_accepted_w  = (outport_awvalid_o && outport_awready_i) || awvalid_q;
wire wr_data_accepted_w = (outport_wvalid_o  && outport_wready_i)  || wvalid_q;

always @ (posedge clk_i )
if (rst_i)
    awvalid_q <= 1'b0;
else if (outport_awvalid_o && outport_awready_i && !wr_data_accepted_w)
    awvalid_q <= 1'b1;
else if (wr_data_accepted_w)
    awvalid_q <= 1'b0;

always @ (posedge clk_i )
if (rst_i)
    wvalid_q <= 1'b0;
else if (outport_wvalid_o && outport_wready_i && !wr_cmd_accepted_w)
    wvalid_q <= 1'b1;
else if (wr_cmd_accepted_w)
    wvalid_q <= 1'b0;

assign req_pop_w      = (outport_awready_i | awvalid_q) & (outport_wready_i | wvalid_q);

assign outport_awvalid_o = req_valid_w & ~awvalid_q;
assign outport_awlen_o   = 8'b0; // Max length of burst = 32-bytes
assign outport_awburst_o = 2'b01; // INCR
assign outport_wvalid_o  = req_valid_w & ~wvalid_q;
assign outport_wlast_o   = 1'b1; // Max length of burst = 32-bytes

//-----------------------------------------------------------------
// Write response retiming
//-----------------------------------------------------------------
axi4_upconv256_fifo
#(
     .WIDTH(2+4)
    ,.DEPTH(2)
    ,.ADDR_W(1)
)
u_wr_resp
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)

    ,.push_i(outport_bvalid_i)
    ,.data_in_i({outport_bresp_i, outport_bid_i})
    ,.accept_o(outport_bready_o)

    ,.valid_o(inport_bvalid_o)
    ,.data_out_o({inport_bresp_o, inport_bid_o})
    ,.pop_i(inport_bready_i)
);

//-----------------------------------------------------------------
// Read response alignment tracking
//-----------------------------------------------------------------
wire       fifo_space_w;
wire [2:0] resp_unaligned_w;
wire       resp_single_w;

axi4_upconv256_fifo
#(
     .WIDTH(1+3)
    ,.DEPTH(16)
    ,.ADDR_W(4)
)
u_rd_tracking
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)

    ,.push_i(inport_arvalid_i & inport_arready_o)
    ,.data_in_i({(inport_arlen_i == 8'b0), inport_araddr_i[4:2]})
    ,.accept_o(fifo_space_w)

    ,.valid_o()
    ,.data_out_o({resp_single_w, resp_unaligned_w})
    ,.pop_i(inport_rvalid_o & inport_rlast_o & inport_rready_i)
);

//-----------------------------------------------------------------
// Read Command Request
//-----------------------------------------------------------------
wire [43:0] read_cmd_req_out_w;
wire        req_arvalid_w;
wire        req_arready_w;
wire        rd_cmd_space_w;

axi4_upconv256_fifo
#(
    .WIDTH(32+4+8),
    .DEPTH(2),
    .ADDR_W(1)
)
u_read_cmd_req
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)

    ,.push_i(inport_arvalid_i & inport_arready_o)
    ,.data_in_i({inport_araddr_i, inport_arid_i, inport_arlen_i})
    ,.accept_o(rd_cmd_space_w)

    ,.valid_o(req_arvalid_w)
    ,.data_out_o(read_cmd_req_out_w)
    ,.pop_i(req_arready_w)
);

assign inport_arready_o = rd_cmd_space_w & fifo_space_w;

wire [31:0] req_araddr_w;
wire [7:0]  req_arlen_w;
wire [3:0]  req_arid_w;

assign {req_araddr_w, req_arid_w, req_arlen_w} = read_cmd_req_out_w;

//-----------------------------------------------------------------
// Read Request Output
//-----------------------------------------------------------------
reg          outport_arvalid_r;
reg [ 31:0]  outport_araddr_r;

always @ *
begin
    outport_arvalid_r = req_arvalid_w;
    outport_araddr_r  = {req_araddr_w[31:5], 5'b0};
end

assign req_arready_w     = outport_arready_i;

assign outport_arvalid_o = outport_arvalid_r;
assign outport_araddr_o  = outport_araddr_r;
assign outport_arid_o    = req_arid_w;
assign outport_arlen_o   = 8'b0;  // Max length is 32-bytes
assign outport_arburst_o = 2'b01; // INCR

//--------------------------------------------------------------------
// Response Retime
//--------------------------------------------------------------------
wire         outport_rvalid_w;
wire [1:0]   outport_rresp_w;
wire [3:0]   outport_rid_w;
wire [255:0] outport_rdata_w;
wire         outport_rready_w;

axi4_upconv256_fifo
#(
     .WIDTH(256+4+2)
    ,.DEPTH(4)
    ,.ADDR_W(2)
)
u_read_resp
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)

    ,.push_i(outport_rvalid_i)
    ,.data_in_i({outport_rresp_i, outport_rid_i, outport_rdata_i})
    ,.accept_o(outport_rready_o)

    ,.valid_o(outport_rvalid_w)
    ,.data_out_o({outport_rresp_w, outport_rid_w, outport_rdata_w})
    ,.pop_i(outport_rready_w)
);

//--------------------------------------------------------------------
// Response Unroll
//--------------------------------------------------------------------
reg [2:0] resp_idx_q;

always @ (posedge clk_i )
if (rst_i)
    resp_idx_q <= 3'b0;
else if (inport_rvalid_o & inport_rready_i & inport_rlast_o)
    resp_idx_q <= 3'b0;
else if (inport_rvalid_o & inport_rready_i)
    resp_idx_q <= resp_idx_q + 3'd1;

assign inport_rvalid_o  = outport_rvalid_w;


reg [31:0] inport_rdata_r;

always @ *
begin
    inport_rdata_r = 32'b0;

    case (resp_idx_q | resp_unaligned_w)
    3'd0:    inport_rdata_r = outport_rdata_w[31:0];
    3'd1:    inport_rdata_r = outport_rdata_w[63:32];
    3'd2:    inport_rdata_r = outport_rdata_w[95:64];
    3'd3:    inport_rdata_r = outport_rdata_w[127:96];
    3'd4:    inport_rdata_r = outport_rdata_w[159:128];
    3'd5:    inport_rdata_r = outport_rdata_w[191:160];
    3'd6:    inport_rdata_r = outport_rdata_w[223:192];
    default:    inport_rdata_r = outport_rdata_w[255:224];
    endcase
end

assign inport_rdata_o   = inport_rdata_r;
assign inport_rresp_o   = outport_rresp_w;
assign inport_rid_o     = outport_rid_w;
assign inport_rlast_o   = resp_single_w || (resp_idx_q == 3'd7);

assign outport_rready_w = (resp_single_w || (resp_idx_q == 3'd7)) ? inport_rready_i : 1'b0;

endmodule

//-----------------------------------------------------------------
// FIFO
//-----------------------------------------------------------------
module axi4_upconv256_fifo

//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
    parameter WIDTH   = 8,
    parameter DEPTH   = 4,
    parameter ADDR_W  = 2
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
reg [WIDTH-1:0]         ram [DEPTH-1:0];
reg [ADDR_W-1:0]        rd_ptr;
reg [ADDR_W-1:0]        wr_ptr;
reg [COUNT_W-1:0]       count;

//-----------------------------------------------------------------
// Sequential
//-----------------------------------------------------------------
always @ (posedge clk_i )
if (rst_i)
begin
    count   <= {(COUNT_W) {1'b0}};
    rd_ptr  <= {(ADDR_W) {1'b0}};
    wr_ptr  <= {(ADDR_W) {1'b0}};
end
else
begin
    // Push
    if (push_i & accept_o)
    begin
        ram[wr_ptr] <= data_in_i;
        wr_ptr      <= wr_ptr + 1;
    end

    // Pop
    if (pop_i & valid_o)
        rd_ptr      <= rd_ptr + 1;

    // Count up
    if ((push_i & accept_o) & ~(pop_i & valid_o))
        count <= count + 1;
    // Count down
    else if (~(push_i & accept_o) & (pop_i & valid_o))
        count <= count - 1;
end

//-------------------------------------------------------------------
// Combinatorial
//-------------------------------------------------------------------
/* verilator lint_off WIDTH */
assign accept_o   = (count != DEPTH);
assign valid_o    = (count != 0);
/* verilator lint_on WIDTH */

assign data_out_o = ram[rd_ptr];

endmodule

//-----------------------------------------------------------------
// Data FIFO
//-----------------------------------------------------------------
module axi4_upconv256_dfifo

//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
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

    // Address details
    ,input               awvalid_i
    ,input  [31:0]       awaddr_i
    ,input  [3:0]        awid_i
    ,output              awready_o

    // Data
    ,input               wvalid_i
    ,input  [31:0]       wdata_i
    ,input  [3:0]        wstrb_i
    ,input               wlast_i
    ,output              wready_o

    ,output              valid_o
    ,output [31:0]       awaddr_o
    ,output [3:0]        awid_o
    ,output [255:0]      wdata_o
    ,output [31:0]       wstrb_o
    ,input               pop_i
);

//-----------------------------------------------------------------
// Local Params
//-----------------------------------------------------------------
localparam COUNT_W = ADDR_W + 1;
localparam WIDTH   = 256 + 32 + 32 + 4;

//-----------------------------------------------------------------
// Registers
//-----------------------------------------------------------------
reg [WIDTH-1:0]         ram [DEPTH-1:0];
reg                     rd_ptr_q;
reg                     wr_ptr_q;
reg [COUNT_W-1:0]       count_q;

//-----------------------------------------------------------------
// Burst tracking
//-----------------------------------------------------------------
reg                     in_burst_q;
reg [2:0]               burst_idx_q;

wire push_w = wvalid_i & (in_burst_q | awvalid_i);

assign awready_o = ~in_burst_q & wvalid_i && wready_o;

always @ (posedge clk_i )
if (rst_i)
    in_burst_q <= 1'b0;
else if (push_w && wready_o && wlast_i)
    in_burst_q <= 1'b0;
else if (push_w && wready_o && ~wlast_i)
    in_burst_q <= 1'b1;

always @ (posedge clk_i )
if (rst_i)
    burst_idx_q <= 3'b0;
else if (push_w && wready_o && wlast_i)
    burst_idx_q <= 3'd0;
else if (push_w && wready_o)
    burst_idx_q <= burst_idx_q + 3'd1;

wire [2:0]  offset_w = in_burst_q ? burst_idx_q : awaddr_i[4:2];

//-----------------------------------------------------------------
// Output word staging area
//-----------------------------------------------------------------
reg [255:0] staging_data_q;
reg [255:0] staging_data_r;
reg [31:0]  staging_mask_q;
reg [31:0]  staging_mask_r;

always @ *
begin
    staging_data_r = staging_data_q;
    staging_mask_r = staging_mask_q;

    case (offset_w)
    3'd0:
    begin
        staging_data_r[31:0] = wdata_i;
        staging_mask_r[3:0]    = wstrb_i;
    end
    3'd1:
    begin
        staging_data_r[63:32] = wdata_i;
        staging_mask_r[7:4]    = wstrb_i;
    end
    3'd2:
    begin
        staging_data_r[95:64] = wdata_i;
        staging_mask_r[11:8]    = wstrb_i;
    end
    3'd3:
    begin
        staging_data_r[127:96] = wdata_i;
        staging_mask_r[15:12]    = wstrb_i;
    end
    3'd4:
    begin
        staging_data_r[159:128] = wdata_i;
        staging_mask_r[19:16]    = wstrb_i;
    end
    3'd5:
    begin
        staging_data_r[191:160] = wdata_i;
        staging_mask_r[23:20]    = wstrb_i;
    end
    3'd6:
    begin
        staging_data_r[223:192] = wdata_i;
        staging_mask_r[27:24]    = wstrb_i;
    end
    3'd7:
    begin
        staging_data_r[255:224] = wdata_i;
        staging_mask_r[31:28]    = wstrb_i;
    end
    default: ;
    endcase
end

always @ (posedge clk_i )
if (rst_i)
begin
    staging_data_q <= 256'b0;
    staging_mask_q <= 32'b0;
end
else if (push_w && wready_o && wlast_i)
begin
    staging_data_q <= 256'b0;
    staging_mask_q <= 32'b0;
end
else if (push_w && wready_o)
begin
    staging_data_q <= staging_data_r;
    staging_mask_q <= staging_mask_r;
end

reg [31:0] staging_addr_q;
reg [3:0]  staging_id_q;

always @ (posedge clk_i )
if (rst_i)
begin
    staging_addr_q <= 32'b0;
    staging_id_q   <= 4'b0;
end
else if (awvalid_i && awready_o)
begin
    staging_addr_q <= awaddr_i;
    staging_id_q   <= awid_i;
end

wire [31:0] awaddr_w = awready_o ? awaddr_i : staging_addr_q;
wire [3:0]  awid_w   = awready_o ? awid_i   : staging_id_q;

//-----------------------------------------------------------------
// Sequential
//-----------------------------------------------------------------
reg [COUNT_W-1:0]       count_r;

always @ *
begin
    count_r = count_q;

    if (push_w & wlast_i & wready_o)
        count_r = count_r + 1;

    if (valid_o && pop_i)
        count_r = count_r - 1;
end

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
    if (push_w & wlast_i & wready_o)
    begin
        ram[wr_ptr_q] <= {awaddr_w[31:5], 5'b0, awid_w, staging_mask_r, staging_data_r};
        wr_ptr_q      <= wr_ptr_q + 1;
    end

    // Pop
    if (valid_o && pop_i)
        rd_ptr_q      <= rd_ptr_q + 1;

    count_q <= count_r;
end

//-------------------------------------------------------------------
// Combinatorial
//-------------------------------------------------------------------
/* verilator lint_off WIDTH */
assign wready_o   = (count_q != DEPTH) && (in_burst_q || awvalid_i);
assign valid_o    = (count_q != 0);
/* verilator lint_on WIDTH */

assign {awaddr_o, awid_o, wstrb_o, wdata_o} = ram[rd_ptr_q];



endmodule
