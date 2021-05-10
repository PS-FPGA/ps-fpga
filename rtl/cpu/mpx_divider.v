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
module mpx_divider
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

    // Outputs
    ,output          writeback_valid_o
    ,output [ 31:0]  writeback_hi_o
    ,output [ 31:0]  writeback_lo_o
);



//-------------------------------------------------------------
// Includes
//-------------------------------------------------------------
`include "mpx_defs.v"

//-------------------------------------------------------------
// Registers / Wires
//-------------------------------------------------------------
reg          valid_q;
reg  [31:0]  wb_hi_q;
reg  [31:0]  wb_lo_q;

//-------------------------------------------------------------
// Divider
//-------------------------------------------------------------
wire inst_div_w         = opcode_opcode_i[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_opcode_i[`OPCODE_FUNC_R] == `INSTR_R_DIV;
wire inst_divu_w        = opcode_opcode_i[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_opcode_i[`OPCODE_FUNC_R] == `INSTR_R_DIVU;

wire div_rem_inst_w     = inst_div_w | inst_divu_w;

wire signed_operation_w = inst_div_w;

reg [31:0] dividend_q;
reg [62:0] divisor_q;
reg [31:0] quotient_q;
reg [31:0] q_mask_q;
reg        div_busy_q;
reg        invert_div_q;
reg        invert_mod_q;

wire div_start_w    = opcode_valid_i & div_rem_inst_w;
wire div_complete_w = !(|q_mask_q) & div_busy_q;

always @(posedge clk_i )
if (rst_i)
begin
    div_busy_q     <= 1'b0;
    dividend_q     <= 32'b0;
    divisor_q      <= 63'b0;
    invert_div_q   <= 1'b0;
    invert_mod_q   <= 1'b0;
    quotient_q     <= 32'b0;
    q_mask_q       <= 32'b0;
end
else if (div_start_w)
begin
    div_busy_q     <= 1'b1;

    if (signed_operation_w && opcode_rs_operand_i[31])
        dividend_q <= -opcode_rs_operand_i;
    else
        dividend_q <= opcode_rs_operand_i;

    if (signed_operation_w && opcode_rt_operand_i[31])
        divisor_q <= {-opcode_rt_operand_i, 31'b0};
    else
        divisor_q <= {opcode_rt_operand_i, 31'b0};

    invert_div_q   <= signed_operation_w && (opcode_rs_operand_i[31] != opcode_rt_operand_i[31]);
    invert_mod_q   <= signed_operation_w && opcode_rs_operand_i[31];
    quotient_q     <= 32'b0;
    q_mask_q       <= 32'h80000000;
end
else if (div_complete_w)
begin
    div_busy_q <= 1'b0;
end
else if (div_busy_q)
begin
    if (divisor_q <= {31'b0, dividend_q})
    begin
        dividend_q <= dividend_q - divisor_q[31:0];
        quotient_q <= quotient_q | q_mask_q;
    end

    divisor_q <= {1'b0, divisor_q[62:1]};
    q_mask_q  <= {1'b0, q_mask_q[31:1]};
end

reg [31:0] div_result_r;
reg [31:0] mod_result_r;
always @ *
begin
    div_result_r = invert_div_q ? -quotient_q : quotient_q;
    mod_result_r = invert_mod_q ? -dividend_q : dividend_q;
end

always @(posedge clk_i )
if (rst_i)
    valid_q <= 1'b0;
else
    valid_q <= div_complete_w;

always @(posedge clk_i )
if (rst_i)
    wb_lo_q <= 32'b0;
else if (div_complete_w)
    wb_lo_q <= div_result_r;

always @(posedge clk_i )
if (rst_i)
    wb_hi_q <= 32'b0;
else if (div_complete_w)
    wb_hi_q <= mod_result_r;

assign writeback_valid_o = valid_q;
assign writeback_lo_o    = wb_lo_q;
assign writeback_hi_o    = wb_hi_q;

//-----------------------------------------------------------------
// Simulation Only
//-----------------------------------------------------------------
`ifdef verilator
reg [31:0] stats_div_q;

always @ (posedge clk_i )
if (rst_i)
    stats_div_q   <= 32'b0;
else if (div_start_w)
    stats_div_q   <= stats_div_q + 32'd1;

`endif


endmodule
