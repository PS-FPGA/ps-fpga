
module arty_ddr256
(
    // Inputs
     input           clk100_i
    ,input           clk200_i
    ,input           inport_awvalid_i
    ,input  [ 31:0]  inport_awaddr_i
    ,input  [  3:0]  inport_awid_i
    ,input  [  7:0]  inport_awlen_i
    ,input  [  1:0]  inport_awburst_i
    ,input           inport_wvalid_i
    ,input  [255:0]  inport_wdata_i
    ,input  [ 31:0]  inport_wstrb_i
    ,input           inport_wlast_i
    ,input           inport_bready_i
    ,input           inport_arvalid_i
    ,input  [ 31:0]  inport_araddr_i
    ,input  [  3:0]  inport_arid_i
    ,input  [  7:0]  inport_arlen_i
    ,input  [  1:0]  inport_arburst_i
    ,input           inport_rready_i

    // Outputs
    ,output          clk_out_o
    ,output          rst_out_o
    ,output          inport_awready_o
    ,output          inport_wready_o
    ,output          inport_bvalid_o
    ,output [  1:0]  inport_bresp_o
    ,output [  3:0]  inport_bid_o
    ,output          inport_arready_o
    ,output          inport_rvalid_o
    ,output [255:0]  inport_rdata_o
    ,output [  1:0]  inport_rresp_o
    ,output [  3:0]  inport_rid_o
    ,output          inport_rlast_o
    ,output          ddr_ck_p_o
    ,output          ddr_ck_n_o
    ,output          ddr_cke_o
    ,output          ddr_reset_n_o
    ,output          ddr_ras_n_o
    ,output          ddr_cas_n_o
    ,output          ddr_we_n_o
    ,output          ddr_cs_n_o
    ,output [  2:0]  ddr_ba_o
    ,output [ 13:0]  ddr_addr_o
    ,output          ddr_odt_o
    ,output [  1:0]  ddr_dm_o
    ,inout [  1:0]  ddr_dqs_p_io
    ,inout [  1:0]  ddr_dqs_n_io
    ,inout [ 15:0]  ddr_data_io
);




wire [31 : 0]  m_axi_awaddr;
wire [7 : 0]   m_axi_awlen;
wire [2 : 0]   m_axi_awsize;
wire [1 : 0]   m_axi_awburst;
wire [0 : 0]   m_axi_awlock;
wire [3 : 0]   m_axi_awcache;
wire [2 : 0]   m_axi_awprot;
wire [3 : 0]   m_axi_awregion;
wire [3 : 0]   m_axi_awqos;
wire           m_axi_awvalid;
wire           m_axi_awready;
wire [127 : 0] m_axi_wdata;
wire [15 : 0]  m_axi_wstrb;
wire           m_axi_wlast;
wire           m_axi_wvalid;
wire           m_axi_wready;
wire [1 : 0]   m_axi_bresp;
wire           m_axi_bvalid;
wire           m_axi_bready;
wire [31 : 0]  m_axi_araddr;
wire [7 : 0]   m_axi_arlen;
wire [2 : 0]   m_axi_arsize;
wire [1 : 0]   m_axi_arburst;
wire [0 : 0]   m_axi_arlock;
wire [3 : 0]   m_axi_arcache;
wire [2 : 0]   m_axi_arprot;
wire [3 : 0]   m_axi_arregion;
wire [3 : 0]   m_axi_arqos;
wire           m_axi_arvalid;
wire           m_axi_arready;
wire [127 : 0] m_axi_rdata;
wire [1 : 0]   m_axi_rresp;
wire           m_axi_rlast;
wire           m_axi_rvalid;
wire           m_axi_rready;

