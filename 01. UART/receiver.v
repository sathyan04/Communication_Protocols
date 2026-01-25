module recevier #(parameter data_width = 8)
(
	input clk, rst, rx_tick, rx, parity_en, odd_or_even_parity,
	output reg done, framing_error, parity_error,
	output reg [data_width-1:0] data_out
);

localparam data_count_width = $clog2(data_width);

reg [data_count_width-1:0] data_count;
reg [data_width-1:0] data_shift_register;
reg [3:0] rx_tick_count;

parameter [2:0] idle=0,
		start=1,
		data=2,
		parity=3,
		stop=4;
reg [2:0] state;

always @(posedge clk or negedge rst) begin
	if(!rst) begin
		state		<= idle;
		done		<= 0;
		framing_error	<= 0;
		parity_error	<= 0;
		data_out	<= 0;
		data_count	<= 0;
		rx_tick_count	<= 0;
	end

	else if(rx_tick) begin
		done<=0;
		case(state)
			
			idle: begin
				rx_tick_count	<= 0;
				data_count	<= 0;
				parity_error	<= 0;
				framing_error	<= 0;
	
				if(rx==0)
					state<=start;
			end

			start: begin
				if (rx_tick_count==7) begin
					if(rx==0) begin
						state<=data;
						rx_tick_count<=0;
						data_count<=0;
					end
					else
						state<=idle;
				end
				else
					rx_tick_count <= rx_tick_count + 1'b1;
			end

			data: begin
				if (rx_tick_count==15) begin
					data_shift_register[data_count]<=rx;
					rx_tick_count<=0;
					if(data_count == data_width-1) begin
						data_count<=0;
						state <= (parity_en) ? parity : stop;
					end
					else
						data_count <= data_count + 1'b1;
				end
				else
					rx_tick_count <= rx_tick_count + 1'b1;
			end
			
			parity: begin
				if(rx_tick_count == 15) begin
					rx_tick_count<=0;
					parity_error <= (odd_or_even_parity) ? (^data_shift_register != rx) : ~(^data_shift_register != rx);
					state<=stop;
				end
				else 
					rx_tick_count <= rx_tick_count + 1'b1;
			end

			stop: begin
				if (rx_tick_count == 15) begin
					done		<= 1;
					state		<= idle;
					data_out	<= data_shift_register;
					framing_error	<= (rx!=1);
					rx_tick_count	<= 0;
				end
				else
					rx_tick_count	<= rx_tick_count + 1'b1;
			end

			default: state<=idle;
		endcase
	end
end
endmodule
