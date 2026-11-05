`timescale 1ns/1ps
interface fifo_if #(parameter DATA_WIDTH = 8) (input logic wclk, input logic rclk);
  logic                  wrst_n, rrst_n;
  logic                  winc, rinc;
  logic [DATA_WIDTH-1:0] wdata, rdata;
  logic                  wfull, rempty;
  real whalf = 5.0;   // write clock half-period in ns
  real rhalf = 6.5;   // read clock half-period in ns
  int unsigned wr_blocked = 0, rd_blocked = 0;  // attempts made while FIFO full / empty
  always @(posedge wclk) if (wrst_n && winc && wfull)  wr_blocked++;
  always @(posedge rclk) if (rrst_n && rinc && rempty) rd_blocked++;

  // Driver clocking blocks: drive 1 ns after the edge, sample just before it
  clocking wcb @(posedge wclk);
    default input #1step output #1;
    output winc, wdata;
    input  wfull;
  endclocking

  clocking rcb @(posedge rclk);
    default input #1step output #1;
    output rinc;
    input  rdata, rempty;
  endclocking

  // Monitor clocking blocks: sample only (what the DUT saw at each edge)
  clocking wmon @(posedge wclk);
    default input #1step;
    input winc, wdata, wfull;
  endclocking

  clocking rmon @(posedge rclk);
    default input #1step;
    input rinc, rdata, rempty;
  endclocking
endinterface
