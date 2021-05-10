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
module sio
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
    ,input           sio_rx_i

    // Outputs
    ,output [ 31:0]  cfg_data_rd_o
    ,output          cfg_stall_o
    ,output          cfg_ack_o
    ,output          cfg_err_o
    ,output          irq_o
    ,output          sio_tx_o
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

// 1F801050h SIO_TX_DATA (W)
wire reg_tx_data_wr_w  = reg_write_w & (reg_addr_w == 8'h50);

// 1F801050h SIO_RX_DATA (R)
wire reg_rx_data_rd_w  = reg_read_w  & (reg_addr_w == 8'h50);

// 1F801054h SIO_STAT (R)
wire reg_stat_rd_w     = reg_read_w  & (reg_addr_w == 8'h54);

// 1F801058h SIO_MODE (R/W)
wire reg_mode_wr_w     = reg_write_w & (reg_addr_w == 8'h58) & (|cfg_sel_i[1:0]);
wire reg_mode_rd_w     = reg_read_w  & (reg_addr_w == 8'h58) & (|cfg_sel_i[1:0]);

// 1F80105Ah SIO_CTRL (R/W)
wire reg_ctrl_wr_w     = reg_write_w & (reg_addr_w == 8'h58) & (|cfg_sel_i[3:2]);
wire reg_ctrl_rd_w     = reg_read_w  & (reg_addr_w == 8'h58) & (|cfg_sel_i[3:2]);

// 1F80105Eh SIO_BAUD (R/W)
wire reg_baud_wr_w     = reg_write_w & (reg_addr_w == 8'h5c) & (|cfg_sel_i[3:2]);
wire reg_baud_rd_w     = reg_read_w  & (reg_addr_w == 8'h5c) & (|cfg_sel_i[3:2]);

//-----------------------------------------------------------------
// 1F801058h SIO_MODE (R/W)
//-----------------------------------------------------------------
reg [15:0] sio_mode_q;

always @ (posedge clk_i )
if (rst_i)
    sio_mode_q <= 16'b0;
else if (reg_mode_wr_w)
    sio_mode_q <= cfg_wr_data0_1_w;

// 0-1   Baudrate Reload Factor (1=MUL1, 2=MUL16, 3=MUL64) (or 0=STOP)
wire mode_stop_w   = (sio_mode_q[1:0] == 2'd0);
wire mode_mul1_w   = (sio_mode_q[1:0] == 2'd1);
wire mode_mul16_w  = (sio_mode_q[1:0] == 2'd2);
wire mode_mul64_w  = (sio_mode_q[1:0] == 2'd3);

// 2-3   Character Length       (0=5bits, 1=6bits, 2=7bits, 3=8bits)
// TODO: Not supported for now
wire [1:0] mode_char_w = sio_mode_q[3:2];

// 4     Parity Enable          (0=No, 1=Enable)
// TODO: Not supported for now
wire mode_parity_w  = sio_mode_q[4];

// 5     Parity Type            (0=Even, 1=Odd)
// TODO: Not supported for now
wire mode_par_t_w   = sio_mode_q[5];

// 6-7   Stop bit length        (0=Reserved/1bit, 1=1bit, 2=1.5bits, 3=2bits)
// TODO: Not supported for now
wire mode_stop1_w   = (sio_mode_q[7:6] == 2'b00 || sio_mode_q[7:6] == 2'b01);
wire mode_stop1_5_w = (sio_mode_q[7:6] == 2'b10);
wire mode_stop2_w   = (sio_mode_q[7:6] == 2'b11);

//-----------------------------------------------------------------
// 1F80105Ah SIO_CTRL (R/W)
//-----------------------------------------------------------------
reg [15:0] sio_ctrl_q;

always @ (posedge clk_i )
if (rst_i)
    sio_ctrl_q <= 16'h0005;
else if (reg_ctrl_wr_w)
    sio_ctrl_q <= cfg_wr_data2_3_w;
// Auto clear Acknowledge, Reset fields
else
    sio_ctrl_q <= sio_ctrl_q & ~((1 << 4) | (1 << 6));

// 0 TX Enable (TXEN)  (0=Disable, 1=Enable, when CTS=On)
wire ctrl_txen_w             = sio_ctrl_q[0];

// 1 DTR Output Level  (0=Off, 1=On)
wire ctrl_dtr_w              = sio_ctrl_q[1];

// 2 RX Enable (RXEN)  (0=Disable, 1=Enable)  ;Disable also clears RXFIFO
wire ctrl_rxen_w             = sio_ctrl_q[2];

// 3 TX Output Level   (0=Normal, 1=Inverted, during Inactivity & Stop bits)
wire ctrl_tx_lev_inv_w       = sio_ctrl_q[3];

// 4 Acknowledge       (0=No change, 1=Reset SIO_STAT.Bits 3,4,5,9)      (W)
wire ctrl_ack_irq_w          = sio_ctrl_q[4];

// 5 RTS Output Level  (0=Off, 1=On)
wire ctrl_rts_w              = sio_ctrl_q[5];

// 6 Reset             (0=No change, 1=Reset most SIO_registers to zero) (W)
wire ctrl_reset_w            = sio_ctrl_q[6];

// 8-9 RX Interrupt Mode    (0..3 = IRQ when RX FIFO contains 1,2,4,8 bytes)
wire [1:0] ctrl_rx_intmode_w = sio_ctrl_q[9:8];

// 10 TX Interrupt Enable  (0=Disable, 1=Enable) ;when SIO_STAT.0-or-2 ;Ready
wire ctrl_tx_int_en_w        = sio_ctrl_q[10];

// 11 RX Interrupt Enable  (0=Disable, 1=Enable) ;when N bytes in RX FIFO
wire ctrl_rx_int_en_w        = sio_ctrl_q[11];

// 12 DSR Interrupt Enable (0=Disable, 1=Enable) ;when SIO_STAT.7  ;DSR=On
wire ctrl_dsr_int_en_w       = sio_ctrl_q[12];

//-----------------------------------------------------------------
// 1F80105Eh SIO_BAUD (R/W) 
//-----------------------------------------------------------------
reg [15:0] sio_baud_q;

always @ (posedge clk_i )
if (rst_i)
    sio_baud_q <= 16'b0;
else if (reg_baud_wr_w)
    sio_baud_q <= cfg_wr_data2_3_w;

//-----------------------------------------------------------------
// Clock divider
//-----------------------------------------------------------------
reg [23:0] clk_div_r;

always @ *
begin
    clk_div_r = 24'b0;

    case (1'b1)
    mode_mul1_w:  clk_div_r = {8'b0, sio_baud_q};
    mode_mul16_w: clk_div_r = {4'b0, sio_baud_q, 4'b0};
    mode_mul64_w: clk_div_r = {2'b0, sio_baud_q, 6'b0};
    default: ;
    endcase
end

//-----------------------------------------------------------------
// Tx FIFO
//-----------------------------------------------------------------
wire       tx_valid_w;
wire [7:0] tx_data_w;
wire       tx_accept_w;
wire       tx_space_w;

sio_fifo
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

sio_fifo
#(
     .WIDTH(8)
    ,.DEPTH(8)
    ,.ADDR_W(3)
)
u_rx_fifo
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)

    ,.flush_i(ctrl_reset_w | ctrl_rxen_w)

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

sio_serial
u_serial
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)

    ,.clk_div_i(clk_div_r)

    ,.mode_char_i(mode_char_w)
    ,.mode_parity_i(mode_parity_w)
    ,.mode_parity_type_i(mode_par_t_w)
    ,.mode_stop1_i(mode_stop1_w)
    ,.mode_stop1_5_i(mode_stop1_5_w)
    ,.mode_stop2_i(mode_stop2_w)

    ,.sw_reset_i(ctrl_reset_w)
    ,.tx_enable_i(ctrl_txen_w)
    ,.rx_enable_i(ctrl_rxen_w)

    ,.tx_valid_i(tx_valid_w)
    ,.tx_data_i(tx_data_w)
    ,.tx_accept_o(tx_accept_w)

    ,.rx_valid_o(rx_push_w)
    ,.rx_data_o(rx_data_in_w)

    ,.sio_tx_o(sio_tx_o)
    ,.sio_rx_i(sio_rx_i)

    ,.busy_o(serial_busy_w)
);

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

    // 1F801050h SIO_RX_DATA (R)
    if (reg_rx_data_rd_w)
        data_rd_r = {24'b0, rx_data_out_w};

    // 1F801058h SIO_MODE (R)
    // TODO: FIFO preview mode not supported
    if (reg_mode_rd_w)
        data_rd_r[15:0] = sio_mode_q;

    // 1F80105Ah SIO_CTRL (R)
    if (reg_ctrl_rd_w)
        data_rd_r[31:16] = sio_ctrl_q;

    // 1F80105Eh SIO_BAUD (R) 
    if (reg_baud_rd_w)
        data_rd_r[31:16] = sio_baud_q;

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

        // TODO:
        // 4 RX FIFO Overrun   (0=No, 1=Error; Received more than 8 bytes) (sticky)
        // 5 RX Bad Stop Bit   (0=No, 1=Error; Bad Stop Bit) (when RXEN)   (sticky)
        // 6 RX Input Level    (0=Normal, 1=Inverted) ;only AFTER receiving Stop Bit
        // 7 DSR Input Level   (0=Off, 1=On) (remote DTR) ;DSR not required to be on
        // 8 CTS Input Level   (0=Off, 1=On) (remote RTS) ;CTS required for TX

        // 9 Interrupt Request (0=None, 1=IRQ7) (See JOY_CTRL.Bit4,10-12)   (sticky)
        data_rd_r[9] = irq_q;

        // 11-25 Baudrate Timer    (15bit timer, decrementing at 33MHz)
        data_rd_r[25:11] = 15'b0; // TODO: Not yet...
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


endmodule
