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
module mpx_issue
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
     parameter SUPPORT_MULDIV   = 1
    ,parameter SUPPORT_LOAD_BYPASS = 1
    ,parameter SUPPORT_MUL_BYPASS = 1
    ,parameter SUPPORT_REGFILE_XILINX = 0
    ,parameter SUPPORTED_COP    = 5
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(
    // Inputs
     input           clk_i
    ,input           rst_i
    ,input           fetch_valid_i
    ,input  [ 31:0]  fetch_instr_i
    ,input  [ 31:0]  fetch_pc_i
    ,input           fetch_delay_slot_i
    ,input           fetch_fault_fetch_i
    ,input           fetch_instr_exec_i
    ,input           fetch_instr_lsu_i
    ,input           fetch_instr_branch_i
    ,input           fetch_instr_mul_i
    ,input           fetch_instr_div_i
    ,input           fetch_instr_cop0_i
    ,input           fetch_instr_cop0_wr_i
    ,input           fetch_instr_cop1_i
    ,input           fetch_instr_cop1_wr_i
    ,input           fetch_instr_cop2_i
    ,input           fetch_instr_cop2_wr_i
    ,input           fetch_instr_cop3_i
    ,input           fetch_instr_cop3_wr_i
    ,input           fetch_instr_rd_valid_i
    ,input           fetch_instr_rt_is_rd_i
    ,input           fetch_instr_lr_is_rd_i
    ,input           fetch_instr_invalid_i
    ,input  [ 31:0]  cop0_rd_rdata_i
    ,input           branch_d_exec_request_i
    ,input           branch_d_exec_exception_i
    ,input  [ 31:0]  branch_d_exec_pc_i
    ,input           branch_d_exec_priv_i
    ,input           branch_cop0_request_i
    ,input           branch_cop0_exception_i
    ,input  [ 31:0]  branch_cop0_pc_i
    ,input           branch_cop0_priv_i
    ,input  [ 31:0]  writeback_exec_value_i
    ,input           writeback_mem_valid_i
    ,input  [ 31:0]  writeback_mem_value_i
    ,input  [  5:0]  writeback_mem_exception_i
    ,input           writeback_mul_valid_i
    ,input  [ 31:0]  writeback_mul_hi_i
    ,input  [ 31:0]  writeback_mul_lo_i
    ,input           writeback_div_valid_i
    ,input  [ 31:0]  writeback_div_hi_i
    ,input  [ 31:0]  writeback_div_lo_i
    ,input  [  5:0]  cop0_result_x_exception_i
    ,input           lsu_stall_i
    ,input           take_interrupt_i
    ,input           take_interrupt_nmi_i
    ,input           cop1_accept_i
    ,input  [ 31:0]  cop1_reg_rdata_i
    ,input           cop2_accept_i
    ,input  [ 31:0]  cop2_reg_rdata_i
    ,input           cop3_accept_i
    ,input  [ 31:0]  cop3_reg_rdata_i

    // Outputs
    ,output          fetch_accept_o
    ,output          branch_request_o
    ,output          branch_exception_o
    ,output [ 31:0]  branch_pc_o
    ,output          branch_priv_o
    ,output          exec_opcode_valid_o
    ,output          lsu_opcode_valid_o
    ,output          cop0_opcode_valid_o
    ,output          mul_opcode_valid_o
    ,output          div_opcode_valid_o
    ,output [ 31:0]  opcode_opcode_o
    ,output [ 31:0]  opcode_pc_o
    ,output          opcode_invalid_o
    ,output          opcode_delay_slot_o
    ,output [  4:0]  opcode_rd_idx_o
    ,output [  4:0]  opcode_rs_idx_o
    ,output [  4:0]  opcode_rt_idx_o
    ,output [ 31:0]  opcode_rs_operand_o
    ,output [ 31:0]  opcode_rt_operand_o
    ,output [ 31:0]  lsu_opcode_opcode_o
    ,output [ 31:0]  lsu_opcode_pc_o
    ,output          lsu_opcode_invalid_o
    ,output          lsu_opcode_delay_slot_o
    ,output [  4:0]  lsu_opcode_rd_idx_o
    ,output [  4:0]  lsu_opcode_rs_idx_o
    ,output [  4:0]  lsu_opcode_rt_idx_o
    ,output [ 31:0]  lsu_opcode_rs_operand_o
    ,output [ 31:0]  lsu_opcode_rt_operand_o
    ,output [ 31:0]  lsu_opcode_rt_operand_m_o
    ,output [ 31:0]  mul_opcode_opcode_o
    ,output [ 31:0]  mul_opcode_pc_o
    ,output          mul_opcode_invalid_o
    ,output          mul_opcode_delay_slot_o
    ,output [  4:0]  mul_opcode_rd_idx_o
    ,output [  4:0]  mul_opcode_rs_idx_o
    ,output [  4:0]  mul_opcode_rt_idx_o
    ,output [ 31:0]  mul_opcode_rs_operand_o
    ,output [ 31:0]  mul_opcode_rt_operand_o
    ,output [ 31:0]  cop0_opcode_opcode_o
    ,output [ 31:0]  cop0_opcode_pc_o
    ,output          cop0_opcode_invalid_o
    ,output          cop0_opcode_delay_slot_o
    ,output [  4:0]  cop0_opcode_rd_idx_o
    ,output [  4:0]  cop0_opcode_rs_idx_o
    ,output [  4:0]  cop0_opcode_rt_idx_o
    ,output [ 31:0]  cop0_opcode_rs_operand_o
    ,output [ 31:0]  cop0_opcode_rt_operand_o
    ,output          cop0_rd_ren_o
    ,output [  5:0]  cop0_rd_raddr_o
    ,output          cop0_writeback_write_o
    ,output [  5:0]  cop0_writeback_waddr_o
    ,output [ 31:0]  cop0_writeback_wdata_o
    ,output [  5:0]  cop0_writeback_exception_o
    ,output [ 31:0]  cop0_writeback_exception_pc_o
    ,output [ 31:0]  cop0_writeback_exception_addr_o
    ,output          cop0_writeback_delay_slot_o
    ,output          exec_hold_o
    ,output          mul_hold_o
    ,output          squash_muldiv_o
    ,output          interrupt_inhibit_o
    ,output          cop1_valid_o
    ,output [ 31:0]  cop1_opcode_o
    ,output          cop1_reg_write_o
    ,output [  5:0]  cop1_reg_waddr_o
    ,output [ 31:0]  cop1_reg_wdata_o
    ,output [  5:0]  cop1_reg_raddr_o
    ,output          cop2_valid_o
    ,output [ 31:0]  cop2_opcode_o
    ,output          cop2_reg_write_o
    ,output [  5:0]  cop2_reg_waddr_o
    ,output [ 31:0]  cop2_reg_wdata_o
    ,output [  5:0]  cop2_reg_raddr_o
    ,output          cop3_valid_o
    ,output [ 31:0]  cop3_opcode_o
    ,output          cop3_reg_write_o
    ,output [  5:0]  cop3_reg_waddr_o
    ,output [ 31:0]  cop3_reg_wdata_o
    ,output [  5:0]  cop3_reg_raddr_o
);



