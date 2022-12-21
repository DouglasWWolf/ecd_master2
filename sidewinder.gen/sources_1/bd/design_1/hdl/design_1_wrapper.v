//Copyright 1986-2021 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2021.1 (lin64) Build 3247384 Thu Jun 10 19:36:07 MDT 2021
//Date        : Wed Dec 21 10:58:48 2022
//Host        : simtool-5 running 64-bit Ubuntu 20.04.5 LTS
//Command     : generate_target design_1_wrapper.bd
//Design      : design_1_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module design_1_wrapper
   (clk_100mhz_clk_n,
    clk_100mhz_clk_p,
    led_pci_link_up,
    pb_rst_n,
    pci_refclk_clk_n,
    pci_refclk_clk_p,
    pcie_mgt_rxn,
    pcie_mgt_rxp,
    pcie_mgt_txn,
    pcie_mgt_txp,
    qsfp0_clk_clk_n,
    qsfp0_clk_clk_p,
    qsfp0_rx_rxn,
    qsfp0_rx_rxp,
    qsfp0_tx_txn,
    qsfp0_tx_txp,
    qsfp0_up,
    qsfp1_clk_clk_n,
    qsfp1_clk_clk_p,
    qsfp1_rx_rxn,
    qsfp1_rx_rxp,
    qsfp1_tx_txn,
    qsfp1_tx_txp,
    qsfp1_up);
  input [0:0]clk_100mhz_clk_n;
  input [0:0]clk_100mhz_clk_p;
  output led_pci_link_up;
  input pb_rst_n;
  input [0:0]pci_refclk_clk_n;
  input [0:0]pci_refclk_clk_p;
  input [15:0]pcie_mgt_rxn;
  input [15:0]pcie_mgt_rxp;
  output [15:0]pcie_mgt_txn;
  output [15:0]pcie_mgt_txp;
  input qsfp0_clk_clk_n;
  input qsfp0_clk_clk_p;
  input [0:3]qsfp0_rx_rxn;
  input [0:3]qsfp0_rx_rxp;
  output [0:3]qsfp0_tx_txn;
  output [0:3]qsfp0_tx_txp;
  output qsfp0_up;
  input qsfp1_clk_clk_n;
  input qsfp1_clk_clk_p;
  input [0:3]qsfp1_rx_rxn;
  input [0:3]qsfp1_rx_rxp;
  output [0:3]qsfp1_tx_txn;
  output [0:3]qsfp1_tx_txp;
  output qsfp1_up;

  wire [0:0]clk_100mhz_clk_n;
  wire [0:0]clk_100mhz_clk_p;
  wire led_pci_link_up;
  wire pb_rst_n;
  wire [0:0]pci_refclk_clk_n;
  wire [0:0]pci_refclk_clk_p;
  wire [15:0]pcie_mgt_rxn;
  wire [15:0]pcie_mgt_rxp;
  wire [15:0]pcie_mgt_txn;
  wire [15:0]pcie_mgt_txp;
  wire qsfp0_clk_clk_n;
  wire qsfp0_clk_clk_p;
  wire [0:3]qsfp0_rx_rxn;
  wire [0:3]qsfp0_rx_rxp;
  wire [0:3]qsfp0_tx_txn;
  wire [0:3]qsfp0_tx_txp;
  wire qsfp0_up;
  wire qsfp1_clk_clk_n;
  wire qsfp1_clk_clk_p;
  wire [0:3]qsfp1_rx_rxn;
  wire [0:3]qsfp1_rx_rxp;
  wire [0:3]qsfp1_tx_txn;
  wire [0:3]qsfp1_tx_txp;
  wire qsfp1_up;

  design_1 design_1_i
       (.clk_100mhz_clk_n(clk_100mhz_clk_n),
        .clk_100mhz_clk_p(clk_100mhz_clk_p),
        .led_pci_link_up(led_pci_link_up),
        .pb_rst_n(pb_rst_n),
        .pci_refclk_clk_n(pci_refclk_clk_n),
        .pci_refclk_clk_p(pci_refclk_clk_p),
        .pcie_mgt_rxn(pcie_mgt_rxn),
        .pcie_mgt_rxp(pcie_mgt_rxp),
        .pcie_mgt_txn(pcie_mgt_txn),
        .pcie_mgt_txp(pcie_mgt_txp),
        .qsfp0_clk_clk_n(qsfp0_clk_clk_n),
        .qsfp0_clk_clk_p(qsfp0_clk_clk_p),
        .qsfp0_rx_rxn(qsfp0_rx_rxn),
        .qsfp0_rx_rxp(qsfp0_rx_rxp),
        .qsfp0_tx_txn(qsfp0_tx_txn),
        .qsfp0_tx_txp(qsfp0_tx_txp),
        .qsfp0_up(qsfp0_up),
        .qsfp1_clk_clk_n(qsfp1_clk_clk_n),
        .qsfp1_clk_clk_p(qsfp1_clk_clk_p),
        .qsfp1_rx_rxn(qsfp1_rx_rxn),
        .qsfp1_rx_rxp(qsfp1_rx_rxp),
        .qsfp1_tx_txn(qsfp1_tx_txn),
        .qsfp1_tx_txp(qsfp1_tx_txp),
        .qsfp1_up(qsfp1_up));
endmodule
