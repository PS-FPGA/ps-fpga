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
module axi4_wb_tap
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
     parameter WB_PORT_ADDR0    = 32'h1f801000
    ,parameter WB_PORT_ADDR1    = 32'h1f802000
    ,parameter WB_PORT_MASK     = 32'h1ffff000
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(
    // Inputs
     input           clk_i
    ,input           rst_i
    ,input           inhibit_i
    ,input           inport_awvalid_i
    ,input  [ 31:0]  inport_awaddr_i
    ,input  [  3:0]  inport_awid_i
    ,input  [  7:0]  inport_awlen_i
    ,input  [  1:0]  inport_awburst_i
    ,input  [  2:0]  inport_awsize_i
    ,input           inport_wvalid_i
    ,input  [ 31:0]  inport_wdata_i
    ,input  [  3:0]  inport_wstrb_i
    ,input           inport_wlast_i
    ,input           inport_bready_i
    ,input           inport_arvalid_i
    ,input  [ 31:0]  inport_araddr_i
    ,input  [  3:0]  inport_arid_i
    ,input  [  7:0]  inport_arlen_i
    ,input  [  1:0]  inport_arburst_i
    ,input  [  2:0]  inport_arsize_i
    ,input           inport_rready_i
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
    ,input  [ 31:0]  outport_wb_data_rd_i
    ,input           outport_wb_stall_i
    ,input           outport_wb_ack_i
    ,input           outport_wb_err_i

    // Outputs
    ,output          inport_awready_o
    ,output          inport_wready_o
    ,output          inport_bvalid_o
    ,output [  1:0]  inport_bresp_o
    ,output [  3:0]  inport_bid_o
    ,output          inport_arready_o
    ,output          inport_rvalid_o
    ,output [ 31:0]  inport_rdata_o
    ,output [  1:0]  inport_rresp_o
    ,output [  3:0]  inport_rid_o
    ,output          inport_rlast_o
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
    ,output [ 31:0]  outport_wb_addr_o
    ,output [ 31:0]  outport_wb_data_wr_o
    ,output          outport_wb_stb_o
    ,output          outport_wb_cyc_o
    ,output [  3:0]  outport_wb_sel_o
    ,output          outport_wb_we_o
);



wire write_in_prog_w;

//-----------------------------------------------------------------
// Write tracking
//-----------------------------------------------------------------
reg mid_write_q;
reg mid_write_r;

always @ *
begin
    mid_write_r = mid_write_q;

    if (inport_wvalid_i && inport_wlast_i && inport_wready_o)
        mid_write_r = 1'b0;
    else if (inport_awvalid_i && (!inport_awready_o || !inport_wlast_i || !inport_wvalid_i || !inport_wready_o))
        mid_write_r = 1'b1;
end

always @ (posedge clk_i )
if (rst_i)
    mid_write_q <= 1'b0;
else
    mid_write_q <= mid_write_r;

//-----------------------------------------------------------------
// Inhibit - change on clean boundaries
//-----------------------------------------------------------------
reg inhibit_q;

always @ (posedge clk_i )
if (rst_i)
    inhibit_q <= 1'b0;
else if (!inhibit_i)
    inhibit_q <= 1'b0;
else if ((!inport_arvalid_i || inport_arready_o) && (!mid_write_r))
    inhibit_q <= inhibit_i;

//-----------------------------------------------------------------
// AXI: Read
//-----------------------------------------------------------------
reg [3:0] read_pending_q;
reg [3:0] read_pending_r;
reg [3:0] arid_q;
reg       read_port_q;
reg       read_port_r;

always @ *
begin
    read_port_r = 1'b0;

    if (((inport_araddr_i & WB_PORT_MASK) == WB_PORT_ADDR0) || ((inport_araddr_i & WB_PORT_MASK) == WB_PORT_ADDR1))
        read_port_r = 1'b1;
end

wire read_incr_w = (inport_arvalid_i && inport_arready_o);
wire read_decr_w = (inport_rvalid_o  && inport_rlast_o && inport_rready_i);

always @ *
begin
    read_pending_r = read_pending_q;

    if (read_incr_w && !read_decr_w)
        read_pending_r = read_pending_r + 4'd1;
    else if (!read_incr_w && read_decr_w)
        read_pending_r = read_pending_r - 4'd1;
end

always @ (posedge clk_i )
if (rst_i)
begin
    read_pending_q <= 4'b0;
    arid_q         <= 4'b0;
    read_port_q    <= 1'b0;
end
else 
begin
    read_pending_q <= read_pending_r;

    // Read command accepted
    if (inport_arvalid_i && inport_arready_o)
    begin
        arid_q      <= inport_arid_i;
        read_port_q <= read_port_r;
    end
end