//-------------------------------------------------------------
// Includes
//-------------------------------------------------------------
`include "mpx_defs.v"

wire        enable_muldiv_w = SUPPORT_MULDIV;
wire [3:0]  enable_cop_w    = SUPPORTED_COP[3:0];

wire stall_w;
wire squash_w;

wire [3:0] cop_stall_w;

assign cop_stall_w[0] = 1'b0;
assign cop_stall_w[1] = enable_cop_w[1] & (fetch_instr_cop1_i & ~cop1_accept_i);
assign cop_stall_w[2] = enable_cop_w[2] & (fetch_instr_cop2_i & ~cop2_accept_i);
assign cop_stall_w[3] = enable_cop_w[3] & (fetch_instr_cop3_i & ~cop3_accept_i);

//-------------------------------------------------------------
// Priv level
//-------------------------------------------------------------
reg priv_x_q;

always @ (posedge clk_i )
if (rst_i)
    priv_x_q <= 1'b0;
else if (branch_cop0_request_i)
    priv_x_q <= branch_cop0_priv_i;

//-------------------------------------------------------------
// Branch request (exception or branch instruction)
//-------------------------------------------------------------
assign branch_request_o     = branch_cop0_request_i | branch_d_exec_request_i;
assign branch_pc_o          = branch_cop0_request_i ? branch_cop0_pc_i   : branch_d_exec_pc_i;
assign branch_priv_o        = branch_cop0_request_i ? branch_cop0_priv_i : priv_x_q;
assign branch_exception_o   = branch_cop0_request_i;

//-------------------------------------------------------------
// Instruction Input
//-------------------------------------------------------------
wire       opcode_valid_w   = fetch_valid_i & ~squash_w & ~branch_cop0_request_i;
wire [4:0] issue_rs_idx_w   = fetch_instr_i[`OPCODE_RS_R];
wire [4:0] issue_rt_idx_w   = fetch_instr_i[`OPCODE_RT_R];
wire [4:0] issue_rd_idx_w   = fetch_instr_lr_is_rd_i ? 5'd31: // $LR 
                              fetch_instr_rt_is_rd_i ? fetch_instr_i[`OPCODE_RT_R] : 
                                                       fetch_instr_i[`OPCODE_RD_R];
wire       issue_sb_alloc_w = fetch_instr_rd_valid_i;
wire       issue_lsu_w      = fetch_instr_lsu_i;
wire       issue_branch_w   = fetch_instr_branch_i;
wire       issue_mul_w      = fetch_instr_mul_i;
wire       issue_div_w      = fetch_instr_div_i;
wire       issue_cop0_w     = fetch_instr_cop0_i;
wire       issue_cop1_w     = fetch_instr_cop1_i;
wire       issue_cop2_w     = fetch_instr_cop2_i;
wire       issue_cop3_w     = fetch_instr_cop3_i;
wire       issue_invalid_w  = fetch_instr_invalid_i;

//-------------------------------------------------------------
// Pipeline status tracking
//------------------------------------------------------------- 
wire        pipe_squash_x_m_w;

reg         opcode_issue_r;
reg         opcode_accept_r;
wire        pipe_stall_raw_w;

wire        pipe_load_x_w;
wire        pipe_store_x_w;
wire        pipe_mul_x_w;
wire        pipe_branch_x_w;
wire [4:0]  pipe_rd_x_w;

wire [31:0] pipe_pc_x_w;
wire [31:0] pipe_opcode_x_w;
wire [31:0] pipe_operand_rs_x_w;
wire [31:0] pipe_operand_rt_x_w;

wire        pipe_load_m_w;
wire        pipe_mul_m_w;
wire [4:0]  pipe_rd_m_w;
wire [31:0] pipe_result_m_w;

wire        pipe_valid_wb_w;
wire        pipe_cop0_wb_w;
wire        pipe_cop1_wb_w;
wire        pipe_cop2_wb_w;
wire        pipe_cop3_wb_w;
wire [4:0]  pipe_rd_wb_w;
wire [31:0] pipe_result_wb_w;
wire [31:0] pipe_pc_wb_w;
wire [31:0] pipe_opc_wb_w;
wire [31:0] pipe_rs_val_wb_w;
wire [31:0] pipe_rt_val_wb_w;
wire        pipe_del_slot_wb_w;
wire [`EXCEPTION_W-1:0] pipe_exception_x_w;
wire [`EXCEPTION_W-1:0] pipe_exception_wb_w;

wire [`EXCEPTION_W-1:0] issue_fault_w = fetch_fault_fetch_i ? `EXCEPTION_IBE:
                                                              `EXCEPTION_W'b0;

