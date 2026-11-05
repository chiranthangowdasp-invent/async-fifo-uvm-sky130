module sync_2ff #(parameter WIDTH = 5) (
  input  wire             clk,
  input  wire             rst_n,
  input  wire [WIDTH-1:0] d,
  output reg  [WIDTH-1:0] q
);
  reg [WIDTH-1:0] meta;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin meta <= 0; q <= 0; end
    else        begin meta <= d; q <= meta; end
  end
endmodule
