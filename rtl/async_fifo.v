module async_fifo #(parameter DATA_WIDTH = 8, ADDR_WIDTH = 4) (
  input  wire                  wclk, wrst_n, winc,
  input  wire [DATA_WIDTH-1:0] wdata,
  output wire                  wfull,
  input  wire                  rclk, rrst_n, rinc,
  output wire [DATA_WIDTH-1:0] rdata,
  output wire                  rempty
);
  wire [ADDR_WIDTH-1:0] waddr, raddr;
  wire [ADDR_WIDTH:0]   wptr, rptr, wq2_rptr, rq2_wptr;

  sync_2ff #(ADDR_WIDTH+1) sync_r2w (.clk(wclk), .rst_n(wrst_n), .d(rptr), .q(wq2_rptr));
  sync_2ff #(ADDR_WIDTH+1) sync_w2r (.clk(rclk), .rst_n(rrst_n), .d(wptr), .q(rq2_wptr));

  fifo_mem #(DATA_WIDTH, ADDR_WIDTH) u_mem (
    .wclk(wclk), .wen(winc & ~wfull), .waddr(waddr), .raddr(raddr),
    .wdata(wdata), .rdata(rdata));

  wptr_full  #(ADDR_WIDTH) u_wptr (.wclk(wclk), .wrst_n(wrst_n), .winc(winc),
    .wq2_rptr(wq2_rptr), .wfull(wfull), .waddr(waddr), .wptr(wptr));

  rptr_empty #(ADDR_WIDTH) u_rptr (.rclk(rclk), .rrst_n(rrst_n), .rinc(rinc),
    .rq2_wptr(rq2_wptr), .rempty(rempty), .raddr(raddr), .rptr(rptr));
endmodule
