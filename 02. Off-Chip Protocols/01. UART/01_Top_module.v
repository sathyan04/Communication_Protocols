module top_module #(
	parameter sys_clk=50_000_000,
	parameter baud_rate=9600,
	data_width=8)
	(
		input clk, 
		input rst, 
		input baud_gen_en,
		input tx_en, 
		input parity_en, 
		input odd_or_even_parity,
		input [data_width-1:0] data_in,

		output busy,
		output tx,
		output done, 
		output framing_error, 
		output parity_error,
		output [data_width-1:0] data_out	
	);
	
	wire tx_tick, rx_tick, rx;
	assign rx=tx;

	baud_generator #(
		.sys_clk(50_000_000), 
		.baud_rate(9600)) 
		
		bg(
			.clk(clk), 
			.rst(rst), 
			.baud_gen_en(baud_gen_en), 
			.tx_tick(tx_tick), 
			.rx_tick(rx_tick)
		);

	transmitter #(
		.data_width(8))

		tr(
			.clk(clk),
			.rst(rst),
			.tx_en(tx_en),
			.tx_tick(tx_tick),
			.parity_en(parity_en),
			.odd_or_even_parity(odd_or_even_parity),
			.data_in(data_in),
			.tx(tx),
			.busy(busy)
		);

	receiver #(
		.data_width(8))

		re(
			.clk(clk),
			.rst(rst),
			.rx_tick(rx_tick),
			.rx(rx),
			.parity_en(parity_en),
			.odd_or_even_parity(odd_or_even_parity),
			.done(done),
			.framing_error(framing_error),
			.parity_error(parity_error),
			.data_out(data_out)
		);
endmodule
