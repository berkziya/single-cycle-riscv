module extender (
    input [31:0] Instr,  // assuming the compiler ignores the unused bits
    input [2:0] ImmSrc,
    output reg [31:0] ImmExt
);

  /// source: ch7.3.4 table7.5
  always @(*) begin
    case (ImmSrc)
      3'd0:  ImmExt = {{20{Instr[31]}}, Instr[31:20]};  // I-type
      3'd1:  ImmExt = {{20{Instr[31]}}, Instr[31:25], Instr[11:7]};  // S-type
      3'd2:  ImmExt = {{20{Instr[31]}}, Instr[7], Instr[30:25], Instr[11:8], 1'b0};  // B-type
      3'd3:  ImmExt = {{12{Instr[31]}}, Instr[19:12], Instr[20], Instr[30:21], 1'b0};  // J-type
      3'd4:  ImmExt = {Instr[31:12], 12'b0};  // U-type
      default: ImmExt = 32'd0;
    endcase
  end


endmodule
