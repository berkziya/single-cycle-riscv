module register_file (
    input clk,
    input rst,
    input [4:0] ADDR1,
    input [4:0] ADDR2,
    input [4:0] ADDR3,
    input [31:0] WD3,
    input we,

    output [31:0] RD1,
    output [31:0] RD2,

    input  [ 4:0] debug_addr,
    output [31:0] debug_data
);
  reg [31:0] x[31:1];  // x0 is zero

  integer i;
  always @(posedge clk) begin
    if (rst) for (i = 1; i < 32; i = i + 1) x[i] <= 32'b0;
    else if (we && (ADDR3 != 0)) x[ADDR3] <= WD3;
  end

  assign RD1 = (ADDR1 == 0) ? 32'b0 : x[ADDR1];
  assign RD2 = (ADDR2 == 0) ? 32'b0 : x[ADDR2];
  assign debug_data = (debug_addr == 0) ? 32'b0 : x[debug_addr];

endmodule
