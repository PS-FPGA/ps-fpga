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
module tcm_mem_ram
(
    // Inputs
     input           clk0_i
    ,input           rst0_i
    ,input  [ 13:0]  addr0_i
    ,input  [ 31:0]  data0_i
    ,input  [  3:0]  wr0_i
    ,input           clk1_i
    ,input           rst1_i
    ,input  [ 13:0]  addr1_i
    ,input  [ 31:0]  data1_i
    ,input  [  3:0]  wr1_i

    // Outputs
    ,output [ 31:0]  data0_o
    ,output [ 31:0]  data1_o
);



//-----------------------------------------------------------------
// Dual Port RAM 64KB
// Mode: Read First
//-----------------------------------------------------------------
/* verilator lint_off MULTIDRIVEN */
reg [31:0]   ram [16383:0] /*verilator public*/;
/* verilator lint_on MULTIDRIVEN */

initial
begin
    ram[0] = 32'h80000137;
    ram[1] = 32'h40010113;
    ram[2] = 32'h4000ef;
    ram[3] = 32'hff010113;
    ram[4] = 32'h1c80637;
    ram[5] = 32'h112623;
    ram[6] = 32'h40060613;
    ram[7] = 32'h7e380837;
    ram[8] = 32'h900007b7;
    ram[9] = 32'h700593;
    ram[10] = 32'h1c90537;
    ram[11] = 32'h10606b3;
    ram[12] = 32'h22c7aa23;
    ram[13] = 32'h2060613;
    ram[14] = 32'h23c7a703;
    ram[15] = 32'hff77713;
    ram[16] = 32'hfee5fce3;
    ram[17] = 32'h2387a703;
    ram[18] = 32'he6a023;
    ram[19] = 32'h2387a703;
    ram[20] = 32'he6a223;
    ram[21] = 32'h2387a703;
    ram[22] = 32'he6a423;
    ram[23] = 32'h2387a703;
    ram[24] = 32'he6a623;
    ram[25] = 32'h2387a703;
    ram[26] = 32'he6a823;
    ram[27] = 32'h2387a703;
    ram[28] = 32'he6aa23;
    ram[29] = 32'h2387a703;
    ram[30] = 32'he6ac23;
    ram[31] = 32'h2387a703;
    ram[32] = 32'he6ae23;
    ram[33] = 32'hfaa614e3;
    ram[34] = 32'h800007b7;
    ram[35] = 32'h40078793;
    ram[36] = 32'h780e7;
    ram[37] = 32'h6f;
    ram[38] = 32'h0;
    ram[39] = 32'h0;
end

reg [31:0] ram_read0_q;
reg [31:0] ram_read1_q;


// Synchronous write
always @ (posedge clk0_i)
begin
    if (wr0_i[0])
        ram[addr0_i][7:0] <= data0_i[7:0];
    if (wr0_i[1])
        ram[addr0_i][15:8] <= data0_i[15:8];
    if (wr0_i[2])
        ram[addr0_i][23:16] <= data0_i[23:16];
    if (wr0_i[3])
        ram[addr0_i][31:24] <= data0_i[31:24];

    ram_read0_q <= ram[addr0_i];
end

always @ (posedge clk1_i)
begin
    if (wr1_i[0])
        ram[addr1_i][7:0] <= data1_i[7:0];
    if (wr1_i[1])
        ram[addr1_i][15:8] <= data1_i[15:8];
    if (wr1_i[2])
        ram[addr1_i][23:16] <= data1_i[23:16];
    if (wr1_i[3])
        ram[addr1_i][31:24] <= data1_i[31:24];

    ram_read1_q <= ram[addr1_i];
end


assign data0_o = ram_read0_q;
assign data1_o = ram_read1_q;



endmodule