mpx_pipe_ctrl
#( 
     .SUPPORT_LOAD_BYPASS(SUPPORT_LOAD_BYPASS)
    ,.SUPPORT_MUL_BYPASS(SUPPORT_MUL_BYPASS)
)
u_pipe_ctrl
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)    

    // Issue
    ,.issue_valid_i(opcode_issue_r)
    ,.issue_accept_i(opcode_accept_r)
    ,.issue_stall_i(stall_w)
    ,.issue_lsu_i(issue_lsu_w)
    ,.issue_cop0_i(issue_cop0_w)
    ,.issue_cop0_wr_i(fetch_instr_cop0_wr_i)
    ,.issue_cop1_i(issue_cop1_w)
    ,.issue_cop1_wr_i(fetch_instr_cop1_wr_i)
    ,.issue_cop2_i(issue_cop2_w)
    ,.issue_cop2_wr_i(fetch_instr_cop2_wr_i)
    ,.issue_cop3_i(issue_cop3_w)
    ,.issue_cop3_wr_i(fetch_instr_cop3_wr_i)
    ,.issue_div_i(issue_div_w)
    ,.issue_mul_i(issue_mul_w)
    ,.issue_branch_i(issue_branch_w)
    ,.issue_rd_valid_i(issue_sb_alloc_w)
    ,.issue_rt_is_rd_i(fetch_instr_rt_is_rd_i)
    ,.issue_rd_i(issue_rd_idx_w)
    ,.issue_exception_i(issue_fault_w)
    ,.issue_pc_i(opcode_pc_o)
    ,.issue_opcode_i(opcode_opcode_o)
    ,.issue_operand_rs_i(opcode_rs_operand_o)
    ,.issue_operand_rt_i(opcode_rt_operand_o)
    ,.issue_branch_taken_i(branch_d_exec_request_i)
    ,.issue_branch_target_i(branch_d_exec_pc_i)
    ,.issue_delay_slot_i(fetch_delay_slot_i)
    ,.take_interrupt_i(take_interrupt_i)
    ,.take_nmi_i(take_interrupt_nmi_i)

    // Issue: 0 cycle latency read results (COPx)
    ,.cop0_result_rdata_i(cop0_rd_rdata_i)
    ,.cop1_result_rdata_i(cop1_reg_rdata_i)
    ,.cop2_result_rdata_i(cop2_reg_rdata_i)
    ,.cop3_result_rdata_i(cop3_reg_rdata_i)

    // Execution stage 1: ALU result
    ,.alu_result_x_i(writeback_exec_value_i)
    ,.cop0_result_exception_x_i(cop0_result_x_exception_i)

    // Execution stage 1
    ,.load_x_o(pipe_load_x_w)
    ,.store_x_o(pipe_store_x_w)
    ,.mul_x_o(pipe_mul_x_w)
    ,.branch_x_o(pipe_branch_x_w)
    ,.rd_x_o(pipe_rd_x_w)
    ,.pc_x_o(pipe_pc_x_w)
    ,.opcode_x_o(pipe_opcode_x_w)
    ,.operand_rs_x_o(pipe_operand_rs_x_w)
    ,.operand_rt_x_o(pipe_operand_rt_x_w)
    ,.exception_x_o(pipe_exception_x_w)

    // Execution stage 2: Other results
    ,.mem_complete_i(writeback_mem_valid_i)
    ,.mem_result_m_i(writeback_mem_value_i)
    ,.mem_exception_m_i(writeback_mem_exception_i)

    // Execution stage 2
    ,.load_m_o(pipe_load_m_w)
    ,.mul_m_o(pipe_mul_m_w)
    ,.rd_m_o(pipe_rd_m_w)
    ,.result_m_o(pipe_result_m_w)
    ,.operand_rt_m_o(lsu_opcode_rt_operand_m_o) // (for LWL, LWR)

    ,.stall_o(pipe_stall_raw_w)
    ,.squash_x_m_o(pipe_squash_x_m_w)

    // Out of pipe: Divide Result
    ,.div_complete_i(writeback_div_valid_i)

    // Commit
    ,.valid_wb_o(pipe_valid_wb_w)
    ,.cop0_wb_o(pipe_cop0_wb_w)
    ,.cop1_wb_o(pipe_cop1_wb_w)
    ,.cop2_wb_o(pipe_cop2_wb_w)
    ,.cop3_wb_o(pipe_cop3_wb_w)
    ,.rd_wb_o(pipe_rd_wb_w)
    ,.result_wb_o(pipe_result_wb_w)
    ,.pc_wb_o(pipe_pc_wb_w)
    ,.opcode_wb_o(pipe_opc_wb_w)
    ,.operand_rs_wb_o(pipe_rs_val_wb_w)
    ,.operand_rt_wb_o(pipe_rt_val_wb_w)
    ,.exception_wb_o(pipe_exception_wb_w)
    ,.delay_slot_wb_o(pipe_del_slot_wb_w)
    
    ,.cop0_write_wb_o(cop0_writeback_write_o)
    ,.cop1_write_wb_o(cop1_reg_write_o)
    ,.cop2_write_wb_o(cop2_reg_write_o)
    ,.cop3_write_wb_o(cop3_reg_write_o)

    ,.cop0_waddr_wb_o(cop0_writeback_waddr_o)
    ,.cop0_wdata_wb_o(cop0_writeback_wdata_o)   
);

