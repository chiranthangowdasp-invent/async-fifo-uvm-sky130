module wptr_full #(parameter ADDR_WIDTH = 4) (
  input  wire                  wclk,
  input  wire                  wrst_n,
  input  wire                  winc,
  input  wire [ADDR_WIDTH:0]   wq2_rptr,
  output reg                   wfull,
  output wire [ADDR_WIDTH-1:0] waddr,
  output reg  [ADDR_WIDTH:0]   wptr
);
  reg  [ADDR_WIDTH:0] wbin;
  wire [ADDR_WIDTH:0] wbin_next  = wbin + (winc & ~wfull);
  wire [ADDR_WIDTH:0] wgray_next = (wbin_next >> 1) ^ wbin_next;
  wire wfull_val = (wgray_next == {~wq2_rptr[ADDR_WIDTH:ADDR_WIDTH-1],
                                    wq2_rptr[ADDR_WIDTH-2:0]});
  assign waddr = wbin[ADDR_WIDTH-1:0];
  always @(posedge wclk or negedge wrst_n) begin
    if (!wrst_n) begin wbin <= 0; wptr <= 0; wfull <= 1'b0; end
    else         begin wbin <= wbin_next; wptr <= wgray_next; wfull <= wfull_val; end
  end
endmodule