axi_dconv
u_conv
(
     .s_axi_aclk(clk_out_o)
    ,.s_axi_aresetn(~rst_out_o)

    ,.s_axi_awid(inport_awid_i)
    ,.s_axi_awaddr(inport_awaddr_i)
    ,.s_axi_awlen(inport_awlen_i)
    ,.s_axi_awsize(3'b101)
    ,.s_axi_awburst(inport_awburst_i)
    ,.s_axi_awlock(1'b0)
    ,.s_axi_awcache(4'h2)
    ,.s_axi_awprot(3'b010)
    ,.s_axi_awqos(4'h0)
    ,.s_axi_awregion(4'b0)
    ,.s_axi_awvalid(inport_awvalid_i)
    ,.s_axi_awready(inport_awready_o)
    ,.s_axi_wready(inport_wready_o)
    ,.s_axi_wdata(inport_wdata_i)
    ,.s_axi_wstrb(inport_wstrb_i)
    ,.s_axi_wlast(inport_wlast_i)
    ,.s_axi_wvalid(inport_wvalid_i)
    ,.s_axi_bready(inport_bready_i)
    ,.s_axi_bid(inport_bid_o)
    ,.s_axi_bresp(inport_bresp_o)
    ,.s_axi_bvalid(inport_bvalid_o)
    ,.s_axi_arid(inport_arid_i)
    ,.s_axi_araddr(inport_araddr_i)
    ,.s_axi_arlen(inport_arlen_i)
    ,.s_axi_arsize(3'b101)
    ,.s_axi_arburst(inport_arburst_i)
    ,.s_axi_arlock(1'b0)
    ,.s_axi_arcache(4'h2)
    ,.s_axi_arprot(3'b010)
    ,.s_axi_arqos(4'h0)
    ,.s_axi_arregion(4'b0)
    ,.s_axi_arvalid(inport_arvalid_i)
    ,.s_axi_arready(inport_arready_o)
    ,.s_axi_rready(inport_rready_i)
    ,.s_axi_rid(inport_rid_o)
    ,.s_axi_rdata(inport_rdata_o)
    ,.s_axi_rresp(inport_rresp_o)
    ,.s_axi_rlast(inport_rlast_o)
    ,.s_axi_rvalid(inport_rvalid_o)

    ,.m_axi_awaddr(m_axi_awaddr)
    ,.m_axi_awlen(m_axi_awlen)
    ,.m_axi_awsize(m_axi_awsize)
    ,.m_axi_awburst(m_axi_awburst)
    ,.m_axi_awlock(m_axi_awlock)
    ,.m_axi_awcache(m_axi_awcache)
    ,.m_axi_awprot(m_axi_awprot)
    ,.m_axi_awregion(m_axi_awregion)
    ,.m_axi_awqos(m_axi_awqos)
    ,.m_axi_awvalid(m_axi_awvalid)
    ,.m_axi_awready(m_axi_awready)
    ,.m_axi_wdata(m_axi_wdata)
    ,.m_axi_wstrb(m_axi_wstrb)
    ,.m_axi_wlast(m_axi_wlast)
    ,.m_axi_wvalid(m_axi_wvalid)
    ,.m_axi_wready(m_axi_wready)
    ,.m_axi_bresp(m_axi_bresp)
    ,.m_axi_bvalid(m_axi_bvalid)
    ,.m_axi_bready(m_axi_bready)
    ,.m_axi_araddr(m_axi_araddr)
    ,.m_axi_arlen(m_axi_arlen)
    ,.m_axi_arsize(m_axi_arsize)
    ,.m_axi_arburst(m_axi_arburst)
    ,.m_axi_arlock(m_axi_arlock)
    ,.m_axi_arcache(m_axi_arcache)
    ,.m_axi_arprot(m_axi_arprot)
    ,.m_axi_arregion(m_axi_arregion)
    ,.m_axi_arqos(m_axi_arqos)
    ,.m_axi_arvalid(m_axi_arvalid)
    ,.m_axi_arready(m_axi_arready)
    ,.m_axi_rdata(m_axi_rdata)
    ,.m_axi_rresp(m_axi_rresp)
    ,.m_axi_rlast(m_axi_rlast)
    ,.m_axi_rvalid(m_axi_rvalid)
    ,.m_axi_rready(m_axi_rready)
);

// Other wires ...
wire         init_calib_complete, mmcm_locked;
wire         app_sr_active, app_ref_ack, app_zq_ack;
wire         app_sr_req, app_ref_req, app_zq_req;
wire         w_sys_reset;
wire [11:0]  w_device_temp;

mig_axis mig_sdram
(
    // DDR Pins
    .ddr3_ck_p(ddr_ck_p_o),
    .ddr3_ck_n(ddr_ck_n_o),
    .ddr3_reset_n(ddr_reset_n_o),
    .ddr3_cke(ddr_cke_o),
    .ddr3_cs_n(ddr_cs_n_o),
    .ddr3_ras_n(ddr_ras_n_o),
    .ddr3_we_n(ddr_we_n_o),
    .ddr3_cas_n(ddr_cas_n_o),
    .ddr3_ba(ddr_ba_o),
    .ddr3_addr(ddr_addr_o),
    .ddr3_odt(ddr_odt_o),
    .ddr3_dqs_p(ddr_dqs_p_io),
    .ddr3_dqs_n(ddr_dqs_n_io),
    .ddr3_dq(ddr_data_io),
    .ddr3_dm(ddr_dm_o),

    // Misc
    .sys_clk_i(clk100_i),
    .clk_ref_i(clk200_i),
    .ui_clk(clk_out_o),
    .ui_clk_sync_rst(w_sys_reset),
    .mmcm_locked(mmcm_locked),
    .aresetn(1'b1),
    .app_sr_req(1'b0),
    .app_ref_req(1'b0),
    .app_zq_req(1'b0),
    .app_sr_active(app_sr_active),
    .app_ref_ack(app_ref_ack),
    .app_zq_ack(app_zq_ack),

    // AXI
    .s_axi_awid(4'b0),
    .s_axi_awaddr(m_axi_awaddr[27:0]),
    .s_axi_awlen(m_axi_awlen),
    .s_axi_awsize(m_axi_awsize),
    .s_axi_awburst(m_axi_awburst),
    .s_axi_awlock(m_axi_awlock),
    .s_axi_awcache(m_axi_awcache),
    .s_axi_awprot(m_axi_awprot),
    .s_axi_awqos(m_axi_awqos),
    .s_axi_awvalid(m_axi_awvalid),
    .s_axi_awready(m_axi_awready),
    .s_axi_wready(m_axi_wready),
    .s_axi_wdata(m_axi_wdata),
    .s_axi_wstrb(m_axi_wstrb),
    .s_axi_wlast(m_axi_wlast),
    .s_axi_wvalid(m_axi_wvalid),
    .s_axi_bready(m_axi_bready),
    .s_axi_bid(),
    .s_axi_bresp(m_axi_bresp),
    .s_axi_bvalid(m_axi_bvalid),
    .s_axi_arid(4'b0),
    .s_axi_araddr(m_axi_araddr[27:0]),
    .s_axi_arlen(m_axi_arlen),
    .s_axi_arsize(m_axi_arsize),
    .s_axi_arburst(m_axi_arburst),
    .s_axi_arlock(m_axi_arlock),
    .s_axi_arcache(m_axi_arcache),
    .s_axi_arprot(m_axi_arprot),
    .s_axi_arqos(m_axi_arqos),
    .s_axi_arvalid(m_axi_arvalid),
    .s_axi_arready(m_axi_arready),
    .s_axi_rready(m_axi_rready),
    .s_axi_rid(),
    .s_axi_rdata(m_axi_rdata),
    .s_axi_rresp(m_axi_rresp),
    .s_axi_rlast(m_axi_rlast),
    .s_axi_rvalid(m_axi_rvalid),

    .init_calib_complete(init_calib_complete),
    .sys_rst(1'b1),
    .device_temp(w_device_temp)
);

// Convert from active low to active high, *and* hold the system in
// reset until the memory comes up. 
reg sys_rst_o;
initial sys_rst_o = 1'b1;
always @(posedge clk_out_o)
    sys_rst_o <= w_sys_reset || (!init_calib_complete) || (!mmcm_locked);

assign rst_out_o = sys_rst_o;


endmodule
