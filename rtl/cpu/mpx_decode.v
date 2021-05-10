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
module mpx_decode
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
     parameter SUPPORT_MULDIV   = 1
    ,parameter SUPPORTED_COP    = 5
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(
    // Inputs
     input           clk_i
    ,input           rst_i
    ,input           fetch_in_valid_i
    ,input  [ 31:0]  fetch_in_instr_i
    ,input  [ 31:0]  fetch_in_pc_i
    ,input           fetch_in_delay_slot_i
    ,input           fetch_in_fault_fetch_i
    ,input           fetch_out_accept_i

    // Outputs
    ,output          fetch_in_accept_o
    ,output          fetch_out_valid_o
    ,output [ 31:0]  fetch_out_instr_o
    ,output [ 31:0]  fetch_out_pc_o
    ,output          fetch_out_delay_slot_o
    ,output          fetch_out_fault_fetch_o
    ,output          fetch_out_instr_exec_o
    ,output          fetch_out_instr_lsu_o
    ,output          fetch_out_instr_branch_o
    ,output          fetch_out_instr_mul_o
    ,output          fetch_out_instr_div_o
    ,output          fetch_out_instr_cop0_o
    ,output          fetch_out_instr_cop0_wr_o
    ,output          fetch_out_instr_cop1_o
    ,output          fetch_out_instr_cop1_wr_o
    ,output          fetch_out_instr_cop2_o
    ,output          fetch_out_instr_cop2_wr_o
    ,output          fetch_out_instr_cop3_o
    ,output          fetch_out_instr_cop3_wr_o
    ,output          fetch_out_instr_rd_valid_o
    ,output          fetch_out_instr_rt_is_rd_o
    ,output          fetch_out_instr_lr_is_rd_o
    ,output          fetch_out_instr_invalid_o
);



