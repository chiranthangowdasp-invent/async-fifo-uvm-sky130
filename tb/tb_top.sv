`timescale 1ns/1ps
module tb_top;
  import uvm_pkg::*;
  import fifo_pkg::*;
  `include "uvm_macros.svh"

  logic wclk = 0, rclk = 0;

  fifo_if #(8) vif (wclk, rclk);

  // Half-periods live in the interface so a test can change the clock ratio
  always #(vif.whalf) wclk = ~wclk;
  always #(vif.rhalf) rclk = ~rclk;

  async_fifo #(8, 4) dut (
    .wclk(wclk), .wrst_n(vif.wrst_n), .winc(vif.winc), .wdata(vif.wdata), .wfull(vif.wfull),
    .rclk(rclk), .rrst_n(vif.rrst_n), .rinc(vif.rinc), .rdata(vif.rdata), .rempty(vif.rempty));

  initial begin                  // reset both domains, then release
    vif.wrst_n = 0; vif.rrst_n = 0;
    vif.winc = 0;   vif.rinc = 0;  vif.wdata = 0;
    #50;
    vif.wrst_n = 1; vif.rrst_n = 1;
  end

  initial begin
    uvm_config_db#(virtual fifo_if)::set(null, "*", "vif", vif);
    run_test();
  end
endmodule
