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
module dma_rr_arb
(
    // Inputs
     input           clk_i
    ,input           rst_i
    ,input           hold_i
    ,input  [  6:0]  request_i

    // Outputs
    ,output [  6:0]  grant_o
);

//-----------------------------------------------------------------
// Registers / Wires
//-----------------------------------------------------------------
wire [6:0] req_ffs_masked_w;
wire [6:0] req_ffs_unmasked_w;
wire [6:0] req_ffs_w;

reg  [6:0] mask_next_q;
reg  [6:0] grant_last_q;
wire [6:0] grant_new_w;

//-----------------------------------------------------------------
// ffs: Find first set
//-----------------------------------------------------------------
function [6:0] ffs;
    input [6:0] request;
begin
    ffs[0] = request[0];
    ffs[1] = ffs[0] | request[1];
    ffs[2] = ffs[1] | request[2];
    ffs[3] = ffs[2] | request[3];
    ffs[4] = ffs[3] | request[4];
    ffs[5] = ffs[4] | request[5];
    ffs[6] = ffs[5] | request[6];
end
endfunction

assign req_ffs_masked_w = ffs(request_i & mask_next_q);
assign req_ffs_unmasked_w = ffs(request_i);

assign req_ffs_w = (|req_ffs_masked_w) ? req_ffs_masked_w : req_ffs_unmasked_w;

always @ (posedge clk_i )
if (rst_i)
begin
    mask_next_q <= {7{1'b1}};
    grant_last_q <= 7'b0;
end
else
begin
    if (~hold_i)
        mask_next_q <= {req_ffs_w[5:0], 1'b0};
    
    grant_last_q <= grant_o;
end

assign grant_new_w = req_ffs_w ^ {req_ffs_w[5:0], 1'b0};
assign grant_o = hold_i ? grant_last_q : grant_new_w;

endmodule
