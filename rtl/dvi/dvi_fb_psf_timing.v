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
module dvi_fb_psf_timing
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
     parameter VIDEO_WIDTH      = 640
    ,parameter VIDEO_HEIGHT     = 480
    ,parameter VIDEO_REFRESH    = 60
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(
    // Inputs
     input           clk_i
    ,input           rst_i
    ,input           enable_i

    // Outputs
    ,output          h_sync_o
    ,output          v_sync_o
    ,output          blanking_o
    ,output [ 11:0]  h_pos_o
    ,output [ 11:0]  v_pos_o
    ,output          enable_fetcher_o
);

//-----------------------------------------------------------------
// Timings
//-----------------------------------------------------------------
localparam H_REZ         = VIDEO_WIDTH;
localparam V_REZ         = VIDEO_HEIGHT;
localparam CLK_MHZ       = (VIDEO_WIDTH == 640 && VIDEO_REFRESH == 60)  ? 25.175 :
                           (VIDEO_WIDTH == 640 && VIDEO_REFRESH == 85)  ? 36 :
                           (VIDEO_WIDTH == 800 && VIDEO_REFRESH == 72)  ? 50.00  :
                           (VIDEO_WIDTH == 1280 && VIDEO_REFRESH == 50) ? 60.00  :
                           (VIDEO_WIDTH == 1280 && VIDEO_REFRESH == 60) ? 74.25  :
                           (VIDEO_WIDTH == 1920 && VIDEO_REFRESH == 60) ? 148.5  :
                                                                          0;
localparam H_SYNC_START  = (VIDEO_WIDTH == 640 && VIDEO_REFRESH == 60)  ? 656 :
                           (VIDEO_WIDTH == 640 && VIDEO_REFRESH == 85)  ? 672 :
                           (VIDEO_WIDTH == 800 && VIDEO_REFRESH == 72)  ? 856 :
                           (VIDEO_WIDTH == 1280 && VIDEO_REFRESH == 50) ? 1328:
                           (VIDEO_WIDTH == 1280 && VIDEO_REFRESH == 60) ? 1390:
                           (VIDEO_WIDTH == 1920 && VIDEO_REFRESH == 60) ? 2008:
                                                                          0;
localparam H_SYNC_END    = (VIDEO_WIDTH == 640 && VIDEO_REFRESH == 60)  ? 752 :
                           (VIDEO_WIDTH == 640 && VIDEO_REFRESH == 85)  ? 720 :
                           (VIDEO_WIDTH == 800 && VIDEO_REFRESH == 72)  ? 976 :
                           (VIDEO_WIDTH == 1280 && VIDEO_REFRESH == 50) ? 1456:
                           (VIDEO_WIDTH == 1280 && VIDEO_REFRESH == 60) ? 1430:
                           (VIDEO_WIDTH == 1920 && VIDEO_REFRESH == 60) ? 2052:
                                                                          0;
localparam H_MAX         = (VIDEO_WIDTH == 640 && VIDEO_REFRESH == 60)  ? 952 :
                           (VIDEO_WIDTH == 640 && VIDEO_REFRESH == 85)  ? 832 :
                           (VIDEO_WIDTH == 800 && VIDEO_REFRESH == 72)  ? 1040:
                           (VIDEO_WIDTH == 1280 && VIDEO_REFRESH == 50) ? 1632:
                           (VIDEO_WIDTH == 1280 && VIDEO_REFRESH == 60) ? 1650:
                           (VIDEO_WIDTH == 1920 && VIDEO_REFRESH == 60) ? 2200:
                                                                          0;
localparam V_SYNC_START  = (VIDEO_HEIGHT == 480 && VIDEO_REFRESH == 60) ? 490 :
                           (VIDEO_HEIGHT == 480 && VIDEO_REFRESH == 85) ? 490 :
                           (VIDEO_HEIGHT == 600 && VIDEO_REFRESH == 72) ? 637 :
                           (VIDEO_HEIGHT == 720 && VIDEO_REFRESH == 50) ? 721 :
                           (VIDEO_HEIGHT == 720 && VIDEO_REFRESH == 60) ? 725 :
                           (VIDEO_HEIGHT == 1080 && VIDEO_REFRESH == 60)? 1084 :
                                                                          0;
localparam V_SYNC_END    = (VIDEO_HEIGHT == 480 && VIDEO_REFRESH == 60) ? 492 :
                           (VIDEO_HEIGHT == 480 && VIDEO_REFRESH == 85) ? 492 :
                           (VIDEO_HEIGHT == 600 && VIDEO_REFRESH == 72) ? 643 :
                           (VIDEO_HEIGHT == 720 && VIDEO_REFRESH == 50) ? 724 :
                           (VIDEO_HEIGHT == 720 && VIDEO_REFRESH == 60) ? 730 :
                           (VIDEO_HEIGHT == 1080 && VIDEO_REFRESH == 60)? 1089:
                                                                          0;
localparam V_MAX         = (VIDEO_HEIGHT == 480 && VIDEO_REFRESH == 60) ? 524 :
                           (VIDEO_HEIGHT == 480 && VIDEO_REFRESH == 85) ? 525 :
                           (VIDEO_HEIGHT == 600 && VIDEO_REFRESH == 72) ? 666 :
                           (VIDEO_HEIGHT == 720 && VIDEO_REFRESH == 50) ? 741 :
                           (VIDEO_HEIGHT == 720 && VIDEO_REFRESH == 60) ? 750 :
                           (VIDEO_HEIGHT == 1080 && VIDEO_REFRESH == 60)? 1125:
                                                                          0;

//-----------------------------------------------------------------
// HSYNC, VSYNC
//-----------------------------------------------------------------
reg [11:0] h_pos_q;
reg [11:0] v_pos_q;
reg        h_sync_q;
reg        v_sync_q;

always @ (posedge clk_i )
if (rst_i)
    h_pos_q  <= 12'b0;
else if (!enable_i)
    h_pos_q  <= 12'b0;
else if (h_pos_q == H_MAX)
    h_pos_q  <= 12'b0;
else
    h_pos_q  <= h_pos_q + 12'd1;

always @ (posedge clk_i )
if (rst_i)
    v_pos_q  <= 12'b0;
else if (!enable_i)
    v_pos_q  <= 12'b0; 
else if (h_pos_q == H_MAX)
begin
    if (v_pos_q == V_MAX)
        v_pos_q  <= 12'b0;
    else
        v_pos_q  <= v_pos_q + 12'd1;
end

always @ (posedge clk_i )
if (rst_i)
    h_sync_q  <= 1'b0;
else if (h_pos_q >= H_SYNC_START && h_pos_q < H_SYNC_END)
    h_sync_q  <= 1'b1;
else
    h_sync_q  <= 1'b0;

assign h_sync_o = h_sync_q;

always @ (posedge clk_i )
if (rst_i)
    v_sync_q  <= 1'b0;
else if (v_pos_q >= V_SYNC_START && v_pos_q < V_SYNC_END)
    v_sync_q  <= 1'b1;
else
    v_sync_q  <= 1'b0;

assign v_sync_o   = v_sync_q;

assign blanking_o = (h_pos_q < H_REZ && v_pos_q < V_REZ) ? 1'b0 : 1'b1;
assign h_pos_o    = h_pos_q;
assign v_pos_o    = v_pos_q;

// Nearly the start of the next frame, start prefetching pixels from memory
assign enable_fetcher_o = (v_pos_q == V_MAX) && (h_pos_o == 12'b0);

endmodule