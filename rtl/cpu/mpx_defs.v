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

//--------------------------------------------------------------------
// ALU Operations
//--------------------------------------------------------------------
`define ALU_NONE            4'd0
`define ALU_SHIFTL          4'd1
`define ALU_SHIFTR          4'd2
`define ALU_SHIFTR_ARITH    4'd3
`define ALU_ADD             4'd4
`define ALU_SUB             4'd5
`define ALU_AND             4'd6
`define ALU_OR              4'd7
`define ALU_XOR             4'd8
`define ALU_NOR             4'd9
`define ALU_SLT             4'd10
`define ALU_SLTE            4'd11
`define ALU_SLTU            4'd12

//--------------------------------------------------------------------
// Instruction Encoding
//--------------------------------------------------------------------  
`define OPCODE_INST_R       31:26
`define OPCODE_RS_R         25:21
`define OPCODE_RT_R         20:16
`define OPCODE_RD_R         15:11
`define OPCODE_RE_R         10:6
`define OPCODE_FUNC_R       5:0
`define OPCODE_IMM_R        15:0
`define OPCODE_ADDR_R       25:0

//--------------------------------------------------------------------
// R Type
//--------------------------------------------------------------------
`define INSTR_R_SPECIAL     6'h00
`define INSTR_R_SLL         6'h00
`define INSTR_R_SRL         6'h02
`define INSTR_R_SRA         6'h03
`define INSTR_R_SLLV        6'h04
`define INSTR_R_SRLV        6'h06
`define INSTR_R_SRAV        6'h07
`define INSTR_R_JR          6'h08
`define INSTR_R_JALR        6'h09
`define INSTR_R_SYSCALL     6'h0c
`define INSTR_R_BREAK       6'h0d
`define INSTR_R_MFHI        6'h10
`define INSTR_R_MTHI        6'h11
`define INSTR_R_MFLO        6'h12
`define INSTR_R_MTLO        6'h13
`define INSTR_R_MULT        6'h18
`define INSTR_R_MULTU       6'h19
`define INSTR_R_DIV         6'h1a
`define INSTR_R_DIVU        6'h1b
`define INSTR_R_ADD         6'h20
`define INSTR_R_ADDU        6'h21
`define INSTR_R_SUB         6'h22
`define INSTR_R_SUBU        6'h23
`define INSTR_R_AND         6'h24
`define INSTR_R_OR          6'h25
`define INSTR_R_XOR         6'h26
`define INSTR_R_NOR         6'h27
`define INSTR_R_SLT         6'h2a
`define INSTR_R_SLTU        6'h2b

`define INSTR_COP0          6'h10
`define INSTR_COP1          6'h11
`define INSTR_COP2          6'h12
`define INSTR_COP3          6'h13

// NOP (duplicate - actually SLL)
`define INSTR_NOP           32'b0

//--------------------------------------------------------------------
// J Type
//--------------------------------------------------------------------
`define INSTR_J_JAL         6'h03
`define INSTR_J_J           6'h02
`define INSTR_J_BEQ         6'h04
`define INSTR_J_BNE         6'h05
`define INSTR_J_BLEZ        6'h06
`define INSTR_J_BGTZ        6'h07

//--------------------------------------------------------------------
// I Type
//--------------------------------------------------------------------
`define INSTR_I_ADDI        6'h08
`define INSTR_I_ADDIU       6'h09
`define INSTR_I_SLTI        6'h0a
`define INSTR_I_SLTIU       6'h0b
`define INSTR_I_ANDI        6'h0c
`define INSTR_I_ORI         6'h0d
`define INSTR_I_XORI        6'h0e
`define INSTR_I_LUI         6'h0f
`define INSTR_I_LB          6'h20
`define INSTR_I_LH          6'h21
`define INSTR_I_LW          6'h23
`define INSTR_I_LBU         6'h24
`define INSTR_I_LHU         6'h25
`define INSTR_I_SB          6'h28
`define INSTR_I_SH          6'h29
`define INSTR_I_SW          6'h2b

`define INSTR_I_BRCOND      6'h01
    `define INSTR_I_BRCOND_GTE_R 0:0
    `define INSTR_I_BRCOND_RA_MASK  5'h1e
    `define INSTR_I_BRCOND_RA_WR    5'h10

`define INSTR_I_LWL         6'h22
`define INSTR_I_LWR         6'h26
`define INSTR_I_SWL         6'h2a
`define INSTR_I_SWR         6'h2e

`define INSTR_I_LWC0        6'h30
`define INSTR_I_LWC1        6'h31
`define INSTR_I_LWC2        6'h32
`define INSTR_I_LWC3        6'h33
`define INSTR_I_SWC0        6'h38
`define INSTR_I_SWC1        6'h39
`define INSTR_I_SWC2        6'h3a
`define INSTR_I_SWC3        6'h3b

//--------------------------------------------------------------------
// COP0
//--------------------------------------------------------------------
`define COP0_RFE            5'h10
`define COP0_MFC0           5'h00
`define COP0_MTC0           5'h04

