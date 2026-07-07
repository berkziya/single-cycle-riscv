module address_decoder (
    input [31:0] addr,
    input        MemWrite,

    output WE_mem,
    output WE_spi,
    output RD_sel
);

  wire its_SPI_addr = (addr >= 32'h400 && addr <= 32'h408);

  assign WE_spi = MemWrite & its_SPI_addr;
  assign WE_mem = MemWrite & ~its_SPI_addr;

  assign RD_sel = its_SPI_addr;

endmodule
