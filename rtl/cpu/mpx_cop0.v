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
module mpx_cop0
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
     parameter SUPPORT_MULDIV   = 1
    ,parameter COP0_PRID        = 2
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(
    // Inputs
     input           clk_i
    ,input           rst_i
    ,input  [  5:0]  intr_i
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
    ,input           cop0_rd_ren_i
    ,input  [  5:0]  cop0_rd_raddr_i
    ,input           cop0_writeback_write_i
    ,input  [  5:0]  cop0_writeback_waddr_i
    ,input  [ 31:0]  cop0_writeback_wdata_i
    ,input  [  5:0]  cop0_writeback_exception_i
    ,input  [ 31:0]  cop0_writeback_exception_pc_i
    ,input  [ 31:0]  cop0_writeback_exception_addr_i
    ,input           cop0_writeback_delay_slot_i
    ,input           mul_result_m_valid_i
    ,input  [ 31:0]  mul_result_m_hi_i
    ,input  [ 31:0]  mul_result_m_lo_i
    ,input           div_result_valid_i
    ,input  [ 31:0]  div_result_hi_i
    ,input  [ 31:0]  div_result_lo_i
    ,input           squash_muldiv_i
    ,input  [ 31:0]  reset_vector_i
    ,input  [ 31:0]  exception_vector_i
    ,input           interrupt_inhibit_i
    ,input           nmi_i
    ,input  [ 31:0]  nmi_vector_i

    // Outputs
    ,output [ 31:0]  cop0_rd_rdata_o
    ,output [  5:0]  cop0_result_x_exception_o
    ,output          branch_cop0_request_o
    ,output          branch_cop0_exception_o
    ,output [ 31:0]  branch_cop0_pc_o
    ,output          branch_cop0_priv_o
    ,output          take_interrupt_o
    ,output          take_interrupt_nmi_o
    ,output          iflush_o
    ,output [ 31:0]  status_o
);



//-----------------------------------------------------------------
// Includes
//-----------------------------------------------------------------
`include "mpx_defs.v"

//-----------------------------------------------------------------
// COP0 Faults...
//-----------------------------------------------------------------
reg         cop0_fault_r;
always @ *
begin
    // TODO: Detect access fault on COP access
    cop0_fault_r     = 1'b0;
end

//-----------------------------------------------------------------
// COP0 register file
//-----------------------------------------------------------------
wire [31:0] csr_rdata_w;

wire        csr_branch_w;
wire [31:0] csr_target_w;

wire        interrupt_w;

mpx_cop0_regfile
u_regfile
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)

    ,.cop0_prid_i(COP0_PRID)

    ,.ext_intr_i(intr_i)

    // Exception handler address
    ,.exception_vector_i(exception_vector_i)
    ,.nmi_vector_i(nmi_vector_i)

    // Issue
    ,.cop0_ren_i(cop0_rd_ren_i)
    ,.cop0_raddr_i(cop0_rd_raddr_i)
    ,.cop0_rdata_o(cop0_rd_rdata_o)

    // Exception (WB)
    ,.exception_i(cop0_writeback_exception_i)
    ,.exception_pc_i(cop0_writeback_exception_pc_i)
    ,.exception_addr_i(cop0_writeback_exception_addr_i)
    ,.exception_delay_slot_i(cop0_writeback_delay_slot_i)

    // COP0 register writes (WB)
    ,.cop0_waddr_i(cop0_writeback_write_i ? cop0_writeback_waddr_i : 6'b0) // TODO
    ,.cop0_wdata_i(cop0_writeback_wdata_i)

    // Multiply / Divide result
    ,.muldiv_i((mul_result_m_valid_i | div_result_valid_i) & ~ squash_muldiv_i)
    ,.muldiv_hi_i(div_result_valid_i ? div_result_hi_i : mul_result_m_hi_i)
    ,.muldiv_lo_i(div_result_valid_i ? div_result_lo_i : mul_result_m_lo_i)

    // COP0 branches
    ,.cop0_branch_o(csr_branch_w)
    ,.cop0_target_o(csr_target_w)

    // Various COP0 registers
    ,.priv_o()
    ,.status_o(status_o)

    // Masked interrupt output
    ,.interrupt_o(interrupt_w)
);

//-----------------------------------------------------------------
// COP0 early exceptions (X)
//-----------------------------------------------------------------
reg [`EXCEPTION_W-1:0]  exception_x_q;

