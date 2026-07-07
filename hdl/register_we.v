module register_we #(
    W = 32
) (
    input clk,
    input rst,
    input [W-1:0] d,
    input we,

    output reg [W-1:0] q
);

  initial q = 0;

  always @(posedge clk) begin
    if (rst) q <= 0;
    else if (we) q <= d;
  end

endmodule
