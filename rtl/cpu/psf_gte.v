
module psf_gte
(
    // Inputs
     input           clk_i
    ,input           rst_i
    ,input           cop_valid_i
    ,input  [ 31:0]  cop_opcode_i
    ,input           cop_reg_write_i
    ,input  [  5:0]  cop_reg_waddr_i
    ,input  [ 31:0]  cop_reg_wdata_i
    ,input  [  5:0]  cop_reg_raddr_i

    // Outputs
    ,output          cop_accept_o
    ,output [ 31:0]  cop_reg_rdata_o
);



`include "mpx_defs.v"

//-------------------------------------------------------------
// GTE
//-------------------------------------------------------------
// TODO: Remove this logic - not needed... (hopefully)
wire        inst_mfc2_w = cop_valid_i && (cop_opcode_i[`OPCODE_INST_R] == `INSTR_COP2) && (cop_opcode_i[`OPCODE_RS_R] == 5'b00000);
wire        inst_cfc2_w = cop_valid_i && (cop_opcode_i[`OPCODE_INST_R] == `INSTR_COP2) && (cop_opcode_i[`OPCODE_RS_R] == 5'b00010);
wire        inst_swc2_w = cop_valid_i && (cop_opcode_i[`OPCODE_INST_R] == `INSTR_I_SWC2);

wire        cop2_busy_w;
wire [5:0]  cop2_addr_w   = cop_reg_write_i                            ? cop_reg_waddr_i : 
                            (inst_mfc2_w || inst_cfc2_w || inst_swc2_w) ? cop_reg_raddr_i : 6'b0;
wire        cop2_inst_w   = cop_valid_i && (cop_opcode_i[`OPCODE_INST_R] == `INSTR_COP2) && cop_opcode_i[25];
assign      cop_accept_o = ~cop2_busy_w;

GTEEngine
u_gte
(
     .i_clk(clk_i)
    ,.i_nRst(~rst_i)

    ,.i_regID(cop2_addr_w)               // Register ID to write or read. (READ ALWAYS HAPPEN, 0 LATENCY to o_dataOut, please use when o_executing=0)
    ,.i_WritReg(cop_reg_write_i)         // Write to 'Register ID' = i_dataIn.
    
    ,.i_DIP_USEFASTGTE(1'b1)             // Control signal coming from the console (not the CPU, from outside at runtime or compile option)
    ,.i_DIP_FIXWIDE(1'b0)                // Same
    
    ,.i_dataIn(cop_reg_wdata_i)         // Register Write value.
    ,.o_dataOut(cop_reg_rdata_o)        // Register Read  value.

    ,.i_Instruction(cop_opcode_i[24:0]) // Instruction to execute
    ,.i_run(cop2_inst_w)                 // Instruction valid
    ,.o_executing(cop2_busy_w)           // BUSY, only read/write/execute when o_executing = 0
);

//-----------------------------------------------------------------
// Simulation Only
//-----------------------------------------------------------------
`ifdef verilator
reg [31:0] dbg_cycle_q;

always @ (posedge clk_i )
if (rst_i)
    dbg_cycle_q <= 32'b0;
else
    dbg_cycle_q <= dbg_cycle_q + 32'd1;

always @ (posedge clk_i)
begin
    if (cop2_inst_w && cop_accept_o)
        $display(" [GTE] Opcode %08x [INST] @ %0d", cop_opcode_i, dbg_cycle_q);
    if (cop_reg_write_i && cop_accept_o)
        $display(" [GTE] Write Reg%02x = %08x @ %0d", cop2_addr_w, cop_reg_wdata_i, dbg_cycle_q);
    if ((inst_mfc2_w || inst_cfc2_w || inst_swc2_w) && cop_accept_o)
        $display(" [GTE] Read Reg%02x = %08x @ %0d", cop2_addr_w, cop_reg_rdata_o, dbg_cycle_q);
end

reg [31:0] stats_read_q;
reg [31:0] stats_write_q;
reg [31:0] stats_ops_q;
reg [31:0] stats_stalls_q;
reg [31:0] stats_busy_q;

always @ (posedge clk_i )
if (rst_i)
    stats_read_q   <= 32'b0;
else if ((inst_mfc2_w || inst_cfc2_w || inst_swc2_w) && cop_accept_o)
    stats_read_q   <= stats_read_q + 32'd1;

always @ (posedge clk_i )
if (rst_i)
    stats_write_q   <= 32'b0;
else if (cop_reg_write_i && cop_accept_o)
    stats_write_q   <= stats_write_q + 32'd1;

always @ (posedge clk_i )
if (rst_i)
    stats_ops_q   <= 32'b0;
else if (cop2_inst_w && cop_accept_o)
    stats_ops_q   <= stats_ops_q + 32'd1;

always @ (posedge clk_i )
if (rst_i)
    stats_stalls_q   <= 32'b0;
else if ((cop2_inst_w || cop_reg_write_i || inst_mfc2_w || inst_cfc2_w || inst_swc2_w) && ~cop_accept_o)
    stats_stalls_q   <= stats_stalls_q + 32'd1;

always @ (posedge clk_i )
if (rst_i)
    stats_busy_q   <= 32'b0;
else if (cop2_busy_w)
    stats_busy_q   <= stats_busy_q + 32'd1;

`endif

endmodule
