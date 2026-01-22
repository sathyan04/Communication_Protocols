module trasmitter #(parameter data_width = 8)
	(
	input clk, rst, tx_en, tx_tick, parity_en, odd_or_even_parity,
	input [data_width-1:0] data_in,
	output reg tx,
	output busy);

localparam data_count_width = $clog2(data_width);

reg [data_count_width-1:0] data_count;
reg [data_width-1:0] data_shift_register;
reg parity_bit;

parameter [2:0] idle=0,
		start=1,
		data=2,
		parity=3,
		stop=4;
reg [2:0] state;

always @(posedge clk or negedge rst) begin
	if(!rst) begin
		state<=idle;
		tx<=1;
		data_count<=0;
	end
	else begin
		case(state)
			
			idle: begin
				tx<=1;
				if (tx_en) begin
					data_shift_register<=data_in;
					state<=start;
					parity_bit <= (odd_or_even_parity) ? ^data_in : ~(^data_in);
				end
			end

			start: begin
				tx<=1;
				if(tx_tick) begin
					state<=data;
					tx<=0;
					data_count<=0;
				end
			end

			data: begin
				if(tx_tick) begin
					tx<=data_shift_register(data_count);
					if(data_count == data_width-1) begin
						data_count<=0;
						state<=(parity_bit)?parity:stop;
					end 
					else begin
						data_count<=data_count+1;
					end
				end
			end

			parity: begin
				if(tx_tick) begin
					tx<=parity_bit;
					state<=idle;
				end
			end

			stop: begin
				if(tx_tick) begin
					tx<=1'b1;
					state<=idle;
				end
			end

			default: state<=idle;

		endcase
	end
end

assign busy = (state!=idle);

endmodule