assign exec_hold_o = stall_w;
assign mul_hold_o  = stall_w;

//-------------------------------------------------------------
// Status tracking
//-------------------------------------------------------------
assign cop0_writeback_exception_o      = pipe_exception_wb_w;
assign cop0_writeback_exception_pc_o   = pipe_pc_wb_w;
assign cop0_writeback_exception_addr_o = pipe_result_wb_w;
assign cop0_writeback_delay_slot_o     = pipe_del_slot_wb_w;

//-------------------------------------------------------------
// Blocking events (division, COP0 unit access)
//-------------------------------------------------------------
reg mul_pending_q;
reg div_pending_q;
reg cop0_pending_q;
reg cop1_pending_q;
reg cop2_pending_q;
reg cop3_pending_q;

// TODO: Multiplies should be non-blocking...
always @ (posedge clk_i )
if (rst_i)
    mul_pending_q <= 1'b0;
else if (pipe_squash_x_m_w)
    mul_pending_q <= 1'b0;
else if (mul_opcode_valid_o && issue_mul_w)
    mul_pending_q <= 1'b1;
else if (writeback_mul_valid_i)
    mul_pending_q <= 1'b0;

// Division operations take 2 - 34 cycles and stall
// the pipeline (complete out-of-pipe) until completed.
always @ (posedge clk_i )
if (rst_i)
    div_pending_q <= 1'b0;
