`include "i2c_controller.sv"
`include "i2c_target.sv"

module i2c_top_design #(
  parameter CLK_FREQ = 50_000_000,
  parameter I2C_FREQ = 100_000,
  parameter SLV_ADDR = 7'd42
)(
  input		clk,
  input		rst_n,

  input		start,
  input		rw,
  input		[6:0] addr,

  input		[7:0] m_data_in,
  output	[7:0] m_data_out,
  output	m_busy,
  output	m_done,
  output	m_ack_error,

  input		[7:0] s_data_in,	
  output	[7:0] s_data_out,	
  output	s_busy,
  output	s_done,
  output	s_ack_error,

  inout		sda,	// Bi-directional Serial Data Line
  inout		scl
);

  i2c_controller #(
    .CLK_FREQ(CLK_FREQ),
    .I2C_FREQ(I2C_FREQ)
  ) con(
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .rw(rw),
    .addr(addr),
    .data_in(m_data_in),
    .data_out(m_data_out),
    .busy(m_busy),
    .done(m_done),
    .ack_error(m_ack_error),
    .sda(sda),
    .scl(scl)
  );

  i2c_target #(
    .SLV_ADDR(SLV_ADDR)
  ) tar(
    .clk(clk),
    .rst_n(rst_n),
    .sda(sda),
    .scl(scl),
    .data_in(s_data_in),
    .data_out(s_data_out),
    .busy(s_busy),
    .done(s_done),
    .ack_error(s_ack_error)
  );
  
endmodule
