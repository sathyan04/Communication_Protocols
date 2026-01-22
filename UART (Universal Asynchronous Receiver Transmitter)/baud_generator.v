module baud_generator #(
	parameter sys_clk=50_000_000, 
	parameter baud_rate=9600)
	(input clk, rst, baud_gen_en, 
	output reg tx_tick, rx_tick);

localparam integer tx_cycle = sys_clk / baud_rate;
localparam integer rx_cycle = sys_clk / (baud_rate * 16);

localparam integer tx_bit = $clog2(tx_cycle);
localparam integer rx_bit = $clog2(rx_cycle);

reg [tx_bit-1:0] tx_count;
reg [rx_bit-1:0] rx_count;

always @(posedge clk or negedge rst) begin
	if(!rst) begin
		tx_count<=0;
		tx_tick<=0;
	end
	else if (baud_gen_en) begin
		if (tx_count == tx_cycle - 1) begin
			tx_count<=0;
			tx_tick<=1;
		end
		else begin
			tx_tick<=0;
			tx_count<=tx_count + 1'b1;
		end
	end
end

always @(posedge clk or negedge rst) begin
        if(!rst) begin
                rx_count<=0;
                rx_tick<=0;
        end
        else if (baud_gen_en) begin
                if (rx_count == rx_cycle - 1) begin
                        rx_count<=0;
                        rx_tick<=1;
                end
                else begin
                        rx_tick<=0;
                        rx_count<=rx_count + 1'b1;
                end
        end
end
endmodule
