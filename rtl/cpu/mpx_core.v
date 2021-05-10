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
module mpx_core
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
     parameter SUPPORT_MULDIV   = 1
    ,parameter SUPPORT_REGFILE_XILINX = 0
    ,parameter MEM_CACHE_ADDR_MIN = 32'h80000000
    ,parameter MEM_CACHE_ADDR_MAX = 32'h8fffffff
    ,parameter SUPPORTED_COP    = 5
    ,parameter COP0_PRID        = 2
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(
    // Inputs
     input           clk_i
    ,input           rst_i
    ,input  [ 31:0]  mem_d_data_rd_i
    ,input           mem_d_accept_i
    ,input           mem_d_ack_i
    ,input           mem_d_error_i
    ,input  [ 10:0]  mem_d_resp_tag_i
    ,input           mem_i_accept_i
    ,input           mem_i_valid_i
    ,input           mem_i_error_i
    ,input  [ 31:0]  mem_i_inst_i
    ,input  [  5:0]  intr_i
    ,input  [ 31:0]  reset_vector_i
    ,input           nmi_i
    ,input  [ 31:0]  nmi_vector_i
    ,input  [ 31:0]  exception_vector_i
    ,input           cop2_accept_i
    ,input  [ 31:0]  cop2_reg_rdata_i

    // Outputs
    ,output [ 31:0]  mem_d_addr_o
    ,output [ 31:0]  mem_d_data_wr_o
    ,output          mem_d_rd_o
    ,output [  3:0]  mem_d_wr_o
    ,output          mem_d_cacheable_o
    ,output [ 10:0]  mem_d_req_tag_o
    ,output          mem_d_invalidate_o
    ,output          mem_d_writeback_o
    ,output          mem_d_flush_o
    ,output          mem_i_rd_o
    ,output          mem_i_flush_o
    ,output          mem_i_invalidate_o
    ,output [ 31:0]  mem_i_pc_o
    ,output [ 31:0]  cop0_status_o
    ,output          cop2_valid_o
    ,output [ 31:0]  cop2_opcode_o
    ,output          cop2_reg_write_o
    ,output [  5:0]  cop2_reg_waddr_o
    ,output [ 31:0]  cop2_reg_wdata_o
    ,output [  5:0]  cop2_reg_raddr_o
);

