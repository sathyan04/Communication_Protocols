`include "spi_master.sv"
`include "spi_slave.sv"

module top_module #(parameter sys_clk = 50_000_000,  // SOC Clock Freq: 50MHz
                    parameter spi_clk = 10_000_000)  // SPI Clock Freq: 10MHz
  (
    input 			clk,
    input 			rst_n,
    input 			start,
    input [7:0]		main_tx_data,
    input [7:0]		subnode_tx_data,
    
    output [7:0]	main_rx_data,
    output [7:0]	subnode_rx_data,
    output 			done,
    output 			data_valid
  );
  
  wire sclk;
  wire cs_n; 
  wire mosi; 
  wire miso;

  spi_master #(.sys_clk(sys_clk), .spi_clk(spi_clk)) mas(
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .tx_data(main_tx_data),
    .rx_data(main_rx_data),
    .done(done),
    .sclk(sclk),
    .mosi(mosi),
    .miso(miso),
    .cs_n(cs_n)
  );
  
  spi_slave slv(
    .clk(clk),
    .rst_n(rst_n),
    .sclk(sclk),
    .cs_n(cs_n),
    .mosi(mosi),
    .miso(miso),
    .tx_data(subnode_tx_data),
    .rx_data(subnode_rx_data),
    .data_valid(data_valid)
  );
  
endmodule
