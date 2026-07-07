module single_cycle_riscv (
    input clk,
    input rst,
    input [4:0] debug_reg_select,

    output [31:0] debug_reg_out,
    output [31:0] PC,

    input  spi_miso,
    output spi_mosi,
    output spi_sclk,
    output spi_cs_n
);
  wire [31:0] Instr;
  wire Zero, lt, ltu;

  wire ALUSrcB, MemWrite, RegWrite;
  wire [1:0] PCSrc, ALUSrcA, ResultSrc;
  wire [2:0] ImmSrc, MemOp;
  wire [3:0] ALUControl;

  datapath my_datapath (
      .clk(clk),
      .rst(rst),
      .PCSrc(PCSrc),
      .ResultSrc(ResultSrc),
      .MemWrite(MemWrite),
      .ALUControl(ALUControl),
      .ALUSrcA(ALUSrcA),
      .ALUSrcB(ALUSrcB),
      .ImmSrc(ImmSrc),
      .RegWrite(RegWrite),
      .MemOp(MemOp),

      .Instr(Instr),
      .Zero(Zero),
      .lt(lt),
      .ltu(ltu),

      .debug_reg_select(debug_reg_select),
      .debug_reg_out(debug_reg_out),
      .PC(PC),

      .spi_miso(spi_miso),
      .spi_mosi(spi_mosi),
      .spi_sclk(spi_sclk),
      .spi_cs_n(spi_cs_n)
  );

  controller my_controller (
      .Instr(Instr),
      .Zero(Zero),
      .lt(lt),
      .ltu(ltu),

      .PCSrc(PCSrc),
      .ResultSrc(ResultSrc),
      .MemWrite(MemWrite),
      .ALUControl(ALUControl),
      .ALUSrcA(ALUSrcA),
      .ALUSrcB(ALUSrcB),
      .ImmSrc(ImmSrc),
      .RegWrite(RegWrite),
      .MemOp(MemOp)
  );

endmodule