wire  [  4:0]  mul_opcode_rd_idx_w;
wire           fetch_dec_delay_slot_w;
wire  [ 31:0]  lsu_opcode_pc_w;
wire           fetch_accept_w;
wire  [ 31:0]  opcode_rt_operand_m_w;
wire  [ 31:0]  lsu_opcode_rt_operand_w;
wire  [ 31:0]  lsu_opcode_rs_operand_w;
wire  [ 31:0]  opcode_pc_w;
wire           cop0_opcode_delay_slot_w;
wire           mul_opcode_valid_w;
wire  [ 31:0]  writeback_div_hi_w;
wire  [ 31:0]  cop0_opcode_pc_w;
wire           cop0_opcode_invalid_w;
wire           branch_d_exec_priv_w;
wire           fetch_instr_mul_w;
wire           fetch_instr_rt_is_rd_w;
wire           branch_request_w;
wire           writeback_mem_valid_w;
wire  [ 31:0]  opcode_rt_operand_w;
wire           cop0_writeback_write_w;
wire           opcode_delay_slot_w;
wire           iflush_w;
wire  [  4:0]  mul_opcode_rt_idx_w;
wire           branch_d_exec_exception_w;
wire  [  5:0]  cop0_writeback_waddr_w;
wire  [ 31:0]  cop0_writeback_exception_addr_w;
wire  [ 31:0]  mul_opcode_opcode_w;
wire           exec_hold_w;
wire  [  4:0]  cop0_opcode_rs_idx_w;
wire           fetch_instr_invalid_w;
wire  [  4:0]  cop0_opcode_rd_idx_w;
wire  [ 31:0]  branch_pc_w;
wire           lsu_stall_w;
wire           writeback_mul_valid_w;
wire  [ 31:0]  writeback_mul_lo_w;
wire  [ 31:0]  mul_opcode_rs_operand_w;
wire  [ 31:0]  opcode_opcode_w;
wire  [ 31:0]  mul_opcode_pc_w;
wire           branch_d_exec_request_w;
wire           fetch_instr_cop3_wr_w;
wire           branch_cop0_request_w;
wire  [  4:0]  cop0_opcode_rt_idx_w;
wire  [ 31:0]  opcode_rs_operand_w;
wire  [ 31:0]  cop0_opcode_rs_operand_w;
wire           squash_muldiv_w;
wire           fetch_dec_fault_fetch_w;
wire           fetch_dec_valid_w;
wire  [  5:0]  cop0_result_x_exception_w;
wire  [  4:0]  mul_opcode_rs_idx_w;
wire           fetch_fault_fetch_w;
wire           lsu_opcode_invalid_w;
wire           mul_hold_w;
wire  [ 31:0]  fetch_pc_w;
wire  [  5:0]  cop0_rd_raddr_w;
wire           branch_exception_w;
wire  [ 31:0]  lsu_opcode_opcode_w;
wire           branch_priv_w;
wire           div_opcode_valid_w;
wire  [ 31:0]  fetch_dec_pc_w;
wire           interrupt_inhibit_w;
wire  [ 31:0]  cop0_writeback_wdata_w;
wire           lsu_opcode_delay_slot_w;
wire  [  5:0]  writeback_mem_exception_w;
wire  [ 31:0]  writeback_div_lo_w;
wire           fetch_instr_lsu_w;
wire           fetch_instr_cop0_wr_w;
wire  [ 31:0]  cop0_rd_rdata_w;
wire  [ 31:0]  writeback_mem_value_w;
wire           take_interrupt_nmi_w;
wire           cop0_opcode_valid_w;
wire           writeback_div_valid_w;
wire           fetch_instr_branch_w;
wire           fetch_instr_lr_is_rd_w;
wire  [  4:0]  lsu_opcode_rd_idx_w;
wire           branch_cop0_priv_w;
wire           fetch_delay_slot_w;
wire  [  4:0]  opcode_rt_idx_w;
wire           fetch_dec_accept_w;
wire  [  4:0]  opcode_rs_idx_w;
wire           branch_cop0_exception_w;
wire           fetch_instr_exec_w;
wire  [  4:0]  opcode_rd_idx_w;
wire           opcode_invalid_w;
wire           cop0_rd_ren_w;
wire           take_interrupt_w;
wire  [  4:0]  lsu_opcode_rs_idx_w;
wire  [ 31:0]  branch_d_exec_pc_w;
wire  [ 31:0]  mul_opcode_rt_operand_w;
wire  [  4:0]  lsu_opcode_rt_idx_w;
wire           fetch_valid_w;
wire           mul_opcode_invalid_w;
wire  [ 31:0]  branch_cop0_pc_w;
wire  [ 31:0]  cop0_opcode_rt_operand_w;
wire  [ 31:0]  cop0_writeback_exception_pc_w;
wire           fetch_instr_cop1_wr_w;
wire           lsu_opcode_valid_w;
wire           cop0_writeback_delay_slot_w;
wire  [ 31:0]  fetch_dec_instr_w;
wire  [ 31:0]  cop0_opcode_opcode_w;
wire           fetch_instr_div_w;
wire  [ 31:0]  fetch_instr_w;
wire           fetch_instr_rd_valid_w;
wire           exec_opcode_valid_w;
wire           fetch_instr_cop2_wr_w;
wire           fetch_instr_cop0_w;
wire           fetch_instr_cop1_w;
wire           fetch_instr_cop2_w;
wire           fetch_instr_cop3_w;
wire           mul_opcode_delay_slot_w;
wire  [ 31:0]  writeback_mul_hi_w;
wire  [ 31:0]  writeback_exec_value_w;
wire  [  5:0]  cop0_writeback_exception_w;


mpx_exec
u_exec
(
    // Inputs
     .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.opcode_valid_i(exec_opcode_valid_w)
    ,.opcode_opcode_i(opcode_opcode_w)
    ,.opcode_pc_i(opcode_pc_w)
    ,.opcode_invalid_i(opcode_invalid_w)
    ,.opcode_delay_slot_i(opcode_delay_slot_w)
    ,.opcode_rd_idx_i(opcode_rd_idx_w)
    ,.opcode_rs_idx_i(opcode_rs_idx_w)
    ,.opcode_rt_idx_i(opcode_rt_idx_w)
    ,.opcode_rs_operand_i(opcode_rs_operand_w)
    ,.opcode_rt_operand_i(opcode_rt_operand_w)
    ,.hold_i(exec_hold_w)

    // Outputs
    ,.branch_d_request_o(branch_d_exec_request_w)
    ,.branch_d_exception_o(branch_d_exec_exception_w)
    ,.branch_d_pc_o(branch_d_exec_pc_w)
    ,.branch_d_priv_o(branch_d_exec_priv_w)
    ,.writeback_value_o(writeback_exec_value_w)
);


