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
module ctrl_mc_serial
(
     input              clk_i
    ,input              rst_i

    ,input              clk_en_i

    ,input              enable_i
    ,input              sw_reset_i
    ,input              select_i
    ,input              rx_enable_i
    ,input              mode_cpol_i

    ,input              tx_valid_i
    ,input [7:0]        tx_data_i
    ,output             tx_accept_o

    ,output             rx_valid_o
    ,output [7:0]       rx_data_o

    ,output             joy1_clk_o
    ,output             joy1_cmd_o
    ,input              joy1_dat_i
    ,output             joy2_clk_o
    ,output             joy2_cmd_o
    ,input              joy2_dat_i

    ,output             busy_o
);

//-----------------------------------------------------------------
// Registers
//-----------------------------------------------------------------
reg       active_q;
reg [3:0] bit_count_q;
reg [7:0] shift_reg_q;
reg       done_q;

// NOTE: Duplicate output flops for IOB placement...
// Xilinx placement pragmas:
//synthesis attribute IOB of joy1_clk_q is "TRUE"
//synthesis attribute IOB of joy1_cmd_q is "TRUE"
//synthesis attribute IOB of joy2_clk_q is "TRUE"
//synthesis attribute IOB of joy2_cmd_q is "TRUE"
reg       joy1_clk_q;
reg       joy1_cmd_q;
reg       joy2_clk_q;
reg       joy2_cmd_q;

assign busy_o = active_q | done_q;

// Start operation
wire start_w = enable_i & ~busy_o & tx_valid_i;

//-----------------------------------------------------------------
// Mode change
//-----------------------------------------------------------------
reg mode_cpol_q;

always @ (posedge clk_i )
if (rst_i)
    mode_cpol_q <= 1'b0;
else
    mode_cpol_q <= mode_cpol_i;

wire mode_change_w = mode_cpol_q ^ mode_cpol_i;

//-----------------------------------------------------------------
// Sample, Drive pulse generation
//-----------------------------------------------------------------
reg sample_r;
reg drive_r;

wire cpha_w = 1'b1;
wire cpol_w = ~mode_cpol_i;

always @ *
begin
    sample_r = 1'b0;
    drive_r  = 1'b0;

    // IDLE
    if (start_w)    
        drive_r  = ~cpha_w; // Drive initial data (CPHA=0)
    // ACTIVE
    else if (active_q && clk_en_i)
    begin
        // Sample
        // CPHA=0, sample on the first edge
        // CPHA=1, sample on the second edge
        if (bit_count_q[0] == cpha_w)
            sample_r = 1'b1;
        // Drive (CPHA = 1)
        else if (cpha_w)
            drive_r = 1'b1;
        // Drive (CPHA = 0)
        else 
            drive_r = (bit_count_q != 4'b0) && (bit_count_q != 4'd15);
    end
end

//-----------------------------------------------------------------
// Shift register
//-----------------------------------------------------------------
// Bit reverse - LSB first
wire [7:0] tx_data_w = {
      tx_data_i[0]
    , tx_data_i[1]
    , tx_data_i[2]
    , tx_data_i[3]
    , tx_data_i[4]
    , tx_data_i[5]
    , tx_data_i[6]
    , tx_data_i[7]
    };

reg joyx_clk_q;

always @ (posedge clk_i )
if (rst_i)
begin
    shift_reg_q    <= 8'b0;
    joyx_clk_q     <= 1'b1;
    joy1_clk_q     <= 1'b1;
    joy1_cmd_q     <= 1'b0;
    joy2_clk_q     <= 1'b1;
    joy2_cmd_q     <= 1'b0;
end
else
begin
    // Reset / clock polarity change
    if (sw_reset_i || mode_change_w)
    begin
        shift_reg_q    <= 8'b0;
        joyx_clk_q     <= cpol_w;
        joy1_clk_q     <= cpol_w;
        joy2_clk_q     <= cpol_w;
    end
    // IDLE
    else if (start_w)
    begin
        joyx_clk_q     <= cpol_w;
        joy1_clk_q     <= cpol_w;
        joy2_clk_q     <= cpol_w;

        // CPHA = 0
        if (drive_r)
        begin
            joy1_cmd_q    <= tx_data_w[7];
            joy2_cmd_q    <= tx_data_w[7];
            shift_reg_q   <= {tx_data_w[6:0], 1'b0};
        end
        // CPHA = 1
        else
            shift_reg_q   <= tx_data_w;
    end
    // ACTIVE
    else if (active_q && clk_en_i)
    begin
        // Toggle clock output
        joy1_clk_q <= ~joyx_clk_q;
        joy2_clk_q <= ~joyx_clk_q;
        joyx_clk_q <= ~joyx_clk_q;

        // Drive CMD
        if (drive_r)
        begin
            joy1_cmd_q  <= shift_reg_q[7];
            joy2_cmd_q  <= shift_reg_q[7];
            shift_reg_q <= {shift_reg_q[6:0],1'b0};
        end
        // Sample DAT
        else if (sample_r)
            shift_reg_q[0] <= select_i ? joy2_dat_i : joy1_dat_i;
    end
end

assign rx_valid_o = done_q & rx_enable_i;

// Bit reverse - LSB first
assign rx_data_o = {
      shift_reg_q[0]
    , shift_reg_q[1]
    , shift_reg_q[2]
    , shift_reg_q[3]
    , shift_reg_q[4]
    , shift_reg_q[5]
    , shift_reg_q[6]
    , shift_reg_q[7]
    };

//-----------------------------------------------------------------
// Bit counter
//-----------------------------------------------------------------
always @ (posedge clk_i )
if (rst_i)
begin
    bit_count_q    <= 4'b0;
    active_q       <= 1'b0;
    done_q         <= 1'b0;
end
else if (sw_reset_i)
begin
    bit_count_q    <= 4'b0;
    active_q       <= 1'b0;
    done_q         <= 1'b0;
end
else if (start_w)
begin
    bit_count_q    <= 4'b0;
    active_q       <= 1'b1;
    done_q         <= 1'b0;
end
else if (active_q && clk_en_i)
begin
    // End of transfer reached
    if (bit_count_q == 4'd15)
    begin
        // Go back to IDLE
        active_q  <= 1'b0;

        // Set transfer complete flags
        done_q   <= 1'b1;
    end
    // Increment cycle counter
    else 
        bit_count_q <= bit_count_q + 4'd1;
end
else
    done_q         <= 1'b0;


assign tx_accept_o = (enable_i & ~busy_o);

assign joy1_clk_o  = joy1_clk_q;
assign joy1_cmd_o  = joy1_cmd_q;
assign joy2_clk_o  = joy2_clk_q;
assign joy2_cmd_o  = joy2_cmd_q;

endmodule