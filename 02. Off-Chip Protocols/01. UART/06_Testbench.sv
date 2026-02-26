`timescale 1ns/1ps

module test_bench();
  parameter tx_sys_clk = 10_000_000;
  parameter rx_sys_clk = 40_000_000;
  parameter baud_rate = 9600;
  parameter data_width = 8;
  
  reg tx_clk; 
  reg rx_clk; 
  reg rst; 
  reg baud_en;
  reg rx; 
  reg tx_en; 
  reg parity_en; 
  reg odd_or_even_parity;
  reg [data_width-1:0] data_in;

  wire tx; 
  wire busy; 
  wire done; 
  wire framing_error; 
  wire parity_error;
  wire [data_width-1:0] data_out;
  
  uart_top #(.tx_sys_clk(tx_sys_clk), 
             .rx_sys_clk(rx_sys_clk),
             .baud_rate(baud_rate),
             .data_width(data_width))
  dut(
    .tx_clk(tx_clk),
    .rx_clk(rx_clk),
    .rst(rst),
    .baud_en(baud_en),
    .rx(rx),
    .tx_en(tx_en),
    .parity_en(parity_en),
    .odd_or_even_parity(odd_or_even_parity),
    .data_in(data_in),
    .tx(tx),
    .busy(busy),
    .done(done),
    .framing_error(framing_error),
    .parity_error(parity_error),
    .data_out(data_out)
  );
  
  initial begin
    tx_clk=0;
    forever #50 tx_clk = ~tx_clk;
  end
  
  initial begin
    rx_clk=0;
    forever #12.5 rx_clk = ~rx_clk;
  end
  
  assign #1 rx = tx;
  
  initial begin
    $dumpfile("uart.vcd");
    $dumpvars();
    $monitor("IN: %0d | TX: %0d | Busy: %0d | Rx: %0d | Done: %0d | OUT: %0d | Framing Er: %0d | Parity Er: %0d | Tx State: %0d | Rx State: %0d | Time: %0t",data_in, tx, busy, rx, done, data_out, framing_error, parity_error, dut.transmit.state, dut.receive.state, $time);
    
    rst=0;
    baud_en=1;
    tx_en=0;
    parity_en=0;
    odd_or_even_parity=0;
    data_in=0;
    
    #100 rst=1;
    
    testing(8'd57,0,1); // no parity
    testing(8'd10,1,0); // parity enabled with odd parity
    testing(8'd123,1,1); // parity enabled with even parity
    
    #1000 $finish;
  end
  
  task testing(input [data_width-1:0] data, input par_en, input par_type);
    begin
      @(posedge tx_clk);
      data_in = data;
      parity_en = par_en;
      odd_or_even_parity = par_type;
      
      $display("\nSending Data: %0d (%b) | parity enabling: %0d and type: %0s\n", data, data, par_en, (par_type) ? "Even" : "Odd"); // 1 - Even and 0 - Odd
      
      tx_en=1;
      @(posedge busy);
      
      tx_en=0;
      @(posedge done);
      
      #100;
      
      if(data_out==data && !parity_error && !framing_error) begin
        $display("\nSuccessfully transferred and received\n");
      end
      else begin
        $display("\nError in transmission\n");
      end
    end
  endtask
  
endmodule