mpx_decode
#(
     .SUPPORT_MULDIV(SUPPORT_MULDIV)
    ,.SUPPORTED_COP(SUPPORTED_COP)
)
u_decode
(
    // Inputs
     .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.fetch_in_valid_i(fetch_dec_valid_w)
    ,.fetch_in_instr_i(fetch_dec_instr_w)
    ,.fetch_in_pc_i(fetch_dec_pc_w)
    ,.fetch_in_delay_slot_i(fetch_dec_delay_slot_w)
    ,.fetch_in_fault_fetch_i(fetch_dec_fault_fetch_w)
    ,.fetch_out_accept_i(fetch_accept_w)

    // Outputs
    ,.fetch_in_accept_o(fetch_dec_accept_w)
    ,.fetch_out_valid_o(fetch_valid_w)
    ,.fetch_out_instr_o(fetch_instr_w)
    ,.fetch_out_pc_o(fetch_pc_w)
    ,.fetch_out_delay_slot_o(fetch_delay_slot_w)
    ,.fetch_out_fault_fetch_o(fetch_fault_fetch_w)
    ,.fetch_out_instr_exec_o(fetch_instr_exec_w)
    ,.fetch_out_instr_lsu_o(fetch_instr_lsu_w)
    ,.fetch_out_instr_branch_o(fetch_instr_branch_w)
    ,.fetch_out_instr_mul_o(fetch_instr_mul_w)
    ,.fetch_out_instr_div_o(fetch_instr_div_w)
    ,.fetch_out_instr_cop0_o(fetch_instr_cop0_w)
    ,.fetch_out_instr_cop0_wr_o(fetch_instr_cop0_wr_w)
    ,.fetch_out_instr_cop1_o(fetch_instr_cop1_w)
    ,.fetch_out_instr_cop1_wr_o(fetch_instr_cop1_wr_w)
    ,.fetch_out_instr_cop2_o(fetch_instr_cop2_w)
    ,.fetch_out_instr_cop2_wr_o(fetch_instr_cop2_wr_w)
    ,.fetch_out_instr_cop3_o(fetch_instr_cop3_w)
    ,.fetch_out_instr_cop3_wr_o(fetch_instr_cop3_wr_w)
    ,.fetch_out_instr_rd_valid_o(fetch_instr_rd_valid_w)
    ,.fetch_out_instr_rt_is_rd_o(fetch_instr_rt_is_rd_w)
    ,.fetch_out_instr_lr_is_rd_o(fetch_instr_lr_is_rd_w)
    ,.fetch_out_instr_invalid_o(fetch_instr_invalid_w)
);