`include "mpx_defs.v"

wire        valid_w         = fetch_in_valid_i;
wire        fetch_fault_w   = fetch_in_fault_fetch_i;
wire [31:0] opcode_w        = fetch_out_instr_o;
wire        enable_muldiv_w = SUPPORT_MULDIV;
wire [3:0]  enable_cop_w    = SUPPORTED_COP[3:0];

// Move to and from HI/LO registers
wire inst_mfhi_w    = (opcode_w[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_w[`OPCODE_FUNC_R] == `INSTR_R_MFHI) && enable_muldiv_w;
wire inst_mflo_w    = (opcode_w[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_w[`OPCODE_FUNC_R] == `INSTR_R_MFLO) && enable_muldiv_w;
wire inst_mthi_w    = (opcode_w[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_w[`OPCODE_FUNC_R] == `INSTR_R_MTHI) && enable_muldiv_w;
wire inst_mtlo_w    = (opcode_w[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_w[`OPCODE_FUNC_R] == `INSTR_R_MTLO) && enable_muldiv_w;

// COPx + 24-bits of operand
wire inst_cop0_w = (opcode_w[`OPCODE_INST_R] == `INSTR_COP0 && opcode_w[25]) && enable_cop_w[0];
wire inst_cop1_w = (opcode_w[`OPCODE_INST_R] == `INSTR_COP1 && opcode_w[25]) && enable_cop_w[1];
wire inst_cop2_w = (opcode_w[`OPCODE_INST_R] == `INSTR_COP2 && opcode_w[25]) && enable_cop_w[2];
wire inst_cop3_w = (opcode_w[`OPCODE_INST_R] == `INSTR_COP3 && opcode_w[25]) && enable_cop_w[3];

// MFC, MTC, CFC, CTC (COP <-> GPR register move)
wire inst_mfc0_w = (opcode_w[`OPCODE_INST_R] == `INSTR_COP0) && (opcode_w[`OPCODE_RS_R] == 5'b00000) && enable_cop_w[0];
wire inst_cfc0_w = (opcode_w[`OPCODE_INST_R] == `INSTR_COP0) && (opcode_w[`OPCODE_RS_R] == 5'b00010) && enable_cop_w[0];
wire inst_mtc0_w = (opcode_w[`OPCODE_INST_R] == `INSTR_COP0) && (opcode_w[`OPCODE_RS_R] == 5'b00100) && enable_cop_w[0];
wire inst_ctc0_w = (opcode_w[`OPCODE_INST_R] == `INSTR_COP0) && (opcode_w[`OPCODE_RS_R] == 5'b00110) && enable_cop_w[0];
wire inst_mfc1_w = (opcode_w[`OPCODE_INST_R] == `INSTR_COP1) && (opcode_w[`OPCODE_RS_R] == 5'b00000) && enable_cop_w[1];
wire inst_cfc1_w = (opcode_w[`OPCODE_INST_R] == `INSTR_COP1) && (opcode_w[`OPCODE_RS_R] == 5'b00010) && enable_cop_w[1];
wire inst_mtc1_w = (opcode_w[`OPCODE_INST_R] == `INSTR_COP1) && (opcode_w[`OPCODE_RS_R] == 5'b00100) && enable_cop_w[1];
wire inst_ctc1_w = (opcode_w[`OPCODE_INST_R] == `INSTR_COP1) && (opcode_w[`OPCODE_RS_R] == 5'b00110) && enable_cop_w[1];
wire inst_mfc2_w = (opcode_w[`OPCODE_INST_R] == `INSTR_COP2) && (opcode_w[`OPCODE_RS_R] == 5'b00000) && enable_cop_w[2];
wire inst_cfc2_w = (opcode_w[`OPCODE_INST_R] == `INSTR_COP2) && (opcode_w[`OPCODE_RS_R] == 5'b00010) && enable_cop_w[2];
wire inst_mtc2_w = (opcode_w[`OPCODE_INST_R] == `INSTR_COP2) && (opcode_w[`OPCODE_RS_R] == 5'b00100) && enable_cop_w[2];
wire inst_ctc2_w = (opcode_w[`OPCODE_INST_R] == `INSTR_COP2) && (opcode_w[`OPCODE_RS_R] == 5'b00110) && enable_cop_w[2];
wire inst_mfc3_w = (opcode_w[`OPCODE_INST_R] == `INSTR_COP3) && (opcode_w[`OPCODE_RS_R] == 5'b00000) && enable_cop_w[3];
wire inst_cfc3_w = (opcode_w[`OPCODE_INST_R] == `INSTR_COP3) && (opcode_w[`OPCODE_RS_R] == 5'b00010) && enable_cop_w[3];
wire inst_mtc3_w = (opcode_w[`OPCODE_INST_R] == `INSTR_COP3) && (opcode_w[`OPCODE_RS_R] == 5'b00100) && enable_cop_w[3];
wire inst_ctc3_w = (opcode_w[`OPCODE_INST_R] == `INSTR_COP3) && (opcode_w[`OPCODE_RS_R] == 5'b00110) && enable_cop_w[3];

// Return from exception
wire inst_rfe_w     = inst_cop0_w && (opcode_w[`OPCODE_FUNC_R] == 6'b010000);

// Invalid instruction
wire invalid_w =    valid_w && 
                   1'b0; // TODO:

assign fetch_out_instr_invalid_o = invalid_w;

assign fetch_out_instr_rt_is_rd_o =
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_ADDI)  ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_ADDIU) ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_SLTI)  ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_SLTIU) ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_ANDI)  ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_ORI)   ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_XORI)  ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_LUI)   ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_LB)    ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_LH)    ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_LW)    ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_LBU)   ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_LHU)   ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_LWL)   ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_LWR)   ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_COP0)    ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_COP1)    ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_COP2)    ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_COP3);

