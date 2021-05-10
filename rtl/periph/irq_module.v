//-----------------------------------------------------------------
// Copyright (c) 2021, admin@ultra-embedded.com
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions 
// are met:
//   - Redistributions of source code must retain the above copyright
//     notice, this list of conditions and the following disclaimer.
//   - Redistributions in binary form must reproduce the above copyright
//     notice, this list of conditions and the following disclaimer 
//     in the documentation and/or other materials provided with the 
//     distribution.
//   - Neither the name of the author nor the names of its contributors 
//     may be used to endorse or promote products derived from this 
//     software without specific prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR 
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE 
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR 
// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
// LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF 
// THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF 
// SUCH DAMAGE.
//-----------------------------------------------------------------
module irq_module
(
    // Inputs
     input           clk_i
    ,input           rst_i
    ,input  [ 31:0]  cfg_addr_i
    ,input  [ 31:0]  cfg_data_wr_i
    ,input           cfg_stb_i
    ,input           cfg_cyc_i
    ,input  [  3:0]  cfg_sel_i
    ,input           cfg_we_i
    ,input           irq0_gpu_vbl_i
    ,input           irq1_gpu_cmd_i
    ,input           irq2_cdrom_i
    ,input           irq3_dma_i
    ,input           irq4_timer0_i
    ,input           irq5_timer1_i
    ,input           irq6_timer2_i
    ,input           irq7_memcard_i
    ,input           irq8_sio_i
    ,input           irq9_spu_i
    ,input           irq10_lightpen_i

    // Outputs
    ,output [ 31:0]  cfg_data_rd_o
    ,output          cfg_stall_o
    ,output          cfg_ack_o
    ,output          cfg_err_o
    ,output [  5:0]  intr_o
);



wire       reg_write_w = cfg_stb_i && ~cfg_stall_o &&  cfg_we_i;
wire       reg_read_w  = cfg_stb_i && ~cfg_stall_o && ~cfg_we_i;
wire [3:0] reg_mask_w  = cfg_sel_i;