`define COP0_STATUS         5'd12 // Processor status and control
    `define COP0_SR_IEC         0 // Interrupt enable (current)
    `define COP0_SR_KUC         1 // User mode (current)
    `define COP0_SR_IEP         2 // Interrupt enable (previous)
    `define COP0_SR_KUP         3 // User mode (previous)
    `define COP0_SR_IEO         4 // Interrupt enable (old)
    `define COP0_SR_KUO         5 // User mode (old)
    `define COP0_SR_IM0         8 // Interrupt mask
    `define COP0_SR_IM_MASK     8'hFF
    `define COP0_SR_IM_R        15:8
    `define COP0_SR_CU0         28 // User mode enable to COPx
    `define COP0_SR_CU_MASK     4'hF
`define COP0_CAUSE          5'd13 // Cause of last general exception
    `define COP0_CAUSE_EXC      2
    `define COP0_CAUSE_EXC_MASK 5'h1F
    `define COP0_CAUSE_EXC_R    5:2
    `define COP0_CAUSE_IP0      8
    `define COP0_CAUSE_IP_MASK  8'hFF
    `define COP0_CAUSE_IP1_0_R  9:8
    `define COP0_CAUSE_IP_R     15:8
    `define COP0_CAUSE_IV       23
    `define COP0_CAUSE_CE       28
    `define COP0_CAUSE_CE_MASK  3'h7
    `define COP0_CAUSE_BD       31
`define COP0_EPC            5'd14 // Program counter at last exception
`define COP0_BADADDR        5'd8  // Bad address value
`define COP0_PRID           5'd15 // Processor identification and revision
`define COP0_COUNT          5'd9  // Processor cycle count (Non-std)

// Custom Extensions
`define COP0_SCRATCH        5'd22
`define COP0_ESTATUS        5'd23
`define COP0_EEPC           5'd24
`define COP0_ECAUSE         5'd25
`define COP0_DRFE           5'd26

//--------------------------------------------------------------------
// Exception Causes
//--------------------------------------------------------------------
`define EXCEPTION_W         6
`define EXCEPTION_INT       6'h20  // Interrupt
`define EXCEPTION_NMI       6'h21  // NMI
`define EXCEPTION_ADEL      6'h14  // Address error exception (load or instruction fetch)
`define EXCEPTION_ADES      6'h15  // Address error exception (store)
`define EXCEPTION_IBE       6'h16  // Bus error exception (instruction fetch)
`define EXCEPTION_DBE       6'h17  // Bus error exception (data reference: load or store)
`define EXCEPTION_SYS       6'h18  // Syscall exception
`define EXCEPTION_BP        6'h19  // Breakpoint exception
`define EXCEPTION_RI        6'h1a  // Reserved instruction exception
`define EXCEPTION_CPU       6'h1b  // Coprocessor Unusable exception 
`define EXCEPTION_OV        6'h1c  // Arithmetic Overflow exception
`define EXCEPTION_MASK      6'h10
