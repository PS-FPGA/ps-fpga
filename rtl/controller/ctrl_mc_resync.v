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
module ctrl_mc_resync
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
    parameter RESET_VAL = 1'b0
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(
    input  clk_i,
    input  rst_i,
    input  async_i,
    output sync_o
);

(* ASYNC_REG = "TRUE" *) reg sync_ms;
(* ASYNC_REG = "TRUE" *) reg sync_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
begin
    sync_ms  <= RESET_VAL;
    sync_q   <= RESET_VAL;
end
else
begin
    sync_ms  <= async_i;
    sync_q   <= sync_ms;
end

// Glitch filter - the controller ACK line is known to glitch low for <100ns
// at the start of the command. The actual intended ACK is low for > 2uS.
reg last_sync_q;
always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    last_sync_q <= 1'b1;
else
    last_sync_q <= sync_q;

wire change_w  = sync_q ^ last_sync_q;

localparam THRESHOLD = 8'd4;

reg [7:0] count_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    count_q <= 8'b0;
else if (change_w)
    count_q <= 8'b0;
else if (count_q != 8'd255)
	count_q <= count_q + 8'd1;

reg output_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    output_q <= 1'b1;
else if (count_q >= THRESHOLD)
    output_q <= last_sync_q;

assign sync_o = output_q;

endmodule
