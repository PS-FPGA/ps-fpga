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
module psf_dmem_ram
(
    // Inputs
     input           clk_i
    ,input           rst_i
    ,input  [  7:0]  addr_i
    ,input  [ 31:0]  data_i
    ,input  [  3:0]  wr_i

    // Outputs
    ,output [ 31:0]  data_o
);




//-----------------------------------------------------------------
// Single Port RAM 1KB
// Mode: Read First
//-----------------------------------------------------------------
reg [31:0]   ram [255:0] /*verilator public*/;
reg [31:0]   ram_read_q;


// Synchronous write
always @ (posedge clk_i)
begin
    if (wr_i[0])
        ram[addr_i][7:0] <= data_i[7:0];
    if (wr_i[1])
        ram[addr_i][15:8] <= data_i[15:8];
    if (wr_i[2])
        ram[addr_i][23:16] <= data_i[23:16];
    if (wr_i[3])
        ram[addr_i][31:24] <= data_i[31:24];
    ram_read_q <= ram[addr_i];
end

assign data_o = ram_read_q;


endmodule
