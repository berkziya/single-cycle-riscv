module riscv_memory (
    input             clk,
    input             WE,
    input      [ 2:0] MemOp,
    input      [31:0] ADDR,
    input      [31:0] WD,
    output reg [31:0] RD
);

  reg [7:0] mem[511:0];

  wire [7:0] b0 = mem[ADDR];
  wire [7:0] b1 = mem[ADDR+1];
  wire [7:0] b2 = mem[ADDR+2];
  wire [7:0] b3 = mem[ADDR+3];

  // loads
  always @(*) begin
    case (MemOp)
      3'b000:  RD = {{24{b0[7]}}, b0};  // lb
      3'b001:  RD = {{16{b1[7]}}, b1, b0};  // lh
      3'b010:  RD = {b3, b2, b1, b0};  // lw
      3'b100:  RD = {24'b0, b0};  // lbu
      3'b101:  RD = {16'b0, b1, b0};  // lhu
      default: RD = {b3, b2, b1, b0};
    endcase
  end

  // stores
  always @(posedge clk) begin
    if (WE) begin
      case (MemOp)
        3'b000: begin  // sb
          mem[ADDR] <= WD[7:0];
        end

        3'b001: begin  // sh
          mem[ADDR]   <= WD[7:0];
          mem[ADDR+1] <= WD[15:8];
        end

        3'b010: begin  // sw
          mem[ADDR]   <= WD[7:0];
          mem[ADDR+1] <= WD[15:8];
          mem[ADDR+2] <= WD[23:16];
          mem[ADDR+3] <= WD[31:24];
        end
        default: ;
      endcase
    end
  end

endmodule
