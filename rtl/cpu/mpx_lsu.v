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
module mpx_lsu
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
     parameter MEM_CACHE_ADDR_MIN = 32'h80000000
    ,parameter MEM_CACHE_ADDR_MAX = 32'h8fffffff
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
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
    ,input  [ 31:0]  opcode_rt_operand_m_i
    ,input  [ 31:0]  mem_data_rd_i
    ,input           mem_accept_i
    ,input           mem_ack_i
    ,input           mem_error_i
    ,input  [ 10:0]  mem_resp_tag_i

    // Outputs
    ,output [ 31:0]  mem_addr_o
    ,output [ 31:0]  mem_data_wr_o
    ,output          mem_rd_o
    ,output [  3:0]  mem_wr_o
    ,output          mem_cacheable_o
    ,output [ 10:0]  mem_req_tag_o
    ,output          mem_invalidate_o
    ,output          mem_writeback_o
    ,output          mem_flush_o
    ,output          writeback_valid_o
    ,output [ 31:0]  writeback_value_o
    ,output [  5:0]  writeback_exception_o
    ,output          stall_o
);



//-----------------------------------------------------------------
// Includes
//-----------------------------------------------------------------
`include "mpx_defs.v"

//-----------------------------------------------------------------
// Registers / Wires
//-----------------------------------------------------------------
reg [ 31:0]  mem_addr_q;
reg [ 31:0]  mem_data_wr_q;
reg          mem_rd_q;
reg [  3:0]  mem_wr_q;
reg          mem_cacheable_q;
reg          mem_invalidate_q;
reg          mem_writeback_q;
reg          mem_flush_q;
reg          mem_unaligned_x_q;
reg          mem_unaligned_m_q;

reg          mem_load_q;
reg          mem_xb_q;
reg          mem_xh_q;
reg          mem_ls_q;
reg          mem_xwl_q;
reg          mem_xwr_q;

//-----------------------------------------------------------------
// Outstanding Access Tracking
//-----------------------------------------------------------------
reg pending_lsu_m_q;

wire issue_lsu_x_w    = (mem_rd_o || (|mem_wr_o) || mem_writeback_o || mem_invalidate_o || mem_flush_o) && mem_accept_i;
wire complete_ok_m_w  = mem_ack_i & ~mem_error_i;
wire complete_err_m_w = mem_ack_i & mem_error_i;

always @ (posedge clk_i )
if (rst_i)
    pending_lsu_m_q <= 1'b0;
else if (issue_lsu_x_w)
    pending_lsu_m_q <= 1'b1;
else if (complete_ok_m_w || complete_err_m_w)
    pending_lsu_m_q <= 1'b0;

// Delay next instruction if outstanding response is late
wire delay_lsu_m_w = pending_lsu_m_q && !complete_ok_m_w;

//-----------------------------------------------------------------
// Dummy Ack (unaligned access / M - stage)
//-----------------------------------------------------------------
always @ (posedge clk_i )
if (rst_i)
    mem_unaligned_m_q <= 1'b0;
else
    mem_unaligned_m_q <= mem_unaligned_x_q & ~delay_lsu_m_w;

//-----------------------------------------------------------------
// Opcode decode
//-----------------------------------------------------------------
wire inst_lb_w  = (opcode_opcode_i[`OPCODE_INST_R] == `INSTR_I_LB);
wire inst_lh_w  = (opcode_opcode_i[`OPCODE_INST_R] == `INSTR_I_LH);
wire inst_lw_w  = (opcode_opcode_i[`OPCODE_INST_R] == `INSTR_I_LW   || 
                   opcode_opcode_i[`OPCODE_INST_R] == `INSTR_I_LWC0 ||
                   opcode_opcode_i[`OPCODE_INST_R] == `INSTR_I_LWC1 ||
                   opcode_opcode_i[`OPCODE_INST_R] == `INSTR_I_LWC2 ||
                   opcode_opcode_i[`OPCODE_INST_R] == `INSTR_I_LWC3);
wire inst_lbu_w = (opcode_opcode_i[`OPCODE_INST_R] == `INSTR_I_LBU);
wire inst_lhu_w = (opcode_opcode_i[`OPCODE_INST_R] == `INSTR_I_LHU);
wire inst_lwl_w = (opcode_opcode_i[`OPCODE_INST_R] == `INSTR_I_LWL);
wire inst_lwr_w = (opcode_opcode_i[`OPCODE_INST_R] == `INSTR_I_LWR);

wire inst_sb_w  = (opcode_opcode_i[`OPCODE_INST_R] == `INSTR_I_SB);
wire inst_sh_w  = (opcode_opcode_i[`OPCODE_INST_R] == `INSTR_I_SH);
wire inst_sw_w  = (opcode_opcode_i[`OPCODE_INST_R] == `INSTR_I_SW   || 
                   opcode_opcode_i[`OPCODE_INST_R] == `INSTR_I_SWC0 ||
                   opcode_opcode_i[`OPCODE_INST_R] == `INSTR_I_SWC1 ||
                   opcode_opcode_i[`OPCODE_INST_R] == `INSTR_I_SWC2 ||
                   opcode_opcode_i[`OPCODE_INST_R] == `INSTR_I_SWC3);
wire inst_swl_w = (opcode_opcode_i[`OPCODE_INST_R] == `INSTR_I_SWL);
wire inst_swr_w = (opcode_opcode_i[`OPCODE_INST_R] == `INSTR_I_SWR);

wire load_inst_w =  inst_lb_w  ||
                    inst_lh_w  ||
                    inst_lw_w  ||
                    inst_lbu_w ||
                    inst_lhu_w ||
                    inst_lwl_w ||
                    inst_lwr_w;

wire load_signed_inst_w = inst_lb_w  ||
                          inst_lh_w  ||
                          inst_lw_w;

wire store_inst_w = inst_sb_w  ||
                    inst_sh_w  ||
                    inst_sw_w  ||
                    inst_swl_w ||
                    inst_swr_w;

wire req_lb_w = inst_lb_w || inst_lbu_w;
wire req_lh_w = inst_lh_w || inst_lhu_w;
wire req_sb_w = inst_sb_w;
wire req_sh_w = inst_sh_w;
wire req_sw_w = inst_sw_w;

wire req_sw_lw_w = inst_lw_w | req_sw_w;
wire req_sh_lh_w = req_lh_w | req_sh_w;

wire [15:0] imm_w    = opcode_opcode_i[`OPCODE_IMM_R];
wire [31:0] s_imm_w  = {{16{imm_w[15]}}, imm_w};

