/////////////////////////////////////////////////////////////////////
//
// Copyright 2018 Ettus Research, A National Instruments Company
// Copyright 2019 Ettus Research, A National Instruments Brand
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//
// Module: e31x
// Description:
//   E31x Top Level
//
/////////////////////////////////////////////////////////////////////

module e31x (

  // PS Connections
  inout [53:0]  MIO,
  input         PS_SRSTB,
  input         PS_CLK,
  input         PS_PORB,
  inout         DDR_CLK,
  inout         DDR_CLK_N,
  inout         DDR_CKE,
  inout         DDR_CS_N,
  inout         DDR_RAS_N,
  inout         DDR_CAS_N,
  inout         DDR_WEB,
  inout [2:0]   DDR_BANKADDR,
  inout [14:0]  DDR_ADDR,
  inout         DDR_ODT,
  inout         DDR_DRSTB,
  inout [31:0]  DDR_DQ,
  inout [3:0]   DDR_DM,
  inout [3:0]   DDR_DQS,
  inout [3:0]   DDR_DQS_N,
  inout         DDR_VRP,
  inout         DDR_VRN,

  // Leds
  output        LED_TXRX1_TX,
  output        LED_RX1_RX,
  output        LED_TXRX2_TX,
  output        LED_RX2_RX,

  // AD9361 connections
  input  [7:0]  CAT_CTRL_OUT,
  output [3:0]  CAT_CTRL_IN,
  output        CAT_RESET,  // FIXME Fix in Pinout
  output        CAT_CS,
  output        CAT_SCLK,
  output        CAT_MOSI,
  input         CAT_MISO,
  output        CAT_SYNC,
  output        CAT_TXNRX,
  output        CAT_ENABLE,
  output        CAT_ENAGC,
  input         CAT_RX_FRAME,
  input         CAT_DATA_CLK,
  output        CAT_TX_FRAME,
  output        CAT_FB_CLK,
  input [11:0]  CAT_P0_D,
  output [11:0] CAT_P1_D,

  // pps connections
  input         GPS_PPS,

  // VTCXO and the DAC that feeds it
  output        TCXO_DAC_SYNC_N,
  output        TCXO_DAC_SCLK,
  output        TCXO_DAC_SDIN,
  input         TCXO_CLK,

  // Internal GPIOs (INT0)
  inout [5:0]   PL_GPIO
);

  // Include the RFNoC image core header file
  `ifdef RFNOC_IMAGE_CORE_HDR
    `include `"`RFNOC_IMAGE_CORE_HDR`"
  `else
    ERROR_RFNOC_IMAGE_CORE_HDR_not_defined();
    `define CHDR_WIDTH     64
    `define RFNOC_PROTOVER { 8'd1, 8'd0 }
  `endif
  localparam CHDR_W         = `CHDR_WIDTH;
  localparam RFNOC_PROTOVER = `RFNOC_PROTOVER;

  // This USRP currently only supports 64-bit CHDR width
  if (CHDR_W != 64) begin : gen_chdr_w_error
    CHDR_W_must_be_64_for_this_USRP();
  end

  // Log base 2 of the maximum transmission unit (MTU) in bytes
  localparam BYTE_MTU = $clog2(8192);

  // Constants
  localparam REG_AWIDTH = 14; // log2(0x4000)
  localparam REG_DWIDTH = 32;
  localparam DB_GPIO_WIDTH = 32;
  localparam FP_GPIO_OFFSET = 32; // Offset within ps_gpio_*
  localparam FP_GPIO_WIDTH = 6;

  //If bus_clk freq ever changes, update this parameter accordingly.
  localparam BUS_CLK_RATE = 32'd100000000; //100 MHz bus_clk rate.
  localparam NUM_SFP_PORTS = 0;
  localparam NUM_RADIOS = 1;
  localparam NUM_CHANNELS_PER_RADIO = 2;
  localparam NUM_DBOARDS = 1;
  localparam NUM_CHANNELS = NUM_RADIOS * NUM_CHANNELS_PER_RADIO;

  // Clocks
  wire bus_clk;
  wire radio_clk;
  wire reg_clk;
  wire clk40;
  wire clk166;
  wire clk200;
  wire FCLK_CLK0;
  wire FCLK_CLK1;
  wire FCLK_CLK2;
  wire FCLK_CLK3;

  // Resets
  wire global_rst;
  wire bus_rst;
  wire radio_rst;
  wire reg_rstn;
  wire clk40_rst;
  wire clk40_rstn;
  wire FCLK_RESET0_N;

  //ETH DMA
  wire        m_axi_eth_internal_arvalid;
  wire        m_axi_eth_internal_arready;
  wire        m_axi_eth_internal_awvalid;
  wire        m_axi_eth_internal_awready;
  wire        m_axi_eth_internal_bready;
  wire        m_axi_eth_internal_rready;
  wire        m_axi_eth_internal_wvalid;
  wire [31:0] m_axi_eth_internal_araddr;
  wire [31:0] m_axi_eth_internal_awaddr;
  wire [31:0] m_axi_eth_internal_wdata;
  wire [3:0]  m_axi_eth_internal_wstrb;
  wire        m_axi_eth_internal_rvalid;
  wire        m_axi_eth_internal_wready;
  wire [1:0]  m_axi_eth_internal_bresp;
  wire        m_axi_eth_internal_bvalid;
  wire [1:0]  m_axi_eth_internal_rresp;
  wire [31:0] m_axi_eth_internal_rdata;

  // Crossbar
  wire        m_axi_xbar_arvalid;
  wire        m_axi_xbar_awvalid;
  wire        m_axi_xbar_bready;
  wire        m_axi_xbar_rready;
  wire        m_axi_xbar_wvalid;
  wire [11:0] m_axi_xbar_arid;
  wire [11:0] m_axi_xbar_awid;
  wire [11:0] m_axi_xbar_wid;
  wire [31:0] m_axi_xbar_araddr;
  wire [31:0] m_axi_xbar_awaddr;
  wire [31:0] m_axi_xbar_wdata;
  wire [3:0]  m_axi_xbar_wstrb;
  wire        m_axi_xbar_arready;
  wire        m_axi_xbar_awready;
  wire        m_axi_xbar_bvalid;
  wire        m_axi_xbar_rlast;
  wire        m_axi_xbar_rvalid;
  wire        m_axi_xbar_wready;
  wire [1:0]  m_axi_xbar_bresp;
  wire [1:0]  m_axi_xbar_rresp;
  wire [31:0] m_axi_xbar_rdata;

  // Internal Ethernet xport adapter to PS
  wire [63:0] h2e_tdata;
  wire [7:0]  h2e_tkeep;
  wire        h2e_tlast;
  wire        h2e_tready;
  wire        h2e_tvalid;

  wire [63:0] e2h_tdata;
  wire [7:0]  e2h_tkeep;
  wire        e2h_tlast;
  wire        e2h_tready;
  wire        e2h_tvalid;

  wire [63:0] m_axis_dma_tdata;
  wire        m_axis_dma_tlast;
  wire        m_axis_dma_tready;
  wire        m_axis_dma_tvalid;

  wire [63:0] s_axis_dma_tdata;
  wire        s_axis_dma_tlast;
  wire        s_axis_dma_tready;
  wire        s_axis_dma_tvalid;

  // GPIO
  wire [63:0] ps_gpio_in;
  wire [63:0] ps_gpio_out;
  wire [63:0] ps_gpio_tri;

  //Misc
  wire [15:0] device_id;

  /////////////////////////////////////////////////////////////////////
  //
  // Resets:
  //  - PL - Global Reset --> Bus Reset
  //                      --> Radio Reset
  //  - PS - FCLK_RESET0_N --> clk40_rst(n)
  //
  //////////////////////////////////////////////////////////////////////

  // Global synchronous reset, on the bus_clk domain. De-asserts after 85
  // bus_clk cycles. Asserted by default.
  por_gen por_gen (
    .clk(bus_clk),
    .reset_out(global_rst)
  );

  // Synchronous reset for the bus_clk domain
  reset_sync bus_reset_gen (
    .clk(bus_clk),
    .reset_in(~FCLK_RESET0_N),
    //.reset_in(~clocks_locked),
    .reset_out(bus_rst)
  );


  // PS-based Resets //
  //
  // Synchronous reset for the clk40 domain. This is derived from the PS reset 0.
  reset_sync clk40_reset_gen (
    .clk(clk40),
    .reset_in(~FCLK_RESET0_N),
    .reset_out(clk40_rst)
  );
  // Invert for various modules.
  assign clk40_rstn = ~clk40_rst;
  assign reg_rstn = clk40_rstn;

  /////////////////////////////////////////////////////////////////////
  //
  // Clocks and PPS
  //
  /////////////////////////////////////////////////////////////////////

  wire [1:0] pps_select;

  assign bus_clk = FCLK_CLK0;   // 100 MHz
  assign clk40   = FCLK_CLK1;   // 40 MHz
  assign clk166  = FCLK_CLK2;   // 166.666 MHz
  assign clk200  = FCLK_CLK3;   // 200 MHz
  assign reg_clk = clk40;

  wire pps;
  wire clk_tcxo = TCXO_CLK; // 40 MHz
  wire is_10meg, is_pps, reflck, plllck; // reference status bits
  reg [3:0] tcxo_status, st_rsync;
  reg [2:0] pps_reg;

  wire gps_pps = GPS_PPS;

  // A local pps signal is derived from the tcxo clock. If a reference
  // at an appropriate rate (1 pps or 10 MHz) is present and selected
  // a digital control loop will be invoked to tune the vcxo and lock
  // the reference.
  ppsloop ppslp (
    .reset(1'b0),
    .xoclk(clk_tcxo), .ppsgps(gps_pps),
    .refsel(pps_select),
    .lpps(pps),
    .is10meg(is_10meg), .ispps(is_pps), .reflck(reflck), .plllck(plllck),
    .sclk(TCXO_DAC_SCLK), .mosi(TCXO_DAC_SDIN), .sync_n(TCXO_DAC_SYNC_N),
    .dac_dflt(16'h7fff)
  );

  always @(posedge bus_clk) begin
    // status signals originate from other than the bus_clk domain so re-sync
    // before passing to e300_core
    st_rsync <= {plllck, is_10meg, is_pps, reflck};
    tcxo_status <= st_rsync;
  end

  // TODO: Check this logic
  // connect PPS input to GPIO so ntpd can use it
  always @ (posedge bus_clk)
    pps_reg <= bus_rst ? 3'b000 : {pps_reg[1:0], GPS_PPS};
  assign ps_gpio_in[8] = pps_reg[2]; // 62


  /////////////////////////////////////////////////////////////////////
  //
  // Internal Ethernet Interface
  //
  //////////////////////////////////////////////////////////////////////
  eth_internal #(
    .DWIDTH(REG_DWIDTH),
    .AWIDTH(REG_AWIDTH),
    .PORTNUM(8'd1),
    .BYTE_MTU(BYTE_MTU),
    .RFNOC_PROTOVER(RFNOC_PROTOVER),
    .NODE_INST(0)
  ) eth_internal_i (
    // Resets
    .bus_rst (bus_rst),

    // Clocks
    .bus_clk (bus_clk),

    //Axi-lite
    .s_axi_aclk     (clk40),
    .s_axi_aresetn  (clk40_rstn),
    .s_axi_awaddr   (m_axi_eth_internal_awaddr),
    .s_axi_awvalid  (m_axi_eth_internal_awvalid),
    .s_axi_awready  (m_axi_eth_internal_awready),

    .s_axi_wdata    (m_axi_eth_internal_wdata),
    .s_axi_wstrb    (m_axi_eth_internal_wstrb),
    .s_axi_wvalid   (m_axi_eth_internal_wvalid),
    .s_axi_wready   (m_axi_eth_internal_wready),

    .s_axi_bresp    (m_axi_eth_internal_bresp),
    .s_axi_bvalid   (m_axi_eth_internal_bvalid),
    .s_axi_bready   (m_axi_eth_internal_bready),

    .s_axi_araddr   (m_axi_eth_internal_araddr),
    .s_axi_arvalid  (m_axi_eth_internal_arvalid),
    .s_axi_arready  (m_axi_eth_internal_arready),

    .s_axi_rdata    (m_axi_eth_internal_rdata),
    .s_axi_rresp    (m_axi_eth_internal_rresp),
    .s_axi_rvalid   (m_axi_eth_internal_rvalid),
    .s_axi_rready   (m_axi_eth_internal_rready),

    // Host-Ethernet DMA interface
    .e2h_tdata    (e2h_tdata),
    .e2h_tkeep    (e2h_tkeep),
    .e2h_tlast    (e2h_tlast),
    .e2h_tvalid   (e2h_tvalid),
    .e2h_tready   (e2h_tready),

    .h2e_tdata    (h2e_tdata),
    .h2e_tkeep    (h2e_tkeep),
    .h2e_tlast    (h2e_tlast),
    .h2e_tvalid   (h2e_tvalid),
    .h2e_tready   (h2e_tready),

    // Vita router interface
    .e2v_tdata    (m_axis_dma_tdata),
    .e2v_tlast    (m_axis_dma_tlast),
    .e2v_tvalid   (m_axis_dma_tvalid),
    .e2v_tready   (m_axis_dma_tready),

    .v2e_tdata    (s_axis_dma_tdata),
    .v2e_tlast    (s_axis_dma_tlast),
    .v2e_tvalid   (s_axis_dma_tvalid),
    .v2e_tready   (s_axis_dma_tready),

    // MISC
    .port_info    (),
    .device_id    (device_id),

    .link_up      (),
    .activity     ()
  );

  /////////////////////////////////////////////////////////////////////
  //
  // PS Connections
  //
  //////////////////////////////////////////////////////////////////////

  e31x_ps_bd e31x_ps_bd_inst (

    // DDR Interface
    .DDR_VRN(DDR_VRN),
    .DDR_VRP(DDR_VRP),
    .DDR_addr(DDR_ADDR),
    .DDR_ba(DDR_BANKADDR),
    .DDR_cas_n(DDR_CAS_N),
    .DDR_ck_n(DDR_CLK_N),
    .DDR_ck_p(DDR_CLK),
    .DDR_cke(DDR_CKE),
    .DDR_cs_n(DDR_CS_N),
    .DDR_dm(DDR_DM),
    .DDR_dq(DDR_DQ),
    .DDR_dqs_n(DDR_DQS_N),
    .DDR_dqs_p(DDR_DQS),
    .DDR_odt(DDR_ODT),
    .DDR_ras_n(DDR_RAS_N),
    .DDR_reset_n(DDR_RESET_N),
    .DDR_we_n(DDR_WE_N),

    // Clocks
    .FCLK_CLK0(FCLK_CLK0),
    .FCLK_CLK1(FCLK_CLK1),
    .FCLK_CLK2(FCLK_CLK2),
    .FCLK_CLK3(FCLK_CLK3),

    // Resets
    .FCLK_RESET0_N(FCLK_RESET0_N),

    // GPIO
    .GPIO_0_tri_i(ps_gpio_in),
    .GPIO_0_tri_o(ps_gpio_out),
    .GPIO_0_tri_t(ps_gpio_tri),

    // Interrupts
    .IRQ_F2P(IRQ_F2P),

    // MIO
    .MIO(MIO),

    .PS_CLK(PS_CLK),
    .PS_PORB(PS_PORB),
    .PS_SRSTB(PS_SRSTB),

    // SPI
    .SPI0_MISO_I(CAT_MISO),
    .SPI0_MISO_O(),
    .SPI0_MISO_T(),
    .SPI0_MOSI_I(1'b0),
    .SPI0_MOSI_O(CAT_MOSI),
    .SPI0_MOSI_T(),
    .SPI0_SCLK_I(1'b0),
    .SPI0_SCLK_O(CAT_SCLK),
    .SPI0_SCLK_T(),
    .SPI0_SS1_O(),
    .SPI0_SS2_O(),
    .SPI0_SS_I(1'b1),
    .SPI0_SS_O(CAT_CS),
    .SPI0_SS_T(),

    .SPI1_MISO_I(),
    .SPI1_MISO_O(),
    .SPI1_MISO_T(),
    .SPI1_MOSI_I(),
    .SPI1_MOSI_O(),
    .SPI1_MOSI_T(),
    .SPI1_SCLK_I(),
    .SPI1_SCLK_O(),
    .SPI1_SCLK_T(),
    .SPI1_SS1_O(),
    .SPI1_SS2_O(),
    .SPI1_SS_I(),
    .SPI1_SS_O(),
    .SPI1_SS_T(),

    // Ethernet DMA engines
    .m_axi_eth_internal_araddr(m_axi_eth_internal_araddr),
    .m_axi_eth_internal_arprot(),
    .m_axi_eth_internal_arready(m_axi_eth_internal_arready),
    .m_axi_eth_internal_arvalid(m_axi_eth_internal_arvalid),
    .m_axi_eth_internal_awaddr(m_axi_eth_internal_awaddr),
    .m_axi_eth_internal_awprot(),
    .m_axi_eth_internal_awready(m_axi_eth_internal_awready),
    .m_axi_eth_internal_awvalid(m_axi_eth_internal_awvalid),
    .m_axi_eth_internal_bready(m_axi_eth_internal_bready),
    .m_axi_eth_internal_bresp(m_axi_eth_internal_bresp),
    .m_axi_eth_internal_bvalid(m_axi_eth_internal_bvalid),
    .m_axi_eth_internal_rdata(m_axi_eth_internal_rdata),
    .m_axi_eth_internal_rready(m_axi_eth_internal_rready),
    .m_axi_eth_internal_rresp(m_axi_eth_internal_rresp),
    .m_axi_eth_internal_rvalid(m_axi_eth_internal_rvalid),
    .m_axi_eth_internal_wdata(m_axi_eth_internal_wdata),
    .m_axi_eth_internal_wready(m_axi_eth_internal_wready),
    .m_axi_eth_internal_wstrb(m_axi_eth_internal_wstrb),
    .m_axi_eth_internal_wvalid(m_axi_eth_internal_wvalid),

    // USB
    .USBIND_0_port_indctl(),
    .USBIND_0_vbus_pwrfault(),
    .USBIND_0_vbus_pwrselect(),

    .bus_clk(bus_clk),
    .bus_rstn(~bus_rst),
    .clk40(clk40),
    .clk40_rstn(clk40_rstn),
    .S_AXI_GP0_ACLK(clk40),
    .S_AXI_GP0_ARESETN(clk40_rstn),

    // XBAR Regport
    .m_axi_xbar_araddr(m_axi_xbar_araddr),
    .m_axi_xbar_arprot(m_axi_xbar_arprot),
    .m_axi_xbar_arready(m_axi_xbar_arready),
    .m_axi_xbar_arvalid(m_axi_xbar_arvalid),
    .m_axi_xbar_awaddr(m_axi_xbar_awaddr),
    .m_axi_xbar_awprot(m_axi_xbar_awprot),
    .m_axi_xbar_awready(m_axi_xbar_awready),
    .m_axi_xbar_awvalid(m_axi_xbar_awvalid),
    .m_axi_xbar_bready(m_axi_xbar_bready),
    .m_axi_xbar_bresp(m_axi_xbar_bresp),
    .m_axi_xbar_bvalid(m_axi_xbar_bvalid),
    .m_axi_xbar_rdata(m_axi_xbar_rdata),
    .m_axi_xbar_rready(m_axi_xbar_rready),
    .m_axi_xbar_rresp(m_axi_xbar_rresp),
    .m_axi_xbar_rvalid(m_axi_xbar_rvalid),
    .m_axi_xbar_wdata(m_axi_xbar_wdata),
    .m_axi_xbar_wready(m_axi_xbar_wready),
    .m_axi_xbar_wstrb(m_axi_xbar_wstrb),
    .m_axi_xbar_wvalid(m_axi_xbar_wvalid),

    // DMA
    .s_axis_dma_tdata(e2h_tdata),
    .s_axis_dma_tkeep(e2h_tkeep),
    .s_axis_dma_tlast(e2h_tlast),
    .s_axis_dma_tready(e2h_tready),
    .s_axis_dma_tvalid(e2h_tvalid),
    .m_axis_dma_tdata(h2e_tdata),
    .m_axis_dma_tkeep(h2e_tkeep),
    .m_axis_dma_tlast(h2e_tlast),
    .m_axis_dma_tready(h2e_tready),
    .m_axis_dma_tvalid(h2e_tvalid)
  );

  /////////////////////////////////////////////////////////////////////
  //
  // AD9361 Interface
  //
  /////////////////////////////////////////////////////////////////////

  wire [REG_DWIDTH-1:0] dboard_ctrl;
  wire [REG_DWIDTH-1:0] dboard_status;
  wire mimo_busclk;
  wire tx_pll_lock_busclk, rx_pll_lock_busclk;

  wire codec_arst;
  wire [NUM_CHANNELS*32-1:0] rx_flat, tx_flat;

  wire [11:0] rx_i0, rx_q0, tx_i0, tx_q0;
  wire [11:0] rx_i1, rx_q1, tx_i1, tx_q1;

  wire rx_stb, tx_stb;
  wire [NUM_CHANNELS-1:0] rx_atr, tx_atr;

  assign rx_flat = {rx_i1, 4'd0, rx_q1, 4'd0,
                    rx_i0, 4'd0, rx_q0, 4'd0};

  assign tx_q0 = tx_flat[15:4];
  assign tx_i0 = tx_flat[31:20];
  assign tx_q1 = tx_flat[47:36];
  assign tx_i1 = tx_flat[63:52];

  assign mimo_busclk = dboard_ctrl[0];
  assign codec_arst = dboard_ctrl[1];

  synchronizer synchronizer_tx_pll_lock (
    .clk(bus_clk), .rst(1'b0), .in(CAT_CTRL_OUT[7]), .out(tx_pll_lock_busclk)
  );

  synchronizer synchronizer_rx_pll_lock (
    .clk(bus_clk), .rst(1'b0), .in(CAT_CTRL_OUT[6]), .out(rx_pll_lock_busclk)
  );

  assign dboard_status = {
    20'b0,
    tcxo_status,          // TCXO satus {plllck, is_10meg, is_pps, refclk}
    tx_pll_lock_busclk,   // TX PLL Lock
    rx_pll_lock_busclk,   // RX PLL Lock
    6'b0
  };


  e310_io e310_io (
    //.areset(codec_arst), TODO
    .areset(bus_rst),
    .mimo(mimo_busclk),
    // Baseband sample interface
    .radio_clk(radio_clk),
    .radio_rst(radio_rst),
    .rx_i0(rx_i1),
    .rx_q0(rx_q1),
    .rx_i1(rx_i0),
    .rx_q1(rx_q0),
    .rx_stb(rx_stb),
    .tx_i0(tx_i1),
    .tx_q0(tx_q1),
    .tx_i1(tx_i0),
    .tx_q1(tx_q0),
    .tx_stb(tx_stb),
    // AD9361 interface
    .rx_clk(CAT_DATA_CLK),
    .rx_frame(CAT_RX_FRAME),
    .rx_data(CAT_P0_D),
    .tx_clk(CAT_FB_CLK),
    .tx_frame(CAT_TX_FRAME),
    .tx_data(CAT_P1_D)
  );

  assign CAT_CTRL_IN = 4'b1;
  assign CAT_ENAGC = 1'b1;
  assign CAT_TXNRX = 1'b1;
  assign CAT_ENABLE = 1'b1;
  assign CAT_RESET = ~bus_rst; // Operates active-low, really CAT_RESET_B
  assign CAT_SYNC = 1'b0;

  /////////////////////////////////////////////////////////////////////
  //
  // DB GPIO Interface
  //  - Control Filter Banks
  //  - LEDs
  //
  /////////////////////////////////////////////////////////////////////

  // Flattened Radio GPIO control
  wire [DB_GPIO_WIDTH*NUM_CHANNELS-1:0] db_gpio_out_flat;
  wire [DB_GPIO_WIDTH*NUM_CHANNELS-1:0] db_gpio_ddr_flat;
  wire [DB_GPIO_WIDTH*NUM_CHANNELS-1:0] db_gpio_in_flat;
  wire [32*NUM_CHANNELS-1:0] leds_flat;

  // Radio GPIO control
  wire [DB_GPIO_WIDTH-1:0] db_gpio_in[0:NUM_CHANNELS-1];
  wire [DB_GPIO_WIDTH-1:0] db_gpio_out[0:NUM_CHANNELS-1];
  wire [DB_GPIO_WIDTH-1:0] db_gpio_ddr[0:NUM_CHANNELS-1];
  wire [DB_GPIO_WIDTH-1:0] db_gpio_pins[0:NUM_CHANNELS-1];
  wire [31:0] leds[0:NUM_CHANNELS-1];

  genvar i;
  generate
    for (i = 0; i < NUM_CHANNELS; i = i + 1) begin

      assign db_gpio_in_flat[DB_GPIO_WIDTH*i +: DB_GPIO_WIDTH] = db_gpio_in[i];
      assign db_gpio_out[i] = db_gpio_out_flat[DB_GPIO_WIDTH*i +: DB_GPIO_WIDTH];
      assign db_gpio_ddr[i] = db_gpio_ddr_flat[DB_GPIO_WIDTH*i +: DB_GPIO_WIDTH];
      assign leds[i] = leds_flat[32*i +: 32];

      gpio_atr_io #(
        .WIDTH(DB_GPIO_WIDTH)
      ) gpio_atr_db_inst (
        .clk(radio_clk),
        .gpio_pins(db_gpio_pins[i]),
        .gpio_ddr(db_gpio_ddr[i]),
        .gpio_out(db_gpio_out[i]),
        .gpio_in(db_gpio_in[i])
      );
    end
  endgenerate

  // DB_GPIO and LED pin assignments with software mapping
  // wire [2:0] TX1_BANDSEL;
  // wire [2:0] TX2_BANDSEL;


  assign {LED_RX1_RX,
          LED_TXRX1_TX,
          LED_TXRX1_RX
         } = leds[1];


  assign {LED_RX2_RX,
          LED_TXRX2_TX,
          LED_TXRX2_RX
         } = leds[0];

  // It is okay to OR here as the both channels must be set to the same freq.
  // This is needed so software does not have to set properties of radio core 0
  // when only using radio core 1.
  // assign TX_BANDSEL = TX1_BANDSEL | TX2_BANDSEL;

  /////////////////////////////////////////////////////////////////////
  //
  // Front-Panel GPIO
  //
  /////////////////////////////////////////////////////////////////////

  wire [FP_GPIO_WIDTH-1:0] fp_gpio_in;
  wire [FP_GPIO_WIDTH-1:0] fp_gpio_out;
  wire [FP_GPIO_WIDTH-1:0] fp_gpio_tri;

  gpio_atr_io #(.WIDTH(FP_GPIO_WIDTH)) fp_gpio_atr_inst (
    .clk(radio_clk), .gpio_pins(PL_GPIO),
    .gpio_ddr(fp_gpio_tri), .gpio_out(fp_gpio_out), .gpio_in(fp_gpio_in)
  );

  /////////////////////////////////////////////////////////////////////
  //
  // E310 Core:
  //   - RFNoC Image Core (incl. radio, RFNoC blocks, etc.)
  //   - Other RFNoC controls
  //
  //////////////////////////////////////////////////////////////////////

  wire [31:0] build_datestamp;

  USR_ACCESSE2 usr_access_i (
    .DATA(build_datestamp), .CFGCLK(), .DATAVALID()
  );

  e31x_core #(
    .REG_AWIDTH(REG_AWIDTH),
    .BUS_CLK_RATE(BUS_CLK_RATE),
    .NUM_SFP_PORTS(NUM_SFP_PORTS),
    .NUM_RADIOS(NUM_RADIOS),
    .NUM_CHANNELS_PER_RADIO(NUM_CHANNELS_PER_RADIO),
    .NUM_CHANNELS(NUM_CHANNELS),
    .NUM_DBOARDS(NUM_DBOARDS),
    .NUM_CHANNELS_PER_DBOARD(NUM_CHANNELS_PER_RADIO),
    .FP_GPIO_WIDTH(FP_GPIO_WIDTH),
    .DB_GPIO_WIDTH(DB_GPIO_WIDTH),
    .CHDR_W(CHDR_W),
    .BYTE_MTU(BYTE_MTU),
    .RFNOC_PROTOVER(RFNOC_PROTOVER)
  ) e31x_core_inst (

    //Clocks and resets
    .radio_clk(radio_clk),
    .radio_rst(radio_rst),
    .bus_clk(bus_clk),
    .bus_rst(bus_rst),
    .clk40(clk40),
    .clk200(clk200),

    // Clocking and PPS Controls/Indicators
    .pps_refclk(pps),
    .refclk_locked(reflck),
    .pps_select(pps_select),

    .s_axi_aclk(clk40),
    .s_axi_aresetn(clk40_rstn),
    // AXI4-Lite: Write address port (domain: s_axi_aclk)
    .s_axi_awaddr(m_axi_xbar_awaddr),
    .s_axi_awvalid(m_axi_xbar_awvalid),
    .s_axi_awready(m_axi_xbar_awready),
    // AXI4-Lite: Write data port (domain: s_axi_aclk)
    .s_axi_wdata(m_axi_xbar_wdata),
    .s_axi_wstrb(m_axi_xbar_wstrb),
    .s_axi_wvalid(m_axi_xbar_wvalid),
    .s_axi_wready(m_axi_xbar_wready),
    // AXI4-Lite: Write response port (domain: s_axi_aclk)
    .s_axi_bresp(m_axi_xbar_bresp),
    .s_axi_bvalid(m_axi_xbar_bvalid),
    .s_axi_bready(m_axi_xbar_bready),
    // AXI4-Lite: Read address port (domain: s_axi_aclk)
    .s_axi_araddr(m_axi_xbar_araddr),
    .s_axi_arvalid(m_axi_xbar_arvalid),
    .s_axi_arready(m_axi_xbar_arready),
    // AXI4-Lite: Read data port (domain: s_axi_aclk)
    .s_axi_rdata(m_axi_xbar_rdata),
    .s_axi_rresp(m_axi_xbar_rresp),
    .s_axi_rvalid(m_axi_xbar_rvalid),
    .s_axi_rready(m_axi_xbar_rready),

    // Radio ATR
    .rx_atr(rx_atr),
    .tx_atr(tx_atr),

    // Front-Panel GPIO
    .fp_gpio_in(fp_gpio_in),
    .fp_gpio_tri(fp_gpio_tri),
    .fp_gpio_out(fp_gpio_out),

    // PS GPIO Connection
    .ps_gpio_tri(ps_gpio_tri[FP_GPIO_WIDTH+FP_GPIO_OFFSET-1: FP_GPIO_OFFSET]),
    .ps_gpio_out(ps_gpio_out[FP_GPIO_WIDTH+FP_GPIO_OFFSET-1: FP_GPIO_OFFSET]),
    .ps_gpio_in(ps_gpio_in[FP_GPIO_WIDTH+FP_GPIO_OFFSET-1: FP_GPIO_OFFSET]),

    // DB GPIO
    .db_gpio_out_flat(db_gpio_out_flat),
    .db_gpio_ddr_flat(db_gpio_ddr_flat),
    .db_gpio_in_flat(db_gpio_in_flat),
    .db_gpio_fab_flat(32'b0),

    // TX/RX LEDs
    .leds_flat(leds_flat),

    // Radio Strobes
    .rx_stb({NUM_CHANNELS{rx_stb}}),
    .tx_stb({NUM_CHANNELS{tx_stb}}),

    // Radio Data
    .rx(rx_flat),
    .tx(tx_flat),

    // Internal DMA to PS
    .m_dma_tdata(s_axis_dma_tdata),
    .m_dma_tlast(s_axis_dma_tlast),
    .m_dma_tready(s_axis_dma_tready),
    .m_dma_tvalid(s_axis_dma_tvalid),

    .s_dma_tdata(m_axis_dma_tdata),
    .s_dma_tlast(m_axis_dma_tlast),
    .s_dma_tready(m_axis_dma_tready),
    .s_dma_tvalid(m_axis_dma_tvalid),

    .build_datestamp(build_datestamp),
    .sfp_ports_info(),
    .dboard_status(dboard_status),
    .xadc_readback(32'h0), //Unused
    .fp_gpio_ctrl(), //Unused
    .dboard_ctrl(dboard_ctrl),
    .device_id(device_id)
  );



endmodule // e31x