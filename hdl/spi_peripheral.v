module spi_peripheral (
    input clk,
    input rst,

    input [31:0] addr,
    input we,
    input [31:0] wd,
    output [31:0] rd,

    input spi_miso,
    output reg spi_mosi,
    output reg spi_sclk,
    output reg spi_cs_n
);
  /// REGISTERS
  localparam [31:0]
      tx_data_addr = 32'h400,
      tx_length_addr = 32'h404,
      rx_data_addr = 32'h408,
      rx_length_addr = 32'h405,
      x_start_addr = 32'h406;

  wire [31:0] tx_data;
  wire [ 7:0] tx_length;
  wire [ 7:0] rx_length;

  reg  [31:0] rx_data;
  assign rd = rx_data;
  wire x_start = we && addr == x_start_addr;

  register_we tx_data_reg (
      .clk(clk),
      .rst(rst),
      .we (we && addr == tx_data_addr),
      .d  (wd),
      .q  (tx_data)
  );

  register_we #(
      .W(8)
  ) tx_length_reg (
      .clk(clk),
      .rst(rst),
      .we (we && addr == tx_length_addr),
      .d  (wd[7:0]),
      .q  (tx_length)
  );

  register_we #(
      .W(8)
  ) rx_length_reg (
      .clk(clk),
      .rst(rst),
      .we (we && addr == rx_length_addr),
      .d  (wd[7:0]),
      .q  (rx_length)
  );


  /// SPI FSM
  localparam [1:0] IDLE = 2'd0, WRITE = 2'd1, READ = 2'd2;

  reg [1:0] state, next_state;

  reg [1:0] byte_counter;
  reg [2:0] bit_counter;
  wire [4:0] target_bit = {byte_counter, bit_counter};

  reg [5:0] sclk_divider;
  wire sclk_tick = (sclk_divider == 0);
  wire sclk_rising = (sclk_tick && spi_sclk == 0);
  wire sclk_falling = (sclk_tick && spi_sclk == 1);

  always @(*) begin
    next_state = state;

    case (state)
      IDLE: if (x_start) next_state = WRITE;

      WRITE: begin
        if (byte_counter == (tx_length - 1) && bit_counter == 0 && sclk_falling) begin
          if (rx_length > 0) next_state = READ;
          else next_state = IDLE;
        end
      end

      READ: begin
        if (byte_counter == (rx_length - 1) && bit_counter == 0 && sclk_falling) begin
          next_state = IDLE;
        end
      end

      default: next_state = IDLE;
    endcase
  end

  always @(posedge clk) begin
    if (rst) begin
      state <= IDLE;
      bit_counter <= 3'b111;
      byte_counter <= 2'b00;
      sclk_divider <= 6'd49;
      spi_mosi <= 0;
      spi_cs_n <= 1;
      spi_sclk <= 0;
      rx_data <= 0;
    end else begin
      state <= next_state;

      if (sclk_tick) sclk_divider <= 6'd49;
      else sclk_divider <= sclk_divider - 1;

      // reset on state change
      if (state != next_state) begin
        bit_counter  <= 3'b111;
        byte_counter <= 2'b00;
      end

      case (state)
        IDLE: begin
          spi_cs_n <= 1;
          spi_sclk <= 0;
          if (x_start) begin
            sclk_divider <= 6'd49;
            spi_cs_n <= 0;  // CS setup time min 100ns
            spi_mosi <= tx_data[7];
          end
        end

        WRITE: begin
          spi_cs_n <= 0;
          if (sclk_tick) spi_sclk <= ~spi_sclk;

          if (sclk_falling) begin
            bit_counter <= bit_counter - 1;
            if (bit_counter != 0) begin  // current byte's next bit
              spi_mosi <= tx_data[{byte_counter, bit_counter-3'b001}];
            end else if (next_state == WRITE) begin  // there is next byte to write
              byte_counter <= byte_counter + 1;
              spi_mosi <= tx_data[{byte_counter+2'b01, 3'b111}];  // next byte's MSB
            end
          end
        end

        READ: begin
          spi_cs_n <= 0;
          if (sclk_tick) spi_sclk <= ~spi_sclk;

          if (sclk_rising) begin  // sample on rising edge
            rx_data[target_bit] <= spi_miso;
          end

          if (sclk_falling) begin
            bit_counter <= bit_counter - 1;  // always decrement
            if (bit_counter == 0 && next_state == READ) begin  // there is next byte to read
              byte_counter <= byte_counter + 1;
            end
          end
        end

        default: ;
      endcase
    end
  end
endmodule
