module rptr_empty #(parameter ADDR_WIDTH = 4) (
  input  wire                  rclk,
  input  wire                  rrst_n,
  input  wire                  rinc,
  input  wire [ADDR_WIDTH:0]   rq2_wptr,
  output reg                   rempty,
  output wire [ADDR_WIDTH-1:0] raddr,
  output reg  [ADDR_WIDTH:0]   rptr
);
  reg  [ADDR_WIDTH:0] rbin;
  wire [ADDR_WIDTH:0] rbin_next  = rbin + (rinc & ~rempty);
  wire [ADDR_WIDTH:0] rgray_next = (rbin_next >> 1) ^ rbin_next;
  assign raddr = rbin[ADDR_WIDTH-1:0];
  always @(posedge rclk or negedge rrst_n) begin
    if (!rrst_n) begin rbin <= 0; rptr <= 0; rempty <= 1'b1; end
    else         begin rbin <= rbin_next; rptr <= rgray_next;
                       rempty <= (rgray_next == rq2_wptr); end
  end
endmodule
