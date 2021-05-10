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
module mpx_fetch
(
    // Inputs
     input           clk_i
    ,input           rst_i
    ,input           fetch_accept_i
    ,input           icache_accept_i
    ,input           icache_valid_i
    ,input           icache_error_i
    ,input  [ 31:0]  icache_inst_i
    ,input           fetch_invalidate_i
    ,input           branch_request_i
    ,input           branch_exception_i
    ,input  [ 31:0]  branch_pc_i
    ,input           branch_priv_i

    // Outputs
    ,output          fetch_valid_o
    ,output [ 31:0]  fetch_instr_o
    ,output [ 31:0]  fetch_pc_o
    ,output          fetch_delay_slot_o
    ,output          fetch_fault_fetch_o
    ,output          icache_rd_o
    ,output          icache_flush_o
    ,output          icache_invalidate_o
    ,output [ 31:0]  icache_pc_o
    ,output          icache_priv_o
);



//-------------------------------------------------------------
// Includes
//-------------------------------------------------------------
`include "mpx_defs.v"

reg         active_q;
wire        fetch_valid_w;
wire        icache_busy_w;
wire        stall_w       = !fetch_accept_i || icache_busy_w || !icache_accept_i;

//-------------------------------------------------------------
// Buffered branch (required for busy I$)
//-------------------------------------------------------------
reg         branch_q;
reg         branch_excpn_q;
reg [31:0]  branch_pc_q;
reg         branch_priv_q;

always @ (posedge clk_i )
if (rst_i)
begin
    branch_q       <= 1'b0;
    branch_excpn_q <= 1'b0;
    branch_pc_q    <= 32'b0;
    branch_priv_q  <= 1'b0;
end
// Branch request
else if (branch_request_i)
begin
    branch_q       <= stall_w && active_q;
    branch_excpn_q <= stall_w && active_q && branch_exception_i;
    branch_pc_q    <= branch_pc_i;
    branch_priv_q  <= branch_priv_i;
end
else if (icache_rd_o && icache_accept_i)
begin
    branch_q       <= 1'b0;
    branch_excpn_q <= 1'b0;
    branch_pc_q    <= 32'b0;
end

//-------------------------------------------------------------
// Active flag
//-------------------------------------------------------------
always @ (posedge clk_i )
if (rst_i)
    active_q    <= 1'b0;
else if (branch_request_i)
    active_q    <= 1'b1;

//-------------------------------------------------------------
// Request tracking
//-------------------------------------------------------------
reg icache_fetch_q;
reg icache_invalidate_q;

// ICACHE fetch tracking
always @ (posedge clk_i )
if (rst_i)
    icache_fetch_q <= 1'b0;
else if (icache_rd_o && icache_accept_i)
    icache_fetch_q <= 1'b1;
else if (icache_valid_i)
    icache_fetch_q <= 1'b0;

always @ (posedge clk_i )
if (rst_i)
    icache_invalidate_q <= 1'b0;
else if (icache_invalidate_o && !icache_accept_i)
    icache_invalidate_q <= 1'b1;
else
    icache_invalidate_q <= 1'b0;

//-------------------------------------------------------------
// PC
//-------------------------------------------------------------
reg [31:0]  pc_f_q;
reg [31:0]  pc_d_q;

wire [31:0] icache_pc_w;
wire        icache_priv_w;

always @ (posedge clk_i )
if (rst_i)
    pc_f_q  <= 32'b0;
else if (branch_request_i && (!active_q || !stall_w))
    pc_f_q  <= branch_pc_i;
// Delayed branch due to stall
else if (branch_q && ~stall_w)
    pc_f_q  <= branch_pc_q;
// NPC
else if (!stall_w)
    pc_f_q  <= {icache_pc_w[31:2],2'b0} + 32'd4;

assign icache_pc_w       = pc_f_q;
assign icache_priv_w     = 1'b0;

// Last fetch address
always @ (posedge clk_i )
if (rst_i)
    pc_d_q <= 32'b0;
else if (icache_rd_o && icache_accept_i)
    pc_d_q <= icache_pc_w;

//-------------------------------------------------------------
// Branch Delay Slot
//-------------------------------------------------------------
reg delay_slot_q;

always @ (posedge clk_i )
if (rst_i)
    delay_slot_q <= 1'b0;
else if (branch_request_i && !(stall_w && active_q))
    delay_slot_q <= ~branch_exception_i;
else if (branch_q && ~stall_w)
    delay_slot_q <= ~branch_excpn_q;
else if (fetch_valid_o && fetch_accept_i)
    delay_slot_q <= 1'b0;

//-------------------------------------------------------------
// Exception Delay Slot (squashed)
//-------------------------------------------------------------
reg excpn_slot_q;

always @ (posedge clk_i )
if (rst_i)
    excpn_slot_q <= 1'b0;
else if (branch_request_i && branch_exception_i && icache_busy_w)
    excpn_slot_q <= 1'b1;
else if (branch_request_i && !stall_w)
    excpn_slot_q <= branch_exception_i & active_q;
else if (branch_q && ~stall_w)
    excpn_slot_q <= branch_excpn_q;
else if (fetch_valid_w)
    excpn_slot_q <= 1'b0;

//-------------------------------------------------------------
// Outputs
//-------------------------------------------------------------
assign icache_rd_o         = active_q & fetch_accept_i & !icache_busy_w;
assign icache_pc_o         = {icache_pc_w[31:2],2'b0};
assign icache_priv_o       = icache_priv_w;
assign icache_flush_o      = fetch_invalidate_i | icache_invalidate_q;
assign icache_invalidate_o = 1'b0;

assign icache_busy_w       =  icache_fetch_q && !icache_valid_i;

//-------------------------------------------------------------
// Response Buffer (for back-pressure from the decoder)
//-------------------------------------------------------------
reg [64:0]  skid_buffer_q;
reg         skid_valid_q;

always @ (posedge clk_i )
if (rst_i)
begin
    skid_buffer_q  <= 65'b0;
    skid_valid_q   <= 1'b0;
end
// Core is back-pressuring current response, but exception comes along
else if (fetch_valid_o && !fetch_accept_i && branch_exception_i)
begin
    skid_buffer_q  <= 65'b0;
    skid_valid_q   <= 1'b0;
end
// Instruction output back-pressured - hold in skid buffer
else if (fetch_valid_o && !fetch_accept_i)
begin
    skid_valid_q  <= 1'b1;
    skid_buffer_q <= {fetch_fault_fetch_o, fetch_pc_o, fetch_instr_o};
end
else
begin
    skid_valid_q  <= 1'b0;
    skid_buffer_q <= 65'b0;
end

assign fetch_valid_w       = (icache_valid_i || skid_valid_q);

assign fetch_valid_o       = fetch_valid_w & ~excpn_slot_q;
assign fetch_pc_o          = skid_valid_q ? skid_buffer_q[63:32] : {pc_d_q[31:2],2'b0};
assign fetch_instr_o       = (skid_valid_q ? skid_buffer_q[31:0]  : icache_inst_i) & {32{~fetch_fault_fetch_o}};
assign fetch_delay_slot_o  = delay_slot_q;

// Faults (clamp instruction to NOP to avoid odd pipeline behaviour)
assign fetch_fault_fetch_o = skid_valid_q ? skid_buffer_q[64] : icache_error_i;



endmodule
