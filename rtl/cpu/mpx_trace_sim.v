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
`include "mpx_defs.v"

module mpx_trace_sim
(
     input                        valid_i
    ,input  [31:0]                pc_i
    ,input  [31:0]                opcode_i
);

//-----------------------------------------------------------------
// get_regname_str: Convert register number to string
//-----------------------------------------------------------------
`ifdef verilator
function [79:0] get_regname_str;
    input  [4:0] regnum;
begin
    case (regnum)
    5'd0:  get_regname_str = "zero";
    5'd1:  get_regname_str = "at";
    5'd2:  get_regname_str = "v0";
    5'd3:  get_regname_str = "v1";
    5'd4:  get_regname_str = "a0";
    5'd5:  get_regname_str = "a1";
    5'd6:  get_regname_str = "a2";
    5'd7:  get_regname_str = "a3";
    5'd8:  get_regname_str = "t0";
    5'd9:  get_regname_str = "t1";
    5'd10:  get_regname_str = "t2";
    5'd11:  get_regname_str = "t3";
    5'd12:  get_regname_str = "t4";
    5'd13:  get_regname_str = "t5";
    5'd14:  get_regname_str = "t6";
    5'd15:  get_regname_str = "t7";
    5'd16:  get_regname_str = "s0";
    5'd17:  get_regname_str = "s1";
    5'd18:  get_regname_str = "s2";
    5'd19:  get_regname_str = "s3";
    5'd20:  get_regname_str = "s4";
    5'd21:  get_regname_str = "s5";
    5'd22:  get_regname_str = "s6";
    5'd23:  get_regname_str = "s7";
    5'd24:  get_regname_str = "t8";
    5'd25:  get_regname_str = "t9";
    5'd26:  get_regname_str = "k0";
    5'd27:  get_regname_str = "k1";
    5'd28:  get_regname_str = "gp";
    5'd29:  get_regname_str = "sp";
    5'd30:  get_regname_str = "fp";
    5'd31:  get_regname_str = "ra";
    endcase
end
endfunction

//-------------------------------------------------------------------
// Debug strings
//-------------------------------------------------------------------
reg [79:0] dbg_inst_str;
reg [79:0] dbg_inst_rs;
reg [79:0] dbg_inst_rt;
reg [79:0] dbg_inst_rd;
reg [31:0] dbg_inst_imm;
reg [31:0] dbg_inst_pc;

wire [4:0] rs_idx_w = opcode_i[`OPCODE_RS_R];
wire [4:0] rt_idx_w = opcode_i[`OPCODE_RT_R];
wire [4:0] rd_idx_w = opcode_i[`OPCODE_RD_R];
wire [4:0] re_idx_w = opcode_i[`OPCODE_RE_R];