else if (pipe_squash_x_m_w)
    div_pending_q <= 1'b0;
else if (div_opcode_valid_o && issue_div_w)
    div_pending_q <= 1'b1;
else if (writeback_div_valid_i)
    div_pending_q <= 1'b0;

// COP0 operations are infrequent - avoid any complications of pipelining them.
// These only take a 2-3 cycles anyway and may result in a pipe flush (e.g. syscall, break..).
always @ (posedge clk_i )
if (rst_i)
    cop0_pending_q <= 1'b0;
else if (pipe_squash_x_m_w)
    cop0_pending_q <= 1'b0;
else if (cop0_opcode_valid_o && issue_cop0_w)
    cop0_pending_q <= 1'b1;
else if (pipe_cop0_wb_w)
    cop0_pending_q <= 1'b0;

// TODO: This is all wrong
always @ (posedge clk_i )
if (rst_i)
    cop1_pending_q <= 1'b0;
else if (pipe_squash_x_m_w)
    cop1_pending_q <= 1'b0;
else if (cop1_valid_o && issue_cop1_w)
    cop1_pending_q <= 1'b1;
else if (pipe_cop1_wb_w)
    cop1_pending_q <= 1'b0;
always @ (posedge clk_i )
if (rst_i)
    cop2_pending_q <= 1'b0;
else if (pipe_squash_x_m_w)
    cop2_pending_q <= 1'b0;
else if (cop2_valid_o && issue_cop2_w)
    cop2_pending_q <= 1'b1;
else if (pipe_cop2_wb_w)
    cop2_pending_q <= 1'b0;
always @ (posedge clk_i )
if (rst_i)
    cop3_pending_q <= 1'b0;
else if (pipe_squash_x_m_w)
    cop3_pending_q <= 1'b0;
else if (cop3_valid_o && issue_cop3_w)
    cop3_pending_q <= 1'b1;
else if (pipe_cop3_wb_w)
    cop3_pending_q <= 1'b0;

assign squash_w = pipe_squash_x_m_w;
assign squash_muldiv_o = squash_w;

//-------------------------------------------------------------
// Issue / scheduling logic
//-------------------------------------------------------------
reg [31:0] scoreboard_r;

always @ *
begin
    opcode_issue_r     = 1'b0;
    opcode_accept_r    = 1'b0;
    scoreboard_r       = 32'b0;

    // Execution units with >= 2 cycle latency
    if (SUPPORT_LOAD_BYPASS == 0)
    begin
        if (pipe_load_m_w)
            scoreboard_r[pipe_rd_m_w] = 1'b1;
    end
    if (SUPPORT_MUL_BYPASS == 0)
    begin
        if (pipe_mul_m_w)
            scoreboard_r[pipe_rd_m_w] = 1'b1;
    end

    // Execution units with >= 1 cycle latency (loads / multiply)
    if (pipe_load_x_w || pipe_mul_x_w)
        scoreboard_r[pipe_rd_x_w] = 1'b1;

    // Do not start multiply, division or COP operation in the cycle after a load (leaving only ALU operations and branches)
    if ((pipe_load_x_w || pipe_store_x_w) && (issue_mul_w || issue_div_w || issue_cop0_w || issue_cop1_w || issue_cop2_w || issue_cop3_w))
        scoreboard_r = 32'hFFFFFFFF;

    // Stall - no issues...
    if (lsu_stall_i || stall_w || div_pending_q || mul_pending_q || 
        cop0_pending_q || cop1_pending_q || cop2_pending_q || cop3_pending_q || (|cop_stall_w))
        ;
    // Handling exception
    else if (|pipe_exception_x_w)
        ;
    // Valid opcode - no hazards
    else if (opcode_valid_w &&
        !(scoreboard_r[issue_rs_idx_w] || 
          scoreboard_r[issue_rt_idx_w] ||
          scoreboard_r[issue_rd_idx_w]))
    begin
        opcode_issue_r  = 1'b1;
        opcode_accept_r = 1'b1;

        if (opcode_accept_r && issue_sb_alloc_w && (|issue_rd_idx_w))
            scoreboard_r[issue_rd_idx_w] = 1'b1;
    end 
