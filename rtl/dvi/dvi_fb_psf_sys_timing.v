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
module dvi_fb_psf_sys_timing
(
    // Inputs
     input           clk_i
    ,input           rst_i
    ,input           enable_i

    // Mode
    ,input  [  9:0]  display_res_x_i
    ,input  [  8:0]  display_res_y_i
    ,input           display_interlaced_i
    ,input           display_pal_i

    // 640x480 video timing
    ,input           h_sync_i
    ,input           v_sync_i
    ,input           blanking_i
    ,input [ 11:0]   h_pos_i
    ,input [ 11:0]   v_pos_i

    // Outputs
    ,output          display_field_o
    ,output          display_hblank_o
    ,output          display_vblank_o
    ,output          display_dotclk_o
);

//-----------------------------------------------------------------
// TODO: Need to translate these to be representative of PAL/NTSC
//       but for now...
//-----------------------------------------------------------------
wire [15:0] hblank_start_w  = 16'd1840;//16'd1534; // TODO: Add PAL
wire [15:0] hblank_end_w    = 16'd0062; // TODO: Add PAL

wire [15:0] hblank_max_w    = 16'd1902;//16'd1596; // TODO: Add PAL

wire [15:0] vblank_start_w  = 16'd240; // TODO: Add PAL
wire [15:0] vblank_field_w  = 16'd240; // TODO: Add PAL
wire [15:0] vblank_max_w    = 16'd262; // TODO: Add PAL

reg [15:0] pixel_counter_q;

always @ (posedge clk_i )
if (rst_i)
    pixel_counter_q <= 16'b0;
else if (!enable_i || (h_pos_i == 12'd0 && v_pos_i == 12'd0))
    pixel_counter_q <= 16'b0;
else if (pixel_counter_q == hblank_max_w)
    pixel_counter_q <= 16'b0;
else
    pixel_counter_q <= pixel_counter_q + 16'd1;

reg [15:0] line_counter_q;

always @ (posedge clk_i )
if (rst_i)
    line_counter_q <= 16'b0;
else if (!enable_i || (h_pos_i == 12'd0 && v_pos_i == 12'd0))
    line_counter_q <= 16'b0;
else if (pixel_counter_q == hblank_max_w)
    line_counter_q <= line_counter_q + 16'd1;

//-----------------------------------------------------------------
// HBLANK
//-----------------------------------------------------------------
reg hblank_q;

always @ (posedge clk_i )
if (rst_i)
    hblank_q <= 1'b0;
else
    hblank_q <= (pixel_counter_q < hblank_end_w || pixel_counter_q > hblank_start_w);

assign display_hblank_o = hblank_q;

//-----------------------------------------------------------------
// VBLANK
//-----------------------------------------------------------------
reg vblank_q;

always @ (posedge clk_i )
if (rst_i)
    vblank_q <= 1'b0;
else if (!enable_i || (h_pos_i == 12'd0 && v_pos_i == 12'd0))
    vblank_q <= 1'b0;
else if (pixel_counter_q == 16'd0 && line_counter_q == vblank_start_w)
    vblank_q <= 1'b1;
else if (pixel_counter_q == hblank_max_w && line_counter_q == vblank_max_w)
    vblank_q <= 1'b0;

assign display_vblank_o = vblank_q;

//-----------------------------------------------------------------
// Interlace Field
//-----------------------------------------------------------------
reg field_q;

always @ (posedge clk_i )
if (rst_i)
    field_q <= 1'b0;
else if (pixel_counter_q == 16'b0 && line_counter_q == vblank_field_w)
    field_q <= ~field_q;

assign display_field_o = field_q;

//-----------------------------------------------------------------
// Hacky dotclock
//-----------------------------------------------------------------
reg [3:0] count_q;
reg [3:0] count_max_r;

always @ *
begin
    count_max_r = 4'b0;

    case (display_res_x_i)
    10'd256: count_max_r = 4'd9;
    10'd320: count_max_r = 4'd7;
    10'd368: count_max_r = 4'd6;
    10'd512: count_max_r = 4'd4;
    10'd640: count_max_r = 4'd3;
    default: ;
    endcase
end

always @ (posedge clk_i )
if (rst_i)
    count_q <= 4'b0;
else if (count_q >= count_max_r)
    count_q <= 4'b0;
else
    count_q <= count_q + 4'd1;

reg dotclk_en_q;

always @ (posedge clk_i )
if (rst_i)
    dotclk_en_q <= 1'b0;
else
    dotclk_en_q <= ~(|count_q);

assign display_dotclk_o = dotclk_en_q;

endmodule
