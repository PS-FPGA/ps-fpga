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
module sio_serial
(
     input              clk_i
    ,input              rst_i

    ,input [23:0]       clk_div_i

    ,input [1:0]        mode_char_i
    ,input              mode_parity_i
    ,input              mode_parity_type_i
    ,input              mode_stop1_i
    ,input              mode_stop1_5_i
    ,input              mode_stop2_i

    ,input              sw_reset_i
    ,input              tx_enable_i
    ,input              rx_enable_i

    ,input              tx_valid_i
    ,input [7:0]        tx_data_i
    ,output             tx_accept_o

    ,output             rx_valid_o
    ,output [7:0]       rx_data_o

    ,output             sio_tx_o
    ,input              sio_rx_i

    ,output             busy_o
);

// TODO: character width
// TODO: parity
// TODO: 1.5 stop bits

localparam   START_BIT = 4'd0;
localparam   STOP_BIT0 = 4'd9;
localparam   STOP_BIT1 = 4'd10;

// Xilinx placement pragmas:
//synthesis attribute IOB of txd_q is "TRUE"

// TX Signals
reg          tx_busy_q;
reg [3:0]    tx_bits_q;
reg [31:0]   tx_count_q;
reg [7:0]    tx_shift_reg_q;
reg          txd_q;

// RX Signals
reg          rxd_q;
reg [7:0]    rx_data_q;
reg [3:0]    rx_bits_q;
reg [31:0]   rx_count_q;
reg [7:0]    rx_shift_reg_q;
reg          rx_ready_q;
reg          rx_busy_q;

//-----------------------------------------------------------------
// Re-sync RXD
//-----------------------------------------------------------------
reg rxd_ms_q;

always @ (posedge clk_i )
if (rst_i)
begin
   rxd_ms_q <= 1'b1;
   rxd_q    <= 1'b1;
end
else
begin
   rxd_ms_q <= sio_rx_i;
   rxd_q    <= rxd_ms_q;
end

