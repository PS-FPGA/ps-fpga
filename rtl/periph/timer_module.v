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
module timer_module
(
    // Inputs
     input           clk_i
    ,input           rst_i
    ,input  [ 31:0]  cfg_addr_i
    ,input  [ 31:0]  cfg_data_wr_i
    ,input           cfg_stb_i
    ,input           cfg_we_i
    ,input           dotclk_i
    ,input           hblank_i
    ,input           vblank_i
    ,input           mode_pal_i

    // Outputs
    ,output [ 31:0]  cfg_data_rd_o
    ,output          cfg_ack_o
    ,output          cfg_stall_o
    ,output          irq_timer0_o
    ,output          irq_timer1_o
    ,output          irq_timer2_o
);



// Select timer based on address
wire        cs_timer0_w    = cfg_stb_i & ~cfg_stall_o & (cfg_addr_i[7:4] == 4'h0);
wire        cs_timer1_w    = cfg_stb_i & ~cfg_stall_o & (cfg_addr_i[7:4] == 4'h1);
wire        cs_timer2_w    = cfg_stb_i & ~cfg_stall_o & (cfg_addr_i[7:4] == 4'h2);

wire [15:0] cfg_data_rd0_w;
wire [15:0] cfg_data_rd1_w;
wire [15:0] cfg_data_rd2_w;

//-----------------------------------------------------------------
// HBLANK, VBLANK resyncs
//-----------------------------------------------------------------
// TODO: Use proper resyncs...
reg [1:0] hblank_meta_q;
reg [1:0] vblank_meta_q;

always @ (posedge clk_i )
if (rst_i)
begin
    hblank_meta_q <= 2'b0;
    vblank_meta_q <= 2'b0;
end
else
begin
    hblank_meta_q <= {hblank_meta_q[0], hblank_i};
    vblank_meta_q <= {vblank_meta_q[0], vblank_i};
end

wire hblank_sync_w = hblank_meta_q[1];
wire vblank_sync_w = vblank_meta_q[1];

reg hblank_q;
reg vblank_q;

always @ (posedge clk_i )
if (rst_i)
    hblank_q <= 1'b0;
else
    hblank_q <= hblank_sync_w;

always @ (posedge clk_i )
if (rst_i)
    vblank_q <= 1'b0;
else
    vblank_q <= vblank_sync_w;

// Rising edges
wire clk_hblank_w = ~hblank_q & hblank_sync_w;
wire clk_vblank_w = ~vblank_q & vblank_sync_w;

//-----------------------------------------------------------------
// sys clk / 8
//-----------------------------------------------------------------
reg [7:0] div_clk8_q;

always @ (posedge clk_i )
if (rst_i)
    div_clk8_q <= 8'd1;
else
    div_clk8_q <= {div_clk8_q[6:0], div_clk8_q[7]};

//-----------------------------------------------------------------
// Timer 0
//-----------------------------------------------------------------
timer_unit
#(.TYPE(0))
u_timer0
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.dotclk_valid_i(dotclk_i)
    ,.dotclk_incr_i(4'd1) // TODO: FIX ME
    ,.clk_div8_i(div_clk8_q[7])
    ,.clk_hblank_i(clk_hblank_w)
    ,.clk_vblank_i(clk_vblank_w)
    ,.hblank_i(hblank_sync_w)
    ,.vblank_i(vblank_sync_w)
    ,.cfg_cs_i(cs_timer0_w)
    ,.cfg_we_i(cfg_we_i)
    ,.cfg_addr_i(cfg_addr_i[3:0])
    ,.cfg_data_wr_i(cfg_data_wr_i[15:0])
    ,.cfg_data_rd_o(cfg_data_rd0_w)
    ,.irq_o(irq_timer0_o)
);

//-----------------------------------------------------------------
// Timer 1
//-----------------------------------------------------------------
timer_unit
#(.TYPE(1)) 
u_timer1
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.dotclk_valid_i(dotclk_i)
    ,.dotclk_incr_i(4'd1) // TODO: FIX ME
    ,.clk_div8_i(div_clk8_q[7])
    ,.clk_hblank_i(clk_hblank_w)
    ,.clk_vblank_i(clk_vblank_w)
    ,.hblank_i(hblank_sync_w)
    ,.vblank_i(vblank_sync_w)
    ,.cfg_cs_i(cs_timer1_w)
    ,.cfg_we_i(cfg_we_i)
    ,.cfg_addr_i(cfg_addr_i[3:0])
    ,.cfg_data_wr_i(cfg_data_wr_i[15:0])
    ,.cfg_data_rd_o(cfg_data_rd1_w)
    ,.irq_o(irq_timer1_o)
);

//-----------------------------------------------------------------
// Timer 2
//-----------------------------------------------------------------
timer_unit
#(.TYPE(2))
u_timer2
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.dotclk_valid_i(dotclk_i)
    ,.dotclk_incr_i(4'd1) // TODO: FIX ME
    ,.clk_div8_i(div_clk8_q[7])
    ,.clk_hblank_i(clk_hblank_w)
    ,.clk_vblank_i(clk_vblank_w)
    ,.hblank_i(hblank_sync_w)
    ,.vblank_i(vblank_sync_w)
    ,.cfg_cs_i(cs_timer2_w)
    ,.cfg_we_i(cfg_we_i)
    ,.cfg_addr_i(cfg_addr_i[3:0])
    ,.cfg_data_wr_i(cfg_data_wr_i[15:0])
    ,.cfg_data_rd_o(cfg_data_rd2_w)
    ,.irq_o(irq_timer2_o)
);

//-----------------------------------------------------------------
// Read response flops
//-----------------------------------------------------------------
reg [15:0] cfg_data_rd_r;

always @ *
begin
    cfg_data_rd_r = 16'b0;

    case (cfg_addr_i[7:4])
    4'd0    : cfg_data_rd_r = cfg_data_rd0_w;
    4'd1    : cfg_data_rd_r = cfg_data_rd1_w;
    4'd2    : cfg_data_rd_r = cfg_data_rd2_w;
    default : cfg_data_rd_r = 16'b0;
    endcase
end

reg [31:0] cfg_data_rd_q;

always @ (posedge clk_i )
if (rst_i)
    cfg_data_rd_q <= 32'b0;
else
    cfg_data_rd_q <= {16'b0, cfg_data_rd_r};

assign cfg_data_rd_o = cfg_data_rd_q;

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



endmodule
