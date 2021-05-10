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
module mpx_pipe_ctrl
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
     parameter SUPPORT_LOAD_BYPASS = 1
    ,parameter SUPPORT_MUL_BYPASS  = 1
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(
     input           clk_i
    ,input           rst_i

    // Issue
    ,input           issue_valid_i
    ,input           issue_accept_i
    ,input           issue_stall_i
    ,input           issue_lsu_i
    ,input           issue_cop0_i
    ,input           issue_cop0_wr_i
    ,input           issue_cop1_i
    ,input           issue_cop1_wr_i
    ,input           issue_cop2_i
    ,input           issue_cop2_wr_i
    ,input           issue_cop3_i
    ,input           issue_cop3_wr_i
    ,input           issue_div_i
    ,input           issue_mul_i
    ,input           issue_branch_i
    ,input           issue_rd_valid_i
    ,input           issue_rt_is_rd_i
    ,input  [4:0]    issue_rd_i
    ,input  [5:0]    issue_exception_i
    ,input           take_interrupt_i
    ,input           take_nmi_i
    ,input           issue_branch_taken_i
    ,input [31:0]    issue_branch_target_i
    ,input [31:0]    issue_pc_i
    ,input [31:0]    issue_opcode_i
    ,input [31:0]    issue_operand_rs_i
    ,input [31:0]    issue_operand_rt_i
    ,input           issue_delay_slot_i

    // Issue (combinatorial reads)
    ,input [31:0]    cop0_result_rdata_i
    ,input [31:0]    cop1_result_rdata_i
    ,input [31:0]    cop2_result_rdata_i
    ,input [31:0]    cop3_result_rdata_i

    // Execution stage (X): ALU result
    ,input [31:0]    alu_result_x_i

    // Execution stage (X): COP0 early exceptions
    ,input [  5:0]   cop0_result_exception_x_i

    // Execution stage (X)
    ,output          load_x_o
    ,output          store_x_o
    ,output          mul_x_o
    ,output          branch_x_o
    ,output [  4:0]  rd_x_o
    ,output [31:0]   pc_x_o
    ,output [31:0]   opcode_x_o
    ,output [31:0]   operand_rs_x_o
    ,output [31:0]   operand_rt_x_o
    ,output [ 5:0]   exception_x_o

    // Memory stage (M): Other results
    ,input           mem_complete_i
    ,input [31:0]    mem_result_m_i
    ,input  [5:0]    mem_exception_m_i

    // Memory stage (M)
    ,output          load_m_o
    ,output          mul_m_o
    ,output [  4:0]  rd_m_o
    ,output [31:0]   result_m_o
    ,output [31:0]   operand_rt_m_o

    // Out of pipe: Divide Result
    ,input           div_complete_i

    // Writeback stage (W)
    ,output          valid_wb_o
    ,output          cop0_wb_o
    ,output          cop1_wb_o
    ,output          cop2_wb_o
    ,output          cop3_wb_o
    ,output [  4:0]  rd_wb_o
    ,output [31:0]   result_wb_o
    ,output [31:0]   pc_wb_o
    ,output [31:0]   opcode_wb_o
    ,output [31:0]   operand_rs_wb_o
    ,output [31:0]   operand_rt_wb_o
    ,output [5:0]    exception_wb_o
    ,output          delay_slot_wb_o

    ,output          cop0_write_wb_o
    ,output          cop1_write_wb_o
    ,output          cop2_write_wb_o
    ,output          cop3_write_wb_o
    ,output [5:0]    cop0_waddr_wb_o
    ,output [31:0]   cop0_wdata_wb_o

    ,output          stall_o
    ,output          squash_x_m_o
);

//-------------------------------------------------------------
// Includes
//-------------------------------------------------------------
`include "mpx_defs.v"

wire squash_x_m_w;
wire branch_misaligned_w = (issue_branch_taken_i && issue_branch_target_i[1:0] != 2'b0);

//-------------------------------------------------------------
// X-stage
//------------------------------------------------------------- 
`define PCINFO_W     24
`define PCINFO_ALU       0
`define PCINFO_LOAD      1
`define PCINFO_STORE     2
`define PCINFO_DEL_SLOT  3
`define PCINFO_DIV       4
`define PCINFO_MUL       5
`define PCINFO_BRANCH    6
`define PCINFO_RD_VALID  7
`define PCINFO_RD        12:8
`define PCINFO_INTR      13
`define PCINFO_COMPLETE  14
`define PCINFO_COP0      15
`define PCINFO_COP0_WR   16
`define PCINFO_COP1      17
`define PCINFO_COP1_WR   18
`define PCINFO_COP2      19
`define PCINFO_COP2_WR   20
`define PCINFO_COP3      21
`define PCINFO_COP3_WR   22
`define PCINFO_NMI       23

