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
`include "irq_ctrl_defs.v"

//-----------------------------------------------------------------
// Module:  IRQ Controller
//-----------------------------------------------------------------
module irq_ctrl
(
    // Inputs
     input          clk_i
    ,input          rst_i
    ,input  [31:0]  cfg_addr_i
    ,input  [31:0]  cfg_data_wr_i
    ,input          cfg_stb_i
    ,input          cfg_we_i
    ,input          interrupt0_i
    ,input          interrupt1_i
    ,input          interrupt2_i
    ,input          interrupt3_i

    // Outputs
    ,output [31:0]  cfg_data_rd_o
    ,output         cfg_ack_o
    ,output         cfg_stall_o
    ,output         intr_o
);

wire read_en_w  = cfg_stb_i && ~cfg_we_i && ~cfg_stall_o;
wire write_en_w = cfg_stb_i &&  cfg_we_i && ~cfg_stall_o;

wire [7:0] wr_addr_w = cfg_addr_i[7:0];

assign cfg_stall_o  = cfg_ack_o;

//-----------------------------------------------------------------
// Write data
//-----------------------------------------------------------------
reg [31:0] wr_data_q;

always @ (posedge clk_i )
if (rst_i)
    wr_data_q <= 32'b0;
else if (write_en_w)
    wr_data_q <= cfg_data_wr_i;


//-----------------------------------------------------------------
// Register irq_isr
//-----------------------------------------------------------------
reg irq_isr_wr_q;

always @ (posedge clk_i )
if (rst_i)
    irq_isr_wr_q <= 1'b0;
else if (write_en_w && (wr_addr_w[7:0] == `IRQ_ISR))
    irq_isr_wr_q <= 1'b1;
else
    irq_isr_wr_q <= 1'b0;

// irq_isr_status [external]
wire [3:0]  irq_isr_status_out_w = wr_data_q[`IRQ_ISR_STATUS_R];


//-----------------------------------------------------------------
// Register irq_ipr
//-----------------------------------------------------------------
reg irq_ipr_wr_q;

always @ (posedge clk_i )
if (rst_i)
    irq_ipr_wr_q <= 1'b0;
else if (write_en_w && (wr_addr_w[7:0] == `IRQ_IPR))
    irq_ipr_wr_q <= 1'b1;
else
    irq_ipr_wr_q <= 1'b0;


//-----------------------------------------------------------------
// Register irq_ier
//-----------------------------------------------------------------
reg irq_ier_wr_q;

always @ (posedge clk_i )
if (rst_i)
    irq_ier_wr_q <= 1'b0;
