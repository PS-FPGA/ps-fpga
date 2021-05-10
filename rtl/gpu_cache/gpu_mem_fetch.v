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
module gpu_mem_fetch
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
     parameter AXI_ID           = 0
    ,parameter VRAM_BASE        = 0
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(
    // Inputs
     input           clk_i
    ,input           rst_i
    ,input           mem_command_i
    ,input           mem_write_i
    ,input  [ 14:0]  mem_addr_i
    ,input  [ 15:0]  mem_write_mask_i
    ,input  [255:0]  mem_data_out_i
    ,input           axi_awready_i
    ,input           axi_wready_i
    ,input           axi_bvalid_i
    ,input  [  1:0]  axi_bresp_i
    ,input  [  3:0]  axi_bid_i
    ,input           axi_arready_i
    ,input           axi_rvalid_i
    ,input  [255:0]  axi_rdata_i
    ,input  [  1:0]  axi_rresp_i
    ,input  [  3:0]  axi_rid_i
    ,input           axi_rlast_i

    // Outputs
    ,output          mem_busy_o
    ,output          mem_data_in_valid_o
    ,output [255:0]  mem_data_in_o
    ,output          axi_awvalid_o
    ,output [ 31:0]  axi_awaddr_o
    ,output [  3:0]  axi_awid_o
    ,output [  7:0]  axi_awlen_o
    ,output [  1:0]  axi_awburst_o
    ,output          axi_wvalid_o
    ,output [255:0]  axi_wdata_o
    ,output [ 31:0]  axi_wstrb_o
    ,output          axi_wlast_o
    ,output          axi_bready_o
    ,output          axi_arvalid_o
    ,output [ 31:0]  axi_araddr_o
    ,output [  3:0]  axi_arid_o
    ,output [  7:0]  axi_arlen_o
    ,output [  1:0]  axi_arburst_o
    ,output          axi_rready_o
    ,output          busy_o
);

//-----------------------------------------------------------------
// States
//-----------------------------------------------------------------
localparam STATE_W           = 3;
localparam STATE_IDLE        = 3'd0;
localparam STATE_FETCH1      = 3'd2;
localparam STATE_FETCH2      = 3'd3;
localparam STATE_FETCH3      = 3'd4;
localparam STATE_WAIT        = 3'd5;
localparam STATE_SLOT_HIT    = 3'd6;

// States
reg [STATE_W-1:0]           next_state_r;
reg [STATE_W-1:0]           state_q;

//-----------------------------------------------------------------
// Response tracking
//-----------------------------------------------------------------
reg [1:0] resp_idx_q;

