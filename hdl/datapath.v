module datapath (
    input clk,
    input rst,

    input [1:0] PCSrc,
    input [1:0] ResultSrc,
    input MemWrite,
    input [3:0] ALUControl,
    input [1:0] ALUSrcA,
    input ALUSrcB,
    input [2:0] ImmSrc,
    input RegWrite,
    input [2:0] MemOp,

    output [31:0] Instr,
    output Zero,
    output lt,
    output ltu,

    input  [ 4:0] debug_reg_select,
    output [31:0] debug_reg_out,
    output [31:0] PC,

    input  spi_miso,
    output spi_mosi,
    output spi_sclk,
    output spi_cs_n
);

  wire [31:0] ALUResult, PCTarget, PCPlus4, PCNext, ImmExt;

  mux #(
      .IN_DIM(3)
  ) mux_pcnext (
      .in ({ALUResult, PCTarget, PCPlus4}),
      .sel(PCSrc),
      .out(PCNext)
  );

  register pc_reg (
      .clk(clk),
      .rst(rst),
      .d  ({PCNext[31:1], 1'b0}),  // for our lovely lovely jalr
      .q  (PC)
  );

  adder adder_pcplus4 (
      .DATA_A(PC),
      .DATA_B(32'd4),
      .OUT(PCPlus4)
  );

  instruction_mem imem (
      .ADDR(PC),
      .RD  (Instr)
  );

  extender ext (
      .Instr (Instr),
      .ImmSrc(ImmSrc),
      .ImmExt(ImmExt)
  );

  adder adder_pctarget (
      .DATA_A(PC),
      .DATA_B(ImmExt),
      .OUT(PCTarget)
  );

  wire [31:0] RD1, RD2, SrcA, SrcB, Result;
  register_file regfile (
      .clk       (clk),
      .rst       (rst),
      .ADDR1     (Instr[19:15]),
      .ADDR2     (Instr[24:20]),
      .ADDR3     (Instr[11:7]),
      .WD3       (Result),
      .we        (RegWrite),
      .RD1       (RD1),
      .RD2       (RD2),
      .debug_addr(debug_reg_select),
      .debug_data(debug_reg_out)
  );

  mux #(
      .IN_DIM(3)
  ) mux_srca (
      .in ({32'b0, PC, RD1}),
      .sel(ALUSrcA),
      .out(SrcA)
  );

  mux #(
      .IN_DIM(2)
  ) mux_srcb (
      .in ({ImmExt, RD2}),
      .sel(ALUSrcB),
      .out(SrcB)
  );

  alu alu_i (
      .a      (SrcA),
      .b      (SrcB),
      .control(ALUControl),
      .out    (ALUResult),
      .zero   (Zero),
      .lt     (lt),
      .ltu    (ltu)
  );

  wire WE_mem, WE_spi, RD_sel;
  address_decoder addr_decoder (
      .addr    (ALUResult),
      .MemWrite(MemWrite),
      .WE_mem  (WE_mem),
      .WE_spi  (WE_spi),
      .RD_sel  (RD_sel)
  );

  wire [31:0] MemResult;
  riscv_memory data_mem (
      .clk  (clk),
      .WE   (WE_mem),
      .MemOp(MemOp),
      .ADDR (ALUResult),
      .WD   (RD2),
      .RD   (MemResult)
  );

  wire [31:0] SPIResult;
  spi_peripheral spi (
      .clk     (clk),
      .rst     (rst),
      .we      (WE_spi),
      .addr    (ALUResult),
      .wd      (RD2),
      .rd      (SPIResult),
      .spi_miso(spi_miso),
      .spi_mosi(spi_mosi),
      .spi_sclk(spi_sclk),
      .spi_cs_n(spi_cs_n)
  );

  wire [31:0] ReadData;
  mux #(
      .IN_DIM(2)
  ) mux_read_data (
      .in ({SPIResult, MemResult}),
      .sel(RD_sel),
      .out(ReadData)
  );

  mux #(
      .IN_DIM(3)
  ) mux_result (
      .in ({PCPlus4, ReadData, ALUResult}),
      .sel(ResultSrc),
      .out(Result)
  );

endmodule
