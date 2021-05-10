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
`include "cdrom_int_regs_defs.v"

//-----------------------------------------------------------------
// Module:  
//-----------------------------------------------------------------
module cdrom_int_regs
(
    // Inputs
     input          clk_i
    ,input          rst_i
    ,input  [31:0]  cfg_addr_i
    ,input  [31:0]  cfg_data_wr_i
    ,input          cfg_stb_i
    ,input          cfg_we_i

    ,input         command_valid_i
    ,input [7:0]   command_data_i

    ,input [7:0]   param_data_i
    ,input         param_valid_i
    ,input [7:0]   vol_audl_cdl_i
    ,input [7:0]   vol_audl_cdr_i
    ,input [7:0]   vol_audr_cdl_i
    ,input [7:0]   vol_audr_cdr_i
    ,input         status_adpmute_i
    ,input         status_smen_i
    ,input         status_bfwr_i
    ,input         status_bfrd_i
    ,input [7:0]   status_intf_i
    ,input         event_command_wr_i
    ,input         event_param_wr_i
    ,input         event_request_wr_i
    ,input         event_vol_apply_i
    ,input         event_snd_map_dat_wr_i
    ,input         event_snd_map_cdi_wr_i
    ,input         event_bfrd_rise_i
    ,input         fifo_status_param_empty_i
    ,input         fifo_status_param_full_i
    ,input         fifo_status_response_empty_i
    ,input         fifo_status_response_full_i
    ,input         fifo_status_data_empty_i
    ,input         fifo_status_data_full_i
    ,input         fifo_status_data_half_i
    ,input [7:0]   fifo_level_param_i
    ,input [7:0]   fifo_level_response_i
    ,input [15:0]  fifo_level_data_i
    ,input [3:0]   dma_status_level_i
    ,input [31:0]  dma_fifo_data_i
    ,input         dma_fetch_accept_i
    ,input  [31:0] gpio_i

    // Outputs
    ,output [31:0]  cfg_data_rd_o
    ,output         cfg_ack_o
    ,output         cfg_stall_o

    ,output         command_rd_o
    ,output         param_rd_o

    ,output         response_wr_o
    ,output [7:0]   response_data_o

    ,output         data_wr_o
    ,output [31:0]  data_data_o

    ,output         dma_dreq_inhibit_o
    ,output         bfrd_clear_inhibit_o

    ,output [7:0]   int_raise_o

    ,output         clear_busy_o
    ,output         clear_param_fifo_o
    ,output         clear_resp_fifo_o
    ,output         clear_data_fifo_o
    ,output         clear_cdrom_o

    ,output [31:0]  gpio_o

    ,output         dma_fetch_o
    ,output [31:0]  dma_fetch_addr_o
    ,output         dma_fifo_pop_o

    ,output [31:0]  debug0_o
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
// Register intcpu_response
//-----------------------------------------------------------------
reg intcpu_response_wr_q;

always @ (posedge clk_i )
if (rst_i)
    intcpu_response_wr_q <= 1'b0;
else if (write_en_w && (wr_addr_w[7:0] == `INTCPU_RESPONSE))
    intcpu_response_wr_q <= 1'b1;
else
    intcpu_response_wr_q <= 1'b0;

// intcpu_response_data [external]
wire [7:0]  intcpu_response_data_out_w = wr_data_q[`INTCPU_RESPONSE_DATA_R];

//-----------------------------------------------------------------
// Register intcpu_data
//-----------------------------------------------------------------
reg intcpu_data_wr_q;

always @ (posedge clk_i )
if (rst_i)
    intcpu_data_wr_q <= 1'b0;
else if (write_en_w && (wr_addr_w[7:0] == `INTCPU_DATA))
    intcpu_data_wr_q <= 1'b1;
else
    intcpu_data_wr_q <= 1'b0;