wire critical_resp_w = (resp_idx_q == 2'd0);
wire last_resp_w     = (resp_idx_q == 2'd3);

always @ (posedge clk_i )
if (rst_i)
    resp_idx_q <= 2'd0;
else if (state_q == STATE_SLOT_HIT)
    resp_idx_q <= 2'd1;
else if (axi_rvalid_i && axi_rready_o)
    resp_idx_q <= resp_idx_q + 2'd1;

//-----------------------------------------------------------------
// Prefetch slots
//-----------------------------------------------------------------
reg         slot0_valid_q;
reg [14:0]  slot0_addr_q;
reg [255:0] slot0_data_q;

wire slot0_match_w = slot0_valid_q && (slot0_addr_q == mem_addr_i);

always @ (posedge clk_i )
if (rst_i)
    slot0_valid_q   <= 1'b0;
// Slot respone ready
else if (resp_idx_q == 2'd1 && axi_rvalid_i && axi_rready_o)
    slot0_valid_q   <= 1'b1;
// Invalidate on write
else if (mem_command_i && mem_write_i && ~mem_busy_o && slot0_match_w)
    slot0_valid_q   <= 1'b0;

always @ (posedge clk_i )
if (rst_i)
    slot0_data_q   <= 256'b0;
else if (resp_idx_q == 2'd1 && axi_rvalid_i && axi_rready_o)
    slot0_data_q   <= axi_rdata_i;

reg         slot1_valid_q;
reg [14:0]  slot1_addr_q;
reg [255:0] slot1_data_q;

wire slot1_match_w = slot1_valid_q && (slot1_addr_q == mem_addr_i);

always @ (posedge clk_i )
if (rst_i)
    slot1_valid_q   <= 1'b0;
// Slot respone ready
else if (resp_idx_q == 2'd2 && axi_rvalid_i && axi_rready_o)
    slot1_valid_q   <= 1'b1;
// Invalidate on write
else if (mem_command_i && mem_write_i && ~mem_busy_o && slot1_match_w)
    slot1_valid_q   <= 1'b0;

always @ (posedge clk_i )
if (rst_i)
    slot1_data_q   <= 256'b0;
else if (resp_idx_q == 2'd2 && axi_rvalid_i && axi_rready_o)
    slot1_data_q   <= axi_rdata_i;

reg         slot2_valid_q;
reg [14:0]  slot2_addr_q;
reg [255:0] slot2_data_q;

wire slot2_match_w = slot2_valid_q && (slot2_addr_q == mem_addr_i);

always @ (posedge clk_i )
if (rst_i)
    slot2_valid_q   <= 1'b0;
// Slot respone ready
else if (resp_idx_q == 2'd3 && axi_rvalid_i && axi_rready_o)
    slot2_valid_q   <= 1'b1;
// Invalidate on write
else if (mem_command_i && mem_write_i && ~mem_busy_o && slot2_match_w)
    slot2_valid_q   <= 1'b0;

always @ (posedge clk_i )
if (rst_i)
    slot2_data_q   <= 256'b0;
else if (resp_idx_q == 2'd3 && axi_rvalid_i && axi_rready_o)
    slot2_data_q   <= axi_rdata_i;


always @ (posedge clk_i )
if (rst_i)
begin
    slot0_addr_q <= 15'b0;
    slot1_addr_q <= 15'b0;
    slot2_addr_q <= 15'b0;
end
else if ((state_q == STATE_IDLE && next_state_r == STATE_FETCH1) || 
         (state_q == STATE_IDLE && next_state_r == STATE_SLOT_HIT))
begin
    slot0_addr_q <= mem_addr_i - 15'd1;
    slot1_addr_q <= mem_addr_i + 15'd1;
    slot2_addr_q <= mem_addr_i + 15'd64;
end

wire slot_hit_any_w = slot0_match_w | slot1_match_w | slot2_match_w;

reg [255:0] slot_resp_q;

always @ (posedge clk_i )
if (rst_i)
    slot_resp_q <= 256'b0;
else if (state_q == STATE_IDLE)
begin
    case (1'b1)
    slot0_match_w: slot_resp_q <= slot0_data_q;
    slot1_match_w: slot_resp_q <= slot1_data_q;
    slot2_match_w: slot_resp_q <= slot2_data_q;
    endcase    
end

//-----------------------------------------------------------------
// Next State Logic
//-----------------------------------------------------------------
always @ *
begin
    next_state_r = state_q;

    case (state_q)

    //-----------------------------------------
    // STATE_IDLE
    //-----------------------------------------
    STATE_IDLE :
    begin
        // Read
        if (!mem_write_i)
        begin
            if (slot_hit_any_w)
                next_state_r = STATE_SLOT_HIT;
            else if (axi_arready_i)
                next_state_r = STATE_FETCH1;
        end
    end
    //-----------------------------------------
    // STATE_FETCH1
    //-----------------------------------------
    STATE_FETCH1 :
    begin
        if (axi_arready_i)
            next_state_r = STATE_FETCH2;
    end
    STATE_FETCH2 :
    begin
        if (axi_arready_i)
            next_state_r = STATE_FETCH3;
    end
    STATE_FETCH3 :
    begin
        if (axi_arready_i)
            next_state_r = STATE_WAIT;
    end
    //-----------------------------------------
    // STATE_WAIT
    //-----------------------------------------
    STATE_WAIT :
    begin
        if (last_resp_w && axi_rvalid_i && axi_rready_o)
            next_state_r = STATE_IDLE;
    end
    //-----------------------------------------
    // STATE_SLOT_HIT
    //-----------------------------------------
    STATE_SLOT_HIT :
    begin
        next_state_r = STATE_FETCH1;
    end
    default:
        ;
    endcase
end

// Update state
always @ (posedge clk_i )
if (rst_i)
    state_q   <= STATE_IDLE;
else
    state_q   <= next_state_r;

//-----------------------------------------------------------------
//                      AXI Handing
//-----------------------------------------------------------------
// Always accept responses
assign axi_bready_o = 1'b1;
assign axi_rready_o = 1'b1;

// Constant IDs
assign axi_arid_o = AXI_ID;
assign axi_awid_o = AXI_ID;

reg mem_busy_r;

always @ *
begin
    mem_busy_r = 1'b0;

    if (mem_write_i)
        mem_busy_r = ~(axi_awready_i & axi_wready_i);
    // Read - idle
    else if (state_q == STATE_IDLE)
    begin
        if (slot_hit_any_w)
            mem_busy_r = 1'b0;
        else
            mem_busy_r = ~axi_arready_i;
    end
    // Read - busy
    else
        mem_busy_r = 1'b1;
end

assign mem_busy_o = mem_busy_r;

//--------------------------------------------------------------------
// Read request
//--------------------------------------------------------------------
reg        arvalid_r;
reg [31:0] araddr_r;

always @ *
begin
    arvalid_r = 1'b0;
    araddr_r  = 32'b0;

    case (state_q)
    STATE_IDLE:
    begin
        arvalid_r = ~slot_hit_any_w & mem_command_i & ~mem_write_i & ~mem_busy_o;
        araddr_r  = VRAM_BASE + {12'b0, mem_addr_i, 5'b0};
    end
    STATE_FETCH1 :
    begin
        arvalid_r = 1'b1;
        araddr_r  = VRAM_BASE + {12'b0, slot0_addr_q, 5'b0};
    end
    STATE_FETCH2 :
    begin
        arvalid_r = 1'b1;
        araddr_r  = VRAM_BASE + {12'b0, slot1_addr_q, 5'b0};
    end
    STATE_FETCH3 :
    begin
        arvalid_r = 1'b1;
        araddr_r  = VRAM_BASE + {12'b0, slot2_addr_q, 5'b0};
    end
    default : ;
    endcase
end

// For debug
wire [14:0] araddr_block_w = araddr_r[19:5];

assign axi_arvalid_o = arvalid_r;
assign axi_araddr_o  = araddr_r;
assign axi_arlen_o   = 8'b0;
assign axi_arburst_o = 2'b01; // INCR

//--------------------------------------------------------------------
// Read response
//--------------------------------------------------------------------
reg         mem_data_valid_r;
reg [255:0] mem_data_r;

always @ *
begin
    mem_data_valid_r  = 1'b0;
    mem_data_r        = 256'b0;

    if (critical_resp_w && axi_rvalid_i)
    begin
        mem_data_valid_r  = 1'b1;
        mem_data_r        = axi_rdata_i;
    end
    else if (state_q == STATE_SLOT_HIT)
    begin
        mem_data_valid_r  = 1'b1;
        mem_data_r        = slot_resp_q;
    end
end

assign mem_data_in_valid_o = mem_data_valid_r;
assign mem_data_in_o       = mem_data_r;

//--------------------------------------------------------------------
// Write request
//--------------------------------------------------------------------
reg        awvalid_r;
reg [31:0] awaddr_r;

always @ *
begin
    awvalid_r = mem_command_i & mem_write_i & ~mem_busy_o;
    awaddr_r  = VRAM_BASE + {12'b0, mem_addr_i, 5'b0};
end

assign axi_awvalid_o = awvalid_r & axi_wready_i;
assign axi_awaddr_o  = {awaddr_r[31:5], 5'b0};
assign axi_awlen_o   = 8'b0;
assign axi_awburst_o = 2'b01;

//--------------------------------------------------------------------
// Write data
//--------------------------------------------------------------------
reg         wvalid_r;
reg [255:0] wdata_r;
reg [31:0]  wstrb_r;
reg         wlast_r;

// Byte mask version
wire [31:0] gpu_write_strb_w;

assign gpu_write_strb_w[0] = mem_write_mask_i[0];
assign gpu_write_strb_w[1] = mem_write_mask_i[0];
assign gpu_write_strb_w[2] = mem_write_mask_i[1];
assign gpu_write_strb_w[3] = mem_write_mask_i[1];
assign gpu_write_strb_w[4] = mem_write_mask_i[2];
assign gpu_write_strb_w[5] = mem_write_mask_i[2];
assign gpu_write_strb_w[6] = mem_write_mask_i[3];
assign gpu_write_strb_w[7] = mem_write_mask_i[3];
assign gpu_write_strb_w[8] = mem_write_mask_i[4];
assign gpu_write_strb_w[9] = mem_write_mask_i[4];
assign gpu_write_strb_w[10] = mem_write_mask_i[5];
assign gpu_write_strb_w[11] = mem_write_mask_i[5];
assign gpu_write_strb_w[12] = mem_write_mask_i[6];
assign gpu_write_strb_w[13] = mem_write_mask_i[6];
assign gpu_write_strb_w[14] = mem_write_mask_i[7];
assign gpu_write_strb_w[15] = mem_write_mask_i[7];
assign gpu_write_strb_w[16] = mem_write_mask_i[8];
assign gpu_write_strb_w[17] = mem_write_mask_i[8];
assign gpu_write_strb_w[18] = mem_write_mask_i[9];
assign gpu_write_strb_w[19] = mem_write_mask_i[9];
assign gpu_write_strb_w[20] = mem_write_mask_i[10];
assign gpu_write_strb_w[21] = mem_write_mask_i[10];
assign gpu_write_strb_w[22] = mem_write_mask_i[11];
assign gpu_write_strb_w[23] = mem_write_mask_i[11];
assign gpu_write_strb_w[24] = mem_write_mask_i[12];
assign gpu_write_strb_w[25] = mem_write_mask_i[12];
assign gpu_write_strb_w[26] = mem_write_mask_i[13];
assign gpu_write_strb_w[27] = mem_write_mask_i[13];
assign gpu_write_strb_w[28] = mem_write_mask_i[14];
assign gpu_write_strb_w[29] = mem_write_mask_i[14];
assign gpu_write_strb_w[30] = mem_write_mask_i[15];
assign gpu_write_strb_w[31] = mem_write_mask_i[15];

always @ *
begin
    wvalid_r = mem_command_i & mem_write_i & ~mem_busy_o;
    wdata_r  = mem_data_out_i;
    wstrb_r  = gpu_write_strb_w;
end

assign axi_wvalid_o = wvalid_r & axi_awready_i;
assign axi_wdata_o  = wdata_r;
assign axi_wstrb_o  = wstrb_r;
assign axi_wlast_o  = 1'b1;

//-----------------------------------------------------------------
// Write response tracking
//-----------------------------------------------------------------
reg [15:0] pending_writes_q;

always @ (posedge clk_i )
if (rst_i)
    pending_writes_q <= 16'b0;
else if ((axi_awvalid_o && axi_awready_i) != (axi_bvalid_i && axi_bready_o))
begin
    if ((axi_awvalid_o && axi_awready_i))
        pending_writes_q <= pending_writes_q + 16'd1;
    else
        pending_writes_q <= pending_writes_q - 16'd1;
end

assign busy_o = |pending_writes_q;

//-----------------------------------------------------------------
// Debug
//-----------------------------------------------------------------
`ifdef verilator

reg [31:0] stats_slot_hit_q;

always @ (posedge clk_i )
if (rst_i)
    stats_slot_hit_q   <= 32'b0;
else if (state_q == STATE_SLOT_HIT)
    stats_slot_hit_q   <= stats_slot_hit_q + 32'd1;

reg [31:0] stats_read_reqs_q;

always @ (posedge clk_i )
if (rst_i)
    stats_read_reqs_q   <= 32'b0;
else if (axi_arvalid_o && axi_arready_i)
    stats_read_reqs_q   <= stats_read_reqs_q + 32'd1;

`endif

endmodule