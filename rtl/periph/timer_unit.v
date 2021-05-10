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
module timer_unit
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
     parameter TYPE = 0
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(
     input           clk_i
    ,input           rst_i

    // Dotclock (synchronous to clk_i)
    ,input           dotclk_valid_i
    ,input  [3:0]    dotclk_incr_i

    ,input           clk_div8_i
    ,input           clk_hblank_i
    ,input           clk_vblank_i
    ,input           hblank_i
    ,input           vblank_i

    // CPU access
    ,input           cfg_cs_i
    ,input           cfg_we_i
    ,input   [3:0]   cfg_addr_i
    ,input   [15:0]  cfg_data_wr_i
    ,output  [15:0]  cfg_data_rd_o
    ,output          irq_o
);

//-----------------------------------------------------------------
// 1F801104h+N*10h - Timer 0..2 Counter Mode (R/W)
//-----------------------------------------------------------------
/*
  0     Synchronization Enable (0=Free Run, 1=Synchronize via Bit1-2)
  1-2   Synchronization Mode   (0-3, see lists below)
         Synchronization Modes for Counter 0:
           0 = Pause counter during Hblank(s)
           1 = Reset counter to 0000h at Hblank(s)
           2 = Reset counter to 0000h at Hblank(s) and pause outside of Hblank
           3 = Pause until Hblank occurs once, then switch to Free Run
         Synchronization Modes for Counter 1:
           Same as above, but using Vblank instead of Hblank
         Synchronization Modes for Counter 2:
           0 or 3 = Stop counter at current value (forever, no h/v-blank start)
           1 or 2 = Free Run (same as when Synchronization Disabled)
  3     Reset counter to 0000h  (0=After Counter=FFFFh, 1=After Counter=Target)
  4     IRQ when Counter=Target (0=Disable, 1=Enable)
  5     IRQ when Counter=FFFFh  (0=Disable, 1=Enable)
  6     IRQ Once/Repeat Mode    (0=One-shot, 1=Repeatedly)
  7     IRQ Pulse/Toggle Mode   (0=Short Bit10=0 Pulse, 1=Toggle Bit10 on/off)
  8-9   Clock Source (0-3, see list below)
         Counter 0:  0 or 2 = System Clock,  1 or 3 = Dotclock
         Counter 1:  0 or 2 = System Clock,  1 or 3 = Hblank
         Counter 2:  0 or 1 = System Clock,  2 or 3 = System Clock/8
  10    Interrupt Request       (0=Yes, 1=No) (Set after Writing)    (W=1) (R)
  11    Reached Target Value    (0=No, 1=Yes) (Reset after Reading)        (R)
  12    Reached FFFFh Value     (0=No, 1=Yes) (Reset after Reading)        (R)
*/

reg       cfg_sync_en_q;
reg [1:0] cfg_sync_mode_q;
reg       cfg_wrap_on_tgt_q;
reg       cfg_irq_on_tgt_q;
reg       cfg_irq_on_max_q;
reg       cfg_irq_repeat_q;
reg       cfg_irq_toggle_q;
reg [1:0] cfg_clk_source_q;