always @ *
begin
    dbg_inst_str = "-";
    dbg_inst_rs  = "-";
    dbg_inst_rt  = "-";
    dbg_inst_rd  = "-";
    dbg_inst_pc  = 32'bx;

    if (valid_i)
    begin
        dbg_inst_pc  = pc_i;
        dbg_inst_rs  = get_regname_str(rs_idx_w);
        dbg_inst_rt  = get_regname_str(rt_idx_w);
        dbg_inst_rd  = get_regname_str(rd_idx_w);

        case (1'b1)
        (opcode_i[`OPCODE_INST_R] == `INSTR_J_JAL)   : dbg_inst_str = "JAL";
        (opcode_i[`OPCODE_INST_R] == `INSTR_J_J)     : dbg_inst_str = "J";
        (opcode_i[`OPCODE_INST_R] == `INSTR_J_BEQ)   : dbg_inst_str = "BEQ";
        (opcode_i[`OPCODE_INST_R] == `INSTR_J_BNE)   : dbg_inst_str = "BNE";
        (opcode_i[`OPCODE_INST_R] == `INSTR_J_BLEZ)  : dbg_inst_str = "BLEZ";
        (opcode_i[`OPCODE_INST_R] == `INSTR_J_BGTZ)  : dbg_inst_str = "BGTZ";
        (opcode_i[`OPCODE_INST_R] == `INSTR_I_ADDI)  : dbg_inst_str = "ADDI";
        (opcode_i[`OPCODE_INST_R] == `INSTR_I_ADDIU) : dbg_inst_str = "ADDIU";
        (opcode_i[`OPCODE_INST_R] == `INSTR_I_SLTI)  : dbg_inst_str = "SLTI";
        (opcode_i[`OPCODE_INST_R] == `INSTR_I_SLTIU) : dbg_inst_str = "SLTIU";
        (opcode_i[`OPCODE_INST_R] == `INSTR_I_ANDI)  : dbg_inst_str = "ANDI";
        (opcode_i[`OPCODE_INST_R] == `INSTR_I_ORI)   : dbg_inst_str = "ORI";
        (opcode_i[`OPCODE_INST_R] == `INSTR_I_XORI)  : dbg_inst_str = "XORI";
        (opcode_i[`OPCODE_INST_R] == `INSTR_I_LUI)   : dbg_inst_str = "LUI";
        (opcode_i[`OPCODE_INST_R] == `INSTR_I_LB)    : dbg_inst_str = "LB";
        (opcode_i[`OPCODE_INST_R] == `INSTR_I_LH)    : dbg_inst_str = "LH";
        (opcode_i[`OPCODE_INST_R] == `INSTR_I_LW)    : dbg_inst_str = "LW";
        (opcode_i[`OPCODE_INST_R] == `INSTR_I_LBU)   : dbg_inst_str = "LBU";
        (opcode_i[`OPCODE_INST_R] == `INSTR_I_LHU)   : dbg_inst_str = "LHU";
        (opcode_i[`OPCODE_INST_R] == `INSTR_I_LWL)   : dbg_inst_str = "LWL";
        (opcode_i[`OPCODE_INST_R] == `INSTR_I_LWR)   : dbg_inst_str = "LWR";
        (opcode_i[`OPCODE_INST_R] == `INSTR_I_SB)    : dbg_inst_str = "SB";
        (opcode_i[`OPCODE_INST_R] == `INSTR_I_SH)    : dbg_inst_str = "SH";
        (opcode_i[`OPCODE_INST_R] == `INSTR_I_SW)    : dbg_inst_str = "SW";
        (opcode_i[`OPCODE_INST_R] == `INSTR_I_SWL)   : dbg_inst_str = "SWL";
        (opcode_i[`OPCODE_INST_R] == `INSTR_I_SWR)   : dbg_inst_str = "SWR";
        (opcode_i[`OPCODE_INST_R] == `INSTR_COP0)    : dbg_inst_str = "COP0";
        (opcode_i[`OPCODE_INST_R] == `INSTR_COP1)    : dbg_inst_str = "COP1";
        (opcode_i[`OPCODE_INST_R] == `INSTR_COP2)    : dbg_inst_str = "COP2";
        (opcode_i[`OPCODE_INST_R] == `INSTR_COP3)    : dbg_inst_str = "COP3";
        (opcode_i[`OPCODE_INST_R] == `INSTR_I_LWC0)  : dbg_inst_str = "LWC0";
        (opcode_i[`OPCODE_INST_R] == `INSTR_I_LWC1)  : dbg_inst_str = "LWC1";
        (opcode_i[`OPCODE_INST_R] == `INSTR_I_LWC2)  : dbg_inst_str = "LWC2";
        (opcode_i[`OPCODE_INST_R] == `INSTR_I_LWC3)  : dbg_inst_str = "LWC3";
        (opcode_i[`OPCODE_INST_R] == `INSTR_I_SWC0)  : dbg_inst_str = "SWC0";
        (opcode_i[`OPCODE_INST_R] == `INSTR_I_SWC1)  : dbg_inst_str = "SWC1";
        (opcode_i[`OPCODE_INST_R] == `INSTR_I_SWC2)  : dbg_inst_str = "SWC2";
        (opcode_i[`OPCODE_INST_R] == `INSTR_I_SWC3)  : dbg_inst_str = "SWC3";
        (opcode_i[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_i[`OPCODE_FUNC_R] == `INSTR_R_SLL)     : dbg_inst_str = "SLL";
        (opcode_i[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_i[`OPCODE_FUNC_R] == `INSTR_R_SRL)     : dbg_inst_str = "SRL";
        (opcode_i[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_i[`OPCODE_FUNC_R] == `INSTR_R_SRA)     : dbg_inst_str = "SRA";
        (opcode_i[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_i[`OPCODE_FUNC_R] == `INSTR_R_SLLV)    : dbg_inst_str = "SLLV";
        (opcode_i[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_i[`OPCODE_FUNC_R] == `INSTR_R_SRLV)    : dbg_inst_str = "SRLV";
        (opcode_i[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_i[`OPCODE_FUNC_R] == `INSTR_R_SRAV)    : dbg_inst_str = "SRAV";
        (opcode_i[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_i[`OPCODE_FUNC_R] == `INSTR_R_JR)      : dbg_inst_str = "JR";
        (opcode_i[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_i[`OPCODE_FUNC_R] == `INSTR_R_JALR)    : dbg_inst_str = "JALR";
        (opcode_i[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_i[`OPCODE_FUNC_R] == `INSTR_R_SYSCALL) : dbg_inst_str = "SYSCALL";
        (opcode_i[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_i[`OPCODE_FUNC_R] == `INSTR_R_BREAK)   : dbg_inst_str = "BREAK";
        (opcode_i[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_i[`OPCODE_FUNC_R] == `INSTR_R_MFHI)    : dbg_inst_str = "MFHI";
        (opcode_i[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_i[`OPCODE_FUNC_R] == `INSTR_R_MTHI)    : dbg_inst_str = "MTHI";
        (opcode_i[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_i[`OPCODE_FUNC_R] == `INSTR_R_MFLO)    : dbg_inst_str = "MFLO";
        (opcode_i[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_i[`OPCODE_FUNC_R] == `INSTR_R_MTLO)    : dbg_inst_str = "MTLO";
        (opcode_i[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_i[`OPCODE_FUNC_R] == `INSTR_R_MULT)    : dbg_inst_str = "MULT";
        (opcode_i[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_i[`OPCODE_FUNC_R] == `INSTR_R_MULTU)   : dbg_inst_str = "MULTU";
        (opcode_i[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_i[`OPCODE_FUNC_R] == `INSTR_R_DIV)     : dbg_inst_str = "DIV";
        (opcode_i[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_i[`OPCODE_FUNC_R] == `INSTR_R_DIVU)    : dbg_inst_str = "DIVU";
        (opcode_i[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_i[`OPCODE_FUNC_R] == `INSTR_R_ADD)     : dbg_inst_str = "ADD";
        (opcode_i[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_i[`OPCODE_FUNC_R] == `INSTR_R_ADDU)    : dbg_inst_str = "ADDU";
        (opcode_i[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_i[`OPCODE_FUNC_R] == `INSTR_R_SUB)     : dbg_inst_str = "SUB";
        (opcode_i[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_i[`OPCODE_FUNC_R] == `INSTR_R_SUBU)    : dbg_inst_str = "SUBU";
        (opcode_i[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_i[`OPCODE_FUNC_R] == `INSTR_R_AND)     : dbg_inst_str = "AND";
        (opcode_i[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_i[`OPCODE_FUNC_R] == `INSTR_R_OR)      : dbg_inst_str = "OR";
        (opcode_i[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_i[`OPCODE_FUNC_R] == `INSTR_R_XOR)     : dbg_inst_str = "XOR";
        (opcode_i[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_i[`OPCODE_FUNC_R] == `INSTR_R_NOR)     : dbg_inst_str = "NOR";
        (opcode_i[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_i[`OPCODE_FUNC_R] == `INSTR_R_SLT)     : dbg_inst_str = "SLT";
        (opcode_i[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_i[`OPCODE_FUNC_R] == `INSTR_R_SLTU)    : dbg_inst_str = "SLTU";
        (opcode_i[`OPCODE_INST_R] == `INSTR_I_BRCOND) :
        begin
            case ({rt_idx_w[0],(rt_idx_w[4:1] == 4'h8)})
            2'b00:   dbg_inst_str = "BLTZ";
            2'b01:   dbg_inst_str = "BLTZAL";
            2'b10:   dbg_inst_str = "BGEZ";
            default: dbg_inst_str = "BGEZAL";
            endcase
        end
        endcase

        case (1'b1)
        (opcode_i[`OPCODE_INST_R] == `INSTR_J_JAL),
        (opcode_i[`OPCODE_INST_R] == `INSTR_J_J) :
        begin
            dbg_inst_rs  = "-";
            dbg_inst_rt  = "-";
            dbg_inst_rd  = "-";
            dbg_inst_imm = {4'b0, opcode_i[`OPCODE_ADDR_R], 2'b0};
        end
        (opcode_i[`OPCODE_INST_R] == `INSTR_COP2):
        begin
            if (opcode_i[25])
            begin
                dbg_inst_str = "COP2";
                dbg_inst_imm = {6'b0, opcode_i[25:0]};
            end
            else if (opcode_i[`OPCODE_RS_R] == 5'b00000)
            begin
                dbg_inst_str = "MFC2";
                dbg_inst_imm = 32'h0;
            end
            else if (opcode_i[`OPCODE_RS_R] == 5'b00010)
            begin
                dbg_inst_str = "CFC2";
                dbg_inst_imm = 32'h0;
            end
            else if (opcode_i[`OPCODE_RS_R] == 5'b00100)
            begin
                dbg_inst_str = "MTC2";
                dbg_inst_imm = 32'h0;
            end
            else if (opcode_i[`OPCODE_RS_R] == 5'b00110)
            begin
                dbg_inst_str = "CTC2";
                dbg_inst_imm = 32'h0;
            end
        end
        default:
        begin
            dbg_inst_imm = {{16{opcode_i[15]}}, opcode_i[`OPCODE_IMM_R]};
        end
        endcase        
    end
end
`endif

endmodule
