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
module dport_wb
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
     parameter NUM_PORTS        = 4
    ,parameter PORT_SEL_H       = 9
    ,parameter PORT_SEL_L       = 8
    ,parameter PORT_SEL_W       = 2
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
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
    ,input  [ 31:0]  peripheral0_data_rd_i
    ,input           peripheral0_ack_i
    ,input           peripheral0_stall_i
    ,input  [ 31:0]  peripheral1_data_rd_i
    ,input           peripheral1_ack_i
    ,input           peripheral1_stall_i
    ,input  [ 31:0]  peripheral2_data_rd_i
    ,input           peripheral2_ack_i
    ,input           peripheral2_stall_i
    ,input  [ 31:0]  peripheral3_data_rd_i
    ,input           peripheral3_ack_i
    ,input           peripheral3_stall_i

    // Outputs
    ,output [ 31:0]  mem_data_rd_o
    ,output          mem_accept_o
    ,output          mem_ack_o
    ,output          mem_error_o
    ,output [ 10:0]  mem_resp_tag_o
    ,output [ 31:0]  peripheral0_addr_o
    ,output [ 31:0]  peripheral0_data_wr_o
    ,output          peripheral0_stb_o
    ,output          peripheral0_we_o
    ,output [ 31:0]  peripheral1_addr_o
    ,output [ 31:0]  peripheral1_data_wr_o
    ,output          peripheral1_stb_o
    ,output          peripheral1_we_o
    ,output [ 31:0]  peripheral2_addr_o
    ,output [ 31:0]  peripheral2_data_wr_o
    ,output          peripheral2_stb_o
    ,output          peripheral2_we_o
    ,output [ 31:0]  peripheral3_addr_o
    ,output [ 31:0]  peripheral3_data_wr_o
    ,output          peripheral3_stb_o
    ,output          peripheral3_we_o
);



//-----------------------------------------------------------------
// State machine
//-----------------------------------------------------------------
localparam STATE_W          = 1;
localparam STATE_IDLE       = 1'd0;
localparam STATE_ACCESS     = 1'd1;

reg [STATE_W-1:0] state_q;
reg [STATE_W-1:0] next_state_r;

reg               output_stall_r;

always @ *
begin
    next_state_r = state_q;

    case (state_q)
    STATE_IDLE :
    begin
        if ((mem_rd_i || (|mem_wr_i)) && mem_accept_o)
            next_state_r = STATE_ACCESS;
    end
    STATE_ACCESS:
    begin
          if (mem_ack_o)
              next_state_r = STATE_IDLE;
    end    
    default :
       ;
    endcase
end

// Update state
always @ (posedge clk_i )
if (rst_i)
    state_q <= STATE_IDLE;
else
    state_q <= next_state_r;

assign mem_accept_o = (state_q == STATE_IDLE) & ~output_stall_r;

//-----------------------------------------------------------------
// Output Mux
//-----------------------------------------------------------------
wire [NUM_PORTS-1:0] src_w;

assign src_w[0] = mem_addr_i[PORT_SEL_H:PORT_SEL_L] == 2'd0;
assign src_w[1] = mem_addr_i[PORT_SEL_H:PORT_SEL_L] == 2'd1;
assign src_w[2] = mem_addr_i[PORT_SEL_H:PORT_SEL_L] == 2'd2;
assign src_w[3] = mem_addr_i[PORT_SEL_H:PORT_SEL_L] == 2'd3;

reg [NUM_PORTS-1:0]  src_q;

always @ (posedge clk_i )
if (rst_i)
    src_q <= {NUM_PORTS{1'b0}};
else if (mem_accept_o)
    src_q <= src_w;

assign peripheral0_addr_o         = mem_addr_i;
assign peripheral0_data_wr_o      = mem_data_wr_i;
assign peripheral0_we_o           = (|mem_wr_i);
assign peripheral0_stb_o          = (state_q == STATE_IDLE) & src_w[0] & (mem_rd_i || (|mem_wr_i));
assign peripheral1_addr_o         = mem_addr_i;
assign peripheral1_data_wr_o      = mem_data_wr_i;
assign peripheral1_we_o           = (|mem_wr_i);
assign peripheral1_stb_o          = (state_q == STATE_IDLE) & src_w[1] & (mem_rd_i || (|mem_wr_i));
assign peripheral2_addr_o         = mem_addr_i;
assign peripheral2_data_wr_o      = mem_data_wr_i;
assign peripheral2_we_o           = (|mem_wr_i);
assign peripheral2_stb_o          = (state_q == STATE_IDLE) & src_w[2] & (mem_rd_i || (|mem_wr_i));
assign peripheral3_addr_o         = mem_addr_i;
assign peripheral3_data_wr_o      = mem_data_wr_i;
assign peripheral3_we_o           = (|mem_wr_i);
assign peripheral3_stb_o          = (state_q == STATE_IDLE) & src_w[3] & (mem_rd_i || (|mem_wr_i));

always @ *
begin
    output_stall_r = 1'b0;

    case (1'b1)
      src_w[0]     : output_stall_r = peripheral0_stall_i;
      src_w[1]     : output_stall_r = peripheral1_stall_i;
      src_w[2]     : output_stall_r = peripheral2_stall_i;
      src_w[3]     : output_stall_r = peripheral3_stall_i;
    endcase
end

//-----------------------------------------------------------------
// Response 
//-----------------------------------------------------------------
reg        outport_ack_r;
reg [31:0] outport_data_r;

always @ *
begin
    outport_ack_r  = 1'b0;
    outport_data_r = 32'b0;

    case (1'b1)
      src_q[0]     : outport_ack_r = peripheral0_ack_i;
      src_q[1]     : outport_ack_r = peripheral1_ack_i;
      src_q[2]     : outport_ack_r = peripheral2_ack_i;
      src_q[3]     : outport_ack_r = peripheral3_ack_i;
    endcase

    case (1'b1)
      src_q[0]     : outport_data_r = peripheral0_data_rd_i;
      src_q[1]     : outport_data_r = peripheral1_data_rd_i;
      src_q[2]     : outport_data_r = peripheral2_data_rd_i;
      src_q[3]     : outport_data_r = peripheral3_data_rd_i;
    endcase    
end

assign mem_ack_o     = (state_q == STATE_ACCESS) & outport_ack_r;
assign mem_data_rd_o = outport_data_r;
assign mem_error_o   = 1'b0;

reg [10:0] tag_q;

always @ (posedge clk_i )
if (rst_i)
    tag_q <= 11'b0;
else if (mem_accept_o)
    tag_q <= mem_req_tag_i;

assign mem_resp_tag_o = tag_q;


endmodule
