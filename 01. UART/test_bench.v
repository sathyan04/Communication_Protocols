module test_bench();
parameter sys_clk 	= 50_000_000;
parameter baud_rate 	= 9600;
parameter data_width 	= 8;

reg clk;
reg rst;
reg baud_gen_en;
reg tx_en;
reg parity_en;
reg odd_or_even_parity;
reg [data_width-1:0] data_in;

wire busy;
wire tx;
wire done;
wire framing_error;
wire parity_error;
wire [data_width-1:0] data_out;

top_module #(
	.sys_clk(sys_clk),
	.baud_rate(baud_rate),
	.data_width(data_width))

	dut(
		.clk(clk),
		.rst(rst),
		.baud_gen_en(baud_gen_en),
		.tx_en(tx_en),
		.parity_en(parity_en),
		.odd_or_even_parity(odd_or_even_parity),
		.data_in(data_in),
		.busy(busy),
		.tx(tx),
		.done(done),
		.framing_error(framing_error),
		.parity_error(parity_error),
		.data_out(data_out)
	);

	initial begin
		clk=0;
		forever #10 clk = ~clk;
	end

	assign rx=tx;

	task testing (input [data_width-1:0] data, input par_en, input par_type);
		begin
			@(posedge clk);
			data_in 		= data;
			parity_en 		= par_en;
			odd_or_even_parity 	= par_type;

			$display("\nSending Data: %0d | Parity enable and type: %0d and %0s\n", data, par_en, (par_type) ? "Even" : "Odd");

			tx_en=1;
			@(posedge busy);

			tx_en=0;
			@(posedge done);

			#100;

			if(data_out == data && !parity_error && !framing_error)
				$display("Code Successful :: Data [%0d] received correctly",data_out);
			else
				$display("ERROR :: Code Unsuccessful");

			#200;

		end
	endtask

	initial begin
		$dumpfile("uart.vcd");
		$dumpvars(0);
		rst			= 0;
		tx_en			= 0;
		baud_gen_en		= 1;
		parity_en		= 0;
		odd_or_even_parity	= 0;
		data_in			= 0;

		#100 rst=1;
		
		//Running test-conditions:
		testing(8'd10, 1, 1);
		testing(8'd57, 0, 0);
		testing(8'd17, 0, 0);

		#1000 $finish;
	end

	always @(posedge clk) begin
		$monitor("Data Input: %0d(%b) | Tx: %0d | Busy: %0d | Rx: %0d | Data Output: %0d(%b) | Done: %0d | Framing Error: %0d | Parity Error: %0d | Time: %0t", data_in, data_in, tx, busy, rx, data_out, data_out, done, framing_error, parity_error, $time);
	end
endmodule
