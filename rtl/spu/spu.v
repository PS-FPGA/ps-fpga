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
module spu
(
    // Inputs
     input           clk_i
    ,input           rst_i
    ,input  [ 31:0]  cfg_addr_i
    ,input  [ 31:0]  cfg_data_wr_i
    ,input           cfg_stb_i
    ,input           cfg_cyc_i
    ,input  [  3:0]  cfg_sel_i
    ,input           cfg_we_i
    ,input           m2p_valid_i
    ,input  [ 31:0]  m2p_data_i
    ,input           p2m_accept_i

    // Outputs
    ,output [ 31:0]  cfg_data_rd_o
    ,output          cfg_stall_o
    ,output          cfg_ack_o
    ,output          cfg_err_o
    ,output          irq_o
    ,output          m2p_dreq_o
    ,output          m2p_accept_o
    ,output          p2m_dreq_o
    ,output          p2m_valid_o
    ,output [ 31:0]  p2m_data_o
);



//-------------------------------------------------------------------
// SPU Stub
// Consumes DMA data, responds to a few minimal register accesses
//-------------------------------------------------------------------
wire [12:0] reg_addr_w  = {cfg_addr_i[12:2], 2'b0};
wire        reg_write_w = cfg_stb_i && ~cfg_stall_o &&  cfg_we_i;
wire        reg_read_w  = cfg_stb_i && ~cfg_stall_o && ~cfg_we_i;

wire        addr_plus0_w = cfg_sel_i[0];
wire        addr_plus1_w = cfg_sel_i[1];
wire        addr_plus2_w = cfg_sel_i[2];
wire        addr_plus3_w = cfg_sel_i[3];

// 1F801DA6h - Sound RAM Data Transfer Address
wire addr_1F801DA6h_w = (reg_addr_w == 13'h1DA4) & (addr_plus2_w | addr_plus3_w);

// 1F801DAAh - SPU Control Register (SPUCNT)
wire addr_1F801DAAh_w = (reg_addr_w == 13'h1DA8) & (addr_plus2_w | addr_plus3_w);

// 1F801DACh - Sound RAM Data Transfer Control 
wire addr_1F801DACh_w = (reg_addr_w == 13'h1DAC) & (addr_plus0_w | addr_plus1_w);

// 1F801DAEh - SPU Status Register (SPUSTAT) (R)
wire addr_1F801DAEh_w = (reg_addr_w == 13'h1DAC) & (addr_plus2_w | addr_plus3_w);

//-------------------------------------------------------------------
// 1F801DA6h - Sound RAM Data Transfer Address
//-------------------------------------------------------------------
reg [15:0] spudataadr_q;

always @ (posedge clk_i )
if (rst_i)
    spudataadr_q <= 16'b0;
else if (cfg_stb_i && ~cfg_stall_o && cfg_we_i && addr_1F801DA6h_w)
begin
    spudataadr_q[7:0]  <= cfg_data_wr_i[23:16];
    spudataadr_q[15:8] <= cfg_data_wr_i[31:24];
end

//-------------------------------------------------------------------
// 1F801DAAh - SPU Control Register (SPUCNT)
//-------------------------------------------------------------------
reg [15:0] spucnt_q;

always @ (posedge clk_i )
if (rst_i)
    spucnt_q <= 16'b0;
else if (cfg_stb_i && ~cfg_stall_o && cfg_we_i && addr_1F801DAAh_w)
begin
    spucnt_q[7:0]  <= cfg_data_wr_i[23:16];
    spucnt_q[15:8] <= cfg_data_wr_i[31:24];
end

//-------------------------------------------------------------------
// 1F801DACh - Sound RAM Data Transfer Control 
//-------------------------------------------------------------------
reg [15:0] spu_dtc_q;

always @ (posedge clk_i )
if (rst_i)
    spu_dtc_q <= 16'b0;
else if (cfg_stb_i && ~cfg_stall_o && cfg_we_i && addr_1F801DACh_w)
begin
    spu_dtc_q[7:0]  <= cfg_data_wr_i[7:0];
    spu_dtc_q[15:8] <= cfg_data_wr_i[15:8];
end

//-------------------------------------------------------------------
// Read mux
//-------------------------------------------------------------------
reg [31:0] data_r;
always @ *
begin
    data_r = 32'h01010101;

    if (cfg_stb_i && ~cfg_stall_o && ~cfg_we_i)
    begin
        // 1F801DA6h - Sound RAM Data Transfer Address
        if (reg_addr_w == 13'h1DA4)
        begin
            data_r = 32'b0;
            data_r[15+16:0+16] = spudataadr_q;
        end
        // 1F801DAAh - SPU Control Register (SPUCNT)
        else if (reg_addr_w == 13'h1DA8)
        begin
            data_r = 32'b0;
            data_r[15+16:0+16] = spucnt_q;
        end
        else if (reg_addr_w == 13'h1DAC)
        begin
            data_r = 32'b0;

            // 1F801DACh - Sound RAM Data Transfer Control 
            data_r[15:0] = spu_dtc_q;

            // 1F801DAEh - SPU Status Register (SPUSTAT) (R)
            data_r[5+16:0+16] = spucnt_q[5:0];
        end
        // Current ADSR volume (voice 0)
        else if (reg_addr_w == 13'h1C0C)
        begin
            // HACK - 0 has some meaning to F1
            data_r = 32'b0;
        end
    end
end

reg [31:0] data_q;

always @ (posedge clk_i )
if (rst_i)
    data_q <= 32'b0;
else
    data_q <= data_r;

assign cfg_data_rd_o = data_q;

reg ack_q;

always @ (posedge clk_i )
if (rst_i)
    ack_q <= 1'b0;
else if (cfg_stb_i && ~cfg_stall_o)
    ack_q <= 1'b1;
else
    ack_q <= 1'b0;

assign cfg_ack_o     = ack_q;
assign cfg_err_o     = 1'b0;
assign cfg_stall_o   = ack_q;

//-------------------------------------------------------------------
// Combinatorial
//-------------------------------------------------------------------
assign p2m_dreq_o        = 1'b0;
assign p2m_valid_o       = 1'b0;
assign p2m_data_o        = 32'b0;

assign m2p_dreq_o        = 1'b1;
assign m2p_accept_o      = 1'b1;

assign irq_o             = 1'b0;

`ifdef verilator
always @ (posedge clk_i)
if (m2p_valid_i && m2p_accept_o)
begin
    $display("[SPU_M2P] %08x", m2p_data_i);
end
`endif

endmodule
