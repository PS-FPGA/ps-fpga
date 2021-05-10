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
module uart_boot
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
     parameter CLK_FREQ         = 30000000
    ,parameter BAUDRATE         = 1000000
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(
    // Inputs
     input           clk_i
    ,input           rst_i
    ,input  [ 31:0]  cfg_addr_i
    ,input  [ 31:0]  cfg_data_wr_i
    ,input           cfg_stb_i
    ,input           cfg_we_i
    ,input           rx_i

    // Outputs
    ,output [ 31:0]  cfg_data_rd_o
    ,output          cfg_ack_o
    ,output          cfg_stall_o
    ,output          tx_o
);



wire tx_space_w;
reg  ack_q;

always @ (posedge clk_i )
if (rst_i)
    ack_q <= 1'b0;
else if (cfg_stb_i && ~cfg_stall_o)
    ack_q <= 1'b1;
else
    ack_q <= 1'b0;

assign cfg_ack_o     = ack_q;
assign cfg_data_rd_o = 32'b0;
`ifdef verilator
assign cfg_stall_o   = ack_q;
`else
assign cfg_stall_o   = ack_q | (~tx_space_w);
`endif

wire    uart_wr_w = cfg_stb_i && ~cfg_stall_o && cfg_we_i && (cfg_addr_i[7:0] == 8'h80);

uart_stream
#(
     .CLK_FREQ(CLK_FREQ)
    ,.BAUDRATE(BAUDRATE)
)
u_core
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)

    ,.inport_valid_i(uart_wr_w)
    ,.inport_data_i(cfg_data_wr_i[7:0])
    ,.inport_accept_o(tx_space_w)

    ,.outport_valid_o()
    ,.outport_data_o()
    ,.outport_accept_i(1'b1)

    ,.rx_i(rx_i)
    ,.tx_o(tx_o)
);



endmodule
