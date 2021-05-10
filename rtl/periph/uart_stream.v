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
module uart_stream
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
     parameter CLK_FREQ         = 30000000
    ,parameter BAUDRATE         = 1000000
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(
    // Inputs
     input           clk_i
    ,input           rst_i
    ,input           inport_valid_i
    ,input  [  7:0]  inport_data_i
    ,input           outport_accept_i
    ,input           rx_i

    // Outputs
    ,output          inport_accept_o
    ,output          outport_valid_o
    ,output [  7:0]  outport_data_o
    ,output          tx_o
);



//-----------------------------------------------------------------
// TX Fifo
//-----------------------------------------------------------------
wire       tx_fifo_valid_w;
wire [7:0] tx_fifo_data_w;
wire       tx_fifo_pop_w;

uart_stream_fifo
#(
     .WIDTH(8)
    ,.DEPTH(4)
    ,.ADDR_W(2)
)
u_tx_fifo
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)

    ,.push_i(inport_valid_i)
    ,.data_in_i(inport_data_i)
    ,.accept_o(inport_accept_o)

    ,.valid_o(tx_fifo_valid_w)
    ,.data_out_o(tx_fifo_data_w)
    ,.pop_i(tx_fifo_pop_w)
);

//-----------------------------------------------------------------
// RX Fifo
//-----------------------------------------------------------------
wire       rx_fifo_push_w;
wire [7:0] rx_fifo_data_w;
wire       rx_fifo_accept_w;

uart_stream_fifo
#(
     .WIDTH(8)
    ,.DEPTH(4)
    ,.ADDR_W(2)
)
u_rx_fifo
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)

    ,.push_i(rx_fifo_push_w)
    ,.data_in_i(rx_fifo_data_w)
    ,.accept_o(rx_fifo_accept_w)

    ,.valid_o(outport_valid_o)
    ,.data_out_o(outport_data_o)
    ,.pop_i(outport_accept_i)
);

//-----------------------------------------------------------------
// Registers
//-----------------------------------------------------------------

// Configuration
localparam   STOP_BITS = 1'b0; // 0 = 1, 1 = 2
localparam   BIT_DIV   = (CLK_FREQ / BAUDRATE) - 1;

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

reg          rx_err_q;

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
   rxd_ms_q <= rx_i;
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
        rx_count_q    <= {1'b0, BIT_DIV[31:1]};
    // Rx bit timer
    else if (rx_count_q != 0)
        rx_count_q    <= (rx_count_q - 1);
    // Active
    else if (rx_sample_w)
    begin
        // Last bit?
        if ((rx_bits_q == STOP_BIT0 && !STOP_BITS) || (rx_bits_q == STOP_BIT1 && STOP_BITS))
            rx_count_q    <= 32'b0;
        else
            rx_count_q    <= BIT_DIV;
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
    if (rx_bits_q == STOP_BIT0 && !STOP_BITS)
        rx_busy_q <= 1'b0;
    else if (rx_bits_q == STOP_BIT1 && STOP_BITS)
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
    if ((rx_bits_q == STOP_BIT1 && STOP_BITS) || (rx_bits_q == STOP_BIT0 && !STOP_BITS))
        rx_bits_q <= START_BIT;
    else
        rx_bits_q <= rx_bits_q + 4'd1;
end
else if (!rx_busy_q && (BIT_DIV == 32'b0))
    rx_bits_q  <= START_BIT + 4'd1;
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
   rx_err_q        <= 1'b0;
end
else
begin
   // If reading data, reset data state
   if (rx_fifo_accept_w)
   begin
       rx_ready_q <= 1'b0;
       rx_err_q   <= 1'b0;
   end

   if (rx_busy_q && rx_sample_w)
   begin
       // Stop bit
       if ((rx_bits_q == STOP_BIT1 && STOP_BITS) || (rx_bits_q == STOP_BIT0 && !STOP_BITS))
       begin
           // RXD should be still high
           if (rxd_q)
           begin
               rx_data_q      <= rx_shift_reg_q;
               rx_ready_q     <= 1'b1;
           end
           // Bad Stop bit - wait for a full bit period
           // before allowing start bit detection again
           else
           begin
               rx_ready_q      <= 1'b0;
               rx_data_q       <= 8'h00;
               rx_err_q        <= 1'b1;
           end
       end
       // Mid start bit sample - if high then error
       else if (rx_bits_q == START_BIT && rxd_q)
           rx_err_q        <= 1'b1;
   end
end

assign rx_fifo_data_w = rx_data_q;
assign rx_fifo_push_w = rx_ready_q;

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
        tx_count_q  <= BIT_DIV;
    // Tx bit timer
    else if (tx_count_q != 0)
        tx_count_q  <= (tx_count_q - 1);
    else if (tx_sample_w)
        tx_count_q  <= BIT_DIV;
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
    if (tx_bits_q == STOP_BIT0 && tx_sample_w && !STOP_BITS)
    begin
        tx_busy_q      <= 1'b0;
        tx_complete_q  <= 1'b1;
    end
    else if (tx_bits_q == STOP_BIT1 && tx_sample_w && STOP_BITS)
    begin
        tx_busy_q      <= 1'b0;
        tx_complete_q  <= 1'b1;
    end
end
// Buffer data to transmit
else if (tx_fifo_valid_w)
begin
    tx_shift_reg_q <= tx_fifo_data_w;
    tx_busy_q      <= 1'b1;
    tx_complete_q  <= 1'b0;
end
else
    tx_complete_q  <= 1'b0;

always @ (posedge clk_i )
if (rst_i)
    tx_bits_q  <= 4'd0;
else if (tx_sample_w && tx_busy_q)
begin
    if ((tx_bits_q == STOP_BIT1 && STOP_BITS) || (tx_bits_q == STOP_BIT0 && !STOP_BITS))
        tx_bits_q <= START_BIT;
    else
        tx_bits_q <= tx_bits_q + 4'd1;
end

assign tx_fifo_pop_w = ~tx_busy_q;

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

assign tx_o = txd_q;



endmodule
