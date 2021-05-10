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
module dvi_fb_psf
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
     parameter AXI_ID           = 14
    ,parameter VIDEO_WIDTH      = 640
    ,parameter VIDEO_HEIGHT     = 480
    ,parameter VIDEO_REFRESH    = 60
    ,parameter VIDEO_FB_RAM     = 50331648
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(
    // Inputs
     input           clk_i
    ,input           rst_i
    ,input           clk_x5_i
    ,input  [  9:0]  display_res_x_i
    ,input  [  8:0]  display_res_y_i
    ,input  [  9:0]  display_x_i
    ,input  [  8:0]  display_y_i
    ,input           display_interlaced_i
    ,input           display_pal_i
    ,input           outport_awready_i
    ,input           outport_wready_i
    ,input           outport_bvalid_i
    ,input  [  1:0]  outport_bresp_i
    ,input  [  3:0]  outport_bid_i
    ,input           outport_arready_i
    ,input           outport_rvalid_i
    ,input  [ 31:0]  outport_rdata_i
    ,input  [  1:0]  outport_rresp_i
    ,input  [  3:0]  outport_rid_i
    ,input           outport_rlast_i

    // Outputs
    ,output          display_field_o
    ,output          display_hblank_o
    ,output          display_vblank_o
    ,output          display_dotclk_o
    ,output          outport_awvalid_o
    ,output [ 31:0]  outport_awaddr_o
    ,output [  3:0]  outport_awid_o
    ,output [  7:0]  outport_awlen_o
    ,output [  1:0]  outport_awburst_o
    ,output [  2:0]  outport_awsize_o
    ,output          outport_wvalid_o
    ,output [ 31:0]  outport_wdata_o
    ,output [  3:0]  outport_wstrb_o
    ,output          outport_wlast_o
    ,output          outport_bready_o
    ,output          outport_arvalid_o
    ,output [ 31:0]  outport_araddr_o
    ,output [  3:0]  outport_arid_o
    ,output [  7:0]  outport_arlen_o
    ,output [  1:0]  outport_arburst_o
    ,output [  2:0]  outport_arsize_o
    ,output          outport_rready_o
    ,output          dvi_red_o
    ,output          dvi_green_o
    ,output          dvi_blue_o
    ,output          dvi_clock_o
);



//-----------------------------------------------------------------
// Video Timings
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

localparam VIDEO_SIZE    = (H_REZ * V_REZ) * 2; // RG565
localparam BUFFER_SIZE   = 512;
localparam BURST_LEN     = 32;

wire        pixel_valid_w;
wire        pixel_accept_w;
wire [11:0] h_pos_w;
wire [11:0] v_pos_w;
wire        last_pixel_w;
wire [11:0] disp_x_start_w;
wire [11:0] disp_x_end_w;

//-----------------------------------------------------------------
// TODO: Resync...
//-----------------------------------------------------------------
reg [9:0] display_res_x_q;
reg [8:0] display_res_y_q;

always @ (posedge clk_i )
if (rst_i)
    display_res_x_q  <= 10'b0;
else
    display_res_x_q  <= display_res_x_i;

always @ (posedge clk_i )
if (rst_i)
    display_res_y_q  <= 9'b0;
else
    display_res_y_q  <= display_res_y_i;

// Detect resolution change
wire res_change_w = (display_res_x_q  != display_res_x_i) || (display_res_y_q != display_res_y_i);

`ifdef verilator
always @ (posedge clk_i)
if (res_change_w)
begin
    $display("[DISPLAY] Info - resolution changed w:%d h:%d pal:%d interlace:%d", display_res_x_i, display_res_y_i, display_pal_i, display_interlaced_i);
end
`endif

//-----------------------------------------------------------------
// Active
//-----------------------------------------------------------------
reg active_q;

always @ (posedge clk_i )
if (rst_i)
    active_q  <= 1'b0;
else if (pixel_accept_w && !pixel_valid_w)
    active_q  <= 1'b0; // Underrun - abort until next frame
else if (h_pos_w == H_REZ && v_pos_w == V_REZ)
    active_q  <= 1'b1;

//-----------------------------------------------------------------
// Timing
//-----------------------------------------------------------------
wire        h_sync_w;
wire        v_sync_w;
wire        blanking_w;
wire        enable_fetcher_w;