assign fetch_out_instr_rd_valid_o =
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_ADDI)  ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_ADDIU) ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_SLTI)  ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_SLTIU) ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_ANDI)  ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_ORI)   ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_XORI)  ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_LUI)   ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_w[`OPCODE_FUNC_R] == `INSTR_R_SLL)   ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_w[`OPCODE_FUNC_R] == `INSTR_R_SRL)   ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_w[`OPCODE_FUNC_R] == `INSTR_R_SRA)   ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_w[`OPCODE_FUNC_R] == `INSTR_R_SLLV)  ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_w[`OPCODE_FUNC_R] == `INSTR_R_SRLV)  ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_w[`OPCODE_FUNC_R] == `INSTR_R_SRAV)  ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_w[`OPCODE_FUNC_R] == `INSTR_R_ADD)   ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_w[`OPCODE_FUNC_R] == `INSTR_R_ADDU)  ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_w[`OPCODE_FUNC_R] == `INSTR_R_SUB)   ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_w[`OPCODE_FUNC_R] == `INSTR_R_SUBU)  ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_w[`OPCODE_FUNC_R] == `INSTR_R_AND)   ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_w[`OPCODE_FUNC_R] == `INSTR_R_OR)    ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_w[`OPCODE_FUNC_R] == `INSTR_R_XOR)   ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_w[`OPCODE_FUNC_R] == `INSTR_R_NOR)   ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_w[`OPCODE_FUNC_R] == `INSTR_R_SLT)   ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_w[`OPCODE_FUNC_R] == `INSTR_R_SLTU)  ||
                    inst_mfhi_w  ||
                    inst_mflo_w  ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_LB)   ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_LH)   ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_LW)   ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_LBU)  ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_LHU)  ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_LWL)  ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_LWR)  ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_J_JAL)  ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_w[`OPCODE_FUNC_R] == `INSTR_R_JALR)     ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_BRCOND && ((opcode_w[`OPCODE_RT_R] & `INSTR_I_BRCOND_RA_MASK) == `INSTR_I_BRCOND_RA_WR)) || 
                    inst_mfc0_w ||
                    inst_mfc1_w ||
                    inst_mfc2_w ||
                    inst_mfc3_w ||
                    inst_cfc0_w ||
                    inst_cfc1_w ||
                    inst_cfc2_w ||
                    inst_cfc3_w;

// NOTE: Not currently used
assign fetch_out_instr_exec_o =
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_ADDI)  ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_ADDIU) ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_SLTI)  ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_SLTIU) ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_ANDI)  ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_ORI)   ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_XORI)  ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_LUI)   ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_w[`OPCODE_FUNC_R] == `INSTR_R_SLL)   ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_w[`OPCODE_FUNC_R] == `INSTR_R_SRL)   ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_w[`OPCODE_FUNC_R] == `INSTR_R_SRA)   ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_w[`OPCODE_FUNC_R] == `INSTR_R_SLLV)  ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_w[`OPCODE_FUNC_R] == `INSTR_R_SRLV)  ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_w[`OPCODE_FUNC_R] == `INSTR_R_SRAV)  ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_w[`OPCODE_FUNC_R] == `INSTR_R_ADD)   ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_w[`OPCODE_FUNC_R] == `INSTR_R_ADDU)  ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_w[`OPCODE_FUNC_R] == `INSTR_R_SUB)   ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_w[`OPCODE_FUNC_R] == `INSTR_R_SUBU)  ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_w[`OPCODE_FUNC_R] == `INSTR_R_AND)   ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_w[`OPCODE_FUNC_R] == `INSTR_R_OR)    ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_w[`OPCODE_FUNC_R] == `INSTR_R_XOR)   ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_w[`OPCODE_FUNC_R] == `INSTR_R_NOR)   ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_w[`OPCODE_FUNC_R] == `INSTR_R_SLT)   ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_w[`OPCODE_FUNC_R] == `INSTR_R_SLTU);

assign fetch_out_instr_lsu_o =
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_LB)   ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_LH)   ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_LW)   ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_LBU)  ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_LHU)  ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_LWL)  ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_LWR)  ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_SB)   ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_SH)   ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_SW)   ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_SWL)  ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_SWR)  ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_LWC0 && enable_cop_w[0]) ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_LWC1 && enable_cop_w[1]) ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_LWC2 && enable_cop_w[2]) ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_LWC3 && enable_cop_w[3]) ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_SWC0 && enable_cop_w[0]) ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_SWC1 && enable_cop_w[1]) ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_SWC2 && enable_cop_w[2]) ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_SWC3 && enable_cop_w[3]);

// NOTE: Not currently used
assign fetch_out_instr_branch_o =
                    (opcode_w[`OPCODE_INST_R] == `INSTR_J_JAL)  ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_J_J)    ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_J_BEQ)  ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_J_BNE)  ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_J_BLEZ) ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_J_BGTZ) ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_w[`OPCODE_FUNC_R] == `INSTR_R_JR)       ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_w[`OPCODE_FUNC_R] == `INSTR_R_JALR)     ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_BRCOND);

assign fetch_out_instr_lr_is_rd_o =
                    (opcode_w[`OPCODE_INST_R] == `INSTR_J_JAL)  ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_BRCOND && ((opcode_w[`OPCODE_RT_R] & `INSTR_I_BRCOND_RA_MASK) == `INSTR_I_BRCOND_RA_WR));