wire      reg_cfg_write_w = (cfg_cs_i && cfg_we_i  && cfg_addr_i == 4'h04);
wire      reg_cfg_read_w  = (cfg_cs_i && ~cfg_we_i && cfg_addr_i == 4'h04);

always @ (posedge clk_i )
if (rst_i)
begin
    cfg_sync_en_q     <= 1'b0;
    cfg_sync_mode_q   <= 2'b0;
    cfg_wrap_on_tgt_q <= 1'b0;
    cfg_irq_on_tgt_q  <= 1'b0;
    cfg_irq_on_max_q  <= 1'b0;
    cfg_irq_repeat_q  <= 1'b0;
    cfg_irq_toggle_q  <= 1'b0;
    cfg_clk_source_q  <= 2'b0;
end
else if (reg_cfg_write_w)
begin
    cfg_sync_en_q     <= cfg_data_wr_i[0];
    cfg_sync_mode_q   <= cfg_data_wr_i[2:1];
    cfg_wrap_on_tgt_q <= cfg_data_wr_i[3];
    cfg_irq_on_tgt_q  <= cfg_data_wr_i[4];
    cfg_irq_on_max_q  <= cfg_data_wr_i[5];
    cfg_irq_repeat_q  <= cfg_data_wr_i[6];
    cfg_irq_toggle_q  <= cfg_data_wr_i[7];
    cfg_clk_source_q  <= cfg_data_wr_i[9:8];
end

//-----------------------------------------------------------------
// 1F801108h+N*10h - Timer 0..2 Counter Target Value (R/W)
//-----------------------------------------------------------------
reg [15:0] target_q;

always @ (posedge clk_i )
if (rst_i)
    target_q <= 16'b0;
else if (cfg_cs_i && cfg_we_i && cfg_addr_i == 4'h08)
    target_q <= cfg_data_wr_i[15:0];

wire [15:0] wrap_point_w = cfg_wrap_on_tgt_q ? target_q : 16'hFFFF;

reg [9:0] hack_q;

always @ (posedge clk_i )
if (rst_i)
    hack_q <= 10'b0000000001;
else
    hack_q <= {hack_q[8:0], hack_q[9]};

//-----------------------------------------------------------------
// Clock source
//-----------------------------------------------------------------
reg [3:0] clk_incr_r;

always @ *
begin
    clk_incr_r = 4'b0;
    /*
     Counter 0:  0 or 2 = System Clock,  1 or 3 = Dotclock
     Counter 1:  0 or 2 = System Clock,  1 or 3 = Hblank
     Counter 2:  0 or 1 = System Clock,  2 or 3 = System Clock/8
     */

    case (TYPE)
    0:
    begin
        case (cfg_clk_source_q)
        2'd0, 2'd2: clk_incr_r = hack_q[9] ? 4'd2 : 4'd1;
        default:    clk_incr_r = dotclk_valid_i ? dotclk_incr_i : 4'd0;
        endcase
    end
    1:
    begin
        case (cfg_clk_source_q)
        2'd0, 2'd2: clk_incr_r = hack_q[9] ? 4'd2 : 4'd1;
        default:    clk_incr_r = clk_hblank_i ? 4'd1 : 4'd0;
        endcase
    end
    2:
    begin
        case (cfg_clk_source_q)
        2'd0, 2'd1: clk_incr_r = hack_q[9] ? 4'd2 : 4'd1;
        default:    clk_incr_r = clk_div8_i ? 4'd1 : 4'd0;
        endcase
    end
    endcase
end

wire [15:0] count_incr_w = {12'b0, clk_incr_r};

//-----------------------------------------------------------------
// Counter Enable/Reset
//-----------------------------------------------------------------
reg count_en_r;
reg count_rst_r;

always @ *
begin
    count_en_r  = 1'b1;
    count_rst_r = 1'b0;

    /*
         Synchronization Modes for Counter 0:
           0 = Pause counter during Hblank(s)
           1 = Reset counter to 0000h at Hblank(s)
           2 = Reset counter to 0000h at Hblank(s) and pause outside of Hblank
           3 = Pause until Hblank occurs once, then switch to Free Run
         Synchronization Modes for Counter 1:
           0 = Pause counter during Vblank(s)
           1 = Reset counter to 0000h at Vblank(s)
           2 = Reset counter to 0000h at Vblank(s) and pause outside of Vblank
           3 = Pause until Vblank occurs once, then switch to Free Run           
         Synchronization Modes for Counter 2:
           0 or 3 = Stop counter at current value (forever, no h/v-blank start)
           1 or 2 = Free Run (same as when Synchronization Disabled)
    */
    if (cfg_sync_en_q)
    begin
        case (TYPE)
        0:
        begin
            case (cfg_sync_mode_q)
            2'd0:
            begin
                count_en_r  = ~hblank_i;
            end
            2'd1:
            begin
                count_en_r  = 1'b1;
                count_rst_r = clk_hblank_i;
            end
            2'd2:
            begin
                count_en_r  = ~hblank_i;
                count_rst_r = clk_hblank_i;
            end
            default:
            begin
                // TODO: When do we actually start counting (begin or end of xblank..)
                count_en_r  = hblank_i;
            end
            endcase
        end
        1:
        begin
            case (cfg_sync_mode_q)
            2'd0:
            begin
                count_en_r  = ~vblank_i;
            end
            2'd1:
            begin
                count_en_r  = 1'b1;
                count_rst_r = clk_vblank_i;
            end
            2'd2:
            begin
                count_en_r  = ~vblank_i;
                count_rst_r = clk_vblank_i;
            end
            default:
            begin
                // TODO: When do we actually start counting (begin or end of xblank..)
                count_en_r  = vblank_i;
            end
            endcase
        end
        2:
        begin
            case (cfg_sync_mode_q)
            2'd1,
            2'd2:    count_en_r = 1'b1;
            default: count_en_r = 1'b0;
            endcase
        end
        endcase
    end
end

// Remembered triggered state
reg count_en_q;
always @ (posedge clk_i )
if (rst_i)
    count_en_q <= 1'b0;
else if (reg_cfg_write_w)
    count_en_q <= 1'b0;
// Pause until xblank occurs once, then switch to Free Run
else if (cfg_sync_mode_q == 2'd3 && count_en_r)
    count_en_q <= 1'b1;

wire count_en_w = count_en_r | count_en_q;

//-----------------------------------------------------------------
// 1F801100h+N*10h - Timer 0..2 Current Counter Value (R/W)
//-----------------------------------------------------------------
reg [15:0]  counter_q;
reg [15:0]  counter_r;

// Space before the wrap point (target or 0xFFFF)
wire [15:0] count_space_w = wrap_point_w - counter_q;

// Counter reset to 0 request
wire        count_reset_w = reg_cfg_write_w | count_rst_r;

wire        reg_count_write_w = (cfg_cs_i && cfg_we_i  && cfg_addr_i == 4'h00);

always @ *
begin
    counter_r = counter_q;

    if (count_reset_w)
        counter_r = 16'b0;
    else if (reg_count_write_w)
        counter_r = cfg_data_wr_i[15:0];
    else if (count_en_w && count_incr_w != 16'b0)
    begin
        // Counter wraps with excess
        if (count_incr_w > count_space_w)
            counter_r = count_incr_w - 16'd1 - count_space_w;
        else if (count_space_w == 16'b0)
            counter_r = 16'b0;
        // Straightforward increment
        else
            counter_r = counter_r + count_incr_w;
    end
end

always @ (posedge clk_i )
if (rst_i)
    counter_q <= 16'b0;
else
    counter_q <= counter_r;

//-----------------------------------------------------------------
// Status valid (was there a tick event)
//-----------------------------------------------------------------
reg status_ok_q;

always @ (posedge clk_i )
if (rst_i)
    status_ok_q <= 1'b0;
else if (count_reset_w)
    status_ok_q <= 1'b0;
else
    status_ok_q <= count_en_w && (count_incr_w != 16'b0);

//-----------------------------------------------------------------
// Status
//-----------------------------------------------------------------
wire hit_target_w = status_ok_q & (counter_q == target_q);
wire hit_ffff_w   = status_ok_q & (counter_q == 16'hFFFF);

reg sts_hit_tgt_q;
reg sts_hit_ffff_q;

always @ (posedge clk_i )
if (rst_i)
begin
    sts_hit_tgt_q  <= 1'b0;
    sts_hit_ffff_q <= 1'b0;
end
// Spec says reset on read - but write resets the counter so...
else if (reg_cfg_read_w || reg_cfg_write_w)
begin
    sts_hit_tgt_q  <= 1'b0;
    sts_hit_ffff_q <= 1'b0;
end
else
begin
    sts_hit_tgt_q  <= sts_hit_tgt_q  | hit_target_w;
    sts_hit_ffff_q <= sts_hit_ffff_q | hit_ffff_w;
end

//-----------------------------------------------------------------
// Read mux
//-----------------------------------------------------------------
reg [15:0] cfg_data_rd_r;

always @ *
begin
    cfg_data_rd_r = 16'b0;

    case (cfg_addr_i)
    // 1F801100h+N*10h - Timer 0..2 Current Counter Value
    4'h0:
    begin
        cfg_data_rd_r = counter_q;
    end
    // 1F801104h+N*10h - Timer 0..2 Counter Mode
    4'h4:
    begin
        cfg_data_rd_r[0]   = cfg_sync_en_q;
        cfg_data_rd_r[2:1] = cfg_sync_mode_q;
        cfg_data_rd_r[3]   = cfg_wrap_on_tgt_q;
        cfg_data_rd_r[4]   = cfg_irq_on_tgt_q;
        cfg_data_rd_r[5]   = cfg_irq_on_max_q;
        cfg_data_rd_r[6]   = cfg_irq_repeat_q;
        cfg_data_rd_r[7]   = cfg_irq_toggle_q;
        cfg_data_rd_r[9:8] = cfg_clk_source_q;
        // TODO: bit 10...
        cfg_data_rd_r[11]  = sts_hit_tgt_q  | hit_target_w;
        cfg_data_rd_r[12]  = sts_hit_ffff_q | hit_ffff_w;
    end
    // 1F801108h+N*10h - Timer 0..2 Counter Target Value
    4'h8:
    begin
        cfg_data_rd_r = target_q;
    end
    default: ;
    endcase
end

assign cfg_data_rd_o = cfg_data_rd_r;

//-----------------------------------------------------------------
// IRQ
//-----------------------------------------------------------------
reg irq_r;
reg irq_inhibit_q;

// Handle one shot mode interrupts
always @ (posedge clk_i )
if (rst_i)
    irq_inhibit_q <= 1'b0;
else if (reg_cfg_write_w)
    irq_inhibit_q <= 1'b0;
else if (irq_r && ~cfg_irq_repeat_q)
    irq_inhibit_q <= 1'b1;

always @ *
begin
    irq_r = 1'b0;

    if (!irq_inhibit_q)
    begin
        irq_r = (cfg_irq_on_tgt_q & hit_target_w) |
                (cfg_irq_on_max_q & hit_ffff_w);
    end
end

reg irq_q;

always @ (posedge clk_i )
if (rst_i)
    irq_q <= 1'b0;
else
    irq_q <= irq_r;

assign irq_o = irq_q;

//-----------------------------------------------------------------
// Checks
//-----------------------------------------------------------------
`ifdef verilator
always @ (posedge clk_i )
if (rst_i)
    ;
else
begin
    if (cfg_irq_toggle_q)
    begin
        $display("WARNING: IRQ toggle mode enabled but not implemented yet... (%m)");
        $finish;
    end
end
`endif

endmodule