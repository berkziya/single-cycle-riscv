module controller (
    input [31:0] Instr,
    input Zero,
    input lt,
    input ltu,

    output reg [1:0] PCSrc,
    output reg [1:0] ResultSrc,
    output reg       MemWrite,
    output reg [3:0] ALUControl,
    output reg [1:0] ALUSrcA,
    output reg       ALUSrcB,
    output reg [2:0] ImmSrc,
    output reg       RegWrite,
    output reg [2:0] MemOp
);

  wire [6:0] op = Instr[6:0];
  wire [2:0] funct3 = Instr[14:12];
  wire [6:0] funct7 = Instr[31:25];

  reg Branch;
  reg [1:0] ALUOp, Jump;

  //// Main Decoder source: ch7.3 table7.6
  always @(*) begin
    Branch = 0;  // default: pc = pc + 4
    Jump = 0;
    ResultSrc = 0;
    MemWrite = 0;
    ALUOp = 0;
    ALUSrcA = 0;
    ALUSrcB = 0;
    ImmSrc = 0;
    RegWrite = 0;
    MemOp = 3'b010;  // default is word

    case (op)
      7'b0000011: begin  // loads
        RegWrite = 1;
        ALUSrcB = 1;
        ResultSrc = 2'b01;  // rd = mem[ALUResult]
        MemOp = funct3;
      end

      7'b0100011: begin  // stores
        ImmSrc   = 3'd1;  // S-type
        ALUSrcB  = 1;
        MemWrite = 1;
        MemOp    = funct3;
      end

      7'b0110011: begin  // R-type
        RegWrite = 1;
        ALUOp = 2'b10;
      end

      7'b1100011: begin  // beq
        ImmSrc = 3'd2;
        Branch = 1;
        ALUOp  = 2'b01;
      end

      7'b0010011: begin  // I-type ALU
        RegWrite = 1;
        ALUSrcB = 1;
        ALUOp = 2'b10;
      end

      7'b1101111: begin  // jal
        RegWrite  = 1;
        ImmSrc    = 3'd3;  // J-type
        Jump      = 2'b01;  // pc = PCTarget = pc + imm
        ResultSrc = 2'b10;  // rd = PCPlus4
      end

      7'b1100111: begin  // jalr
        RegWrite  = 1;
        ImmSrc    = 3'd0;  // I-type
        ALUSrcB   = 1;  // SrcB = imm
        Jump      = 2'b10;  // pc = ALUResult = rs1 + imm
        ResultSrc = 2'b10;  // rd = PCPlus4
      end

      7'b0110111: begin  // lui
        RegWrite  = 1;
        ImmSrc    = 3'd4;  // U-type
        ALUSrcA   = 2'b10;  // SrcA = 32'b0
        ALUSrcB   = 1;  // SrcB = imm
        ResultSrc = 2'b00;  // rd = ALUResult = 0 + imm
      end

      7'b0010111: begin  // auipc
        RegWrite  = 1;
        ImmSrc    = 3'd4;  // U-type
        ALUSrcA   = 2'b01;  // SrcA = pc
        ALUSrcB   = 1;  // SrcB = imm
        ResultSrc = 2'b00;  // rd = ALUResult = pc + imm
      end

      default: ;
    endcase
  end


  /// PCSrc Decoder
  reg Taken;
  always @(*) begin
    case (funct3)
      3'b000:  Taken = Zero;
      3'b001:  Taken = ~Zero;
      3'b100:  Taken = lt;
      3'b101:  Taken = ~lt;
      3'b110:  Taken = ltu;
      3'b111:  Taken = ~ltu;
      default: Taken = 0;
    endcase
  end

  always @(*) begin
    if (Jump == 2'b10) PCSrc = 2'b10;  // jalr: rs1+imm
    else if ((Branch & Taken) | (Jump == 2'b01)) begin
      PCSrc = 2'b01;  // jal or branch: PCTarget
    end else PCSrc = 2'b00;  // default: pc + 4
  end


  //// ALU Decoder source: ch7.3 table7.3
  always @(*) begin
    case (ALUOp)
      2'b00: ALUControl = 4'b0000;  // lw/sw/lui/auipc/jalr: add
      2'b01: ALUControl = 4'b0001;  // beq: sub
      2'b10: begin  // R-type or I-type ALU
        case (funct3)
          3'b000: ALUControl = (op[5] && funct7[5]) ? 4'b0001 : 4'b0000;  // sub/add
          3'b010: ALUControl = 4'b0101;  // slt
          3'b110: ALUControl = 4'b0011;  // or
          3'b111: ALUControl = 4'b0010;  // and

          3'b100:  ALUControl = 4'b0100;  // xor
          3'b011:  ALUControl = 4'b0110;  // sltu
          3'b001:  ALUControl = 4'b0111;  // sll
          3'b101:  ALUControl = (funct7[5]) ? 4'b1001 : 4'b1000;  // srl/sra
          default: ALUControl = 4'b0000;
        endcase
      end

      default: ALUControl = 4'b0000;
    endcase
  end

endmodule