reg                     valid_x_q;
reg [`PCINFO_W-1:0]     ctrl_x_q;
reg [31:0]              pc_x_q;
reg [31:0]              npc_x_q;
reg [31:0]              opcode_x_q;
reg [31:0]              operand_rs_x_q;
reg [31:0]              operand_rt_x_q;
reg [31:0]              result_x_q;
reg [`EXCEPTION_W-1:0]  exception_x_q;

always @ (posedge clk_i )
if (rst_i)
begin
    valid_x_q      <= 1'b0;
    ctrl_x_q       <= `PCINFO_W'b0;
    pc_x_q         <= 32'b0;
    npc_x_q        <= 32'b0;
    opcode_x_q     <= 32'b0;
    operand_rs_x_q <= 32'b0;
    operand_rt_x_q <= 32'b0;
    result_x_q     <= 32'b0;
    exception_x_q  <= `EXCEPTION_W'b0;
end
// Stall - no change in X state
else if (issue_stall_i)
    ;
else if ((issue_valid_i && issue_accept_i) && ~(squash_x_m_o))
begin
    valid_x_q                  <= 1'b1;
    ctrl_x_q[`PCINFO_ALU]      <= ~(issue_lsu_i | issue_cop0_i | issue_div_i | issue_mul_i);
    ctrl_x_q[`PCINFO_LOAD]     <= issue_lsu_i      &  issue_rd_valid_i & ~take_interrupt_i; // TODO: Check
    ctrl_x_q[`PCINFO_STORE]    <= issue_lsu_i      & ~issue_rd_valid_i & ~take_interrupt_i;
    ctrl_x_q[`PCINFO_COP0]     <= issue_cop0_i     & ~take_interrupt_i;
    ctrl_x_q[`PCINFO_COP0_WR]  <= issue_cop0_wr_i  & ~take_interrupt_i;
    ctrl_x_q[`PCINFO_COP1]     <= issue_cop1_i     & ~take_interrupt_i;
    ctrl_x_q[`PCINFO_COP1_WR]  <= issue_cop1_wr_i  & ~take_interrupt_i;
    ctrl_x_q[`PCINFO_COP2]     <= issue_cop2_i     & ~take_interrupt_i;
    ctrl_x_q[`PCINFO_COP2_WR]  <= issue_cop2_wr_i  & ~take_interrupt_i;
    ctrl_x_q[`PCINFO_COP3]     <= issue_cop3_i     & ~take_interrupt_i;
    ctrl_x_q[`PCINFO_COP3_WR]  <= issue_cop3_wr_i  & ~take_interrupt_i;
    ctrl_x_q[`PCINFO_DIV]      <= issue_div_i      & ~take_interrupt_i;
    ctrl_x_q[`PCINFO_MUL]      <= issue_mul_i      & ~take_interrupt_i;
    ctrl_x_q[`PCINFO_BRANCH]   <= issue_branch_i   & ~take_interrupt_i;
    ctrl_x_q[`PCINFO_RD_VALID] <= issue_rd_valid_i & ~take_interrupt_i;
    ctrl_x_q[`PCINFO_RD]       <= issue_rd_i;
    ctrl_x_q[`PCINFO_DEL_SLOT] <= issue_delay_slot_i;
    ctrl_x_q[`PCINFO_INTR]     <= take_interrupt_i;
    ctrl_x_q[`PCINFO_NMI]      <= take_interrupt_i && take_nmi_i;
    ctrl_x_q[`PCINFO_COMPLETE] <= 1'b1;

    pc_x_q         <= issue_pc_i;
    npc_x_q        <= issue_branch_taken_i ? issue_branch_target_i : issue_pc_i + 32'd4;
    opcode_x_q     <= issue_opcode_i;
    operand_rs_x_q <= issue_operand_rs_i;
    operand_rt_x_q <= issue_operand_rt_i;
    result_x_q     <= (issue_cop0_wr_i | issue_cop1_wr_i | issue_cop2_wr_i | issue_cop3_wr_i) ? 
                       ((issue_opcode_i[31:28] == 4'b0100 /* COPx */) ? issue_operand_rt_i : issue_operand_rs_i) : issue_cop3_i ? cop3_result_rdata_i :
                       issue_cop2_i ? cop2_result_rdata_i :
                       issue_cop1_i ? cop1_result_rdata_i :
                                      cop0_result_rdata_i;
    exception_x_q  <= (|issue_exception_i) ? issue_exception_i : 
                       branch_misaligned_w  ? `EXCEPTION_ADEL : `EXCEPTION_W'b0;

    // Record bad address target
    if (!(|issue_exception_i) && branch_misaligned_w)
        result_x_q     <= issue_branch_target_i; 
end
// No valid instruction (or pipeline flush event)
else
begin
    valid_x_q      <= 1'b0;
    ctrl_x_q       <= `PCINFO_W'b0;
    pc_x_q         <= 32'b0;
    npc_x_q        <= 32'b0;
    opcode_x_q     <= 32'b0;
    operand_rs_x_q <= 32'b0;
    operand_rt_x_q <= 32'b0;
    result_x_q     <= 32'b0;
    exception_x_q  <= `EXCEPTION_W'b0;
end

wire   alu_x_w        = ctrl_x_q[`PCINFO_ALU];
assign load_x_o       = ctrl_x_q[`PCINFO_LOAD];
assign store_x_o      = ctrl_x_q[`PCINFO_STORE];
assign mul_x_o        = ctrl_x_q[`PCINFO_MUL];
assign branch_x_o     = ctrl_x_q[`PCINFO_BRANCH];
assign rd_x_o         = {5{ctrl_x_q[`PCINFO_RD_VALID]}} & ctrl_x_q[`PCINFO_RD];
assign pc_x_o         = pc_x_q;
assign opcode_x_o     = opcode_x_q;
assign operand_rs_x_o = operand_rs_x_q;
assign operand_rt_x_o = operand_rt_x_q;
assign exception_x_o  = exception_x_q;

//-------------------------------------------------------------
// M-stage (Mem result)
//------------------------------------------------------------- 
reg                     valid_m_q;
reg [`PCINFO_W-1:0]     ctrl_m_q;
reg [31:0]              result_m_q;
reg [31:0]              pc_m_q;
reg [31:0]              npc_m_q;
reg [31:0]              opcode_m_q;
reg [31:0]              operand_rs_m_q;
reg [31:0]              operand_rt_m_q;
reg [`EXCEPTION_W-1:0]  exception_m_q;

always @ (posedge clk_i )
if (rst_i)
begin
    valid_m_q      <= 1'b0;
    ctrl_m_q       <= `PCINFO_W'b0;
    pc_m_q         <= 32'b0;
    npc_m_q        <= 32'b0;
    opcode_m_q     <= 32'b0;
    operand_rs_m_q <= 32'b0;
    operand_rt_m_q <= 32'b0;
    result_m_q     <= 32'b0;
    exception_m_q  <= `EXCEPTION_W'b0;
end
// Stall - no change in M state
else if (issue_stall_i)
    ;
// Pipeline flush
else if (squash_x_m_o)
begin
    valid_m_q      <= 1'b0;
    ctrl_m_q       <= `PCINFO_W'b0;
    pc_m_q         <= 32'b0;
    npc_m_q        <= 32'b0;
    opcode_m_q     <= 32'b0;
    operand_rs_m_q <= 32'b0;
    operand_rt_m_q <= 32'b0;
    result_m_q     <= 32'b0;
    exception_m_q  <= `EXCEPTION_W'b0;
end
// Normal pipeline advance
else
begin
    valid_m_q      <= valid_x_q;
    ctrl_m_q       <= ctrl_x_q;
    pc_m_q         <= pc_x_q;
    npc_m_q        <= npc_x_q;
    opcode_m_q     <= opcode_x_q;
    operand_rs_m_q <= operand_rs_x_q;
    operand_rt_m_q <= operand_rt_x_q;

    // Launch interrupt / NMI
    if (ctrl_x_q[`PCINFO_NMI])
        exception_m_q  <= `EXCEPTION_NMI;
    else if (ctrl_x_q[`PCINFO_INTR])
        exception_m_q  <= `EXCEPTION_INT;
    // If frontend reports bad instruction, ignore later CSR errors...
    else if (|exception_x_q)
    begin
        valid_m_q      <= 1'b0;
        exception_m_q  <= exception_x_q;
    end
    else
        exception_m_q  <= cop0_result_exception_x_i;

    if (ctrl_x_q[`PCINFO_COP0] | ctrl_x_q[`PCINFO_COP1] | ctrl_x_q[`PCINFO_COP2] | ctrl_x_q[`PCINFO_COP3])
        result_m_q <= result_x_q;
    else if (exception_x_q  != `EXCEPTION_W'b0)
        result_m_q <= result_x_q;
    else
        result_m_q <= alu_result_x_i;
end

reg [31:0] result_m_r;

wire valid_m_w      = valid_m_q & ~issue_stall_i;

always @ *
begin
    // Default: ALU result
    result_m_r = result_m_q;

    if (SUPPORT_LOAD_BYPASS && valid_m_w && (ctrl_m_q[`PCINFO_LOAD] || ctrl_m_q[`PCINFO_STORE]))
        result_m_r = mem_result_m_i;
end

wire   load_store_m_w = ctrl_m_q[`PCINFO_LOAD] | ctrl_m_q[`PCINFO_STORE];
assign load_m_o       = ctrl_m_q[`PCINFO_LOAD];
assign mul_m_o        = ctrl_m_q[`PCINFO_MUL];
assign rd_m_o         = {5{(valid_m_w && ctrl_m_q[`PCINFO_RD_VALID] && ~stall_o)}} & ctrl_m_q[`PCINFO_RD];
assign operand_rt_m_o = operand_rt_m_q;
assign result_m_o     = result_m_r;

// Load store result not ready when reaching M
assign stall_o         = (ctrl_x_q[`PCINFO_DIV] && ~div_complete_i) || ((ctrl_m_q[`PCINFO_LOAD] | ctrl_m_q[`PCINFO_STORE]) & ~mem_complete_i);

reg [`EXCEPTION_W-1:0] exception_m_r;
always @ *
begin
    if (valid_m_q && (ctrl_m_q[`PCINFO_LOAD] || ctrl_m_q[`PCINFO_STORE]) && mem_complete_i)
        exception_m_r = mem_exception_m_i;
    else
        exception_m_r = exception_m_q;
end

assign squash_x_m_w = |exception_m_r;

reg squash_x_m_q;

always @ (posedge clk_i )
if (rst_i)
    squash_x_m_q <= 1'b0;
else if (~issue_stall_i)
    squash_x_m_q <= squash_x_m_w;

assign squash_x_m_o = squash_x_m_w | squash_x_m_q;

//-------------------------------------------------------------
// Writeback / Commit
//------------------------------------------------------------- 
reg                     valid_wb_q;
reg [`PCINFO_W-1:0]     ctrl_wb_q;
reg [31:0]              result_wb_q;
reg [31:0]              pc_wb_q;
reg [31:0]              npc_wb_q;
reg [31:0]              opcode_wb_q;
reg [31:0]              operand_rs_wb_q;
reg [31:0]              operand_rt_wb_q;
reg [`EXCEPTION_W-1:0]  exception_wb_q;

always @ (posedge clk_i )
if (rst_i)
begin
    valid_wb_q      <= 1'b0;
    ctrl_wb_q       <= `PCINFO_W'b0;
    pc_wb_q         <= 32'b0;
    npc_wb_q        <= 32'b0;
    opcode_wb_q     <= 32'b0;
    operand_rs_wb_q <= 32'b0;
    operand_rt_wb_q <= 32'b0;
    result_wb_q     <= 32'b0;
    exception_wb_q  <= `EXCEPTION_W'b0;
end
// Stall - no change in WB state
else if (issue_stall_i)
    ;
else
begin
    // Squash instruction valid on memory faults
    case (exception_m_r)
    `EXCEPTION_ADEL,
    `EXCEPTION_ADES,
    `EXCEPTION_IBE,
    `EXCEPTION_DBE: // TODO: Other exception..
        valid_wb_q      <= 1'b0;
    default:
        valid_wb_q      <= valid_m_q;
    endcase

    // Exception - squash writeback
    if (|exception_m_r)
        ctrl_wb_q       <= ctrl_m_q & ~(1 << `PCINFO_RD_VALID);
    else
        ctrl_wb_q       <= ctrl_m_q;

    pc_wb_q         <= pc_m_q;
    npc_wb_q        <= npc_m_q;
    opcode_wb_q     <= opcode_m_q;
    operand_rs_wb_q <= operand_rs_m_q;
    operand_rt_wb_q <= operand_rt_m_q;
    exception_wb_q  <= exception_m_r;

    if (valid_m_w && (ctrl_m_q[`PCINFO_LOAD] || ctrl_m_q[`PCINFO_STORE]))
        result_wb_q <= mem_result_m_i;
    else
        result_wb_q <= result_m_q;
end

// Instruction completion (for debug)
wire complete_wb_w     = ctrl_wb_q[`PCINFO_COMPLETE] & ~issue_stall_i;

assign valid_wb_o      = valid_wb_q & ~issue_stall_i;
assign rd_wb_o         = {5{(valid_wb_o && ctrl_wb_q[`PCINFO_RD_VALID] && ~stall_o)}} & ctrl_wb_q[`PCINFO_RD];
assign result_wb_o     = result_wb_q;
assign pc_wb_o         = pc_wb_q;
assign opcode_wb_o     = opcode_wb_q;
assign operand_rs_wb_o = operand_rs_wb_q;
assign operand_rt_wb_o = operand_rt_wb_q;

assign exception_wb_o  = exception_wb_q;
assign delay_slot_wb_o = ctrl_wb_q[`PCINFO_DEL_SLOT];

assign cop0_wb_o       = ctrl_wb_q[`PCINFO_COP0] & ~issue_stall_i; // TODO: Fault disable???
assign cop1_wb_o       = ctrl_wb_q[`PCINFO_COP1] & ~issue_stall_i; // TODO: Fault disable???
assign cop2_wb_o       = ctrl_wb_q[`PCINFO_COP2] & ~issue_stall_i; // TODO: Fault disable???
assign cop3_wb_o       = ctrl_wb_q[`PCINFO_COP3] & ~issue_stall_i; // TODO: Fault disable???
assign cop0_write_wb_o = valid_wb_o && ctrl_wb_q[`PCINFO_COP0_WR] && ~stall_o;
assign cop1_write_wb_o = valid_wb_o && ctrl_wb_q[`PCINFO_COP1_WR] && ~stall_o;
assign cop2_write_wb_o = valid_wb_o && ctrl_wb_q[`PCINFO_COP2_WR] && ~stall_o;
assign cop3_write_wb_o = valid_wb_o && ctrl_wb_q[`PCINFO_COP3_WR] && ~stall_o;
assign cop0_wdata_wb_o = result_wb_q;

reg [5:0] cop_waddr_r;
always @ *
begin
    cop_waddr_r = 6'b0;

    if (opcode_wb_q[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_wb_q[`OPCODE_FUNC_R] == `INSTR_R_MFHI)
        cop_waddr_r = {1'b1, 5'd1};
    else if (opcode_wb_q[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_wb_q[`OPCODE_FUNC_R] == `INSTR_R_MTHI)
        cop_waddr_r = {1'b1, 5'd1};
    else if (opcode_wb_q[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_wb_q[`OPCODE_FUNC_R] == `INSTR_R_MFLO)
        cop_waddr_r = {1'b1, 5'd0};
    else if (opcode_wb_q[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_wb_q[`OPCODE_FUNC_R] == `INSTR_R_MTLO)
        cop_waddr_r = {1'b1, 5'd0};
    else if (opcode_wb_q[`OPCODE_INST_R] == `INSTR_I_LWC0 || 
             opcode_wb_q[`OPCODE_INST_R] == `INSTR_I_LWC1 ||
             opcode_wb_q[`OPCODE_INST_R] == `INSTR_I_LWC2 || 
             opcode_wb_q[`OPCODE_INST_R] == `INSTR_I_LWC3)
        cop_waddr_r = {1'b0, opcode_wb_q[`OPCODE_RT_R]};
    // COP0 - RFE
    else if (opcode_wb_q[`OPCODE_INST_R] == `INSTR_COP0 && opcode_wb_q[`OPCODE_FUNC_R] == 6'b010000)
        cop_waddr_r  = {1'b1, `COP0_STATUS};
    else if (opcode_wb_q[31:28] == 4'b0100 /* COPx */ && opcode_wb_q[`OPCODE_RS_R] == 5'b00110)
        cop_waddr_r  = {1'b1, opcode_wb_q[`OPCODE_RD_R]};
    else
        cop_waddr_r  = {1'b0, opcode_wb_q[`OPCODE_RD_R]};
end
assign cop0_waddr_wb_o  = cop_waddr_r;

`ifdef verilator
mpx_trace_sim
u_trace_d
(
     .valid_i(issue_valid_i)
    ,.pc_i(issue_pc_i)
    ,.opcode_i(issue_opcode_i)
);

mpx_trace_sim
u_trace_wb
(
     .valid_i(valid_wb_o)
    ,.pc_i(pc_wb_o)
    ,.opcode_i(opcode_wb_o)
);
`endif

endmodule