dvi_fb_psf_timing
#(
     .VIDEO_WIDTH(VIDEO_WIDTH)
    ,.VIDEO_HEIGHT(VIDEO_HEIGHT)
    ,.VIDEO_REFRESH(VIDEO_REFRESH)
)
u_timing
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)

    ,.enable_i(1'b1)

    ,.h_sync_o(h_sync_w)
    ,.v_sync_o(v_sync_w)
    ,.blanking_o(blanking_w)
    ,.h_pos_o(h_pos_w)
    ,.v_pos_o(v_pos_w)

    ,.enable_fetcher_o(enable_fetcher_w)
);

//-----------------------------------------------------------------
// Fetch enable
//-----------------------------------------------------------------
reg fetch_en_q;

always @ (posedge clk_i )
if (rst_i)
    fetch_en_q  <= 1'b0;
else if (enable_fetcher_w)
    fetch_en_q  <= 1'b1;
else if (outport_arvalid_o && outport_arready_i && last_pixel_w)
    fetch_en_q  <= 1'b0;

//-----------------------------------------------------------------
// System Timing: Generate strobes and dot clocks for the given res
//-----------------------------------------------------------------
dvi_fb_psf_sys_timing
u_sys_timing
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)

    ,.enable_i(1'b1)

    // Mode
    ,.display_res_x_i(display_res_x_i)
    ,.display_res_y_i(display_res_y_i)
    ,.display_interlaced_i(display_interlaced_i)
    ,.display_pal_i(display_pal_i)

    // 640x480 video timing
    ,.h_sync_i(h_sync_w)
    ,.v_sync_i(v_sync_w)
    ,.blanking_i(blanking_w)
    ,.h_pos_i(h_pos_w)
    ,.v_pos_i(v_pos_w)

    // Outputs
    ,.display_field_o(display_field_o)
    ,.display_hblank_o(display_hblank_o)
    ,.display_vblank_o(display_vblank_o)
    ,.display_dotclk_o(display_dotclk_o)
);

//-----------------------------------------------------------------
// Pixel fetch FIFO
//-----------------------------------------------------------------
wire [31:0] pixel_data_w;
wire        pixel_pop_w    = pixel_accept_w || ~active_q || (blanking_w & ~fetch_en_q);

dvi_fb_psf_fifo
u_fifo
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)

    ,.push_i(outport_rvalid_i)
    ,.data_in_i(outport_rdata_i)
    ,.accept_o()

    ,.valid_o(pixel_valid_w)
    ,.data_out_o(pixel_data_w)
    ,.pop_i(pixel_pop_w)
);

//-----------------------------------------------------------------
// FIFO allocation
//-----------------------------------------------------------------
reg [15:0] allocated_q;

always @ (posedge clk_i )
if (rst_i)
    allocated_q  <= 16'b0;
else if (outport_arvalid_o && outport_arready_i)
begin
    if (pixel_valid_w && pixel_pop_w)
        allocated_q  <= allocated_q + {6'b0, outport_arlen_o, 2'b0};
    else
        allocated_q  <= allocated_q + {6'b0, (outport_arlen_o + 8'd1), 2'b0};
end
else if (pixel_valid_w && pixel_pop_w)
    allocated_q  <= allocated_q - 16'd4;

//-----------------------------------------------------------------
// AXI Request
//-----------------------------------------------------------------
wire       fifo_space_w = (allocated_q <= (BUFFER_SIZE - BURST_LEN));
reg        arvalid_q;

always @ (posedge clk_i )
if (rst_i)
    arvalid_q <= 1'b0;
else if (outport_arvalid_o && outport_arready_i)
    arvalid_q <= 1'b0;
else if (!outport_arvalid_o && fifo_space_w && active_q && fetch_en_q)
    arvalid_q <= 1'b1;

assign outport_arvalid_o = arvalid_q;

wire x2_mode_w;

dvi_fb_psf_addr_gen
#( .VRAM_BASE(VIDEO_FB_RAM) )
u_addr
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)

    // Configuration
    ,.enable_i(active_q & fetch_en_q)
    ,.res_x_i(display_res_x_i)
    ,.res_y_i(display_res_y_i)
    ,.display_x_i(display_x_i)
    ,.display_y_i(display_y_i)
    ,.interlace_i(display_interlaced_i)
    ,.current_field_i(display_field_o)

    // Address
    ,.disp_x_start_o(disp_x_start_w)
    ,.disp_x_end_o(disp_x_end_w)
    ,.addr_o(outport_araddr_o)
    ,.len_o()
    ,.last_o(last_pixel_w)
    ,.x2_mode_o(x2_mode_w)
    ,.accept_i(outport_arvalid_o && outport_arready_i)
);

reg x2_mode_q;

always @ (posedge clk_i )
if (rst_i)
    x2_mode_q  <= 1'b0;