//-----------------------------------------------------------------
// RX Clock Divider
//-----------------------------------------------------------------
wire rx_sample_w = (rx_count_q == 32'b0);

always @ (posedge clk_i )
if (rst_i)
    rx_count_q        <= 32'b0;
else
begin
    // Inactive
    if (!rx_busy_q)
        rx_count_q    <= {9'b0, clk_div_i[23:1]};
    // Rx bit timer
    else if (rx_count_q != 0)
        rx_count_q    <= (rx_count_q - 1);
    // Active
    else if (rx_sample_w)
    begin
        // Last bit?
        if ((rx_bits_q == STOP_BIT0 && mode_stop1_i) || (rx_bits_q == STOP_BIT1 && mode_stop2_i))
            rx_count_q    <= 32'b0;
        else
            rx_count_q    <= {8'b0, clk_div_i};
    end
end

//-----------------------------------------------------------------
// RX Shift Register
//-----------------------------------------------------------------
always @ (posedge clk_i )
if (rst_i)
begin
    rx_shift_reg_q <= 8'h00;
    rx_busy_q      <= 1'b0;
end
// Rx busy
else if (rx_busy_q && rx_sample_w)
begin
    // Last bit?
    if (rx_bits_q == STOP_BIT0 && mode_stop1_i)
        rx_busy_q <= 1'b0;
    else if (rx_bits_q == STOP_BIT1 && mode_stop2_i)
        rx_busy_q <= 1'b0;
    else if (rx_bits_q == START_BIT)
    begin
        // Start bit should still be low as sampling mid
        // way through start bit, so if high, error!
        if (rxd_q)
            rx_busy_q <= 1'b0;
    end
    // Rx shift register
    else 
        rx_shift_reg_q <= {rxd_q, rx_shift_reg_q[7:1]};
end
// Start bit?
else if (!rx_busy_q && rxd_q == 1'b0)
begin
    rx_shift_reg_q <= 8'h00;
    rx_busy_q      <= 1'b1;
end

always @ (posedge clk_i )
if (rst_i)
    rx_bits_q  <= START_BIT;
else if (rx_sample_w && rx_busy_q)
begin
    if ((rx_bits_q == STOP_BIT1 && mode_stop2_i) || (rx_bits_q == STOP_BIT0 && mode_stop1_i))
        rx_bits_q <= START_BIT;
    else
        rx_bits_q <= rx_bits_q + 4'd1;
end
else if (!rx_busy_q)
    rx_bits_q  <= START_BIT;

//-----------------------------------------------------------------
// RX Data
//-----------------------------------------------------------------
always @ (posedge clk_i )
if (rst_i)
begin
   rx_ready_q      <= 1'b0;
   rx_data_q       <= 8'h00;
end
else
begin
   rx_ready_q      <= 1'b0;

   if (rx_busy_q && rx_sample_w)
   begin
       // Stop bit
       if ((rx_bits_q == STOP_BIT1 && mode_stop2_i) || (rx_bits_q == STOP_BIT0 && mode_stop1_i))
       begin
           // RXD should be still high
           if (rxd_q)
           begin
               rx_data_q      <= rx_shift_reg_q;
               rx_ready_q     <= rx_enable_i;
           end
           // Bad Stop bit - wait for a full bit period
           // before allowing start bit detection again
           else
           begin
               rx_ready_q      <= 1'b0;
               rx_data_q       <= 8'h00;
           end
       end
   end
end

assign rx_valid_o = rx_ready_q;
assign rx_data_o  = rx_data_q;

//-----------------------------------------------------------------
// TX Clock Divider
//-----------------------------------------------------------------
wire tx_sample_w = (tx_count_q == 32'b0);

always @ (posedge clk_i )
if (rst_i)
    tx_count_q      <= 32'b0;
else
begin
    // Idle
    if (!tx_busy_q)
        tx_count_q  <= {8'b0, clk_div_i};
    // Tx bit timer
    else if (tx_count_q != 0)
        tx_count_q  <= (tx_count_q - 1);
    else if (tx_sample_w)
        tx_count_q  <= {8'b0, clk_div_i};
end

//-----------------------------------------------------------------
// TX Shift Register
//-----------------------------------------------------------------
reg tx_complete_q;

always @ (posedge clk_i )
if (rst_i)
begin
    tx_shift_reg_q <= 8'h00;
    tx_busy_q      <= 1'b0;
    tx_complete_q  <= 1'b0;
end
// Tx busy
else if (tx_busy_q)
begin
    // Shift tx data
    if (tx_bits_q != START_BIT && tx_sample_w)
        tx_shift_reg_q <= {1'b0, tx_shift_reg_q[7:1]};

    // Last bit?
    if (tx_bits_q == STOP_BIT0 && tx_sample_w && mode_stop1_i)
    begin
        tx_busy_q      <= 1'b0;
        tx_complete_q  <= 1'b1;
    end
    else if (tx_bits_q == STOP_BIT1 && tx_sample_w && mode_stop2_i)
    begin
        tx_busy_q      <= 1'b0;
        tx_complete_q  <= 1'b1;
    end
end
else if (tx_valid_i && tx_enable_i && tx_accept_o)
begin
    tx_shift_reg_q <= tx_data_i;
    tx_busy_q      <= 1'b1;
    tx_complete_q  <= 1'b0;
end
else
    tx_complete_q  <= 1'b0;

assign tx_accept_o = tx_enable_i & ~tx_busy_q;

always @ (posedge clk_i )
if (rst_i)
    tx_bits_q  <= 4'd0;
else if (tx_sample_w && tx_busy_q)
begin
    if ((tx_bits_q == STOP_BIT1 && mode_stop2_i) || (tx_bits_q == STOP_BIT0 && mode_stop1_i))
        tx_bits_q <= START_BIT;
    else
        tx_bits_q <= tx_bits_q + 4'd1;
end

//-----------------------------------------------------------------
// UART Tx Pin
//-----------------------------------------------------------------
reg txd_r;

always @ *
begin
    txd_r = 1'b1;

    if (tx_busy_q)
    begin
        // Start bit (TXD = L)
        if (tx_bits_q == START_BIT)
            txd_r = 1'b0;
        // Stop bits (TXD = H)
        else if (tx_bits_q == STOP_BIT0 || tx_bits_q == STOP_BIT1)
            txd_r = 1'b1;
        // Data bits
        else
            txd_r = tx_shift_reg_q[0];
    end
end

always @ (posedge clk_i )
if (rst_i)
    txd_q <= 1'b1;
else
    txd_q <= txd_r;

assign sio_tx_o = txd_q;

assign busy_o   = tx_busy_q;

endmodule