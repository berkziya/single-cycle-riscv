module debouncer (
    input clk,
    input [4:0] buttons,
    output reg [4:0] out
);

  localparam UPCOUNT = 10000000;

  reg [31:0] count[4:0];

  genvar i;
  generate
    for (i = 0; i < 5; i = i + 1) begin
      always @(posedge clk) begin
        if (out[i] == 0) begin
          if (count[i] == UPCOUNT) begin
            if (buttons[i] == 1) out[i] <= 1;
            else out[i] <= 0;
          end else begin
            count[i] <= count[i] + 1;
            out[i]   <= 0;
          end
        end else begin
          if (count[i] == 0) begin
            if (buttons[i] == 0) out[i] <= 0;
            else out[i] <= 1;
          end else begin
            count[i] <= count[i] - 1;
            out[i]   <= 1;
          end
        end
      end
    end
  endgenerate

endmodule