mpx_cop0
#(
     .SUPPORT_MULDIV(SUPPORT_MULDIV)
    ,.COP0_PRID(COP0_PRID)
)
u_cop0
(
    // Inputs
     .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.intr_i(intr_i)
    ,.opcode_valid_i(cop0_opcode_valid_w)
    ,.opcode_opcode_i(cop0_opcode_opcode_w)
    ,.opcode_pc_i(cop0_opcode_pc_w)
    ,.opcode_invalid_i(cop0_opcode_invalid_w)
    ,.opcode_delay_slot_i(cop0_opcode_delay_slot_w)
    ,.opcode_rd_idx_i(cop0_opcode_rd_idx_w)
    ,.opcode_rs_idx_i(cop0_opcode_rs_idx_w)
    ,.opcode_rt_idx_i(cop0_opcode_rt_idx_w)
    ,.opcode_rs_operand_i(cop0_opcode_rs_operand_w)
    ,.opcode_rt_operand_i(cop0_opcode_rt_operand_w)
    ,.cop0_rd_ren_i(cop0_rd_ren_w)
    ,.cop0_rd_raddr_i(cop0_rd_raddr_w)
    ,.cop0_writeback_write_i(cop0_writeback_write_w)
    ,.cop0_writeback_waddr_i(cop0_writeback_waddr_w)
    ,.cop0_writeback_wdata_i(cop0_writeback_wdata_w)
    ,.cop0_writeback_exception_i(cop0_writeback_exception_w)
    ,.cop0_writeback_exception_pc_i(cop0_writeback_exception_pc_w)
    ,.cop0_writeback_exception_addr_i(cop0_writeback_exception_addr_w)
    ,.cop0_writeback_delay_slot_i(cop0_writeback_delay_slot_w)
    ,.mul_result_m_valid_i(writeback_mul_valid_w)
    ,.mul_result_m_hi_i(writeback_mul_hi_w)
    ,.mul_result_m_lo_i(writeback_mul_lo_w)
    ,.div_result_valid_i(writeback_div_valid_w)
    ,.div_result_hi_i(writeback_div_hi_w)
    ,.div_result_lo_i(writeback_div_lo_w)
    ,.squash_muldiv_i(squash_muldiv_w)
    ,.reset_vector_i(reset_vector_i)
    ,.exception_vector_i(exception_vector_i)
    ,.interrupt_inhibit_i(interrupt_inhibit_w)
    ,.nmi_i(nmi_i)
    ,.nmi_vector_i(nmi_vector_i)

    // Outputs
    ,.cop0_rd_rdata_o(cop0_rd_rdata_w)
    ,.cop0_result_x_exception_o(cop0_result_x_exception_w)
    ,.branch_cop0_request_o(branch_cop0_request_w)
    ,.branch_cop0_exception_o(branch_cop0_exception_w)
    ,.branch_cop0_pc_o(branch_cop0_pc_w)
    ,.branch_cop0_priv_o(branch_cop0_priv_w)
    ,.take_interrupt_o(take_interrupt_w)
    ,.take_interrupt_nmi_o(take_interrupt_nmi_w)
    ,.iflush_o(iflush_w)
    ,.status_o(cop0_status_o)
);


mpx_lsu
#(
     .MEM_CACHE_ADDR_MAX(MEM_CACHE_ADDR_MAX)
    ,.MEM_CACHE_ADDR_MIN(MEM_CACHE_ADDR_MIN)
)
u_lsu
(
    // Inputs
     .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.opcode_valid_i(lsu_opcode_valid_w)
    ,.opcode_opcode_i(lsu_opcode_opcode_w)
    ,.opcode_pc_i(lsu_opcode_pc_w)
    ,.opcode_invalid_i(lsu_opcode_invalid_w)
    ,.opcode_delay_slot_i(lsu_opcode_delay_slot_w)
    ,.opcode_rd_idx_i(lsu_opcode_rd_idx_w)
    ,.opcode_rs_idx_i(lsu_opcode_rs_idx_w)
    ,.opcode_rt_idx_i(lsu_opcode_rt_idx_w)
    ,.opcode_rs_operand_i(lsu_opcode_rs_operand_w)
    ,.opcode_rt_operand_i(lsu_opcode_rt_operand_w)
    ,.opcode_rt_operand_m_i(opcode_rt_operand_m_w)
    ,.mem_data_rd_i(mem_d_data_rd_i)
    ,.mem_accept_i(mem_d_accept_i)
    ,.mem_ack_i(mem_d_ack_i)
    ,.mem_error_i(mem_d_error_i)
    ,.mem_resp_tag_i(mem_d_resp_tag_i)

    // Outputs
    ,.mem_addr_o(mem_d_addr_o)
    ,.mem_data_wr_o(mem_d_data_wr_o)
    ,.mem_rd_o(mem_d_rd_o)
    ,.mem_wr_o(mem_d_wr_o)
    ,.mem_cacheable_o(mem_d_cacheable_o)
    ,.mem_req_tag_o(mem_d_req_tag_o)
    ,.mem_invalidate_o(mem_d_invalidate_o)
    ,.mem_writeback_o(mem_d_writeback_o)
    ,.mem_flush_o(mem_d_flush_o)
    ,.writeback_valid_o(writeback_mem_valid_w)
    ,.writeback_value_o(writeback_mem_value_w)
    ,.writeback_exception_o(writeback_mem_exception_w)
    ,.stall_o(lsu_stall_w)
);


