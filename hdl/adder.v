module adder #(
    W = 32
) (
    input  [W-1:0] DATA_A,
    input  [W-1:0] DATA_B,
    output [W-1:0] OUT
);

  assign OUT = DATA_A + DATA_B;

endmodule