end

assign lsu_opcode_valid_o   = opcode_issue_r & ~take_interrupt_i;
assign exec_opcode_valid_o  = opcode_issue_r;
assign mul_opcode_valid_o   = enable_muldiv_w & opcode_issue_r;
assign div_opcode_valid_o   = enable_muldiv_w & opcode_issue_r;
assign interrupt_inhibit_o  = cop0_pending_q || cop1_pending_q || cop2_pending_q || cop3_pending_q || 
                              issue_cop0_w   || issue_cop1_w   || issue_cop2_w   || issue_cop3_w;

assign fetch_accept_o       = opcode_valid_w ? (opcode_accept_r & ~take_interrupt_i) : 1'b1;

assign stall_w              = pipe_stall_raw_w;

//-------------------------------------------------------------
// Register File
//------------------------------------------------------------- 
wire [31:0] issue_rs_value_w;
wire [31:0] issue_rt_value_w;

// Register file: 1W2R
mpx_regfile
#(
     .SUPPORT_REGFILE_XILINX(SUPPORT_REGFILE_XILINX)
)
u_regfile
(
    .clk_i(clk_i),
    .rst_i(rst_i),

    // Write ports
    .rd0_i(pipe_rd_wb_w),
    .rd0_value_i(pipe_result_wb_w),

    // Read ports
    .ra0_i(issue_rs_idx_w),
    .rb0_i(issue_rt_idx_w),
    .ra0_value_o(issue_rs_value_w),
    .rb0_value_o(issue_rt_value_w)
);

//-------------------------------------------------------------
// Operand resolution (bypass logic)
//------------------------------------------------------------- 
assign opcode_opcode_o = fetch_instr_i;
assign opcode_pc_o     = fetch_pc_i;
assign opcode_rd_idx_o = issue_rd_idx_w;
assign opcode_rs_idx_o = issue_rs_idx_w;
assign opcode_rt_idx_o = issue_rt_idx_w;
assign opcode_invalid_o= 1'b0; 

reg [31:0] issue_rs_value_r;
reg [31:0] issue_rt_value_r;