reg [31:0]  mem_addr_r;
reg         mem_unaligned_r;
reg [31:0]  mem_data_r;
reg         mem_rd_r;
reg [3:0]   mem_wr_r;

always @ *
begin
    mem_addr_r      = opcode_rs_operand_i + s_imm_w;
    mem_data_r      = 32'b0;
    mem_unaligned_r = 1'b0;
    mem_wr_r        = 4'b0;
    mem_rd_r        = 1'b0;

    if (opcode_valid_i && (inst_lwl_w || inst_lwr_w))
        mem_unaligned_r = 1'b0;
    else if (opcode_valid_i && (inst_swl_w || inst_swr_w))
        mem_unaligned_r = 1'b0;
    else if (opcode_valid_i && req_sw_lw_w)
        mem_unaligned_r = (mem_addr_r[1:0] != 2'b0);
    else if (opcode_valid_i && req_sh_lh_w)
        mem_unaligned_r = mem_addr_r[0];

    mem_rd_r = (opcode_valid_i && load_inst_w && !mem_unaligned_r);

    // SWL
    if (opcode_valid_i && inst_swl_w)
    begin
        case (mem_addr_r[1:0])
        2'h0 :
        begin
            mem_data_r  = {24'b0, opcode_rt_operand_i[31:24]};
            mem_wr_r    = 4'b0001;
        end
        2'h1 :
        begin
            mem_data_r  = {16'b0, opcode_rt_operand_i[31:16]};
            mem_wr_r    = 4'b0011;
        end
        2'h2 :
        begin
            mem_data_r  = {8'b0, opcode_rt_operand_i[31:8]};
            mem_wr_r    = 4'b0111;
        end
        default :
        begin
            mem_data_r  = opcode_rt_operand_i;
            mem_wr_r    = 4'b1111;
        end
        endcase
    end
    // SWR
    else if (opcode_valid_i && inst_swr_w)
    begin
        case (mem_addr_r[1:0])
        2'h0 :
        begin
            mem_data_r  = opcode_rt_operand_i;
            mem_wr_r    = 4'b1111;
        end
        2'h1 :
        begin
            mem_data_r  = {opcode_rt_operand_i[23:0],8'b0};
            mem_wr_r    = 4'b1110;
        end
        2'h2 :
        begin
            mem_data_r  = {opcode_rt_operand_i[15:0],16'b0};
            mem_wr_r    = 4'b1100;
        end
        default :
        begin
            mem_data_r  = {opcode_rt_operand_i[7:0],24'b0};
            mem_wr_r    = 4'b1000;
        end
        endcase
    end
    // SW
    else if (opcode_valid_i && req_sw_w && !mem_unaligned_r)
    begin
        mem_data_r  = opcode_rt_operand_i;
        mem_wr_r    = 4'hF;
    end
    // SH
    else if (opcode_valid_i && req_sh_w && !mem_unaligned_r)
    begin
        case (mem_addr_r[1:0])
        2'h2 :
        begin
            mem_data_r  = {opcode_rt_operand_i[15:0],16'h0000};
            mem_wr_r    = 4'b1100;
        end
        default :
        begin
            mem_data_r  = {16'h0000,opcode_rt_operand_i[15:0]};
            mem_wr_r    = 4'b0011;
        end
        endcase
    end
    // SB
    else if (opcode_valid_i && req_sb_w)
    begin
        case (mem_addr_r[1:0])
        2'h3 :
        begin
            mem_data_r  = {opcode_rt_operand_i[7:0],24'h000000};
            mem_wr_r    = 4'b1000;
        end
        2'h2 :
        begin
            mem_data_r  = {{8'h00,opcode_rt_operand_i[7:0]},16'h0000};
            mem_wr_r    = 4'b0100;
        end
        2'h1 :
        begin
            mem_data_r  = {{16'h0000,opcode_rt_operand_i[7:0]},8'h00};
            mem_wr_r    = 4'b0010;
        end
        2'h0 :
        begin
            mem_data_r  = {24'h000000,opcode_rt_operand_i[7:0]};
            mem_wr_r    = 4'b0001;
        end
        default :
            ;
        endcase
    end
    else
        mem_wr_r    = 4'b0;
end

//-----------------------------------------------------------------
// HACK: Cacheable address decoder
//-----------------------------------------------------------------
/*
  KUSEG(000) KSEG0(100) KSEG1(101)
  00000000h 80000000h A0000000h  2048K  Main RAM (first 64K reserved for BIOS)
  1F000000h 9F000000h BF000000h  8192K  Expansion Region 1 (ROM/RAM)
  1F800000h 9F800000h    --      1K     Scratchpad (D-Cache used as Fast RAM)
  1F801000h 9F801000h BF801000h  8K     I/O Ports
  1F802000h 9F802000h BF802000h  8K     Expansion Region 2 (I/O Ports)
  1FA00000h 9FA00000h BFA00000h  2048K  Expansion Region 3 (SRAM BIOS region for DTL cards)
  1FC00000h 9FC00000h BFC00000h  512K   BIOS ROM (Kernel) (4096K max)
        FFFE0000h (KSEG2)        0.5K   I/O Ports (Cache Control)

  Address   Name   i-Cache     Write-Queue
  00000000h KUSEG  Yes         Yes
  80000000h KSEG0  Yes         Yes
  A0000000h KSEG1  No          No
*/
localparam SEG_KUSEG = 3'b000;
localparam SEG_KSEG0 = 3'b100;
localparam SEG_KSEG1 = 3'b101;

wire [2:0]  segment_w     = mem_addr_r[31:29];
wire [31:0] addr_no_seg_w = {3'b0, mem_addr_r[28:0]};

reg cacheable_r;

always @ *
begin
    cacheable_r   = 1'b0;

    // KSEG1 is not cacheable - but make an exception for the bootROM (TMP: boot speed)
    if (segment_w == SEG_KSEG1)
        cacheable_r = (mem_addr_r[31:20] == 12'hBFC);
    // KUSEG / KSEG0
    // Main RAM or Scratchpad
    else
        cacheable_r = (addr_no_seg_w[31:12] == 20'h1F800); //| (addr_no_seg_w[31:20] == 12'h000);
end

//-----------------------------------------------------------------
// Sequential
//-----------------------------------------------------------------
always @ (posedge clk_i )
if (rst_i)
begin
    mem_addr_q         <= 32'b0;
    mem_data_wr_q      <= 32'b0;
    mem_rd_q           <= 1'b0;
    mem_wr_q           <= 4'b0;
    mem_cacheable_q    <= 1'b0;
    mem_flush_q        <= 1'b0;
    mem_unaligned_x_q  <= 1'b0;
    mem_load_q         <= 1'b0;
    mem_xb_q           <= 1'b0;
    mem_xh_q           <= 1'b0;
    mem_ls_q           <= 1'b0;
    mem_xwl_q          <= 1'b0;
    mem_xwr_q          <= 1'b0;
end
// Memory access fault - squash next operation (exception coming...)
else if (complete_err_m_w || mem_unaligned_m_q)
begin
    mem_addr_q         <= 32'b0;
    mem_data_wr_q      <= 32'b0;
    mem_rd_q           <= 1'b0;
    mem_wr_q           <= 4'b0;
    mem_cacheable_q    <= 1'b0;
    mem_flush_q        <= 1'b0;
    mem_unaligned_x_q  <= 1'b0;
    mem_load_q         <= 1'b0;
    mem_xb_q           <= 1'b0;
    mem_xh_q           <= 1'b0;
    mem_ls_q           <= 1'b0;
    mem_xwl_q          <= 1'b0;
    mem_xwr_q          <= 1'b0;    
end
else if ((mem_rd_q || (|mem_wr_q) || mem_unaligned_x_q) && delay_lsu_m_w)
    ;
else if (!((mem_writeback_o || mem_invalidate_o || mem_flush_o || mem_rd_o || mem_wr_o != 4'b0) && !mem_accept_i))
begin
    mem_addr_q         <= mem_addr_r;
    mem_data_wr_q      <= mem_data_r;
    mem_rd_q           <= mem_rd_r;
    mem_wr_q           <= mem_wr_r;
    mem_unaligned_x_q  <= mem_unaligned_r;
    mem_load_q         <= opcode_valid_i && load_inst_w;
    mem_xb_q           <= req_lb_w | req_sb_w;
    mem_xh_q           <= req_lh_w | req_sh_w;
    mem_ls_q           <= load_signed_inst_w;
    mem_xwl_q          <= inst_lwl_w | inst_swl_w;
    mem_xwr_q          <= inst_lwr_w | inst_swr_w;
    mem_cacheable_q    <= cacheable_r;
    mem_flush_q        <= 1'b0;
end

assign mem_addr_o       = mem_addr_q;
assign mem_data_wr_o    = mem_data_wr_q;
assign mem_rd_o         = mem_rd_q & ~delay_lsu_m_w;
assign mem_wr_o         = mem_wr_q & ~{4{delay_lsu_m_w}};
assign mem_cacheable_o  = mem_cacheable_q;
assign mem_req_tag_o    = {9'b0, mem_xh_q, mem_xb_q};
assign mem_invalidate_o = 1'b0;
assign mem_writeback_o  = 1'b0;
assign mem_flush_o      = mem_flush_q;

// Stall upstream if cache is busy
assign stall_o          = ((mem_writeback_o || mem_invalidate_o || mem_flush_o || mem_rd_o || mem_wr_o != 4'b0) && !mem_accept_i) || delay_lsu_m_w || mem_unaligned_x_q;

wire        resp_load_w;
wire [31:0] resp_addr_w;
wire        resp_byte_w;
wire        resp_half_w;
wire        resp_signed_w;
wire        resp_xwl_w;
wire        resp_xwr_w;

mpx_lsu_fifo
#(
     .WIDTH(38)
    ,.DEPTH(2)
    ,.ADDR_W(1)
)
u_lsu_request
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)

    ,.push_i(((mem_rd_o || (|mem_wr_o) || mem_writeback_o || mem_invalidate_o || mem_flush_o) && mem_accept_i) || (mem_unaligned_x_q && ~delay_lsu_m_w))
    ,.data_in_i({mem_addr_q, mem_xwl_q, mem_xwr_q, mem_ls_q, mem_xh_q, mem_xb_q, mem_load_q})
    ,.accept_o()

    ,.valid_o()
    ,.data_out_o({resp_addr_w, resp_xwl_w, resp_xwr_w, resp_signed_w, resp_half_w, resp_byte_w, resp_load_w})
    ,.pop_i(mem_ack_i || mem_unaligned_m_q)
);

//-----------------------------------------------------------------
// Load response
//-----------------------------------------------------------------
reg [1:0]  addr_lsb_r;
reg        load_byte_r;
reg        load_half_r;
reg        load_signed_r;
reg [31:0] wb_result_r;

always @ *
begin
    wb_result_r   = 32'b0;

    // Tag associated with load
    addr_lsb_r    = resp_addr_w[1:0];
    load_byte_r   = resp_byte_w;
    load_half_r   = resp_half_w;
    load_signed_r = resp_signed_w;

    // Access fault - pass badaddr on writeback result bus
    if ((mem_ack_i && mem_error_i) || mem_unaligned_m_q)
        wb_result_r = resp_addr_w;
    // Handle responses
    else if (mem_ack_i && resp_load_w)
    begin
        // LWL
        if (resp_xwl_w)
        begin
            case (addr_lsb_r[1:0])
            2'h0: wb_result_r = {mem_data_rd_i[7:0],  opcode_rt_operand_m_i[23:0]};
            2'h1: wb_result_r = {mem_data_rd_i[15:0], opcode_rt_operand_m_i[15:0]};
            2'h2: wb_result_r = {mem_data_rd_i[23:0], opcode_rt_operand_m_i[7:0]};
            2'h3: wb_result_r = mem_data_rd_i;
            endcase
        end
        // LWR
        else if (resp_xwr_w)
        begin
            case (addr_lsb_r[1:0])
            2'h0: wb_result_r = mem_data_rd_i;
            2'h1: wb_result_r = {opcode_rt_operand_m_i[31:24], mem_data_rd_i[31:8]};
            2'h2: wb_result_r = {opcode_rt_operand_m_i[31:16], mem_data_rd_i[31:16]};
            2'h3: wb_result_r = {opcode_rt_operand_m_i[31:8],  mem_data_rd_i[31:24]};
            endcase
        end
        else if (load_byte_r)
        begin
            case (addr_lsb_r[1:0])
            2'h3: wb_result_r = {24'b0, mem_data_rd_i[31:24]};
            2'h2: wb_result_r = {24'b0, mem_data_rd_i[23:16]};
            2'h1: wb_result_r = {24'b0, mem_data_rd_i[15:8]};
            2'h0: wb_result_r = {24'b0, mem_data_rd_i[7:0]};
            endcase

            if (load_signed_r && wb_result_r[7])
                wb_result_r = {24'hFFFFFF, wb_result_r[7:0]};
        end
        else if (load_half_r)
        begin
            if (addr_lsb_r[1])
                wb_result_r = {16'b0, mem_data_rd_i[31:16]};
            else
                wb_result_r = {16'b0, mem_data_rd_i[15:0]};

            if (load_signed_r && wb_result_r[15])
                wb_result_r = {16'hFFFF, wb_result_r[15:0]};
        end
        else
            wb_result_r = mem_data_rd_i;
    end
end

assign writeback_valid_o    = mem_ack_i | mem_unaligned_m_q;
assign writeback_value_o    = wb_result_r;

wire fault_load_align_w     = mem_unaligned_m_q & resp_load_w;
wire fault_store_align_w    = mem_unaligned_m_q & ~resp_load_w;

assign writeback_exception_o         = fault_load_align_w  ? `EXCEPTION_ADEL:
                                       fault_store_align_w ? `EXCEPTION_ADES:
                                       mem_error_i         ? `EXCEPTION_DBE:
                                                             `EXCEPTION_W'b0;

//-----------------------------------------------------------------
// Simulation Only
//-----------------------------------------------------------------
`ifdef verilator
reg [31:0] stats_lsu_stalls_q;

always @ (posedge clk_i )
if (rst_i)
    stats_lsu_stalls_q   <= 32'b0;
else if (stall_o)
    stats_lsu_stalls_q   <= stats_lsu_stalls_q + 32'd1;
`endif

endmodule 

module mpx_lsu_fifo
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
    parameter WIDTH   = 8,
    parameter DEPTH   = 4,
    parameter ADDR_W  = 2
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(
    // Inputs
     input               clk_i
    ,input               rst_i
    ,input  [WIDTH-1:0]  data_in_i
    ,input               push_i
    ,input               pop_i

    // Outputs
    ,output [WIDTH-1:0]  data_out_o
    ,output              accept_o
    ,output              valid_o
);

//-----------------------------------------------------------------
// Local Params
//-----------------------------------------------------------------
localparam COUNT_W = ADDR_W + 1;

//-----------------------------------------------------------------
// Registers
//-----------------------------------------------------------------
reg [WIDTH-1:0]   ram_q[DEPTH-1:0];
reg [ADDR_W-1:0]  rd_ptr_q;
reg [ADDR_W-1:0]  wr_ptr_q;
reg [COUNT_W-1:0] count_q;

integer i;

//-----------------------------------------------------------------
// Sequential
//-----------------------------------------------------------------
always @ (posedge clk_i )
if (rst_i)
begin
    count_q   <= {(COUNT_W) {1'b0}};
    rd_ptr_q  <= {(ADDR_W) {1'b0}};
    wr_ptr_q  <= {(ADDR_W) {1'b0}};

    for (i=0;i<DEPTH;i=i+1)
    begin
        ram_q[i] <= {(WIDTH) {1'b0}};
    end
end
else
begin
    // Push
    if (push_i & accept_o)
    begin
        ram_q[wr_ptr_q] <= data_in_i;
        wr_ptr_q        <= wr_ptr_q + 1;
    end

    // Pop
    if (pop_i & valid_o)
        rd_ptr_q      <= rd_ptr_q + 1;

    // Count up
    if ((push_i & accept_o) & ~(pop_i & valid_o))
        count_q <= count_q + 1;
    // Count down
    else if (~(push_i & accept_o) & (pop_i & valid_o))
        count_q <= count_q - 1;
end

//-------------------------------------------------------------------
// Combinatorial
//-------------------------------------------------------------------
/* verilator lint_off WIDTH */
assign valid_o       = (count_q != 0);
assign accept_o      = (count_q != DEPTH);
/* verilator lint_on WIDTH */

assign data_out_o    = ram_q[rd_ptr_q];



endmodule
