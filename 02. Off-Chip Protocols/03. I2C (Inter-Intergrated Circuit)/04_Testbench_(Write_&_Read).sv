`timescale 1ns / 1ps

module i2c_tb();
  parameter CLK_FREQ = 50_000_000;
  parameter I2C_FREQ = 100_000;
  parameter SLV_ADDR = 7'd42;

  reg	clk;
  reg 	rst_n;
  reg 	start;
  reg 	rw;                      
  reg 	[6:0] addr;

  reg 	[7:0] m_data_in;     
  wire 	[7:0] m_data_out;   
  wire 	m_busy;
  wire 	m_done;
  wire 	m_ack_error;

  reg 	[7:0] s_data_in;
  wire 	[7:0] s_data_out;
  wire 	s_busy;
  wire 	s_done;
  wire 	s_ack_error;

  wire 	sda;
  wire 	scl;

  pullup (sda);
  pullup (scl);

  i2c_top_design #(
    .CLK_FREQ(CLK_FREQ),
    .I2C_FREQ(I2C_FREQ),
    .SLV_ADDR(SLV_ADDR)
  ) uut (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .rw(rw),
    .addr(addr),
    .m_data_in(m_data_in),
    .m_data_out(m_data_out),
    .m_busy(m_busy),
    .m_done(m_done),
    .m_ack_error(m_ack_error),
    .s_data_in(s_data_in),
    .s_data_out(s_data_out),
    .s_busy(s_busy),
    .s_done(s_done),
    .s_ack_error(s_ack_error),
    .sda(sda),
    .scl(scl)
  );
  
  initial begin
    clk = 0;
    forever #10 clk = ~clk;
  end

  initial begin
    $dumpfile("write_test.vcd");
    $dumpvars(0);
    rst_n 		= 0;
    repeat (2) @(posedge clk);
    rst_n 		= 1;
    rw			= 0;
    addr 		= SLV_ADDR;
    m_data_in 	= 8'h57;
    @(posedge clk);
    start 		= 1;
    @(posedge clk);
    start 		= 0;
    @(posedge m_done);
    #1;
    if (s_data_out == m_data_in) begin
      $display("TEST PASSED");
      $display("Master sent     : 0x%h", m_data_in);
      $display("Slave received  : 0x%h", s_data_out);
    end 
    else begin
      $display("TEST FAILED");
      $display("Expected slave to receive 0x%h, but got 0x%h", m_data_in, s_data_out);
    end

    #100;
    $finish;
  end

endmodule
