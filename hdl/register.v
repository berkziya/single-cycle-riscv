module register #(
    W = 32
) (
    input clk,
    input rst,
    input [W-1:0] d,

    output reg [W-1:0] q
);

  initial q = 0;

  always @(posedge clk) begin
    if (rst) q <= 0;
    else q <= d;
  end

endmodule