always @ (posedge clk_i )
if (rst_i)
begin
    exception_x_q  <= `EXCEPTION_W'b0;
end
else if (opcode_valid_i)
begin
    // (Exceptions from X) COP0 exceptions
    if (opcode_opcode_i[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_opcode_i[`OPCODE_FUNC_R] == `INSTR_R_SYSCALL)
        exception_x_q  <= `EXCEPTION_SYS;
    else if (opcode_opcode_i[`OPCODE_INST_R] == `INSTR_R_SPECIAL && opcode_opcode_i[`OPCODE_FUNC_R] == `INSTR_R_BREAK)
        exception_x_q  <= `EXCEPTION_BP;
    else if (opcode_invalid_i || cop0_fault_r)
        exception_x_q  <= `EXCEPTION_RI;
    else
        exception_x_q  <= `EXCEPTION_W'b0;
end
else
begin
    exception_x_q  <= `EXCEPTION_W'b0;
end

assign cop0_result_x_exception_o = exception_x_q;

//-----------------------------------------------------------------
// NMI
//-----------------------------------------------------------------
reg nmi_q;

always @ (posedge clk_i )
if (rst_i)
    nmi_q <= 1'b0;
else if (~interrupt_inhibit_i)
    nmi_q <= nmi_i;

wire nmi_w = nmi_i & ~nmi_q;

//-----------------------------------------------------------------
// Interrupt launch enable
//-----------------------------------------------------------------
reg take_interrupt_q;

always @ (posedge clk_i )
if (rst_i)
    take_interrupt_q    <= 1'b0;
else
    take_interrupt_q    <= (interrupt_w & ~interrupt_inhibit_i) | nmi_w;

assign take_interrupt_o     = take_interrupt_q;
assign take_interrupt_nmi_o = nmi_q;

//-----------------------------------------------------------------
// Instruction cache flush
//-----------------------------------------------------------------
// NOTE: Detect transition on COP0R12.16 and use this as a hook to flush the cache
wire cop0_r12b16_wr_w = cop0_writeback_write_i && cop0_writeback_waddr_i ==  {1'b0, `COP0_STATUS};
wire cop0_r12b16_w    = cop0_writeback_wdata_i[16];

reg  cop0_r12b16_q;

always @ (posedge clk_i )
if (rst_i)
    cop0_r12b16_q <= 1'b0;
else if (cop0_r12b16_wr_w)
    cop0_r12b16_q <= cop0_r12b16_w;

reg iflush_q;

always @ (posedge clk_i )
if (rst_i)
    iflush_q    <= 1'b0;
else if (cop0_r12b16_wr_w)
    iflush_q    <= cop0_r12b16_w ^ cop0_r12b16_q;
else
    iflush_q    <= 1'b0;

assign iflush_o = iflush_q;

`ifdef verilator
always @ (posedge clk_i)
if (iflush_q)
begin
    $display("[MPX] Instruction cache flush");
end
`endif

//-----------------------------------------------------------------
// Execute - Branch operations
//-----------------------------------------------------------------
reg        branch_q;
reg [31:0] branch_target_q;
reg        reset_q;

always @ (posedge clk_i )
if (rst_i)
begin
    branch_target_q <= 32'b0;
    branch_q        <= 1'b0;
    reset_q         <= 1'b1;
end
else if (reset_q)
begin
    branch_target_q <= reset_vector_i;
    branch_q        <= 1'b1;
    reset_q         <= 1'b0;
end
else
begin
    branch_q        <= csr_branch_w;
    branch_target_q <= csr_target_w;
end

assign branch_cop0_request_o = branch_q;
assign branch_cop0_pc_o      = branch_target_q;
assign branch_cop0_priv_o    = 1'b0; // TODO: USER/KERN


endmodule