wire read_accept_w       = ((read_port_q == read_port_r && read_pending_q != 4'hF) || (read_pending_q == 4'h0) && ~write_in_prog_w) && ~inhibit_q;

assign outport_arvalid_o = inport_arvalid_i & read_accept_w & ~read_port_r;
assign outport_araddr_o  = {inport_araddr_i[31:2], 2'b0};
assign outport_arid_o    = inport_arid_i;
assign outport_arlen_o   = inport_arlen_i;
assign outport_arburst_o = inport_arburst_i;
assign outport_rready_o  = inport_rready_i;

reg        outport_rvalid_r;
reg [31:0] outport_rdata_r;
reg [1:0]  outport_rresp_r;
reg [3:0]  outport_rid_r;
reg        outport_rlast_r;

always @ *
begin
    case (read_port_q)
    1'b1:
    begin
        outport_rvalid_r = (outport_wb_err_i | outport_wb_ack_i) & (|read_pending_q);
        outport_rdata_r  = outport_wb_data_rd_i;
        outport_rresp_r  = outport_wb_err_i ? 2'b01 : 2'b00;
        outport_rid_r    = arid_q;
        outport_rlast_r  = 1'b1;
    end
    default:
    begin
        outport_rvalid_r = outport_rvalid_i;
        outport_rdata_r  = outport_rdata_i;
        outport_rresp_r  = outport_rresp_i;
        outport_rid_r    = outport_rid_i;
        outport_rlast_r  = outport_rlast_i;
    end
    endcase
end

assign inport_rvalid_o  = outport_rvalid_r;
assign inport_rdata_o   = outport_rdata_r;
assign inport_rresp_o   = outport_rresp_r;
assign inport_rid_o     = outport_rid_r;
assign inport_rlast_o   = outport_rlast_r;

reg inport_arready_r;
always @ *
begin
    case (read_port_r)
    1'b1:
        inport_arready_r = ~outport_wb_stall_i;
    default:
        inport_arready_r = outport_arready_i;
    endcase
end

assign inport_arready_o = read_accept_w & inport_arready_r;

//-------------------------------------------------------------
// Write Request
//-------------------------------------------------------------
reg awvalid_q;
reg wvalid_q;
reg wlast_q;

wire wr_cmd_accepted_w  = (inport_awvalid_i && inport_awready_o) || awvalid_q;
wire wr_data_accepted_w = (inport_wvalid_i  && inport_wready_o)  || wvalid_q;
wire wr_data_last_w     = (wvalid_q & wlast_q) || (inport_wvalid_i && inport_wready_o && inport_wlast_i);

always @ (posedge clk_i )
if (rst_i)
    awvalid_q <= 1'b0;
else if (inport_awvalid_i && inport_awready_o && (!wr_data_accepted_w || !wr_data_last_w))
    awvalid_q <= 1'b1;
else if (wr_data_accepted_w && wr_data_last_w)
    awvalid_q <= 1'b0;

always @ (posedge clk_i )
if (rst_i)
    wvalid_q <= 1'b0;
else if (inport_wvalid_i && inport_wready_o && !wr_cmd_accepted_w)
    wvalid_q <= 1'b1;
else if (wr_cmd_accepted_w)
    wvalid_q <= 1'b0;

always @ (posedge clk_i )
if (rst_i)
    wlast_q <= 1'b0;
else if (inport_wvalid_i && inport_wready_o)
    wlast_q <= inport_wlast_i;

assign write_in_prog_w = inport_awvalid_i || awvalid_q || inport_wvalid_i || wvalid_q;

//-----------------------------------------------------------------
// AXI: Write
//-----------------------------------------------------------------
reg [3:0] write_pending_q;
reg [3:0] write_pending_r;
reg [3:0] awid_q;
reg       write_port_q;
reg       write_port_r;

always @ *
begin    
    if (inport_awvalid_i & ~awvalid_q)
    begin
        write_port_r = 1'b0;
        if (((inport_awaddr_i & WB_PORT_MASK) == WB_PORT_ADDR0) || ((inport_awaddr_i & WB_PORT_MASK) == WB_PORT_ADDR1))
            write_port_r = 1'b1;
    end
    else
        write_port_r = write_port_q;
end

wire write_incr_w = (inport_awvalid_i && inport_awready_o);
wire write_decr_w = (inport_bvalid_o  && inport_bready_i);

always @ *
begin
    write_pending_r = write_pending_q;

    if (write_incr_w && !write_decr_w)
        write_pending_r = write_pending_r + 4'd1;
    else if (!write_incr_w && write_decr_w)
        write_pending_r = write_pending_r - 4'd1;
end

always @ (posedge clk_i )
if (rst_i)
begin
    write_pending_q <= 4'b0;
    awid_q          <= 4'b0;
    write_port_q    <= 1'b0;
end
else 
begin
    write_pending_q <= write_pending_r;

    // Write command accepted
    if (inport_awvalid_i && inport_awready_o)
    begin
        awid_q       <= inport_awid_i;
        write_port_q <= write_port_r;
    end
end

wire write_accept_w      = ((write_port_q == write_port_r && write_pending_q != 4'hF) || (write_pending_q == 4'h0)) && ~inhibit_q;

assign outport_awvalid_o = inport_awvalid_i & ~awvalid_q & write_accept_w & ~write_port_r;
assign outport_awaddr_o  = {inport_awaddr_i[31:2], 2'b0};
assign outport_awid_o    = inport_awid_i;
assign outport_awlen_o   = inport_awlen_i;
assign outport_awburst_o = inport_awburst_i;
assign outport_wvalid_o  = inport_wvalid_i & ~wvalid_q & (inport_awvalid_i || awvalid_q) & ~write_port_r;
assign outport_wdata_o   = inport_wdata_i;
assign outport_wstrb_o   = inport_wstrb_i;
assign outport_wlast_o   = inport_wlast_i;
assign outport_bready_o  = inport_bready_i;

assign outport_wb_stb_o     = (inport_awvalid_i & write_accept_w & write_port_r) | (inport_arvalid_i & read_accept_w & read_port_r);
assign outport_wb_addr_o    = inport_awvalid_i ? inport_awaddr_i : inport_araddr_i;
assign outport_wb_we_o      = inport_awvalid_i;
assign outport_wb_data_wr_o = inport_wdata_i;

reg [3:0] wb_sel_r;

always @ *
begin
    wb_sel_r = 4'hF;

    // Read - adjust byte enables to match width of access (for narrow reads)
    if (!outport_wb_we_o)
    begin
        // Byte
        if (inport_arsize_i == 3'd0)
        begin
            case (inport_araddr_i[1:0])
            2'd0:    wb_sel_r = 4'h1;
            2'd1:    wb_sel_r = 4'h2;
            2'd2:    wb_sel_r = 4'h4;
            default: wb_sel_r = 4'h8;
            endcase
        end
        // Half
        else if (inport_arsize_i == 3'd1)
        begin
            if (inport_araddr_i[1])
                wb_sel_r = 4'hC;
            else
                wb_sel_r = 4'h3;
        end
    end
    // Write
    else
        wb_sel_r = inport_wstrb_i;
end

assign outport_wb_sel_o     = wb_sel_r;

reg wb_cyc_q;

always @ (posedge clk_i )
if (rst_i)
    wb_cyc_q <= 1'b0;
else if (outport_wb_stb_o)
    wb_cyc_q <= 1'b1;
else if (outport_wb_err_i | outport_wb_ack_i)
    wb_cyc_q <= 1'b0;

assign outport_wb_cyc_o = outport_wb_stb_o | wb_cyc_q;

reg        outport_bvalid_r;
reg [1:0]  outport_bresp_r;
reg [3:0]  outport_bid_r;

always @ *
begin
    case (write_port_q)
    1'b1:
    begin
        outport_bvalid_r = (outport_wb_err_i | outport_wb_ack_i) & (|write_pending_q);
        outport_bresp_r  = outport_wb_err_i ? 2'b01 : 2'b00;
        outport_bid_r    = awid_q;
    end
    default:
    begin
        outport_bvalid_r = outport_bvalid_i;
        outport_bresp_r  = outport_bresp_i;
        outport_bid_r    = outport_bid_i;
    end
    endcase
end

assign inport_bvalid_o  = outport_bvalid_r;
assign inport_bresp_o   = outport_bresp_r;
assign inport_bid_o     = outport_bid_r;

reg inport_awready_r;
reg inport_wready_r;

always @ *
begin
    case (write_port_r)
    1'd1:
    begin
        inport_awready_r = ~outport_wb_stall_i;
        inport_wready_r  = ~outport_wb_stall_i;
    end
    default:
    begin
        inport_awready_r = outport_awready_i;
        inport_wready_r  = outport_wready_i;
    end        
    endcase
end

assign inport_awready_o = write_accept_w & ~awvalid_q & inport_awready_r;
assign inport_wready_o  = write_accept_w & ~wvalid_q & inport_wready_r;

//-----------------------------------------------------------------
// Stats
//-----------------------------------------------------------------
`ifdef verilator
reg [31:0] stats_inhibit_stalls_q;

always @ (posedge clk_i )
if (rst_i)
    stats_inhibit_stalls_q   <= 32'b0;
else if ((inport_arvalid_i || inport_awvalid_i) && inhibit_q)
    stats_inhibit_stalls_q   <= stats_inhibit_stalls_q + 32'd1;

`endif


endmodule