mpx_multiplier
u_mul
(
    // Inputs
     .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.opcode_valid_i(mul_opcode_valid_w)
    ,.opcode_opcode_i(mul_opcode_opcode_w)
    ,.opcode_pc_i(mul_opcode_pc_w)
    ,.opcode_invalid_i(mul_opcode_invalid_w)
    ,.opcode_delay_slot_i(mul_opcode_delay_slot_w)
    ,.opcode_rd_idx_i(mul_opcode_rd_idx_w)
    ,.opcode_rs_idx_i(mul_opcode_rs_idx_w)
    ,.opcode_rt_idx_i(mul_opcode_rt_idx_w)
    ,.opcode_rs_operand_i(mul_opcode_rs_operand_w)
    ,.opcode_rt_operand_i(mul_opcode_rt_operand_w)
    ,.hold_i(mul_hold_w)

    // Outputs
    ,.writeback_valid_o(writeback_mul_valid_w)
    ,.writeback_hi_o(writeback_mul_hi_w)
    ,.writeback_lo_o(writeback_mul_lo_w)
);


mpx_divider
u_div
(
    // Inputs
     .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.opcode_valid_i(div_opcode_valid_w)
    ,.opcode_opcode_i(opcode_opcode_w)
    ,.opcode_pc_i(opcode_pc_w)
    ,.opcode_invalid_i(opcode_invalid_w)
    ,.opcode_delay_slot_i(opcode_delay_slot_w)
    ,.opcode_rd_idx_i(opcode_rd_idx_w)
    ,.opcode_rs_idx_i(opcode_rs_idx_w)
    ,.opcode_rt_idx_i(opcode_rt_idx_w)
    ,.opcode_rs_operand_i(opcode_rs_operand_w)
    ,.opcode_rt_operand_i(opcode_rt_operand_w)

    // Outputs
    ,.writeback_valid_o(writeback_div_valid_w)
    ,.writeback_hi_o(writeback_div_hi_w)
    ,.writeback_lo_o(writeback_div_lo_w)
);


