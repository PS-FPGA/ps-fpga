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
module mpx_cop0_regfile
(
     input           clk_i
    ,input           rst_i

    ,input [5:0]     ext_intr_i

    ,input [31:0]    exception_vector_i
    ,input [31:0]    nmi_vector_i

    ,input [31:0]    cop0_prid_i

    ,input [5:0]     exception_i
    ,input [31:0]    exception_pc_i
    ,input [31:0]    exception_addr_i
    ,input           exception_delay_slot_i

    // COP0 read port
    ,input           cop0_ren_i
    ,input  [5:0]    cop0_raddr_i
    ,output [31:0]   cop0_rdata_o

    // COP0 write port
    ,input  [5:0]    cop0_waddr_i
    ,input  [31:0]   cop0_wdata_i

    // Mul/Div results
    ,input           muldiv_i
    ,input [31:0]    muldiv_hi_i
    ,input [31:0]    muldiv_lo_i

    ,output          cop0_branch_o
    ,output [31:0]   cop0_target_o

    // COP0 registers
    ,output          priv_o
    ,output [31:0]   status_o

    // Masked interrupt output
    ,output          interrupt_o
);

//-----------------------------------------------------------------
// Includes
//-----------------------------------------------------------------
`include "mpx_defs.v"

//-----------------------------------------------------------------
// Registers / Wires
//-----------------------------------------------------------------
reg [31:0]  cop0_eepc_q;    // Custom
reg [31:0]  cop0_scratch_q; // Custom
reg [31:0]  cop0_estatus_q; // Custom
reg [31:0]  cop0_ecause_q;  // Custom
reg [31:0]  cop0_epc_q;
reg [31:0]  cop0_cause_q;
reg [31:0]  cop0_status_q;
reg [31:0]  cop0_bad_addr_q;
reg [31:0]  hi_q;
reg [31:0]  lo_q;
reg [31:0]  cop0_cycles_q;

//-----------------------------------------------------------------
// Masked Interrupts
//-----------------------------------------------------------------
reg [7:0]  irq_pending_r;
reg [7:0]  irq_masked_r;

always @ *
begin
    irq_masked_r    = 8'b0;
    irq_pending_r   = {ext_intr_i, cop0_cause_q[`COP0_CAUSE_IP1_0_R]};

    if (cop0_status_q[`COP0_SR_IEC])
        irq_masked_r    = irq_pending_r & cop0_status_q[`COP0_SR_IM_R];
    else
        irq_masked_r    = 8'b0;
end

assign interrupt_o = (|irq_masked_r);

//-----------------------------------------------------------------
// COP0 Read Port
//-----------------------------------------------------------------
reg [31:0] rdata_r;
always @ *
begin
    rdata_r = 32'b0;

    case (cop0_raddr_i)
    // HI/LO
    {1'b1, 5'd0}:          rdata_r = lo_q;
    {1'b1, 5'd1}:          rdata_r = hi_q;
    // COP0
    {1'b0, `COP0_STATUS}:  rdata_r = cop0_status_q;
    {1'b0, `COP0_CAUSE}:   rdata_r = cop0_cause_q;
    {1'b0, `COP0_EPC}:     rdata_r = cop0_epc_q;
    {1'b0, `COP0_BADADDR}: rdata_r = cop0_bad_addr_q;
    {1'b0, `COP0_COUNT}:   rdata_r = cop0_cycles_q; // TODO: Non-std
    {1'b0, `COP0_PRID}:    rdata_r = cop0_prid_i;
    {1'b0, `COP0_EEPC}:    rdata_r = cop0_eepc_q;
    {1'b0, `COP0_SCRATCH}: rdata_r = cop0_scratch_q;
    {1'b0, `COP0_ESTATUS}: rdata_r = cop0_estatus_q;    
    {1'b0, `COP0_ECAUSE}:  rdata_r = cop0_ecause_q;
    default:               rdata_r = 32'b0;
    endcase
end

assign cop0_rdata_o = rdata_r;
assign priv_o      = cop0_status_q[`COP0_SR_KUC];
assign status_o    = cop0_status_q;

//-----------------------------------------------------------------
// COP0 register next state
//-----------------------------------------------------------------
reg [31:0]  cop0_epc_r;
reg [31:0]  cop0_cause_r;
reg [31:0]  cop0_bad_addr_r;
reg [31:0]  cop0_status_r;
reg [31:0]  cop0_eepc_r;
reg [31:0]  cop0_scratch_r;
reg [31:0]  cop0_estatus_r;
reg [31:0]  cop0_ecause_r;

wire is_exception_w = |(exception_i & `EXCEPTION_MASK);
wire is_interrupt_w = |(exception_i & `EXCEPTION_INT);
wire is_nmi_w       =  (exception_i == `EXCEPTION_NMI);

// HACK: Divert everything to NMI handler
//wire is_bp_w        =  (exception_i == `EXCEPTION_BP);
wire is_bp_w        =  (exception_i == `EXCEPTION_BP)   ||
                       (exception_i == `EXCEPTION_ADEL) ||
                       (exception_i == `EXCEPTION_ADES) ||
                       (exception_i == `EXCEPTION_IBE)  ||
                       (exception_i == `EXCEPTION_DBE)  ||
                       (exception_i == `EXCEPTION_RI);

always @ *
begin
    cop0_epc_r      = cop0_epc_q;
    cop0_status_r   = cop0_status_q;
    cop0_cause_r    = cop0_cause_q;
    cop0_bad_addr_r = cop0_bad_addr_q;
    cop0_eepc_r     = cop0_eepc_q;
    cop0_scratch_r  = cop0_scratch_q;
    cop0_estatus_r  = cop0_estatus_q;
    cop0_ecause_r   = cop0_ecause_q;

    // Interrupts
    if (is_interrupt_w)
    begin
        cop0_estatus_r = cop0_status_r;
        cop0_ecause_r  = cop0_cause_r;

        // STATUS: Interrupt enable stack push
        cop0_status_r[`COP0_SR_IEO] = cop0_status_r[`COP0_SR_IEP];
        cop0_status_r[`COP0_SR_IEP] = cop0_status_r[`COP0_SR_IEC];
        cop0_status_r[`COP0_SR_IEC] = 1'b0;

        // STATUS: User mode stack push
        cop0_status_r[`COP0_SR_KUO] = cop0_status_r[`COP0_SR_KUP];
        cop0_status_r[`COP0_SR_KUP] = cop0_status_r[`COP0_SR_KUC];
        cop0_status_r[`COP0_SR_KUC] = 1'b0;

        // CAUSE: Set exception cause
        cop0_cause_r[`COP0_CAUSE_EXC_R] = exception_i[3:0]; // TODO: ???

        // CAUSE: Record if this exception was in a branch delay slot
        cop0_cause_r[`COP0_CAUSE_BD]    = exception_delay_slot_i;

        // Record fault source PC
        // TODO: Use pc_m?
        cop0_eepc_r     = cop0_epc_r;
        cop0_epc_r      = exception_delay_slot_i ? (exception_pc_i - 32'd4) : exception_pc_i;

        // Bad address / PC
        cop0_bad_addr_r = exception_addr_i;
    end
    // Exception - handled in machine mode
    else if (is_exception_w)
    begin
        cop0_estatus_r = cop0_status_r;
        cop0_ecause_r  = cop0_cause_r;

        // STATUS: Interrupt enable stack push
        cop0_status_r[`COP0_SR_IEO] = cop0_status_r[`COP0_SR_IEP];
        cop0_status_r[`COP0_SR_IEP] = cop0_status_r[`COP0_SR_IEC];
        cop0_status_r[`COP0_SR_IEC] = 1'b0;

        // STATUS: User mode stack push
        cop0_status_r[`COP0_SR_KUO] = cop0_status_r[`COP0_SR_KUP];
        cop0_status_r[`COP0_SR_KUP] = cop0_status_r[`COP0_SR_KUC];
        cop0_status_r[`COP0_SR_KUC] = 1'b0;

        // CAUSE: Set exception cause
        cop0_cause_r[`COP0_CAUSE_EXC_R] = exception_i[3:0]; // TODO: ???

        // CAUSE: Record if this exception was in a branch delay slot
        cop0_cause_r[`COP0_CAUSE_BD]    = exception_delay_slot_i;

        // Record fault source PC
        // TODO: Use pc_m?
        cop0_eepc_r     = cop0_epc_r;
        cop0_epc_r      = exception_delay_slot_i ? (exception_pc_i - 32'd4) : exception_pc_i;

        // Bad address / PC
        cop0_bad_addr_r = exception_addr_i;
    end
    else
    begin
        case (cop0_waddr_i)
        // COP0
        {1'b0, `COP0_STATUS}:  cop0_status_r   = cop0_wdata_i;
        {1'b0, `COP0_CAUSE}:   cop0_cause_r    = cop0_wdata_i;
        {1'b0, `COP0_EPC}:     cop0_epc_r      = cop0_wdata_i;
        {1'b0, `COP0_BADADDR}: cop0_bad_addr_r = cop0_wdata_i;
        {1'b0, `COP0_EEPC}:    cop0_eepc_r     = cop0_wdata_i;
        {1'b0, `COP0_SCRATCH}: cop0_scratch_r  = cop0_wdata_i;
        {1'b0, `COP0_ESTATUS}: cop0_estatus_r  = cop0_wdata_i;
        {1'b0, `COP0_ECAUSE}:  cop0_ecause_r   = cop0_wdata_i;
        // RFE - pop interrupt / mode stacks
        {1'b1, `COP0_STATUS}:
        begin
            // STATUS: Interrupt enable stack pop
            cop0_status_r[`COP0_SR_IEC] = cop0_status_r[`COP0_SR_IEP];
            cop0_status_r[`COP0_SR_IEP] = cop0_status_r[`COP0_SR_IEO];

            // STATUS: User mode stack pop
            cop0_status_r[`COP0_SR_KUC] = cop0_status_r[`COP0_SR_KUP];
            cop0_status_r[`COP0_SR_KUP] = cop0_status_r[`COP0_SR_KUO];
        end
        // Custom - return from debug handler
        {1'b0, `COP0_DRFE}:
        begin
            cop0_epc_r      = cop0_eepc_q;
            cop0_status_r   = cop0_estatus_q;
            cop0_cause_r    = cop0_ecause_r;
        end
        default:
            ;
        endcase
    end

    // External interrupt pending state override
    cop0_cause_r[`COP0_CAUSE_IP_R] = {ext_intr_i, cop0_cause_r[`COP0_CAUSE_IP1_0_R]};
end

//-----------------------------------------------------------------
// Sequential
//-----------------------------------------------------------------
always @ (posedge clk_i )
if (rst_i)
begin
    cop0_epc_q         <= 32'b0;
    cop0_status_q      <= 32'b0;
    cop0_cause_q       <= 32'b0;
    cop0_bad_addr_q    <= 32'b0;
    cop0_eepc_q        <= 32'b0;
    cop0_scratch_q     <= 32'b0;
    cop0_estatus_q     <= 32'b0;
    cop0_ecause_q      <= 32'b0;
    cop0_cycles_q      <= 32'b0;
end
else
begin
    cop0_epc_q         <= cop0_epc_r;
    cop0_status_q      <= cop0_status_r;
    cop0_cause_q       <= cop0_cause_r;
    cop0_bad_addr_q    <= cop0_bad_addr_r;
    cop0_eepc_q        <= cop0_eepc_r;
    cop0_scratch_q     <= cop0_scratch_r;
    cop0_estatus_q     <= cop0_estatus_r;
    cop0_ecause_q      <= cop0_ecause_r;
    cop0_cycles_q      <= cop0_cycles_q + 32'd1;
end

//-----------------------------------------------------------------
// HI/LO registers
//-----------------------------------------------------------------
always @ (posedge clk_i )
if (rst_i)
begin
    hi_q    <= 32'b0;
    lo_q    <= 32'b0;
end
else if (muldiv_i && !is_exception_w)
begin
    hi_q    <= muldiv_hi_i;
    lo_q    <= muldiv_lo_i;
end
else if (!is_exception_w && !is_interrupt_w)
begin
    if (cop0_waddr_i == {1'b1, 5'd0})
        lo_q    <= cop0_wdata_i;
    if (cop0_waddr_i == {1'b1, 5'd1})
        hi_q    <= cop0_wdata_i;
end

//-----------------------------------------------------------------
// COP0 branch (exceptions, interrupts, syscall, break)
//-----------------------------------------------------------------
reg        branch_r;
reg [31:0] branch_target_r;

always @ *
begin
    branch_r        = 1'b0;
    branch_target_r = 32'b0;

    // Interrupts
    if (is_interrupt_w)
    begin
        branch_r        = 1'b1;
        branch_target_r = is_nmi_w ? nmi_vector_i : exception_vector_i;
    end
    // Exception - handled in machine mode
    else if (is_exception_w)
    begin
        branch_r        = 1'b1;
        branch_target_r = is_bp_w ? nmi_vector_i : exception_vector_i;
    end
    // Custom - context restore
    else if (cop0_waddr_i == {1'b0, `COP0_DRFE})
    begin
        branch_r        = 1'b1;
        branch_target_r = cop0_epc_q;
    end
end

assign cop0_branch_o = branch_r;
assign cop0_target_o = branch_target_r;

endmodule