wire       addr1070_w = ({cfg_addr_i[7:2], 2'b0} == 8'h70);
wire       addr1074_w = ({cfg_addr_i[7:2], 2'b0} == 8'h74);

reg [10:0] irq_mask_q;
reg [10:0] irq_stat_q;

//--------------------------------------------------------------------
// Read response
//--------------------------------------------------------------------
reg [31:0] data_r;

always @ *
begin
    data_r = 32'b0;

    if (addr1074_w)
        data_r = {21'b0, irq_mask_q};
    else
        data_r = {21'b0, irq_stat_q};
end

reg [31:0] data_q;

always @ (posedge clk_i )
if (rst_i)
    data_q <= 32'b0;
else
    data_q <= data_r;

assign cfg_data_rd_o = data_q;

//--------------------------------------------------------------------
// WB ACK
//--------------------------------------------------------------------
reg ack_q;

always @ (posedge clk_i )
if (rst_i)
    ack_q <= 1'b0;
else if (cfg_stb_i && ~cfg_stall_o)
    ack_q <= 1'b1;
else
    ack_q <= 1'b0;

assign cfg_ack_o     = ack_q;
assign cfg_err_o     = 1'b0;

assign cfg_stall_o   = ack_q;

//--------------------------------------------------------------------
// Resyncs
//--------------------------------------------------------------------
wire irq0_gpu_vbl_resync_w;

resync
#(
    .RESET_VAL(1'b0)
)
u_vbl_resync
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.async_i(irq0_gpu_vbl_i)
    ,.sync_o(irq0_gpu_vbl_resync_w)
);

//--------------------------------------------------------------------
// IRQ inputs
//--------------------------------------------------------------------
wire [10:0] irq_input_w =   {   irq10_lightpen_i,
                                irq9_spu_i | irq0_gpu_vbl_resync_w, // TODO: Remove when SPU is present
                                irq8_sio_i,
                                irq7_memcard_i,
                                irq6_timer2_i,
                                irq5_timer1_i,
                                irq4_timer0_i,
                                irq3_dma_i,
                                irq2_cdrom_i,
                                irq1_gpu_cmd_i,
                                irq0_gpu_vbl_resync_w  };

reg [10:0] irq_in_prev_q;

always @ (posedge clk_i )
if (rst_i)
    irq_in_prev_q <= 11'b0;
else
    irq_in_prev_q <= irq_input_w;

//--------------------------------------------------------------------
// Edge triggered IRQ (rising edge)
//--------------------------------------------------------------------
wire [10:0] set_irq_w;

assign set_irq_w[0 ] = (!irq_in_prev_q[ 0] && irq_input_w[ 0]);
assign set_irq_w[1 ] = (!irq_in_prev_q[ 1] && irq_input_w[ 1]);
assign set_irq_w[2 ] = (!irq_in_prev_q[ 2] && irq_input_w[ 2]);
assign set_irq_w[3 ] = (!irq_in_prev_q[ 3] && irq_input_w[ 3]);
assign set_irq_w[4 ] = (!irq_in_prev_q[ 4] && irq_input_w[ 4]);
assign set_irq_w[5 ] = (!irq_in_prev_q[ 5] && irq_input_w[ 5]);
assign set_irq_w[6 ] = (!irq_in_prev_q[ 6] && irq_input_w[ 6]);
assign set_irq_w[7 ] = (!irq_in_prev_q[ 7] && irq_input_w[ 7]);
assign set_irq_w[8 ] = (!irq_in_prev_q[ 8] && irq_input_w[ 8]);
assign set_irq_w[9 ] = (!irq_in_prev_q[ 9] && irq_input_w[ 9]);
assign set_irq_w[10] = (!irq_in_prev_q[10] && irq_input_w[10]);

//--------------------------------------------------------------------
// 1F801074h I_MASK - Interrupt mask register (R/W)
//--------------------------------------------------------------------
reg [10:0] irq_mask_r;

always @ *
begin
    irq_mask_r = irq_mask_q;

    if (reg_write_w && addr1074_w && reg_mask_w[0])
        irq_mask_r[7:0] = cfg_data_wr_i[7:0];

    if (reg_write_w && addr1074_w && reg_mask_w[1])
        irq_mask_r[10:8] = cfg_data_wr_i[10:8];
end

always @ (posedge clk_i )
if (rst_i)
    irq_mask_q  <= 11'b111_1111_1111;
else
    irq_mask_q  <= irq_mask_r;

//--------------------------------------------------------------------
// 1F801070h I_STAT - Interrupt status register (R=Status, W=Acknowledge)
//--------------------------------------------------------------------
reg [10:0] irq_stat_r;

always @ *
begin
    irq_stat_r = irq_stat_q;

    // To acknowledge an interrupt, write a "0" to the corresponding bit in I_STAT
    if (reg_write_w && addr1070_w && reg_mask_w[0])
        irq_stat_r[7:0] = irq_stat_r[7:0] & cfg_data_wr_i[7:0];

    // To acknowledge an interrupt, write a "0" to the corresponding bit in I_STAT
    if (reg_write_w && addr1070_w && reg_mask_w[1])
        irq_stat_r[10:8] = irq_stat_r[10:8] & cfg_data_wr_i[10:8];

    // Priority to external IRQ hardware over CPU irq_stat_q setup.
    if (set_irq_w[0 ]) irq_stat_r[ 0] = 1'b1;
    if (set_irq_w[1 ]) irq_stat_r[ 1] = 1'b1;
    if (set_irq_w[2 ]) irq_stat_r[ 2] = 1'b1;
    if (set_irq_w[3 ]) irq_stat_r[ 3] = 1'b1;
    if (set_irq_w[4 ]) irq_stat_r[ 4] = 1'b1;
    if (set_irq_w[5 ]) irq_stat_r[ 5] = 1'b1;
    if (set_irq_w[6 ]) irq_stat_r[ 6] = 1'b1;
    if (set_irq_w[7 ]) irq_stat_r[ 7] = 1'b1;
    if (set_irq_w[8 ]) irq_stat_r[ 8] = 1'b1;
    if (set_irq_w[9 ]) irq_stat_r[ 9] = 1'b1;
    if (set_irq_w[10]) irq_stat_r[10] = 1'b1;
end

always @ (posedge clk_i )
if (rst_i)
    irq_stat_q  <= 11'b000_0000_0000;
else
    irq_stat_q  <= irq_stat_r;

// Send only FLAG to the CPU => Warns of NEW IRQ only.
assign intr_o = {5'b0, |(irq_stat_q & irq_mask_q)};

//--------------------------------------------------------------------
// Debug
//--------------------------------------------------------------------
`ifdef verilator
reg [31:0] dbg_cycle_q;

always @ (posedge clk_i )
if (rst_i)
    dbg_cycle_q <= 32'b0;
else
    dbg_cycle_q <= dbg_cycle_q + 32'd1;

reg dbg_irq_q;

always @ (posedge clk_i )
begin
    if (set_irq_w[0 ]) $display("IO interrupt SRC=gpu_vbl @ %0d", dbg_cycle_q);
    if (set_irq_w[1 ]) $display("IO interrupt SRC=gpu_cmd @ %0d", dbg_cycle_q);
    if (set_irq_w[2 ]) $display("IO interrupt SRC=cdrom @ %0d", dbg_cycle_q);
    if (set_irq_w[3 ]) $display("IO interrupt SRC=dma @ %0d", dbg_cycle_q);
    if (set_irq_w[4 ]) $display("IO interrupt SRC=timer0 @ %0d", dbg_cycle_q);
    if (set_irq_w[5 ]) $display("IO interrupt SRC=timer1 @ %0d", dbg_cycle_q);
    if (set_irq_w[6 ]) $display("IO interrupt SRC=timer2 @ %0d", dbg_cycle_q);
    if (set_irq_w[7 ]) $display("IO interrupt SRC=joy/mem @ %0d", dbg_cycle_q);
    if (set_irq_w[8 ]) $display("IO interrupt SRC=sio @ %0d", dbg_cycle_q);
    if (set_irq_w[9 ]) $display("IO interrupt SRC=spu @ %0d", dbg_cycle_q);
    if (set_irq_w[10]) $display("IO interrupt SRC=lightpen @ %0d", dbg_cycle_q);

    if (intr_o[0] && ~dbg_irq_q)
        $display("IO CPU interrupt asserted: %08x @ %0d", (irq_stat_q & irq_mask_q), dbg_cycle_q);
    else if (~intr_o[0] && dbg_irq_q)
        $display("IO CPU interrupt deasserted: %08x @ %0d", (irq_stat_q & irq_mask_q), dbg_cycle_q);

    dbg_irq_q  <= intr_o[0];
end

function [0:0] get_intr; /*verilator public*/
begin
    get_intr = intr_o[0];
end
endfunction

`endif

endmodule