mpx_issue
#(
     .SUPPORT_REGFILE_XILINX(SUPPORT_REGFILE_XILINX)
    ,.SUPPORT_LOAD_BYPASS(1)
    ,.SUPPORT_MULDIV(SUPPORT_MULDIV)
    ,.SUPPORTED_COP(SUPPORTED_COP)
    ,.SUPPORT_MUL_BYPASS(1)
)
u_issue
(
    // Inputs
     .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.fetch_valid_i(fetch_valid_w)
    ,.fetch_instr_i(fetch_instr_w)
    ,.fetch_pc_i(fetch_pc_w)
    ,.fetch_delay_slot_i(fetch_delay_slot_w)
    ,.fetch_fault_fetch_i(fetch_fault_fetch_w)
    ,.fetch_instr_exec_i(fetch_instr_exec_w)
    ,.fetch_instr_lsu_i(fetch_instr_lsu_w)
    ,.fetch_instr_branch_i(fetch_instr_branch_w)
    ,.fetch_instr_mul_i(fetch_instr_mul_w)
    ,.fetch_instr_div_i(fetch_instr_div_w)
    ,.fetch_instr_cop0_i(fetch_instr_cop0_w)
    ,.fetch_instr_cop0_wr_i(fetch_instr_cop0_wr_w)
    ,.fetch_instr_cop1_i(fetch_instr_cop1_w)
    ,.fetch_instr_cop1_wr_i(fetch_instr_cop1_wr_w)
    ,.fetch_instr_cop2_i(fetch_instr_cop2_w)
    ,.fetch_instr_cop2_wr_i(fetch_instr_cop2_wr_w)
    ,.fetch_instr_cop3_i(fetch_instr_cop3_w)
    ,.fetch_instr_cop3_wr_i(fetch_instr_cop3_wr_w)
    ,.fetch_instr_rd_valid_i(fetch_instr_rd_valid_w)
    ,.fetch_instr_rt_is_rd_i(fetch_instr_rt_is_rd_w)
    ,.fetch_instr_lr_is_rd_i(fetch_instr_lr_is_rd_w)
    ,.fetch_instr_invalid_i(fetch_instr_invalid_w)
    ,.cop0_rd_rdata_i(cop0_rd_rdata_w)
    ,.branch_d_exec_request_i(branch_d_exec_request_w)
    ,.branch_d_exec_exception_i(branch_d_exec_exception_w)
    ,.branch_d_exec_pc_i(branch_d_exec_pc_w)
    ,.branch_d_exec_priv_i(branch_d_exec_priv_w)
    ,.branch_cop0_request_i(branch_cop0_request_w)
    ,.branch_cop0_exception_i(branch_cop0_exception_w)
    ,.branch_cop0_pc_i(branch_cop0_pc_w)
    ,.branch_cop0_priv_i(branch_cop0_priv_w)
    ,.writeback_exec_value_i(writeback_exec_value_w)
    ,.writeback_mem_valid_i(writeback_mem_valid_w)
    ,.writeback_mem_value_i(writeback_mem_value_w)
    ,.writeback_mem_exception_i(writeback_mem_exception_w)
    ,.writeback_mul_valid_i(writeback_mul_valid_w)
    ,.writeback_mul_hi_i(writeback_mul_hi_w)
    ,.writeback_mul_lo_i(writeback_mul_lo_w)
    ,.writeback_div_valid_i(writeback_div_valid_w)
    ,.writeback_div_hi_i(writeback_div_hi_w)
    ,.writeback_div_lo_i(writeback_div_lo_w)
    ,.cop0_result_x_exception_i(cop0_result_x_exception_w)
    ,.lsu_stall_i(lsu_stall_w)
    ,.take_interrupt_i(take_interrupt_w)
    ,.take_interrupt_nmi_i(take_interrupt_nmi_w)
    ,.cop1_accept_i(1'b0)
    ,.cop1_reg_rdata_i(32'b0)
    ,.cop2_accept_i(cop2_accept_i)
    ,.cop2_reg_rdata_i(cop2_reg_rdata_i)
    ,.cop3_accept_i(1'b0)
    ,.cop3_reg_rdata_i(32'b0)

    // Outputs
    ,.fetch_accept_o(fetch_accept_w)
    ,.branch_request_o(branch_request_w)
    ,.branch_exception_o(branch_exception_w)
    ,.branch_pc_o(branch_pc_w)
    ,.branch_priv_o(branch_priv_w)
    ,.exec_opcode_valid_o(exec_opcode_valid_w)
    ,.lsu_opcode_valid_o(lsu_opcode_valid_w)
    ,.cop0_opcode_valid_o(cop0_opcode_valid_w)
    ,.mul_opcode_valid_o(mul_opcode_valid_w)
    ,.div_opcode_valid_o(div_opcode_valid_w)
    ,.opcode_opcode_o(opcode_opcode_w)
    ,.opcode_pc_o(opcode_pc_w)
    ,.opcode_invalid_o(opcode_invalid_w)
    ,.opcode_delay_slot_o(opcode_delay_slot_w)
    ,.opcode_rd_idx_o(opcode_rd_idx_w)
    ,.opcode_rs_idx_o(opcode_rs_idx_w)
    ,.opcode_rt_idx_o(opcode_rt_idx_w)
    ,.opcode_rs_operand_o(opcode_rs_operand_w)
    ,.opcode_rt_operand_o(opcode_rt_operand_w)
    ,.lsu_opcode_opcode_o(lsu_opcode_opcode_w)
    ,.lsu_opcode_pc_o(lsu_opcode_pc_w)
    ,.lsu_opcode_invalid_o(lsu_opcode_invalid_w)
    ,.lsu_opcode_delay_slot_o(lsu_opcode_delay_slot_w)
    ,.lsu_opcode_rd_idx_o(lsu_opcode_rd_idx_w)
    ,.lsu_opcode_rs_idx_o(lsu_opcode_rs_idx_w)
    ,.lsu_opcode_rt_idx_o(lsu_opcode_rt_idx_w)
    ,.lsu_opcode_rs_operand_o(lsu_opcode_rs_operand_w)
    ,.lsu_opcode_rt_operand_o(lsu_opcode_rt_operand_w)
    ,.lsu_opcode_rt_operand_m_o(opcode_rt_operand_m_w)
    ,.mul_opcode_opcode_o(mul_opcode_opcode_w)
    ,.mul_opcode_pc_o(mul_opcode_pc_w)
    ,.mul_opcode_invalid_o(mul_opcode_invalid_w)
    ,.mul_opcode_delay_slot_o(mul_opcode_delay_slot_w)
    ,.mul_opcode_rd_idx_o(mul_opcode_rd_idx_w)
    ,.mul_opcode_rs_idx_o(mul_opcode_rs_idx_w)
    ,.mul_opcode_rt_idx_o(mul_opcode_rt_idx_w)
    ,.mul_opcode_rs_operand_o(mul_opcode_rs_operand_w)
    ,.mul_opcode_rt_operand_o(mul_opcode_rt_operand_w)
    ,.cop0_opcode_opcode_o(cop0_opcode_opcode_w)
    ,.cop0_opcode_pc_o(cop0_opcode_pc_w)
    ,.cop0_opcode_invalid_o(cop0_opcode_invalid_w)
    ,.cop0_opcode_delay_slot_o(cop0_opcode_delay_slot_w)
    ,.cop0_opcode_rd_idx_o(cop0_opcode_rd_idx_w)
    ,.cop0_opcode_rs_idx_o(cop0_opcode_rs_idx_w)
    ,.cop0_opcode_rt_idx_o(cop0_opcode_rt_idx_w)
    ,.cop0_opcode_rs_operand_o(cop0_opcode_rs_operand_w)
    ,.cop0_opcode_rt_operand_o(cop0_opcode_rt_operand_w)
    ,.cop0_rd_ren_o(cop0_rd_ren_w)
    ,.cop0_rd_raddr_o(cop0_rd_raddr_w)
    ,.cop0_writeback_write_o(cop0_writeback_write_w)
    ,.cop0_writeback_waddr_o(cop0_writeback_waddr_w)
    ,.cop0_writeback_wdata_o(cop0_writeback_wdata_w)
    ,.cop0_writeback_exception_o(cop0_writeback_exception_w)
    ,.cop0_writeback_exception_pc_o(cop0_writeback_exception_pc_w)
    ,.cop0_writeback_exception_addr_o(cop0_writeback_exception_addr_w)
    ,.cop0_writeback_delay_slot_o(cop0_writeback_delay_slot_w)
    ,.exec_hold_o(exec_hold_w)
    ,.mul_hold_o(mul_hold_w)
    ,.squash_muldiv_o(squash_muldiv_w)
    ,.interrupt_inhibit_o(interrupt_inhibit_w)
    ,.cop1_valid_o()
    ,.cop1_opcode_o()
    ,.cop1_reg_write_o()
    ,.cop1_reg_waddr_o()
    ,.cop1_reg_wdata_o()
    ,.cop1_reg_raddr_o()
    ,.cop2_valid_o(cop2_valid_o)
    ,.cop2_opcode_o(cop2_opcode_o)
    ,.cop2_reg_write_o(cop2_reg_write_o)
    ,.cop2_reg_waddr_o(cop2_reg_waddr_o)
    ,.cop2_reg_wdata_o(cop2_reg_wdata_o)
    ,.cop2_reg_raddr_o(cop2_reg_raddr_o)
    ,.cop3_valid_o()
    ,.cop3_opcode_o()
    ,.cop3_reg_write_o()
    ,.cop3_reg_waddr_o()
    ,.cop3_reg_wdata_o()
    ,.cop3_reg_raddr_o()
);


mpx_fetch
u_fetch
(
    // Inputs
     .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.fetch_accept_i(fetch_dec_accept_w)
    ,.icache_accept_i(mem_i_accept_i)
    ,.icache_valid_i(mem_i_valid_i)
    ,.icache_error_i(mem_i_error_i)
    ,.icache_inst_i(mem_i_inst_i)
    ,.fetch_invalidate_i(iflush_w)
    ,.branch_request_i(branch_request_w)
    ,.branch_exception_i(branch_exception_w)
    ,.branch_pc_i(branch_pc_w)
    ,.branch_priv_i(branch_priv_w)

    // Outputs
    ,.fetch_valid_o(fetch_dec_valid_w)
    ,.fetch_instr_o(fetch_dec_instr_w)
    ,.fetch_pc_o(fetch_dec_pc_w)
    ,.fetch_delay_slot_o(fetch_dec_delay_slot_w)
    ,.fetch_fault_fetch_o(fetch_dec_fault_fetch_w)
    ,.icache_rd_o(mem_i_rd_o)
    ,.icache_flush_o(mem_i_flush_o)
    ,.icache_invalidate_o(mem_i_invalidate_o)
    ,.icache_pc_o(mem_i_pc_o)
    ,.icache_priv_o()
);



endmodule
