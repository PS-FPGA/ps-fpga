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
module dvi_fb_psf_addr_gen
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
     parameter VRAM_BASE        = 32'h03000000
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(
    // Inputs
     input           clk_i
    ,input           rst_i

    // Configuration
    ,input           enable_i
    ,input  [  9:0]  res_x_i
    ,input  [  8:0]  res_y_i
    ,input  [  9:0]  display_x_i
    ,input  [  8:0]  display_y_i
    ,input           interlace_i
    ,input           current_field_i

    // Address
    ,output [11:0]   disp_x_start_o
    ,output [11:0]   disp_x_end_o
    ,output [31:0]   addr_o
    ,output [31:0]   len_o
    ,output          x2_mode_o
    ,output          last_o
    ,input           accept_i
);

// Last fetch of the frame buffer (before restarting from the top)
wire      final_fetch_w;

reg [10:0] x_pos_q;
reg [9:0]  y_pos_q;

// TODO: Assuming 32-byte bursts, 16 pixels reads at a time.
// TODO: Assuming display_x_i is always a multiple of 16.

//-----------------------------------------------------------------
// Supported resolutions:
// - 320x240
// - 640x240
// - 640x480
// - 320x480
//-----------------------------------------------------------------

//-----------------------------------------------------------------
// Buffer Details
//-----------------------------------------------------------------
wire y2_next_w = (res_y_i == 9'd240);

reg [9:0] res_x_q;
reg [9:0] res_y_q;

always @ (posedge clk_i )
if (rst_i)
    res_x_q <= 10'b0;
else if (!enable_i || final_fetch_w)
begin
    case (res_x_i)
    10'd256: res_x_q <= 10'd256; // X2 mode
    10'd320: res_x_q <= 10'd320; // X2 mode
    10'd368: res_x_q <= 10'd352; // round down to x32 multiple
    10'd512: res_x_q <= 10'd512;
    default: res_x_q <= 10'd640;
    endcase
end

always @ (posedge clk_i )
if (rst_i)
    res_y_q <= 10'b0;
else if (!enable_i || final_fetch_w)
    res_y_q <= {1'b0, res_y_i};

reg [9:0] display_x_q;
reg [9:0] display_y_q;

always @ (posedge clk_i )
if (rst_i)
    display_x_q <= 10'b0;
else
    display_x_q <= display_x_i;

always @ (posedge clk_i )
if (rst_i)
    display_y_q <= 10'b0;
else
    display_y_q <= y2_next_w ? {display_y_i, 1'b0} : {1'b0, display_y_i};

//-----------------------------------------------------------------
// Bounds
//-----------------------------------------------------------------
wire   y2_mode_w    = (res_y_q == 10'd240);
assign x2_mode_o    = (res_x_q == 10'd256 || res_x_q == 10'd320);

wire [10:0] x_next_w = x_pos_q + 11'd16;
wire [9:0]  y_next_w = y_pos_q + 10'd1;

wire [10:0] x_min_w  = 11'd0;
wire [9:0]  y_min_w  = 10'd0;

wire [10:0] x_max_w  = {1'b0, res_x_q};
wire [9:0]  y_max_w  = (y2_mode_w ? {res_y_q[8:0], 1'b0} : res_y_q);

//-----------------------------------------------------------------
// X
//-----------------------------------------------------------------
always @ (posedge clk_i )
if (rst_i)
    x_pos_q <= 11'b0;
else if (!enable_i)
    x_pos_q <= x_min_w;
else if (accept_i)
begin
    if (x_next_w >= x_max_w)
        x_pos_q <= x_min_w;
    else
        x_pos_q <= x_next_w;
end

//-----------------------------------------------------------------
// Y
//-----------------------------------------------------------------
always @ (posedge clk_i )
if (rst_i)
    y_pos_q <= 10'b0;
else if (!enable_i)
    y_pos_q <= y_min_w;
else if (accept_i && x_next_w >= x_max_w)
begin
    if (y_next_w >= y_max_w)
        y_pos_q <= y_min_w;
    else
        y_pos_q <= y_next_w;
end

assign final_fetch_w = accept_i && (x_next_w >= x_max_w) && (y_next_w >= y_max_w);

wire [31:0] base_w = VRAM_BASE;
reg  [31:0] addr_r;

always @ *
begin
    addr_r = 32'b0;

    // E.g. 320x240
    if (y2_mode_w)
    begin
        addr_r = {base_w[31:20], display_y_q[9:1], display_x_q[9:0], 1'b0};
        addr_r = addr_r + {12'b0, y_pos_q[9:1], x_pos_q[9:0], 1'b0};
    end
    // Interlace mode
    else if (interlace_i)
    begin
        addr_r = {base_w[31:20], display_y_q[8:1], 1'b0, display_x_q[9:0], 1'b0};

        // Lines: 113355...
        if (current_field_i)
        begin
            addr_r = addr_r + {12'b0, y_pos_q[8:1], 1'b1, x_pos_q[9:0], 1'b0};
        end
        // Lines: 002244...
        else
        begin
            addr_r = addr_r + {12'b0, y_pos_q[8:1], 1'b0, x_pos_q[9:0], 1'b0};
        end
    end
    // Progressive (e.g. 640x480)
    else
    begin
        // Buffer address
        addr_r = {base_w[31:20], display_y_q[8:0], display_x_q[9:0], 1'b0};
        addr_r = addr_r + {12'b0, y_pos_q[8:0], x_pos_q[9:0], 1'b0};
    end
end

assign addr_o = addr_r;

// TODO: Fixed for now
assign len_o  = 32'd32;

assign last_o = final_fetch_w;

//-----------------------------------------------------------------
// X - Start
//-----------------------------------------------------------------
reg [9:0] disp_x_start_q;

always @ (posedge clk_i )
if (rst_i)
    disp_x_start_q <= 10'b0;
else if (!enable_i || final_fetch_w)
begin
    case (res_x_i)
    10'd256: disp_x_start_q <= 10'd64;
    10'd320: disp_x_start_q <= 10'd0;
    10'd368: disp_x_start_q <= 10'd144;
    10'd512: disp_x_start_q <= 10'd64;
    default: disp_x_start_q <= 10'd0;
    endcase
end

assign disp_x_start_o = {2'b0, disp_x_start_q};

//-----------------------------------------------------------------
// X - End
//-----------------------------------------------------------------
reg [9:0] disp_x_end_q;

always @ (posedge clk_i )
if (rst_i)
    disp_x_end_q <= 10'b0;
else if (!enable_i || final_fetch_w)
begin
    case (res_x_i)
    10'd256: disp_x_end_q <= 10'd576; // X2 mode
    10'd320: disp_x_end_q <= 10'd640; // X2 mode
    10'd368: disp_x_end_q <= 10'd496; // 352 + 144
    10'd512: disp_x_end_q <= 10'd576; // 512 + 64
    default: disp_x_end_q <= 10'd640;
    endcase
end

assign disp_x_end_o = {2'b0, disp_x_end_q};

//-----------------------------------------------------------------
// Simulation Only
//-----------------------------------------------------------------
`ifdef not_yet
reg [31:0] dbg_cycle_q;

always @ (posedge clk_i )
if (rst_i)
    dbg_cycle_q <= 32'b0;
else
    dbg_cycle_q <= dbg_cycle_q + 32'd1;

always @ (posedge clk_i)
if ((display_x_q != display_x_i) || 
    (display_y_q != (y2_next_w ? {display_y_i, 1'b0} : {1'b0, display_y_i})))
begin
     $display("[DISPLAY] Change active display X=%0d Y=%0d @ %0d", display_x_i, display_y_i, dbg_cycle_q);
end
`endif

endmodule