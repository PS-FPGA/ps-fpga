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
module dma_axi4_rd_arb
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
     parameter PORT_SEL_H       = 0
    ,parameter PORT_SEL_L       = 0
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(
     input           clk_i
    ,input           rst_i

    ,input           inport0_arvalid_i
    ,input  [ 31:0]  inport0_araddr_i
    ,input  [  3:0]  inport0_arid_i
    ,input  [  7:0]  inport0_arlen_i
    ,input  [  1:0]  inport0_arburst_i
    ,input           inport0_rready_i
    ,output          inport0_arready_o
    ,output          inport0_rvalid_o
    ,output [ 31:0]  inport0_rdata_o
    ,output [  1:0]  inport0_rresp_o
    ,output [  3:0]  inport0_rid_o
    ,output          inport0_rlast_o

    ,input           inport1_arvalid_i
    ,input  [ 31:0]  inport1_araddr_i
    ,input  [  3:0]  inport1_arid_i
    ,input  [  7:0]  inport1_arlen_i
    ,input  [  1:0]  inport1_arburst_i
    ,input           inport1_rready_i
    ,output          inport1_arready_o
    ,output          inport1_rvalid_o
    ,output [ 31:0]  inport1_rdata_o
    ,output [  1:0]  inport1_rresp_o
    ,output [  3:0]  inport1_rid_o
    ,output          inport1_rlast_o

    ,output          outport_arvalid_o
    ,output [ 31:0]  outport_araddr_o
    ,output [  3:0]  outport_arid_o
    ,output [  7:0]  outport_arlen_o
    ,output [  1:0]  outport_arburst_o
    ,output          outport_rready_o
    ,input           outport_arready_i
    ,input           outport_rvalid_i
    ,input  [ 31:0]  outport_rdata_i
    ,input  [  1:0]  outport_rresp_i
    ,input  [  3:0]  outport_rid_i
    ,input           outport_rlast_i
);

//-----------------------------------------------------------------
// Read Requestor Select
//-----------------------------------------------------------------
wire [1:0] read_req_w;
reg        read_hold_q;
wire [1:0] read_grant_w;

assign read_req_w[0] = inport0_arvalid_i;
assign read_req_w[1] = inport1_arvalid_i;

dma_axi4_rd_arb_onehot2
u_rd_arb
(
    .clk_i(clk_i),
    .rst_i(rst_i),

    .hold_i(read_hold_q),
    .request_i(read_req_w),
    .grant_o(read_grant_w)
);

//-----------------------------------------------------------------
// Read Hold
//-----------------------------------------------------------------
always @ (posedge clk_i )
if (rst_i)
    read_hold_q  <= 1'b0;
else if (outport_arvalid_o && !outport_arready_i)
    read_hold_q  <= 1'b1;
else if (outport_arready_i)
    read_hold_q  <= 1'b0;

//-----------------------------------------------------------------
// Read Request Mux
//-----------------------------------------------------------------
reg          outport_arvalid_r;
reg [ 31:0]  outport_araddr_r;
reg [  3:0]  outport_arid_r;
reg [  7:0]  outport_arlen_r;
reg [  1:0]  outport_arburst_r;

always @ *
begin
    outport_arvalid_r = 1'b0;
    outport_araddr_r  = 32'b0;
    outport_arid_r    = 4'b0;
    outport_arlen_r   = 8'b0;
    outport_arburst_r = 2'b0;

    case (1'b1)
    default: // Input 0
    begin
        outport_arvalid_r = inport0_arvalid_i;
        outport_araddr_r  = inport0_araddr_i;
        outport_arid_r    = inport0_arid_i;
        outport_arlen_r   = inport0_arlen_i;
        outport_arburst_r = inport0_arburst_i;
    end
    read_grant_w[1]:
    begin
        outport_arvalid_r = inport1_arvalid_i;
        outport_araddr_r  = inport1_araddr_i;
        outport_arid_r    = inport1_arid_i;
        outport_arlen_r   = inport1_arlen_i;
        outport_arburst_r = inport1_arburst_i;
    end
    endcase
end

assign outport_arvalid_o = outport_arvalid_r;
assign outport_araddr_o  = outport_araddr_r;
assign outport_arid_o    = outport_arid_r;
assign outport_arlen_o   = outport_arlen_r;
assign outport_arburst_o = outport_arburst_r;

//-----------------------------------------------------------------
// Read Handshaking Demux
//-----------------------------------------------------------------
assign inport0_arready_o = read_grant_w[0] ? outport_arready_i : 1'b0;
assign inport1_arready_o = read_grant_w[1] ? outport_arready_i : 1'b0;

//-----------------------------------------------------------------
// Read Response Routing
//-----------------------------------------------------------------
reg [1:0] rd_resp_target_r;

always @ *
begin
    rd_resp_target_r = 2'b0;

    case (outport_rid_i[PORT_SEL_H:PORT_SEL_L])
    1'd0:
        rd_resp_target_r[0] = 1'b1;
    1'd1:
        rd_resp_target_r[1] = 1'b1;
    default:
        rd_resp_target_r[0] = 1'b1;
    endcase
end

wire [1:0] inport_rready_w;
assign inport_rready_w[0] = inport0_rready_i;
assign inport_rready_w[1] = inport1_rready_i;

assign outport_rready_o = (inport_rready_w & rd_resp_target_r) != 2'b0;

assign inport0_rvalid_o = outport_rvalid_i & rd_resp_target_r[0];
assign inport0_rdata_o  = outport_rdata_i;
assign inport0_rid_o    = outport_rid_i;
assign inport0_rresp_o  = outport_rresp_i;
assign inport0_rlast_o  = outport_rlast_i;
assign inport1_rvalid_o = outport_rvalid_i & rd_resp_target_r[1];
assign inport1_rdata_o  = outport_rdata_i;
assign inport1_rid_o    = outport_rid_i;
assign inport1_rresp_o  = outport_rresp_i;
assign inport1_rlast_o  = outport_rlast_i;

endmodule

//-----------------------------------------------------------------
// One Hot Arbiter
//-----------------------------------------------------------------
module dma_axi4_rd_arb_onehot2
(
    // Inputs
     input         clk_i
    ,input         rst_i
    ,input         hold_i
    ,input  [1:0]  request_i

    // Outputs
    ,output [1:0]  grant_o
);

//-----------------------------------------------------------------
// Registers / Wires
//-----------------------------------------------------------------
wire [1:0] req_ffs_masked_w;
wire [1:0] req_ffs_unmasked_w;
wire [1:0] req_ffs_w;

reg  [1:0] mask_next_q;
reg  [1:0] grant_last_q;
wire [1:0] grant_new_w;

//-----------------------------------------------------------------
// ffs: Find first set
//-----------------------------------------------------------------
function [1:0] ffs;
    input [1:0] request;
begin
    ffs[0] = request[0];
    ffs[1] = ffs[0] | request[1];
end
endfunction

assign req_ffs_masked_w = ffs(request_i & mask_next_q);
assign req_ffs_unmasked_w = ffs(request_i);

assign req_ffs_w = (|req_ffs_masked_w) ? req_ffs_masked_w : req_ffs_unmasked_w;

always @ (posedge clk_i )
if (rst_i)
begin
    mask_next_q <= {2{1'b1}};
    grant_last_q <= 2'b0;
end
else
begin
    if (~hold_i)
        mask_next_q <= {req_ffs_w[0:0], 1'b0};
    
    grant_last_q <= grant_o;
end

assign grant_new_w = req_ffs_w ^ {req_ffs_w[0:0], 1'b0};
assign grant_o = hold_i ? grant_last_q : grant_new_w;

endmodule