else if (write_en_w && (wr_addr_w[7:0] == `IRQ_IER))
    irq_ier_wr_q <= 1'b1;
else
    irq_ier_wr_q <= 1'b0;

// irq_ier_enable [external]
wire [3:0]  irq_ier_enable_out_w = wr_data_q[`IRQ_IER_ENABLE_R];


//-----------------------------------------------------------------
// Register irq_iar
//-----------------------------------------------------------------
reg irq_iar_wr_q;

always @ (posedge clk_i )
if (rst_i)
    irq_iar_wr_q <= 1'b0;
else if (write_en_w && (wr_addr_w[7:0] == `IRQ_IAR))
    irq_iar_wr_q <= 1'b1;
else
    irq_iar_wr_q <= 1'b0;

// irq_iar_ack [auto_clr]
reg [3:0]  irq_iar_ack_q;

always @ (posedge clk_i )
if (rst_i)
    irq_iar_ack_q <= 4'd`IRQ_IAR_ACK_DEFAULT;
else if (write_en_w && (wr_addr_w[7:0] == `IRQ_IAR))
    irq_iar_ack_q <= cfg_data_wr_i[`IRQ_IAR_ACK_R];
else
    irq_iar_ack_q <= 4'd`IRQ_IAR_ACK_DEFAULT;

wire [3:0]  irq_iar_ack_out_w = irq_iar_ack_q;


//-----------------------------------------------------------------
// Register irq_sie
//-----------------------------------------------------------------
reg irq_sie_wr_q;

always @ (posedge clk_i )
if (rst_i)
    irq_sie_wr_q <= 1'b0;
else if (write_en_w && (wr_addr_w[7:0] == `IRQ_SIE))
    irq_sie_wr_q <= 1'b1;
else
    irq_sie_wr_q <= 1'b0;

// irq_sie_set [external]
wire [3:0]  irq_sie_set_out_w = wr_data_q[`IRQ_SIE_SET_R];


//-----------------------------------------------------------------
// Register irq_cie
//-----------------------------------------------------------------
reg irq_cie_wr_q;

always @ (posedge clk_i )
if (rst_i)
    irq_cie_wr_q <= 1'b0;
else if (write_en_w && (wr_addr_w[7:0] == `IRQ_CIE))
    irq_cie_wr_q <= 1'b1;
else
    irq_cie_wr_q <= 1'b0;

// irq_cie_clr [external]
wire [3:0]  irq_cie_clr_out_w = wr_data_q[`IRQ_CIE_CLR_R];


//-----------------------------------------------------------------
// Register irq_ivr
//-----------------------------------------------------------------
reg irq_ivr_wr_q;

always @ (posedge clk_i )
if (rst_i)
    irq_ivr_wr_q <= 1'b0;
else if (write_en_w && (wr_addr_w[7:0] == `IRQ_IVR))
    irq_ivr_wr_q <= 1'b1;
else
    irq_ivr_wr_q <= 1'b0;

// irq_ivr_vector [external]
wire [31:0]  irq_ivr_vector_out_w = wr_data_q[`IRQ_IVR_VECTOR_R];


//-----------------------------------------------------------------
// Register irq_mer
//-----------------------------------------------------------------
reg irq_mer_wr_q;

always @ (posedge clk_i )
if (rst_i)
    irq_mer_wr_q <= 1'b0;
else if (write_en_w && (wr_addr_w[7:0] == `IRQ_MER))
    irq_mer_wr_q <= 1'b1;
else
    irq_mer_wr_q <= 1'b0;

// irq_mer_me [internal]
reg        irq_mer_me_q;

always @ (posedge clk_i )
if (rst_i)
    irq_mer_me_q <= 1'd`IRQ_MER_ME_DEFAULT;
else if (write_en_w && (wr_addr_w[7:0] == `IRQ_MER))
    irq_mer_me_q <= cfg_data_wr_i[`IRQ_MER_ME_R];

wire        irq_mer_me_out_w = irq_mer_me_q;


wire [3:0]  irq_isr_status_in_w;
wire [3:0]  irq_ipr_pending_in_w;
wire [3:0]  irq_ier_enable_in_w;
wire [31:0]  irq_ivr_vector_in_w;


//-----------------------------------------------------------------
// Read mux
//-----------------------------------------------------------------
reg [31:0] data_r;

always @ *
begin
    data_r = 32'b0;

    case (cfg_addr_i[7:0])

    `IRQ_ISR:
    begin
        data_r[`IRQ_ISR_STATUS_R] = irq_isr_status_in_w;
    end
    `IRQ_IPR:
    begin
        data_r[`IRQ_IPR_PENDING_R] = irq_ipr_pending_in_w;
    end
    `IRQ_IER:
    begin
        data_r[`IRQ_IER_ENABLE_R] = irq_ier_enable_in_w;
    end
    `IRQ_IVR:
    begin
        data_r[`IRQ_IVR_VECTOR_R] = irq_ivr_vector_in_w;
    end
    `IRQ_MER:
    begin
        data_r[`IRQ_MER_ME_R] = irq_mer_me_q;
    end
    default :
        data_r = 32'b0;
    endcase
end

//-----------------------------------------------------------------
// ACK
//-----------------------------------------------------------------
reg ack_q;

always @ (posedge clk_i )
if (rst_i)
    ack_q <= 1'b0;
else
    ack_q <= read_en_w || write_en_w;

assign cfg_ack_o = ack_q;

//-----------------------------------------------------------------
// Read response
//-----------------------------------------------------------------
reg [31:0] rd_data_q;

always @ (posedge clk_i )
if (rst_i)
    rd_data_q <= 32'b0;
else if (read_en_w)
    rd_data_q <= data_r;

assign cfg_data_rd_o = rd_data_q;


wire irq_isr_wr_req_w = irq_isr_wr_q;
wire irq_ier_wr_req_w = irq_ier_wr_q;
wire irq_sie_wr_req_w = irq_sie_wr_q;
wire irq_cie_wr_req_w = irq_cie_wr_q;
wire irq_ivr_wr_req_w = irq_ivr_wr_q;

wire [3:0] irq_input_w;

irq_ctrl_resync
u_irq0_sync
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.async_i(interrupt0_i)
    ,.sync_o(irq_input_w[0])
);

irq_ctrl_resync
u_irq1_sync
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.async_i(interrupt1_i)
    ,.sync_o(irq_input_w[1])
);

irq_ctrl_resync
u_irq2_sync
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.async_i(interrupt2_i)
    ,.sync_o(irq_input_w[2])
);

irq_ctrl_resync
u_irq3_sync
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.async_i(interrupt3_i)
    ,.sync_o(irq_input_w[3])
);


//-----------------------------------------------------------------
// IRQ Enable
//-----------------------------------------------------------------
reg [3:0] irq_enable_q;

always @ (posedge clk_i )
if (rst_i)
    irq_enable_q <= 4'b0;
else if (irq_ier_wr_req_w)
    irq_enable_q <= irq_ier_enable_out_w;
else if (irq_sie_wr_req_w)
    irq_enable_q <= irq_enable_q | irq_sie_set_out_w;
else if (irq_cie_wr_req_w)
    irq_enable_q <= irq_enable_q & ~irq_cie_clr_out_w;

assign irq_ier_enable_in_w = irq_enable_q;

//-----------------------------------------------------------------
// IRQ Pending
//-----------------------------------------------------------------
reg [3:0] irq_pending_q;

wire [3:0] irq_sw_int_w = {4{irq_isr_wr_req_w}} & irq_isr_status_out_w;

always @ (posedge clk_i )
if (rst_i)
    irq_pending_q <= 4'b0;
else
    irq_pending_q <= irq_input_w | irq_sw_int_w | (irq_pending_q & ~irq_iar_ack_out_w);

assign irq_isr_status_in_w  = irq_pending_q;
assign irq_ipr_pending_in_w = irq_pending_q & irq_enable_q;

//-----------------------------------------------------------------
// IRQ Vector
//-----------------------------------------------------------------
reg [31:0] ivr_vector_r;
always @ *
begin
    ivr_vector_r = 32'hffffffff;

    if (irq_ipr_pending_in_w[0])
        ivr_vector_r = 32'd0;
    else
    if (irq_ipr_pending_in_w[1])
        ivr_vector_r = 32'd1;
    else
    if (irq_ipr_pending_in_w[2])
        ivr_vector_r = 32'd2;
    else
    if (irq_ipr_pending_in_w[3])
        ivr_vector_r = 32'd3;
    else
        ivr_vector_r = 32'hffffffff;
end

assign irq_ivr_vector_in_w = ivr_vector_r;

//-----------------------------------------------------------------
// IRQ output
//-----------------------------------------------------------------
reg intr_q;

always @ (posedge clk_i )
if (rst_i)
    intr_q <= 1'b0;
else
    intr_q <= irq_mer_me_out_w ? (|irq_ipr_pending_in_w) : 1'b0;

//-----------------------------------------------------------------
// Assignments
//-----------------------------------------------------------------
assign intr_o = intr_q;

endmodule

module irq_ctrl_resync
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
    parameter RESET_VAL = 1'b0
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(
    input  clk_i,
    input  rst_i,
    input  async_i,
    output sync_o
);

reg sync_ms;
reg sync_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
begin
    sync_ms  <= RESET_VAL;
    sync_q   <= RESET_VAL;
end
else
begin
    sync_ms  <= async_i;
    sync_q   <= sync_ms;
end

assign sync_o = sync_q;



endmodule