always @ *
begin
    // NOTE: Newest version of operand takes priority
    issue_rs_value_r = issue_rs_value_w;
    issue_rt_value_r = issue_rt_value_w;

    // Bypass - WB
    if (pipe_rd_wb_w == issue_rs_idx_w)
        issue_rs_value_r = pipe_result_wb_w;
    if (pipe_rd_wb_w == issue_rt_idx_w)
        issue_rt_value_r = pipe_result_wb_w;

    // Bypass - M
    if (pipe_rd_m_w == issue_rs_idx_w)
        issue_rs_value_r = pipe_result_m_w;
    if (pipe_rd_m_w == issue_rt_idx_w)
        issue_rt_value_r = pipe_result_m_w;

    // Bypass - X
    if (pipe_rd_x_w == issue_rs_idx_w)
        issue_rs_value_r = writeback_exec_value_i;
    if (pipe_rd_x_w == issue_rt_idx_w)
        issue_rt_value_r = writeback_exec_value_i;

    // Reg 0 source
    if (issue_rs_idx_w == 5'b0)
        issue_rs_value_r = 32'b0;
    if (issue_rt_idx_w == 5'b0)
        issue_rt_value_r = 32'b0;
end

assign opcode_rs_operand_o = issue_rs_value_r;
assign opcode_rt_operand_o = issue_rt_value_r;
assign opcode_delay_slot_o = fetch_delay_slot_i;

//-------------------------------------------------------------
// Load store unit
//-------------------------------------------------------------
assign lsu_opcode_opcode_o      = opcode_opcode_o;
assign lsu_opcode_pc_o          = opcode_pc_o;
assign lsu_opcode_rd_idx_o      = opcode_rd_idx_o;
assign lsu_opcode_rs_idx_o      = opcode_rs_idx_o;
assign lsu_opcode_rt_idx_o      = opcode_rt_idx_o;
assign lsu_opcode_rs_operand_o  = opcode_rs_operand_o;
assign lsu_opcode_rt_operand_o  = (opcode_opcode_o[`OPCODE_INST_R] == `INSTR_I_SWC0) ? cop0_rd_rdata_i : 
                                  (opcode_opcode_o[`OPCODE_INST_R] == `INSTR_I_SWC2) ? cop2_reg_rdata_i :
                                                                                       opcode_rt_operand_o; // TODO: Horrible long paths...
assign lsu_opcode_invalid_o     = 1'b0;
assign lsu_opcode_delay_slot_o  = fetch_delay_slot_i;

//-------------------------------------------------------------
// Multiply
//-------------------------------------------------------------
assign mul_opcode_opcode_o      = opcode_opcode_o;
assign mul_opcode_pc_o          = opcode_pc_o;
assign mul_opcode_rd_idx_o      = opcode_rd_idx_o;
assign mul_opcode_rs_idx_o      = opcode_rs_idx_o;
assign mul_opcode_rt_idx_o      = opcode_rt_idx_o;
assign mul_opcode_rs_operand_o  = opcode_rs_operand_o;
assign mul_opcode_rt_operand_o  = opcode_rt_operand_o;
assign mul_opcode_invalid_o     = 1'b0;
assign mul_opcode_delay_slot_o  = fetch_delay_slot_i;

//-------------------------------------------------------------
// COP0 unit
//-------------------------------------------------------------
assign cop0_opcode_valid_o       = opcode_issue_r & ~take_interrupt_i;
assign cop0_opcode_opcode_o      = opcode_opcode_o;
assign cop0_opcode_pc_o          = opcode_pc_o;
assign cop0_opcode_rd_idx_o      = opcode_rd_idx_o;
assign cop0_opcode_rs_idx_o      = opcode_rs_idx_o;
assign cop0_opcode_rt_idx_o      = opcode_rt_idx_o;
assign cop0_opcode_rs_operand_o  = opcode_rs_operand_o;
assign cop0_opcode_rt_operand_o  = opcode_rt_operand_o;
assign cop0_opcode_invalid_o     = opcode_issue_r && issue_invalid_w;
assign cop0_opcode_delay_slot_o  = fetch_delay_slot_i;

reg [5:0]   cop_raddr_r;

always @ *
begin
    cop_raddr_r = 6'b0;

    // COP0 only (HI/LO access)
    if (opcode_opcode_o[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_opcode_o[`OPCODE_FUNC_R] == `INSTR_R_MFHI)
        cop_raddr_r = {1'b1, 5'd1};
    else if (opcode_opcode_o[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_opcode_o[`OPCODE_FUNC_R] == `INSTR_R_MTHI)
        cop_raddr_r = {1'b1, 5'd1};
    else if (opcode_opcode_o[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_opcode_o[`OPCODE_FUNC_R] == `INSTR_R_MFLO)
        cop_raddr_r = {1'b1, 5'd0};
    else if (opcode_opcode_o[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_opcode_o[`OPCODE_FUNC_R] == `INSTR_R_MTLO)
        cop_raddr_r = {1'b1, 5'd0};
    // MFCx: r0 - r31
    else if (opcode_opcode_o[31:28] == 4'b0100 && opcode_opcode_o[`OPCODE_RS_R] == 5'b00000)
        cop_raddr_r = {1'b0, opcode_opcode_o[`OPCODE_RD_R]};
    // CFCx: r32 - r63
    else if (opcode_opcode_o[31:28] == 4'b0100 && opcode_opcode_o[`OPCODE_RS_R] == 5'b00010)
        cop_raddr_r = {1'b1, opcode_opcode_o[`OPCODE_RD_R]};
    else if (opcode_opcode_o[`OPCODE_INST_R] == `INSTR_I_SWC0 || 
             opcode_opcode_o[`OPCODE_INST_R] == `INSTR_I_SWC1 ||
             opcode_opcode_o[`OPCODE_INST_R] == `INSTR_I_SWC2 ||
             opcode_opcode_o[`OPCODE_INST_R] == `INSTR_I_SWC3)
        cop_raddr_r = {1'b0, opcode_opcode_o[`OPCODE_RT_R]};
    else
        cop_raddr_r = {1'b0, opcode_opcode_o[`OPCODE_RD_R]};
end

assign cop0_rd_ren_o   = cop0_opcode_valid_o;
assign cop0_rd_raddr_o = cop_raddr_r;

//-------------------------------------------------------------
// COPx unit
//-------------------------------------------------------------
assign cop1_valid_o     = fetch_instr_cop1_i & opcode_issue_r & ~take_interrupt_i;
assign cop1_opcode_o    = opcode_opcode_o;
assign cop1_reg_raddr_o = cop0_rd_raddr_o;
assign cop1_reg_waddr_o = cop0_writeback_waddr_o;
assign cop1_reg_wdata_o = cop0_writeback_wdata_o;
assign cop2_valid_o     = fetch_instr_cop2_i & opcode_issue_r & ~take_interrupt_i;
assign cop2_opcode_o    = opcode_opcode_o;
assign cop2_reg_raddr_o = cop0_rd_raddr_o;
assign cop2_reg_waddr_o = cop0_writeback_waddr_o;
assign cop2_reg_wdata_o = cop0_writeback_wdata_o;
assign cop3_valid_o     = fetch_instr_cop3_i & opcode_issue_r & ~take_interrupt_i;
assign cop3_opcode_o    = opcode_opcode_o;
assign cop3_reg_raddr_o = cop0_rd_raddr_o;
assign cop3_reg_waddr_o = cop0_writeback_waddr_o;
assign cop3_reg_wdata_o = cop0_writeback_wdata_o;

//-------------------------------------------------------------
// Stats
//-------------------------------------------------------------
`ifdef verilator
reg [31:0] stats_cycles_q;
reg [31:0] stats_stalls_q;
reg [31:0] stats_cop_stall_q;
reg [31:0] stats_hazards_q;

always @ (posedge clk_i )
if (rst_i)
    stats_cycles_q   <= 32'b0;
else
    stats_cycles_q   <= stats_cycles_q + 32'd1;

always @ (posedge clk_i )
if (rst_i)
    stats_stalls_q   <= 32'b0;
else if (!fetch_valid_i || !fetch_accept_o)
    stats_stalls_q   <= stats_stalls_q + 32'd1;

always @ (posedge clk_i )
if (rst_i)
    stats_cop_stall_q   <= 32'b0;
else if ((cop0_pending_q || cop1_pending_q || cop2_pending_q || cop3_pending_q) && opcode_valid_w)
    stats_cop_stall_q   <= stats_cop_stall_q + 32'd1;

always @ (posedge clk_i )
if (rst_i)
    stats_hazards_q   <= 32'b0;
else if (opcode_valid_w && !opcode_accept_r && (scoreboard_r[issue_rs_idx_w] || scoreboard_r[issue_rt_idx_w] || scoreboard_r[issue_rd_idx_w]))
    stats_hazards_q   <= stats_hazards_q + 32'd1;

`endif


//-------------------------------------------------------------
// Checker Interface
//-------------------------------------------------------------
`ifdef verilator
mpx_trace_sim
u_pipe_dec0_verif
(
     .valid_i(pipe_valid_wb_w)
    ,.pc_i(pipe_pc_wb_w)
    ,.opcode_i(pipe_opc_wb_w)
);

wire [4:0] v_pipe_rs_w = pipe_opc_wb_w[`OPCODE_RS_R];
wire [4:0] v_pipe_rt_w = pipe_opc_wb_w[`OPCODE_RT_R];

function [0:0] complete_valid; /*verilator public*/
begin
    complete_valid = pipe_valid_wb_w;
end
endfunction
function [31:0] complete_pc; /*verilator public*/
begin
    complete_pc = pipe_pc_wb_w;
end
endfunction
function [31:0] complete_opcode; /*verilator public*/
begin
    complete_opcode = pipe_opc_wb_w;
end
endfunction
function [4:0] complete_rs; /*verilator public*/
begin
    complete_rs = v_pipe_rs_w;
end
endfunction
function [4:0] complete_rt; /*verilator public*/
begin
    complete_rt = v_pipe_rt_w;
end
endfunction
function [4:0] complete_rd; /*verilator public*/
begin
    complete_rd = pipe_rd_wb_w;
end
endfunction
function [31:0] complete_rs_val; /*verilator public*/
begin
    complete_rs_val = pipe_rs_val_wb_w;
end
endfunction
function [31:0] complete_rt_val; /*verilator public*/
begin
    complete_rt_val = pipe_rt_val_wb_w;
end
endfunction
function [31:0] complete_rd_val; /*verilator public*/
begin
    if (|pipe_rd_wb_w)
        complete_rd_val = pipe_result_wb_w;
    else
        complete_rd_val = 32'b0;
end
endfunction
function [5:0] complete_exception; /*verilator public*/
begin
    complete_exception = pipe_exception_wb_w;
end
endfunction
`endif


endmodule
