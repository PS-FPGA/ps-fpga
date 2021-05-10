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
module mpx_multiplier
(
    // Inputs
     input           clk_i
    ,input           rst_i
    ,input           opcode_valid_i
    ,input  [ 31:0]  opcode_opcode_i
    ,input  [ 31:0]  opcode_pc_i
    ,input           opcode_invalid_i
    ,input           opcode_delay_slot_i
    ,input  [  4:0]  opcode_rd_idx_i
    ,input  [  4:0]  opcode_rs_idx_i
    ,input  [  4:0]  opcode_rt_idx_i
    ,input  [ 31:0]  opcode_rs_operand_i
    ,input  [ 31:0]  opcode_rt_operand_i
    ,input           hold_i

    // Outputs
    ,output          writeback_valid_o
    ,output [ 31:0]  writeback_hi_o
    ,output [ 31:0]  writeback_lo_o
);



//-------------------------------------------------------------
// Includes
//-------------------------------------------------------------
`include "mpx_defs.v"

localparam MULT_STAGES = 2; // 2 or 3

//-------------------------------------------------------------
// Registers / Wires
//-------------------------------------------------------------
reg          valid_x_q;
reg          valid_m_q;
reg          valid_e3_q;

reg [63:0]   result_m_q;
reg [63:0]   result_e3_q;

reg [32:0]   operand_a_x_q;
reg [32:0]   operand_b_x_q;

//-------------------------------------------------------------
// Multiplier
//-------------------------------------------------------------
wire [64:0]  mult_result_w;
reg  [32:0]  operand_b_r;
reg  [32:0]  operand_a_r;

wire mult_inst_w    = (opcode_opcode_i[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_opcode_i[`OPCODE_FUNC_R] == `INSTR_R_MULT) || 
                      (opcode_opcode_i[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_opcode_i[`OPCODE_FUNC_R] == `INSTR_R_MULTU);

always @ *
begin
    if (opcode_opcode_i[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_opcode_i[`OPCODE_FUNC_R] == `INSTR_R_MULT)
        operand_a_r = {opcode_rs_operand_i[31], opcode_rs_operand_i[31:0]};
    else // MULTU
        operand_a_r = {1'b0, opcode_rs_operand_i[31:0]};
end

always @ *
begin
    if (opcode_opcode_i[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_opcode_i[`OPCODE_FUNC_R] == `INSTR_R_MULT)
        operand_b_r = {opcode_rt_operand_i[31], opcode_rt_operand_i[31:0]};
    else // MULTU
        operand_b_r = {1'b0, opcode_rt_operand_i[31:0]};
end

// Pipeline flops for multiplier
always @(posedge clk_i )
if (rst_i)
begin
    valid_x_q     <= 1'b0;
    operand_a_x_q <= 33'b0;
    operand_b_x_q <= 33'b0;
end
else if (hold_i)
    ;
else if (opcode_valid_i && mult_inst_w)
begin
    valid_x_q     <= 1'b1;
    operand_a_x_q <= operand_a_r;
    operand_b_x_q <= operand_b_r;
end
else
begin
    valid_x_q     <= 1'b0;
    operand_a_x_q <= 33'b0;
    operand_b_x_q <= 33'b0;
end

assign mult_result_w = {{ 32 {operand_a_x_q[32]}}, operand_a_x_q}*{{ 32 {operand_b_x_q[32]}}, operand_b_x_q};

always @(posedge clk_i )
if (rst_i)
    valid_m_q <= 1'b0;
else if (~hold_i)
    valid_m_q <= valid_x_q;

always @(posedge clk_i )
if (rst_i)
    valid_e3_q <= 1'b0;
else if (~hold_i)
    valid_e3_q <= valid_m_q;

always @(posedge clk_i )
if (rst_i)
    result_m_q <= 64'b0;
else if (~hold_i)
    result_m_q <= mult_result_w[63:0];

always @(posedge clk_i )
if (rst_i)
    result_e3_q <= 64'b0;
else if (~hold_i)
    result_e3_q <= result_m_q;

assign writeback_valid_o = (MULT_STAGES == 3) ? valid_e3_q : valid_m_q;
assign writeback_lo_o    = (MULT_STAGES == 3) ? result_e3_q[31:0] : result_m_q[31:0];
assign writeback_hi_o    = (MULT_STAGES == 3) ? result_e3_q[63:32] : result_m_q[63:32];

//-----------------------------------------------------------------
// Simulation Only
//-----------------------------------------------------------------
`ifdef verilator
reg [31:0] stats_mul_q;

always @ (posedge clk_i )
if (rst_i)
    stats_mul_q   <= 32'b0;
else if (opcode_valid_i && mult_inst_w && ~hold_i)
    stats_mul_q   <= stats_mul_q + 32'd1;

`endif


endmodule