else if (!active_q || blanking_w)
    x2_mode_q  <= x2_mode_w;

assign outport_arburst_o = 2'b01;
assign outport_arid_o    = 4'd14;
assign outport_arlen_o   = (BURST_LEN / 4) - 1;

assign outport_rready_o  = 1'b1;

// Unused
assign outport_awvalid_o = 1'b0;
assign outport_awaddr_o  = 32'b0;
assign outport_awid_o    = 4'b0;
assign outport_awlen_o   = 8'b0;
assign outport_awburst_o = 2'b0;
assign outport_wvalid_o  = 1'b0;
assign outport_wdata_o   = 32'b0;
assign outport_wstrb_o   = 4'b0;
assign outport_wlast_o   = 1'b0;
assign outport_bready_o  = 1'b0;

//-----------------------------------------------------------------
// RGB expansion
//-----------------------------------------------------------------
reg word_sel_q;

wire zero_pixel_w  = (h_pos_w >= disp_x_end_w) || (h_pos_w < disp_x_start_w);

always @ (posedge clk_i )
if (rst_i)
    word_sel_q  <= 1'b0;
else if (!blanking_w && !zero_pixel_w && (h_pos_w[0] || !x2_mode_q))
    word_sel_q  <= ~word_sel_q;
else if (!active_q)
    word_sel_q  <= 1'b0;

wire [4:0] red5_w    = word_sel_q                   ? {pixel_data_w[4+16:0+16]} : 
                                                      {pixel_data_w[4:0]};
wire [4:0] green5_w  = word_sel_q                   ? {pixel_data_w[9+16:5+16]} : 
                                                      {pixel_data_w[9:5]};
wire [4:0] blue5_w   = word_sel_q                   ? {pixel_data_w[14+16:10+16]} : 
                                                      {pixel_data_w[14:10]};

// (n_5bit * 255 / 31 ) -> (value << 3) + ((value >>2) & 0x7)
wire [7:0] red_w    = zero_pixel_w ? 8'h10 : {red5_w[4:0],   red5_w[4:2]};
wire [7:0] green_w  = zero_pixel_w ? 8'h10 : {green5_w[4:0], green5_w[4:2]};
wire [7:0] blue_w   = zero_pixel_w ? 8'h10 : {blue5_w[4:0],  blue5_w[4:2]};

assign pixel_accept_w = ~blanking_w & ~zero_pixel_w & word_sel_q & (h_pos_w[0] || !x2_mode_q) & active_q;

//-----------------------------------------------------------------
// DVI output
//-----------------------------------------------------------------
dvi u_dvi
(
    .clk_i(clk_i),
    .rst_i(rst_i),
    .clk_x5_i(clk_x5_i),
    .vga_red_i(red_w),
    .vga_green_i(green_w),
    .vga_blue_i(blue_w),
    .vga_blank_i(blanking_w),
    .vga_hsync_i(h_sync_w),
    .vga_vsync_i(v_sync_w),
    .dvi_red_o(dvi_red_o),
    .dvi_green_o(dvi_green_o),
    .dvi_blue_o(dvi_blue_o),
    .dvi_clock_o(dvi_clock_o)
);

//-----------------------------------------------------------------
// Checker Interface
//-----------------------------------------------------------------
`ifdef verilator
function [0:0] get_driving; /*verilator public*/
begin
    get_driving = !active_q || blanking_w;
end
endfunction
function [0:0] get_blanking; /*verilator public*/
begin
    get_blanking = blanking_w;
end
endfunction
function [0:0] get_hsync; /*verilator public*/
begin
    get_hsync = h_sync_w;
end
endfunction
function [0:0] get_vsync; /*verilator public*/
begin
    get_vsync = v_sync_w;
end
endfunction
function [23:0] get_rgb888; /*verilator public*/
begin
    get_rgb888 = active_q ? {red_w, green_w, blue_w} : {24'hffc0cb};
end
endfunction
function [31:0] get_res_width; /*verilator public*/
begin
    get_res_width = {22'b0, display_res_x_i};
end
endfunction
function [31:0] get_res_height; /*verilator public*/
begin
    get_res_height = {23'b0, display_res_y_i};
end
endfunction
function [0:0] get_is_interlaced; /*verilator public*/
begin
    get_is_interlaced = display_interlaced_i;
end
endfunction
function [31:0] get_pixel_x; /*verilator public*/
begin
    get_pixel_x = {20'b0, h_pos_w};
end
endfunction
function [31:0] get_pixel_y; /*verilator public*/
begin
    get_pixel_y = {20'b0, v_pos_w};
end
endfunction
`endif



endmodule
