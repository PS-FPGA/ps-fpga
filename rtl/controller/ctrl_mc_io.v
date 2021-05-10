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
module ctrl_mc_io
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
    ,input           joy1_dat_i
    ,input           joy1_ack_i
    ,input           joy2_dat_i
    ,input           joy2_ack_i

    // Outputs
    ,output [ 31:0]  cfg_data_rd_o
    ,output          cfg_stall_o
    ,output          cfg_ack_o
    ,output          cfg_err_o
    ,output          irq_o
    ,output          event_magic_o
    ,output          event_debug_o
    ,output          joy1_sel_o
    ,output          joy1_clk_o
    ,output          joy1_cmd_o
    ,output          joy2_sel_o
    ,output          joy2_clk_o
    ,output          joy2_cmd_o
);




//-----------------------------------------------------------------
// Bus decode helpers
//-----------------------------------------------------------------
wire [7:0] reg_addr_w  = {cfg_addr_i[7:2], 2'b0};
wire       reg_write_w = cfg_stb_i && ~cfg_stall_o &&  cfg_we_i;
wire       reg_read_w  = cfg_stb_i && ~cfg_stall_o && ~cfg_we_i;

wire [7:0]  cfg_wr_data0_w   = cfg_data_wr_i[7:0];
wire [15:0] cfg_wr_data0_1_w = cfg_data_wr_i[15:0];
wire [15:0] cfg_wr_data2_3_w = cfg_data_wr_i[31:16];

// 1F801040h JOY_TX_DATA (W)
wire reg_tx_data_wr_w  = reg_write_w & (reg_addr_w == 8'h40);

// 1F801040h JOY_RX_DATA (R)
wire reg_rx_data_rd_w  = reg_read_w  & (reg_addr_w == 8'h40);

// 1F801044h JOY_STAT (R)
wire reg_stat_rd_w     = reg_read_w  & (reg_addr_w == 8'h44);

// 1F801048h JOY_MODE (R/W)
wire reg_mode_wr_w     = reg_write_w & (reg_addr_w == 8'h48) & (|cfg_sel_i[1:0]);
wire reg_mode_rd_w     = reg_read_w  & (reg_addr_w == 8'h48) & (|cfg_sel_i[1:0]);

// 1F80104Ah JOY_CTRL (R/W)
wire reg_ctrl_wr_w     = reg_write_w & (reg_addr_w == 8'h48) & (|cfg_sel_i[3:2]);
wire reg_ctrl_rd_w     = reg_read_w  & (reg_addr_w == 8'h48) & (|cfg_sel_i[3:2]);

// 1F80104Eh JOY_BAUD (R/W)
wire reg_baud_wr_w     = reg_write_w & (reg_addr_w == 8'h4c) & (|cfg_sel_i[3:2]);
wire reg_baud_rd_w     = reg_read_w  & (reg_addr_w == 8'h4c) & (|cfg_sel_i[3:2]);

//-----------------------------------------------------------------
// 1F801048h JOY_MODE (R/W)
//-----------------------------------------------------------------
reg [15:0] joy_mode_q;

always @ (posedge clk_i )
if (rst_i)
    joy_mode_q <= 16'b0;
else if (reg_mode_wr_w)
    joy_mode_q <= cfg_wr_data0_1_w;

// 0-1   Baudrate Reload Factor (1=MUL1, 2=MUL16, 3=MUL64) (or 0=MUL1, too)
wire mode_mul0_w   = (joy_mode_q[1:0] == 2'd0);
wire mode_mul1_w   = (joy_mode_q[1:0] == 2'd1);
wire mode_mul16_w  = (joy_mode_q[1:0] == 2'd2);
wire mode_mul64_w  = (joy_mode_q[1:0] == 2'd3);

// 2-3   Character Length       (0=5bits, 1=6bits, 2=7bits, 3=8bits)
// TODO: Not supported for now
wire mode_char5_w   = (joy_mode_q[3:2] == 2'd0);
wire mode_char6_w   = (joy_mode_q[3:2] == 2'd1);
wire mode_char7_w   = (joy_mode_q[3:2] == 2'd2);
wire mode_char8_w   = (joy_mode_q[3:2] == 2'd3);

// 4     Parity Enable          (0=No, 1=Enable)
// TODO: Not supported for now
wire mode_parity_w  = joy_mode_q[4];

// 5     Parity Type            (0=Even, 1=Odd)
// TODO: Not supported for now
wire mode_par_t_w   = joy_mode_q[5];

// 8     CLK Output Polarity    (0=Normal:High=Idle, 1=Inverse:Low=Idle)
wire mode_clk_pol_w = joy_mode_q[8];

//-----------------------------------------------------------------
// 1F80104Ah JOY_CTRL (R/W)
//-----------------------------------------------------------------
reg [15:0] joy_ctrl_q;

always @ (posedge clk_i )
if (rst_i)
    joy_ctrl_q <= 16'b0;
else if (reg_ctrl_wr_w)
    joy_ctrl_q <= cfg_wr_data2_3_w;
// Auto clear Acknowledge, Reset fields
else
    joy_ctrl_q <= joy_ctrl_q & ~((1 << 4) | (1 << 6));

// 0 TX Enable (TXEN)  (0=Disable, 1=Enable)
wire ctrl_txen_w             = joy_ctrl_q[0];

// 1 /JOYn Output      (0=High, 1=Low/Select) (/JOYn as defined in Bit13)
wire ctrl_sel_w              = joy_ctrl_q[1];

// 2 RX Enable (RXEN)  (0=Normal, when /JOYn=Low, 1=Force Enable Once)
wire ctrl_rxen_w             = joy_ctrl_q[2];

// 4 Acknowledge       (0=No change, 1=Reset JOY_STAT.Bits 3,9)          (W)
wire ctrl_ack_irq_w          = joy_ctrl_q[4];

// 6 Reset             (0=No change, 1=Reset most JOY_registers to zero) (W)
wire ctrl_reset_w            = joy_ctrl_q[6];

// 8-9 RX Interrupt Mode    (0..3 = IRQ when RX FIFO contains 1,2,4,8 bytes)
wire [1:0] ctrl_rx_intmode_w = joy_ctrl_q[9:8];

// 10 TX Interrupt Enable  (0=Disable, 1=Enable) ;when JOY_STAT.0-or-2 ;Ready
wire ctrl_tx_int_en_w        = joy_ctrl_q[10];

// 11 RX Interrupt Enable  (0=Disable, 1=Enable) ;when N bytes in RX FIFO
wire ctrl_rx_int_en_w        = joy_ctrl_q[11];

// 12 ACK Interrupt Enable (0=Disable, 1=Enable) ;when JOY_STAT.7  ;/ACK=LOW
wire ctrl_ack_int_en_w       = joy_ctrl_q[12];

// 13 Desired Slot Number  (0=/JOY1, 1=/JOY2) (set to LOW when Bit1=1)
wire ctrl_slot_w             = joy_ctrl_q[13];

//-----------------------------------------------------------------
// 1F80104Eh JOY_BAUD (R/W)
//-----------------------------------------------------------------
reg [15:0] joy_baud_q;

always @ (posedge clk_i )
if (rst_i)
    joy_baud_q <= 16'b0;
else if (reg_baud_wr_w)
    joy_baud_q <= cfg_wr_data2_3_w;

//-----------------------------------------------------------------
// Clock divider
//-----------------------------------------------------------------
reg [15:0] clk_div_q;

// TODO: HACK
wire [15:0] fudge_factor_w = 16'd28;

always @ (posedge clk_i )
if (rst_i)
    clk_div_q <= 16'b0;
else if (clk_div_q == 16'd0 || reg_baud_wr_w)
begin
    // TODO: Check this...
    case (1'b1)
    mode_mul0_w:  clk_div_q <= joy_baud_q               + fudge_factor_w;
    mode_mul1_w:  clk_div_q <= {1'b0, joy_baud_q[15:1]} + fudge_factor_w;
    mode_mul16_w: clk_div_q <= {4'b0, joy_baud_q[15:4]} + fudge_factor_w;
    mode_mul64_w: clk_div_q <= {6'b0, joy_baud_q[15:6]} + fudge_factor_w;
    default: ;
    endcase
end
else
    clk_div_q <= clk_div_q - 16'd1;

wire clk_en_w = (clk_div_q == 16'd0);

//-----------------------------------------------------------------
// Tx FIFO
//-----------------------------------------------------------------
wire       tx_valid_w;
wire [7:0] tx_data_w;
wire       tx_accept_w;
wire       tx_space_w;

ctrl_mc_fifo
#(
     .WIDTH(8)
    ,.DEPTH(2)
    ,.ADDR_W(1)
)
u_tx_fifo
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)

    ,.flush_i(ctrl_reset_w)

    ,.push_i(reg_tx_data_wr_w)
    ,.data_in_i(cfg_wr_data0_w)
    ,.accept_o(tx_space_w)

    ,.valid_o(tx_valid_w)
    ,.data_out_o(tx_data_w)
    ,.pop_i(tx_accept_w)

    ,.level_o()
);

//-----------------------------------------------------------------
// Rx FIFO
//-----------------------------------------------------------------
wire       rx_push_w;
wire [7:0] rx_data_in_w;

wire       rx_valid_w;
wire [7:0] rx_data_out_w;
wire       rx_accept_w;
wire [3:0] rx_level_w;

// TODO: If the FIFO preview mode worked, this would need to change..
ctrl_mc_fifo
#(
     .WIDTH(8)
    ,.DEPTH(8)
    ,.ADDR_W(3)
)
u_rx_fifo
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)

    ,.flush_i(ctrl_reset_w)

    ,.push_i(rx_push_w)
    ,.data_in_i(rx_data_in_w)
    ,.accept_o()

    ,.valid_o(rx_valid_w)
    ,.data_out_o(rx_data_out_w)
    ,.pop_i(reg_rx_data_rd_w)

    ,.level_o(rx_level_w)
);

//-----------------------------------------------------------------
// Serial Shifter
//-----------------------------------------------------------------
wire serial_busy_w;

ctrl_mc_serial
u_serial
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)

    ,.clk_en_i(clk_en_w)

    ,.enable_i(ctrl_txen_w & tx_valid_w)
    ,.sw_reset_i(ctrl_reset_w)
    ,.select_i(ctrl_slot_w)
    ,.mode_cpol_i(mode_clk_pol_w)
    ,.rx_enable_i(ctrl_sel_w | ctrl_rxen_w)

    ,.tx_valid_i(tx_valid_w)
    ,.tx_data_i(tx_data_w)
    ,.tx_accept_o(tx_accept_w)

    ,.rx_valid_o(rx_push_w)
    ,.rx_data_o(rx_data_in_w)

    ,.joy1_clk_o(joy1_clk_o)
    ,.joy1_cmd_o(joy1_cmd_o)
    ,.joy1_dat_i(joy1_dat_i)
    ,.joy2_clk_o(joy2_clk_o)
    ,.joy2_cmd_o(joy2_cmd_o)
    ,.joy2_dat_i(joy2_dat_i)

    ,.busy_o(serial_busy_w)
);

//-----------------------------------------------------------------
// ACK resyncs
//-----------------------------------------------------------------
wire joy1_ack_w;
wire joy2_ack_w;

ctrl_mc_resync
#(
    .RESET_VAL(1'b1)
)
u_resync_ack1
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.async_i(joy1_ack_i)
    ,.sync_o(joy1_ack_w)
);

ctrl_mc_resync
#(
    .RESET_VAL(1'b1)
)
u_resync_ack2
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.async_i(joy2_ack_i)
    ,.sync_o(joy2_ack_w)
);

wire ack_input_w = ~(ctrl_slot_w ? joy2_ack_w : joy1_ack_w);

//-----------------------------------------------------------------
// Chip selects
//-----------------------------------------------------------------
// Xilinx placement pragmas:
//synthesis attribute IOB of joy1_sel_q is "TRUE"
//synthesis attribute IOB of joy2_sel_q is "TRUE"
reg joy1_sel_q;
reg joy2_sel_q;

always @ (posedge clk_i )
if (rst_i)
    joy1_sel_q <= 1'b1;
else
    joy1_sel_q <= (~ctrl_slot_w) ? ~ctrl_sel_w : 1'b1;

always @ (posedge clk_i )
if (rst_i)
    joy2_sel_q <= 1'b1;
else
    joy2_sel_q <= ctrl_slot_w    ? ~ctrl_sel_w : 1'b1;

assign joy1_sel_o = joy1_sel_q;
assign joy2_sel_o = joy2_sel_q;

//-----------------------------------------------------------------
// Interrupt
//-----------------------------------------------------------------
reg irq_q;
reg irq_r;

always @ *
begin
    irq_r = irq_q;

    // Interrupt ack
    if (ctrl_ack_irq_w)
        irq_r = 1'b0;

    // ACK Interrupt Enable (level sensitive)
    if (ctrl_ack_int_en_w && ack_input_w)
        irq_r = 1'b1;

    // TX complete (when JOY_STAT.0-or-2 Ready)
    if (ctrl_tx_int_en_w && (tx_space_w || ~serial_busy_w))
        irq_r = 1'b1;

    // RX Interrupt Enable
    if (ctrl_rx_int_en_w)
    begin
        // RX FIFO contains 1,2,4,8 bytes
        if (ctrl_rx_intmode_w == 2'd0 && rx_level_w >= 4'd1)
            irq_r = 1'b1;
        if (ctrl_rx_intmode_w == 2'd1 && rx_level_w >= 4'd2)
            irq_r = 1'b1;
        if (ctrl_rx_intmode_w == 2'd2 && rx_level_w >= 4'd4)
            irq_r = 1'b1;
        if (ctrl_rx_intmode_w == 2'd3 && rx_level_w >= 4'd8)
            irq_r = 1'b1;
    end
end

always @ (posedge clk_i )
if (rst_i)
    irq_q <= 1'b0;
else
    irq_q <= irq_r;

assign irq_o = irq_q;

//-----------------------------------------------------------------
// Read response
//-----------------------------------------------------------------
reg [31:0] data_rd_r;

always @ *
begin
    data_rd_r = 32'b0;

    // 1F801040h JOY_RX_DATA (R)
    if (reg_rx_data_rd_w)
        data_rd_r = {24'b0, rx_data_out_w};

    // 1F801048h JOY_MODE (R/W)
    if (reg_mode_rd_w)
        data_rd_r[15:0] = joy_mode_q;

    // 1F80104Ah JOY_CTRL (R/W)
    if (reg_ctrl_rd_w)
        data_rd_r[31:16] = joy_ctrl_q;

    // 1F80104Eh JOY_BAUD (R/W)
    if (reg_baud_rd_w)
        data_rd_r[31:16] = joy_baud_q;

    // 1F801044h JOY_STAT (R)
    if (reg_stat_rd_w)
    begin
        // 0 TX Ready Flag 1   (1=Ready/Started)
        // NOTE: Guessed that this means FIFO space available for Tx
        data_rd_r[0] = tx_space_w;

        // 1 RX FIFO Not Empty (0=Empty, 1=Not Empty)
        data_rd_r[1] = rx_valid_w;

        // 2 TX Ready Flag 2   (1=Ready/Finished)
        data_rd_r[2] = ~serial_busy_w;

        // 3 RX Parity Error   (0=No, 1=Error; Wrong Parity, when enabled)  (sticky)
        // TODO: Not supported

        // 7 /ACK Input Level  (0=High, 1=Low)
        data_rd_r[7] = ack_input_w;

        // 9 Interrupt Request (0=None, 1=IRQ7) (See JOY_CTRL.Bit4,10-12)   (sticky)
        data_rd_r[9] = irq_q;

        // 11-31 Baudrate Timer    (21bit timer, decrementing at 33MHz)
        data_rd_r[31:11] = {5'b0, clk_div_q};
    end
end

reg [31:0] data_rd_q;

always @ (posedge clk_i )
if (rst_i)
    data_rd_q <= 32'b0;
else
    data_rd_q <= data_rd_r;

assign cfg_data_rd_o = data_rd_q;

reg ack_q;

always @ (posedge clk_i )
if (rst_i)
    ack_q <= 1'b0;
else if (cfg_stb_i && ~cfg_stall_o)
    ack_q <= 1'b1;
else
    ack_q <= 1'b0;

assign cfg_ack_o     = ack_q;
assign cfg_stall_o   = ack_q;
assign cfg_err_o     = 1'b0;

//-----------------------------------------------------------------
// Magic combination detection
// (pressing down a load of keys to trigger some event)
// Magic: L1+L2+R1+R2+START
//-----------------------------------------------------------------
reg [2:0] magic_idx_q;

always @ (posedge clk_i )
if (rst_i)
    magic_idx_q <= 3'd0;
else if (!ctrl_sel_w)
    magic_idx_q <= 3'd0;
else if (rx_push_w)
begin
    case (magic_idx_q)
    3'd0: magic_idx_q <= 3'd1; // SOF
    3'd1: magic_idx_q <= 3'd2; // ID 
    3'd2:
    begin
        if (rx_data_in_w == 8'h5a)
            magic_idx_q <= 3'd3;
        else
            magic_idx_q <= 3'd7;
    end
    3'd3:
    begin
        if (rx_data_in_w == 8'hF7) // START
            magic_idx_q <= 3'd4;
        else if (rx_data_in_w == 8'hFE) // SELECT
            magic_idx_q <= 3'd4;
        else
            magic_idx_q <= 3'd7;
    end
    3'd4:
    begin
        if (rx_data_in_w == 8'hF0) // R1,R2,L1,L2
            magic_idx_q <= 3'd5;
        else
            magic_idx_q <= 3'd7;
    end
    3'd5: magic_idx_q <= 3'd7;
    default:
        ;
    endcase
end

reg magic_sel_q;

always @ (posedge clk_i )
if (rst_i)
    magic_sel_q <= 1'b0;
else if (!ctrl_sel_w)
    magic_sel_q <= 1'b0;
else if (rx_push_w)
begin
    case (magic_idx_q)
    3'd3: magic_sel_q <= (rx_data_in_w == 8'hFE); // SELECT
    default:
        ;
    endcase
end

reg magic_event_q;

always @ (posedge clk_i )
if (rst_i)
    magic_event_q <= 1'b0;
else
    magic_event_q <= (magic_idx_q == 3'd5) & ~magic_sel_q;

assign event_magic_o = magic_event_q;


reg magic_debug_q;

always @ (posedge clk_i )
if (rst_i)
    magic_debug_q <= 1'b0;
else
    magic_debug_q <= (magic_idx_q == 3'd5) & magic_sel_q;

assign event_debug_o = magic_debug_q;


endmodule
