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
module mpx_exec
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
    ,output          branch_d_request_o
    ,output          branch_d_exception_o
    ,output [ 31:0]  branch_d_pc_o
    ,output          branch_d_priv_o
    ,output [ 31:0]  writeback_value_o
);



//-------------------------------------------------------------
// Includes
//-------------------------------------------------------------
`include "mpx_defs.v"

//-------------------------------------------------------------
// Execute - ALU operations
//-------------------------------------------------------------
reg [3:0]  alu_func_r;
reg [31:0] alu_input_a_r;
reg [31:0] alu_input_b_r;

wire [4:0] rs_idx_w  = opcode_opcode_i[`OPCODE_RS_R];
wire [4:0] rt_idx_w  = opcode_opcode_i[`OPCODE_RT_R];
wire [4:0] rd_idx_w  = opcode_opcode_i[`OPCODE_RD_R];
wire [4:0] re_w      = opcode_opcode_i[`OPCODE_RE_R];

wire [15:0] imm_w    = opcode_opcode_i[`OPCODE_IMM_R];
wire [31:0] u_imm_w  = {16'b0, imm_w};
wire [31:0] s_imm_w  = {{16{imm_w[15]}}, imm_w};

wire [31:0] target_w = {4'b0, opcode_opcode_i[`OPCODE_ADDR_R], 2'b0};
wire [31:0] br_off_w = {s_imm_w[29:0], 2'b0};

always @ *
begin
    alu_func_r     = `ALU_NONE;
    alu_input_a_r  = 32'b0;
    alu_input_b_r  = 32'b0;

    // R Type
    if (opcode_opcode_i[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_opcode_i[`OPCODE_FUNC_R] == `INSTR_R_SLL)
    begin
        // result = reg_rt << re
        alu_func_r     = `ALU_SHIFTL;
        alu_input_a_r  = opcode_rt_operand_i;
        alu_input_b_r  = {27'b0, re_w};
    end
    else if (opcode_opcode_i[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_opcode_i[`OPCODE_FUNC_R] == `INSTR_R_SRL)
    begin
        // result = reg_rt >> re
        alu_func_r     = `ALU_SHIFTR;
        alu_input_a_r  = opcode_rt_operand_i;
        alu_input_b_r  = {27'b0, re_w};
    end
    else if (opcode_opcode_i[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_opcode_i[`OPCODE_FUNC_R] == `INSTR_R_SRA)
    begin
        // result = (int)reg_rt >> re;
        alu_func_r     = `ALU_SHIFTR_ARITH;
        alu_input_a_r  = opcode_rt_operand_i;
        alu_input_b_r  = {27'b0, re_w};
    end
    else if (opcode_opcode_i[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_opcode_i[`OPCODE_FUNC_R] == `INSTR_R_SLLV)
    begin
        // result = reg_rt << reg_rs
        alu_func_r     = `ALU_SHIFTL;
        alu_input_a_r  = opcode_rt_operand_i;
        alu_input_b_r  = opcode_rs_operand_i;
    end
    else if (opcode_opcode_i[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_opcode_i[`OPCODE_FUNC_R] == `INSTR_R_SRLV)
    begin
        // result = reg_rt >> reg_rs
        alu_func_r     = `ALU_SHIFTR;
        alu_input_a_r  = opcode_rt_operand_i;
        alu_input_b_r  = opcode_rs_operand_i;
    end
    else if (opcode_opcode_i[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_opcode_i[`OPCODE_FUNC_R] == `INSTR_R_SRAV)
    begin
        // result = (int)reg_rt >> reg_rs
        alu_func_r     = `ALU_SHIFTR_ARITH;
        alu_input_a_r  = opcode_rt_operand_i;
        alu_input_b_r  = opcode_rs_operand_i;
    end
    else if (opcode_opcode_i[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_opcode_i[`OPCODE_FUNC_R] == `INSTR_R_JALR)
    begin
        // result   = pc_next
        alu_func_r     = `ALU_ADD;
        alu_input_a_r  = opcode_pc_i;
        alu_input_b_r  = 32'd8; // TODO: CHECK...
    end
    else if (opcode_opcode_i[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_opcode_i[`OPCODE_FUNC_R] == `INSTR_R_MFHI)
    begin
        // TODO:
    end
    else if (opcode_opcode_i[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_opcode_i[`OPCODE_FUNC_R] == `INSTR_R_MTHI)
    begin
        // TODO:
    end
    else if (opcode_opcode_i[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_opcode_i[`OPCODE_FUNC_R] == `INSTR_R_MFLO)
    begin
        // TODO:
    end
    else if (opcode_opcode_i[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_opcode_i[`OPCODE_FUNC_R] == `INSTR_R_MTLO)
    begin
        // TODO:
    end
    else if (opcode_opcode_i[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_opcode_i[`OPCODE_FUNC_R] == `INSTR_R_ADD)
    begin
        // result = reg_rs + reg_rt
        // TODO: Arithmetic overflow exception...
        alu_func_r     = `ALU_ADD;
        alu_input_a_r  = opcode_rs_operand_i;
        alu_input_b_r  = opcode_rt_operand_i;
    end
    else if (opcode_opcode_i[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_opcode_i[`OPCODE_FUNC_R] == `INSTR_R_ADDU)
    begin
        // result = reg_rs + reg_rt
        alu_func_r     = `ALU_ADD;
        alu_input_a_r  = opcode_rs_operand_i;
        alu_input_b_r  = opcode_rt_operand_i;
    end
    else if (opcode_opcode_i[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_opcode_i[`OPCODE_FUNC_R] == `INSTR_R_SUB)
    begin
        // result = reg_rs - reg_rt
        // TODO: Arithmetic overflow exception...
        alu_func_r     = `ALU_SUB;
        alu_input_a_r  = opcode_rs_operand_i;
        alu_input_b_r  = opcode_rt_operand_i;
    end
    else if (opcode_opcode_i[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_opcode_i[`OPCODE_FUNC_R] == `INSTR_R_SUBU)
    begin
        // result = reg_rs - reg_rt
        alu_func_r     = `ALU_SUB;
        alu_input_a_r  = opcode_rs_operand_i;
        alu_input_b_r  = opcode_rt_operand_i;
    end
    else if (opcode_opcode_i[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_opcode_i[`OPCODE_FUNC_R] == `INSTR_R_AND)
    begin
        // result = reg_rs & reg_rt
        alu_func_r     = `ALU_AND;
        alu_input_a_r  = opcode_rs_operand_i;
        alu_input_b_r  = opcode_rt_operand_i;
    end
    else if (opcode_opcode_i[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_opcode_i[`OPCODE_FUNC_R] == `INSTR_R_OR)
    begin
        // result = reg_rs | reg_rt
        alu_func_r     = `ALU_OR;
        alu_input_a_r  = opcode_rs_operand_i;
        alu_input_b_r  = opcode_rt_operand_i;
    end
    else if (opcode_opcode_i[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_opcode_i[`OPCODE_FUNC_R] == `INSTR_R_XOR)
    begin
        // result = reg_rs ^ reg_rt
        alu_func_r     = `ALU_XOR;
        alu_input_a_r  = opcode_rs_operand_i;
        alu_input_b_r  = opcode_rt_operand_i;
    end
    else if (opcode_opcode_i[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_opcode_i[`OPCODE_FUNC_R] == `INSTR_R_NOR)
    begin
        // result = ~(reg_rs | reg_rt)
        alu_func_r     = `ALU_NOR;
        alu_input_a_r  = opcode_rs_operand_i;
        alu_input_b_r  = opcode_rt_operand_i;
    end
    else if (opcode_opcode_i[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_opcode_i[`OPCODE_FUNC_R] == `INSTR_R_SLT)
    begin
        // result = (int)reg_rs < (int)reg_rt
        alu_func_r     = `ALU_SLT;
        alu_input_a_r  = opcode_rs_operand_i;
        alu_input_b_r  = opcode_rt_operand_i;
    end
    else if (opcode_opcode_i[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_opcode_i[`OPCODE_FUNC_R] == `INSTR_R_SLTU)
    begin
        // result = reg_rs < reg_rt
        alu_func_r     = `ALU_SLTU;
        alu_input_a_r  = opcode_rs_operand_i;
        alu_input_b_r  = opcode_rt_operand_i;
    end
    // I Type
    else if (opcode_opcode_i[`OPCODE_INST_R] == `INSTR_I_ADDI)
    begin
        // result = reg_rs + (signed short)imm;
        // TODO: Arithmetic overflow exception...
        alu_func_r     = `ALU_ADD;
        alu_input_a_r  = opcode_rs_operand_i;
        alu_input_b_r  = s_imm_w;
    end
    else if (opcode_opcode_i[`OPCODE_INST_R] == `INSTR_I_ADDIU)
    begin
        // result = reg_rs + (signed short)imm
        alu_func_r     = `ALU_ADD;
        alu_input_a_r  = opcode_rs_operand_i;
        alu_input_b_r  = s_imm_w;
    end
    else if (opcode_opcode_i[`OPCODE_INST_R] == `INSTR_I_SLTI)
    begin
        // result = (int)reg_rs < (signed short)imm
        alu_func_r     = `ALU_SLT;
        alu_input_a_r  = opcode_rs_operand_i;
        alu_input_b_r  = s_imm_w;
    end
    else if (opcode_opcode_i[`OPCODE_INST_R] == `INSTR_I_SLTIU)
    begin
        // result = reg_rs < (unsigned int)(signed short)imm
        alu_func_r     = `ALU_SLTU;
        alu_input_a_r  = opcode_rs_operand_i;
        alu_input_b_r  = s_imm_w;
    end
    else if (opcode_opcode_i[`OPCODE_INST_R] == `INSTR_I_ANDI)
    begin
        // result = reg_rs & imm
        alu_func_r     = `ALU_AND;
        alu_input_a_r  = opcode_rs_operand_i;
        alu_input_b_r  = u_imm_w;
    end
    else if (opcode_opcode_i[`OPCODE_INST_R] == `INSTR_I_ORI)
    begin
        // result = reg_rs | imm
        alu_func_r     = `ALU_OR;
        alu_input_a_r  = opcode_rs_operand_i;
        alu_input_b_r  = u_imm_w;
    end
    else if (opcode_opcode_i[`OPCODE_INST_R] == `INSTR_I_XORI)
    begin
        // result = reg_rs ^ imm
        alu_func_r     = `ALU_XOR;
        alu_input_a_r  = opcode_rs_operand_i;
        alu_input_b_r  = u_imm_w;
    end
    else if (opcode_opcode_i[`OPCODE_INST_R] == `INSTR_I_LUI)
    begin
        // result = (imm << 16)
        alu_input_a_r  = {imm_w, 16'b0};
    end
    // Branch cond - write $RA
    else if (opcode_opcode_i[`OPCODE_INST_R] == `INSTR_I_BRCOND && rt_idx_w[4:1] == 4'h8)
    begin
        // result = pc_next
        alu_func_r     = `ALU_ADD;
        alu_input_a_r  = opcode_pc_i;
        alu_input_b_r  = 32'd8; // TODO: CHECK...
    end
    else if (opcode_opcode_i[`OPCODE_INST_R] == `INSTR_J_JAL)
    begin
        // result = pc_next
        alu_func_r     = `ALU_ADD;
        alu_input_a_r  = opcode_pc_i;
        alu_input_b_r  = 32'd8; // TODO: CHECK...
    end
end


//-------------------------------------------------------------
// ALU
//-------------------------------------------------------------
wire [31:0]  alu_p_w;
mpx_alu
u_alu
(
    .alu_op_i(alu_func_r),
    .alu_a_i(alu_input_a_r),
    .alu_b_i(alu_input_b_r),
    .alu_p_o(alu_p_w)
);

//-------------------------------------------------------------
// Flop ALU output
//-------------------------------------------------------------
reg [31:0] result_q;
always @ (posedge clk_i )
if (rst_i)
    result_q  <= 32'b0;
else if (~hold_i)
    result_q <= alu_p_w;

assign writeback_value_o  = result_q;

//-----------------------------------------------------------------
// less_than_signed: Less than operator (signed)
// Inputs: x = left operand, y = right operand
// Return: (int)x < (int)y
//-----------------------------------------------------------------
function [0:0] less_than_signed;
    input  [31:0] x;
    input  [31:0] y;
    reg [31:0] v;
begin
    v = (x - y);
    if (x[31] != y[31])
        less_than_signed = x[31];
    else
        less_than_signed = v[31];
end
endfunction

//-----------------------------------------------------------------
// greater_than_signed: Greater than operator (signed)
// Inputs: x = left operand, y = right operand
// Return: (int)x > (int)y
//-----------------------------------------------------------------
function [0:0] greater_than_signed;
    input  [31:0] x;
    input  [31:0] y;
    reg [31:0] v;
begin
    v = (y - x);
    if (x[31] != y[31])
        greater_than_signed = y[31];
    else
        greater_than_signed = v[31];
end
endfunction

//-------------------------------------------------------------
// Branch operations (decode stage)
//-------------------------------------------------------------
reg        branch_r;
reg        branch_taken_r;
reg [31:0] branch_target_r;

always @ *
begin
    branch_r        = 1'b0;
    branch_taken_r  = 1'b0;
    branch_target_r = 32'b0;

    // branch_target_r = pc_next + offset
    branch_target_r = opcode_pc_i + 32'd4 + br_off_w;

    if (opcode_opcode_i[`OPCODE_INST_R] == `INSTR_J_JAL)
    begin
        branch_r        = 1'b1;
        branch_taken_r  = 1'b1;
        branch_target_r = (opcode_pc_i & 32'hf0000000) | target_w;
    end
    else if (opcode_opcode_i[`OPCODE_INST_R] == `INSTR_J_J)
    begin
        branch_r        = 1'b1;
        branch_taken_r  = 1'b1;
        branch_target_r = (opcode_pc_i & 32'hf0000000) | target_w;
    end
    else if (opcode_opcode_i[`OPCODE_INST_R] == `INSTR_J_BEQ)
    begin
        // take_branch = (reg_rs == reg_rt)
        branch_r        = 1'b1;
        branch_taken_r  = (opcode_rs_operand_i == opcode_rt_operand_i);
    end
    else if (opcode_opcode_i[`OPCODE_INST_R] == `INSTR_J_BNE)
    begin
        // take_branch = (reg_rs != reg_rt)
        branch_r        = 1'b1;
        branch_taken_r  = (opcode_rs_operand_i != opcode_rt_operand_i);
    end
    else if (opcode_opcode_i[`OPCODE_INST_R] == `INSTR_J_BLEZ)
    begin
        // take_branch = ((int)reg_rs <= 0)
        branch_r        = 1'b1;
        branch_taken_r  = less_than_signed(opcode_rs_operand_i, 32'h00000001);
    end
    else if (opcode_opcode_i[`OPCODE_INST_R] == `INSTR_J_BGTZ)
    begin
        // take_branch = ((int)reg_rs > 0)
        branch_r        = 1'b1;
        branch_taken_r  = greater_than_signed(opcode_rs_operand_i, 32'h00000000);
    end
    else if (opcode_opcode_i[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_opcode_i[`OPCODE_FUNC_R] == `INSTR_R_JR)
    begin
        // pc_next  = reg_rs
        branch_r        = 1'b1;
        branch_taken_r  = 1'b1;
        branch_target_r = opcode_rs_operand_i;
    end
    else if (opcode_opcode_i[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_opcode_i[`OPCODE_FUNC_R] == `INSTR_R_JALR)
    begin
        // pc_next  = reg_rs
        branch_r        = 1'b1;
        branch_taken_r  = 1'b1;
        branch_target_r = opcode_rs_operand_i;
    end
    else if (opcode_opcode_i[`OPCODE_INST_R] == `INSTR_I_BRCOND)
    begin
        // >= 0
        if (rt_idx_w[0])
        begin
            // take_branch = ((int)reg_rs >= 0)
            branch_r        = 1'b1;
            branch_taken_r  = greater_than_signed(opcode_rs_operand_i, 32'h00000000) |
                              (opcode_rs_operand_i == 32'b0);        
        end
        else
        begin
            // take_branch = ((int)reg_rs < 0)
            branch_r        = 1'b1;
            branch_taken_r  = less_than_signed(opcode_rs_operand_i, 32'h00000000);        
        end
    end
end

assign branch_d_request_o = (branch_r && opcode_valid_i && branch_taken_r);
assign branch_d_pc_o      = branch_target_r;
assign branch_d_priv_o    = 1'b0; // don't care



endmodule
