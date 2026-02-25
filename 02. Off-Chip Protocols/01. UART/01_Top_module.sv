//`timescale 1ns/1ps

`include "tx_baud_generator.sv"
`include "rx_baud_generator.sv"
`include "transmitter.sv"
`include "receiver.sv"

module uart_top #(
  parameter tx_sys_clk = 10_000_000,
  parameter rx_sys_clk = 50_000_000,
  parameter baud_rate = 9600,
  parameter data_width = 8)
  (
    input tx_clk, 
    input rx_clk, 
    input rst, 
    input baud_en,
    input rx, 
    input tx_en, 
    input parity_en, 
    input odd_or_even_parity,
    input [data_width-1:0] data_in,
    
    output tx, 
    output busy, 
    output done, 
    output framing_error, 
    output parity_error,
    output [data_width-1:0] data_out
  );
  
  wire tx_tick;
  wire rx_tick;
  
  tx_baud_generator #(.sys_clk(tx_sys_clk), .baud_rate(baud_rate)) 
  t_gen(
    .clk(tx_clk), 
    .rst(rst), 
    .baud_en(baud_en), 
    .tx_tick(tx_tick)
  );
  
  rx_baud_generator #(.sys_clk(rx_sys_clk), .baud_rate(baud_rate)) 
  r_gen(
    .clk(rx_clk), 
    .rst(rst), 
    .baud_en(baud_en), 
    .rx_tick(rx_tick)
  );
  
  transmitter #(.data_width(data_width))
  transmit(
    .clk(tx_clk), 
    .rst(rst), 
    .tx_en(tx_en), 
    .tx_tick(tx_tick), 
    .parity_en(parity_en), 
    .odd_or_even_parity(odd_or_even_parity), 
    .data_in(data_in), 
    .tx(tx), 
    .busy(busy)
  );
  
  receiver #(.data_width(data_width))
  receive(
    .clk(rx_clk), 
    .rst(rst), 
    .rx(rx), 
    .rx_tick(rx_tick), 
    .parity_en(parity_en), 
    .odd_or_even_parity(odd_or_even_parity), 
    .done(done), 
    .framing_error(framing_error), 
    .parity_error(parity_error), 
    .data_out(data_out)
  );
  
endmodule