assign fetch_out_instr_mul_o =
                    enable_muldiv_w &&
                    ((opcode_w[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_w[`OPCODE_FUNC_R] == `INSTR_R_MULT) ||
                     (opcode_w[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_w[`OPCODE_FUNC_R] == `INSTR_R_MULTU));

assign fetch_out_instr_div_o =
                    enable_muldiv_w &&
                    ((opcode_w[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_w[`OPCODE_FUNC_R] == `INSTR_R_DIV) ||
                     (opcode_w[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_w[`OPCODE_FUNC_R] == `INSTR_R_DIVU));

assign fetch_out_instr_cop0_o =
                    (opcode_w[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_w[`OPCODE_FUNC_R] == `INSTR_R_SYSCALL) ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_w[`OPCODE_FUNC_R] == `INSTR_R_BREAK)   ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_COP0) ||
                    invalid_w   ||
                    fetch_fault_w ||
                    inst_mfhi_w ||
                    inst_mflo_w ||
                    inst_mthi_w ||
                    inst_mtlo_w;

assign fetch_out_instr_cop0_wr_o =
                    inst_mtc0_w ||
                    inst_mthi_w ||
                    inst_mtlo_w ||
                    inst_rfe_w  ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_LWC0 && enable_cop_w[0]);

assign fetch_out_instr_cop1_o =
                   ((opcode_w[`OPCODE_INST_R] == `INSTR_COP1) ||
                    inst_mfc1_w ||
                    inst_cfc1_w ||
                    inst_mtc1_w ||
                    inst_ctc1_w ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_LWC1) ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_SWC1)) && enable_cop_w[1];

assign fetch_out_instr_cop1_wr_o =
                    inst_mtc1_w ||
                    inst_ctc1_w ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_LWC1 && enable_cop_w[1]);

assign fetch_out_instr_cop2_o =
                   ((opcode_w[`OPCODE_INST_R] == `INSTR_COP2) ||
                    inst_mfc2_w ||
                    inst_cfc2_w ||
                    inst_mtc2_w ||
                    inst_ctc2_w ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_LWC2) ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_SWC2)) && enable_cop_w[2];

assign fetch_out_instr_cop2_wr_o =
                    inst_mtc2_w ||
                    inst_ctc2_w ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_LWC2 && enable_cop_w[2]);

assign fetch_out_instr_cop3_o =
                   ((opcode_w[`OPCODE_INST_R] == `INSTR_COP3) ||
                    inst_mfc3_w ||
                    inst_cfc3_w ||
                    inst_mtc3_w ||
                    inst_ctc3_w ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_LWC3) ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_SWC3)) && enable_cop_w[3];

assign fetch_out_instr_cop3_wr_o =
                    inst_mtc3_w ||
                    inst_ctc3_w ||
                    (opcode_w[`OPCODE_INST_R] == `INSTR_I_LWC3 && enable_cop_w[3]);


// Outputs
assign fetch_out_valid_o        = fetch_in_valid_i;
assign fetch_out_pc_o           = fetch_in_pc_i;
assign fetch_out_instr_o        = fetch_in_instr_i;
assign fetch_out_fault_fetch_o  = fetch_in_fault_fetch_i;
assign fetch_out_delay_slot_o   = fetch_in_delay_slot_i;

assign fetch_in_accept_o        = fetch_out_accept_i;




endmodule
