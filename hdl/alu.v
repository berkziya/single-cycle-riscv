module alu (
    input [31:0] a,
    input [31:0] b,
    input [ 3:0] control,

    output reg [31:0] out,
    output reg        zero,
    output reg        lt,
    output reg        ltu
);

  // 0000: add
  // 0001: sub
  // 0010: and
  // 0011: or
  // 0100: xor
  // 0101: slt
  // 0110: sltu
  // 0111: sll
  // 1000: srl
  // 1001: sra

  always @(*) begin
    case (control)
      4'b0000: out = a + b;
      4'b0001: out = a - b;
      4'b0010: out = a & b;
      4'b0011: out = a | b;
      4'b0100: out = a ^ b;
      4'b0101: out = ($signed(a) < $signed(b)) ? 32'b1 : 32'b0;
      4'b0110: out = (a < b) ? 32'b1 : 32'b0;
      4'b0111: out = a << b[4:0];
      4'b1000: out = a >> b[4:0];
      4'b1001: out = $signed(a) >>> b[4:0];
      default: out = 32'b0;
    endcase

    zero = (out == 32'b0);
    lt   = ($signed(a) < $signed(b));
    ltu  = (a < b);
  end
endmodule
