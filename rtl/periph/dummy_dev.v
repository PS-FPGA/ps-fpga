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
module dummy_dev
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



reg ack_q;

always @ (posedge clk_i )
if (rst_i)
    ack_q <= 1'b0;
else if (cfg_stb_i && ~cfg_stall_o)
    ack_q <= 1'b1;
else
    ack_q <= 1'b0;

assign cfg_ack_o     = ack_q;
assign cfg_data_rd_o = 32'b0;
assign cfg_stall_o   = ack_q;

//-----------------------------------------------------------------
// Local Params
//-----------------------------------------------------------------
localparam WIDTH   = 32;
localparam DEPTH   = 16;
localparam ADDR_W  = 4;
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
always @ (posedge clk_i or posedge rst_i)
if (rst_i)
begin
    count_q   <= {(COUNT_W) {1'b0}};
    rd_ptr_q  <= {(ADDR_W) {1'b0}};
    wr_ptr_q  <= {(ADDR_W) {1'b0}};
end
else
begin
    // Push
    if (m2p_valid_i & m2p_accept_o)
    begin
        ram_q[wr_ptr_q] <= m2p_data_i;
        wr_ptr_q        <= wr_ptr_q + 1;
    end

    // Pop
    if (p2m_accept_i & p2m_valid_o)
        rd_ptr_q      <= rd_ptr_q + 1;

    // Count up
    if ((m2p_valid_i & m2p_accept_o) & ~(p2m_accept_i & p2m_valid_o))
        count_q <= count_q + 1;
    // Count down
    else if (~(m2p_valid_i & m2p_accept_o) & (p2m_accept_i & p2m_valid_o))
        count_q <= count_q - 1;
end

//-------------------------------------------------------------------
// Combinatorial
//-------------------------------------------------------------------
/* verilator lint_off WIDTH */
assign p2m_valid_o       = (count_q != 0);
assign m2p_accept_o      = (count_q != DEPTH);
/* verilator lint_on WIDTH */

assign p2m_data_o        = ram_q[rd_ptr_q];

assign m2p_dreq_o        = (count_q == 0);
assign p2m_dreq_o        = (count_q != 0);



endmodule
