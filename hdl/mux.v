module mux #(
    IN_DIM = 2,
    W = 32
) (
    input [IN_DIM*W-1:0] in,
    input [$clog2(IN_DIM)-1:0] sel,

    output reg [W-1:0] out
);

  always @(*) out = in[sel*W+:W];

endmodule