// intcpu_data_data [external]
wire [31:0]  intcpu_data_data_out_w = wr_data_q[`INTCPU_DATA_DATA_R];

//-----------------------------------------------------------------
// Register intcpu_misc_ctrl
//-----------------------------------------------------------------
// intcpu_misc_ctrl_dma_dreq_inhibit [internal]
reg        intcpu_misc_ctrl_dma_dreq_inhibit_q;

always @ (posedge clk_i )
if (rst_i)
    intcpu_misc_ctrl_dma_dreq_inhibit_q <= 1'd`INTCPU_MISC_CTRL_DMA_DREQ_INHIBIT_DEFAULT;
else if (write_en_w && (wr_addr_w[7:0] == `INTCPU_MISC_CTRL))
    intcpu_misc_ctrl_dma_dreq_inhibit_q <= cfg_data_wr_i[`INTCPU_MISC_CTRL_DMA_DREQ_INHIBIT_R];

wire        intcpu_misc_ctrl_dma_dreq_inhibit_out_w = intcpu_misc_ctrl_dma_dreq_inhibit_q;

// intcpu_misc_ctrl_bfrd_clear_inhibit [internal]
reg        intcpu_misc_ctrl_bfrd_clear_inhibit_q;

always @ (posedge clk_i )
if (rst_i)
    intcpu_misc_ctrl_bfrd_clear_inhibit_q <= 1'd`INTCPU_MISC_CTRL_BFRD_CLEAR_INHIBIT_DEFAULT;
else if (write_en_w && (wr_addr_w[7:0] == `INTCPU_MISC_CTRL))
    intcpu_misc_ctrl_bfrd_clear_inhibit_q <= cfg_data_wr_i[`INTCPU_MISC_CTRL_BFRD_CLEAR_INHIBIT_R];

wire        intcpu_misc_ctrl_bfrd_clear_inhibit_out_w = intcpu_misc_ctrl_bfrd_clear_inhibit_q;

//-----------------------------------------------------------------
// Register intcpu_event
//-----------------------------------------------------------------
reg event_command_wr_q;
reg event_param_wr_q;
reg event_request_wr_q;
reg event_vol_apply_q;
reg event_snd_map_dat_wr_q;
reg event_snd_map_cdi_wr_q;
reg event_bfrd_rise_q;

always @ (posedge clk_i )
if (rst_i)
    event_command_wr_q <= 1'b0;
else if (read_en_w && (cfg_addr_i[7:0] == `INTCPU_EVENT))
    event_command_wr_q <= event_command_wr_i;
else
    event_command_wr_q <= event_command_wr_q | event_command_wr_i;

always @ (posedge clk_i )
if (rst_i)
    event_param_wr_q <= 1'b0;
else if (read_en_w && (cfg_addr_i[7:0] == `INTCPU_EVENT))
    event_param_wr_q <= event_param_wr_i;
else
    event_param_wr_q <= event_param_wr_q | event_param_wr_i;

always @ (posedge clk_i )
if (rst_i)
    event_request_wr_q <= 1'b0;
else if (read_en_w && (cfg_addr_i[7:0] == `INTCPU_EVENT))
    event_request_wr_q <= event_request_wr_i;
else
    event_request_wr_q <= event_request_wr_q | event_request_wr_i;

always @ (posedge clk_i )
if (rst_i)
    event_vol_apply_q <= 1'b0;
else if (read_en_w && (cfg_addr_i[7:0] == `INTCPU_EVENT))
    event_vol_apply_q <= event_vol_apply_i;
else
    event_vol_apply_q <= event_vol_apply_q | event_vol_apply_i;

always @ (posedge clk_i )
if (rst_i)
    event_snd_map_dat_wr_q <= 1'b0;
else if (read_en_w && (cfg_addr_i[7:0] == `INTCPU_EVENT))
    event_snd_map_dat_wr_q <= event_snd_map_dat_wr_i;
else
    event_snd_map_dat_wr_q <= event_snd_map_dat_wr_q | event_snd_map_dat_wr_i;

always @ (posedge clk_i )
if (rst_i)
    event_snd_map_cdi_wr_q <= 1'b0;
else if (read_en_w && (cfg_addr_i[7:0] == `INTCPU_EVENT))
    event_snd_map_cdi_wr_q <= event_snd_map_cdi_wr_i;
else
    event_snd_map_cdi_wr_q <= event_snd_map_cdi_wr_q | event_snd_map_cdi_wr_i;

always @ (posedge clk_i )
if (rst_i)
    event_bfrd_rise_q <= 1'b0;
else if (read_en_w && (cfg_addr_i[7:0] == `INTCPU_EVENT))
    event_bfrd_rise_q <= event_bfrd_rise_i;
else
    event_bfrd_rise_q <= event_bfrd_rise_q | event_bfrd_rise_i;

//-----------------------------------------------------------------
// Register intcpu_raise
//-----------------------------------------------------------------
reg intcpu_raise_wr_q;

always @ (posedge clk_i )
if (rst_i)
    intcpu_raise_wr_q <= 1'b0;
else if (write_en_w && (wr_addr_w[7:0] == `INTCPU_RAISE))
    intcpu_raise_wr_q <= 1'b1;
else
    intcpu_raise_wr_q <= 1'b0;

// intcpu_raise_int_sts [auto_clr]
reg [7:0]  intcpu_raise_int_sts_q;

always @ (posedge clk_i )
if (rst_i)
    intcpu_raise_int_sts_q <= 8'd`INTCPU_RAISE_INT_STS_DEFAULT;
else if (write_en_w && (wr_addr_w[7:0] == `INTCPU_RAISE))
    intcpu_raise_int_sts_q <= cfg_data_wr_i[`INTCPU_RAISE_INT_STS_R];
else
    intcpu_raise_int_sts_q <= 8'd`INTCPU_RAISE_INT_STS_DEFAULT;

wire [7:0]  intcpu_raise_int_sts_out_w = intcpu_raise_int_sts_q;

//-----------------------------------------------------------------
// Register intcpu_reset_busy
//-----------------------------------------------------------------
// intcpu_reset_busy_clr [auto_clr]
reg intcpu_reset_busy_clr_q;

always @ (posedge clk_i )
if (rst_i)
    intcpu_reset_busy_clr_q <= 1'd`INTCPU_RESET_BUSY_CLR_DEFAULT;
else if (write_en_w && (wr_addr_w[7:0] == `INTCPU_RESET))
    intcpu_reset_busy_clr_q <= cfg_data_wr_i[`INTCPU_RESET_BUSY_CLR_R];
else
    intcpu_reset_busy_clr_q <= 1'd`INTCPU_RESET_BUSY_CLR_DEFAULT;

//-----------------------------------------------------------------
// Register intcpu_reset_busy
//-----------------------------------------------------------------
// intcpu_reset_param_fifo [auto_clr]
reg intcpu_reset_param_fifo_q;

always @ (posedge clk_i )
if (rst_i)
    intcpu_reset_param_fifo_q <= 1'd`INTCPU_RESET_PARAM_FIFO_DEFAULT;
else if (write_en_w && (wr_addr_w[7:0] == `INTCPU_RESET))
    intcpu_reset_param_fifo_q <= cfg_data_wr_i[`INTCPU_RESET_PARAM_FIFO_R];
else
    intcpu_reset_param_fifo_q <= 1'd`INTCPU_RESET_PARAM_FIFO_DEFAULT;

//-----------------------------------------------------------------
// Register intcpu_reset_busy
//-----------------------------------------------------------------
// intcpu_reset_resp_fifo [auto_clr]
reg intcpu_reset_resp_fifo_q;

always @ (posedge clk_i )
if (rst_i)
    intcpu_reset_resp_fifo_q <= 1'd`INTCPU_RESET_RESP_FIFO_DEFAULT;
else if (write_en_w && (wr_addr_w[7:0] == `INTCPU_RESET))
    intcpu_reset_resp_fifo_q <= cfg_data_wr_i[`INTCPU_RESET_RESP_FIFO_R];
else
    intcpu_reset_resp_fifo_q <= 1'd`INTCPU_RESET_RESP_FIFO_DEFAULT;

//-----------------------------------------------------------------
// Register intcpu_reset_busy
//-----------------------------------------------------------------
// intcpu_reset_data_fifo [auto_clr]
reg intcpu_reset_data_fifo_q;

always @ (posedge clk_i )
if (rst_i)
    intcpu_reset_data_fifo_q <= 1'd`INTCPU_RESET_DATA_FIFO_DEFAULT;
else if (write_en_w && (wr_addr_w[7:0] == `INTCPU_RESET))
    intcpu_reset_data_fifo_q <= cfg_data_wr_i[`INTCPU_RESET_DATA_FIFO_R];
else
    intcpu_reset_data_fifo_q <= 1'd`INTCPU_RESET_DATA_FIFO_DEFAULT;

//-----------------------------------------------------------------
// Register intcpu_reset_busy
//-----------------------------------------------------------------
// intcpu_reset_cdrom [auto_clr]
reg intcpu_reset_cdrom_q;

always @ (posedge clk_i )
if (rst_i)
    intcpu_reset_cdrom_q <= 1'd`INTCPU_RESET_CDROM_DEFAULT;
else if (write_en_w && (wr_addr_w[7:0] == `INTCPU_RESET))
    intcpu_reset_cdrom_q <= cfg_data_wr_i[`INTCPU_RESET_CDROM_R];
else
    intcpu_reset_cdrom_q <= 1'd`INTCPU_RESET_CDROM_DEFAULT;


assign clear_busy_o       = intcpu_reset_busy_clr_q;
assign clear_param_fifo_o = intcpu_reset_param_fifo_q;
assign clear_resp_fifo_o  = intcpu_reset_resp_fifo_q;
assign clear_data_fifo_o  = intcpu_reset_data_fifo_q;
assign clear_cdrom_o      = intcpu_reset_cdrom_q;

//-----------------------------------------------------------------
// Register intcpu_gpio
//-----------------------------------------------------------------
// intcpu_gpio_output_q [internal]
reg [31:0] intcpu_gpio_output_q;

always @ (posedge clk_i )
if (rst_i)
    intcpu_gpio_output_q <= 32'd`INTCPU_GPIO_OUTPUT_DEFAULT;
else if (write_en_w && (wr_addr_w[7:0] == `INTCPU_GPIO))
    intcpu_gpio_output_q <= cfg_data_wr_i[`INTCPU_GPIO_OUTPUT_R];

wire [31:0] intcpu_gpio_output_out_w = intcpu_gpio_output_q;

//-----------------------------------------------------------------
// Register intcpu_debug0
//-----------------------------------------------------------------
// intcpu_debug0_q [internal]
reg [31:0] intcpu_debug0_q;

always @ (posedge clk_i )
if (rst_i)
    intcpu_debug0_q <= 32'd`INTCPU_DEBUG0_OUTPUT_DEFAULT;
else if (write_en_w && (wr_addr_w[7:0] == `INTCPU_DEBUG0))
    intcpu_debug0_q <= cfg_data_wr_i[`INTCPU_DEBUG0_OUTPUT_R];

assign debug0_o = intcpu_debug0_q;

//-----------------------------------------------------------------
// Register dma_fetch
//-----------------------------------------------------------------
reg dma_fetch_q;

always @ (posedge clk_i )
if (rst_i)
    dma_fetch_q <= 1'b0;
else if (write_en_w && (wr_addr_w[7:0] == `INTCPU_DMA_FETCH))
    dma_fetch_q <= 1'b1;
else if (dma_fetch_accept_i)
    dma_fetch_q <= 1'b0;

assign dma_fetch_o      = dma_fetch_q;

//-----------------------------------------------------------------
// Register dma_fetch_addr
//-----------------------------------------------------------------
reg [31:0] dma_fetch_addr_q;

always @ (posedge clk_i )
if (rst_i)
    dma_fetch_addr_q <= 32'b0;
else if (write_en_w && (wr_addr_w[7:0] == `INTCPU_DMA_FETCH))
    dma_fetch_addr_q <= cfg_data_wr_i[`INTCPU_DMA_FETCH_ADDR_R];

assign dma_fetch_addr_o = {dma_fetch_addr_q[31:2], 2'b0};

assign dma_fifo_pop_o = read_en_w & (cfg_addr_i[7:0] == `INTCPU_DMA_FIFO);

//-----------------------------------------------------------------
// Read mux
//-----------------------------------------------------------------
reg [31:0] data_r;

always @ *
begin
    data_r = 32'b0;

    case (cfg_addr_i[7:0])

    `INTCPU_COMMAND:
    begin
        data_r[`INTCPU_COMMAND_DATA_R] = command_data_i;
        data_r[`INTCPU_COMMAND_VALID_R] = command_valid_i;
    end
    `INTCPU_PARAM:
    begin
        data_r[`INTCPU_PARAM_DATA_R] = param_data_i;
        data_r[`INTCPU_PARAM_VALID_R] = param_valid_i;
    end
    `INTCPU_VOL:
    begin
        data_r[`INTCPU_VOL_AUDL_CDL_R] = vol_audl_cdl_i;
        data_r[`INTCPU_VOL_AUDL_CDR_R] = vol_audl_cdr_i;
        data_r[`INTCPU_VOL_AUDR_CDL_R] = vol_audr_cdl_i;
        data_r[`INTCPU_VOL_AUDR_CDR_R] = vol_audr_cdr_i;
    end
    `INTCPU_MISC_STATUS:
    begin
        data_r[`INTCPU_MISC_STATUS_ADPMUTE_R] = status_adpmute_i;
        data_r[`INTCPU_MISC_STATUS_SMEN_R] = status_smen_i;
        data_r[`INTCPU_MISC_STATUS_BFWR_R] = status_bfwr_i;
        data_r[`INTCPU_MISC_STATUS_BFRD_R] = status_bfrd_i;
        data_r[`INTCPU_MISC_STATUS_INTF_R] = status_intf_i;
    end
    `INTCPU_MISC_CTRL:
    begin
        data_r[`INTCPU_MISC_CTRL_DMA_DREQ_INHIBIT_R] = intcpu_misc_ctrl_dma_dreq_inhibit_q;
    end
    `INTCPU_EVENT:
    begin
        data_r[`INTCPU_EVENT_COMMAND_WR_R] = event_command_wr_q;
        data_r[`INTCPU_EVENT_PARAM_WR_R] = event_param_wr_q;
        data_r[`INTCPU_EVENT_REQUEST_WR_R] = event_request_wr_q;
        data_r[`INTCPU_EVENT_VOL_APPLY_R] = event_vol_apply_q;
        data_r[`INTCPU_EVENT_SND_MAP_DAT_WR_R] = event_snd_map_dat_wr_q;
        data_r[`INTCPU_EVENT_SND_MAP_CDI_WR_R] = event_snd_map_cdi_wr_q;
        data_r[`INTCPU_EVENT_BFRD_RISE_R] = event_bfrd_rise_q;
    end
    `INTCPU_FIFO_STATUS:
    begin
        data_r[`INTCPU_FIFO_STATUS_PARAM_EMPTY_R] = fifo_status_param_empty_i;
        data_r[`INTCPU_FIFO_STATUS_PARAM_FULL_R] = fifo_status_param_full_i;
        data_r[`INTCPU_FIFO_STATUS_RESPONSE_EMPTY_R] = fifo_status_response_empty_i;
        data_r[`INTCPU_FIFO_STATUS_RESPONSE_FULL_R] = fifo_status_response_full_i;
        data_r[`INTCPU_FIFO_STATUS_DATA_EMPTY_R] = fifo_status_data_empty_i;
        data_r[`INTCPU_FIFO_STATUS_DATA_FULL_R] = fifo_status_data_full_i;
        data_r[`INTCPU_FIFO_STATUS_DATA_HALF_R] = fifo_status_data_half_i;
    end
    `INTCPU_FIFO_LEVEL:
    begin
        data_r[`INTCPU_FIFO_LEVEL_PARAM_R] = fifo_level_param_i;
        data_r[`INTCPU_FIFO_LEVEL_RESPONSE_R] = fifo_level_response_i;
        data_r[`INTCPU_FIFO_LEVEL_DATA_R] = fifo_level_data_i;
    end
    `INTCPU_GPIO:
    begin
        data_r[`INTCPU_GPIO_OUTPUT_R] = gpio_i;
    end
    `INTCPU_DMA_STATUS:
    begin
        data_r[`INTCPU_DMA_STATUS_LEVEL_R] = dma_status_level_i;
        data_r[`INTCPU_DMA_STATUS_BUSY_R]  = dma_fetch_q;
    end
    `INTCPU_DMA_FIFO:
    begin
        data_r[`INTCPU_DMA_FIFO_DATA_R] = dma_fifo_data_i;
    end
    `INTCPU_DEBUG0:
    begin
        data_r[`INTCPU_DEBUG0_OUTPUT_R] = intcpu_debug0_q;
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

wire intcpu_command_rd_req_w = read_en_w & (cfg_addr_i[7:0] == `INTCPU_COMMAND);
wire intcpu_param_rd_req_w   = read_en_w & (cfg_addr_i[7:0] == `INTCPU_PARAM);

//-----------------------------------------------------------------
// Outputs
//-----------------------------------------------------------------
assign command_rd_o         = intcpu_command_rd_req_w;
assign param_rd_o           = intcpu_param_rd_req_w;

assign response_wr_o        = intcpu_response_wr_q;
assign response_data_o      = intcpu_response_data_out_w;

assign data_wr_o            = intcpu_data_wr_q;
assign data_data_o          = intcpu_data_data_out_w;

assign dma_dreq_inhibit_o   = intcpu_misc_ctrl_dma_dreq_inhibit_out_w;
assign bfrd_clear_inhibit_o = intcpu_misc_ctrl_bfrd_clear_inhibit_out_w;
assign int_raise_o          = intcpu_raise_int_sts_out_w;

assign gpio_o               = intcpu_gpio_output_out_w;

endmodule
