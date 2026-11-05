module fifo_mem #(parameter DATA_WIDTH = 8, ADDR_WIDTH = 4) (
  input  wire                  wclk,
  input  wire                  wen,
  input  wire [ADDR_WIDTH-1:0] waddr,
  input  wire [ADDR_WIDTH-1:0] raddr,
  input  wire [DATA_WIDTH-1:0] wdata,
  output wire [DATA_WIDTH-1:0] rdata
);
  localparam DEPTH = 1 << ADDR_WIDTH;
  reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
  always @(posedge wclk) if (wen) mem[waddr] <= wdata;
  assign rdata = mem[raddr];
endmodule
