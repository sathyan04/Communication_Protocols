//`timescale 1ns/1ps

module receiver #(parameter data_width = 8)(
  input clk, rst, rx, rx_tick, parity_en, odd_or_even_parity,
  output reg done, framing_error, parity_error,
  output reg [data_width-1:0] data_out
);
  
  localparam data_count_width = $clog2(data_width);
  
  reg [data_count_width-1:0] data_count;
  reg [data_width-1:0] data_shift_reg;
  reg [3:0] rx_tick_count;
  
  parameter [2:0] idle=0, start=1, data=2, parity=3, stop=4;
  reg [2:0] state;
  
  always @(posedge clk or negedge rst) begin
    
    if(!rst) begin
      state<=idle;
      framing_error<=0;
      parity_error<=0;
      data_out<=0;
      data_count<=0;
      rx_tick_count<=0;
      done<=0;
    end
    
    else if(rx_tick) begin
      done<=0;
      
      case(state)
      
        idle: begin
          framing_error<=0;
          parity_error<=0;
          data_count<=0;
          rx_tick_count<=0;
          if(rx==0) begin
          	state<=start;
          end
        end
        
        start: begin
          if(rx_tick_count==7) begin
            if(rx==0) begin
              state<=data;
              rx_tick_count<=0;
              data_count<=0;
            end
            else begin
              state<=idle;
            end
          end
          else begin
            rx_tick_count <= rx_tick_count + 1;
          end
        end
        
        data: begin
          if(rx_tick_count==15) begin
            data_shift_reg[data_count]<=rx;
            rx_tick_count<=0;
            if(data_count==data_width-1) begin
              data_count<=0;
              state<=parity_en?parity:stop;
            end
            else begin
              data_count<=data_count+1;
            end
          end
          else begin
            rx_tick_count<=rx_tick_count+1;
          end
        end
        
        parity: begin
          if(rx_tick_count==15) begin
            state<=stop;
            rx_tick_count<=0;
            parity_error<=(odd_or_even_parity)?(^data_shift_reg!=rx):(~(^data_shift_reg)!=rx);
          end
          else begin
            rx_tick_count<=rx_tick_count+1;
          end
        end
        
        stop: begin
          if(rx_tick_count==15) begin
            if(rx==1) begin
              done<=1;
              data_out<=data_shift_reg;
              rx_tick_count<=0;
              state<=idle;
            end
            else begin
              framing_error<=(rx!=1);
            end
          end
          else begin
            rx_tick_count<=rx_tick_count+1;
          end
        end
        
        default: state<=idle;
        
      endcase
      
    end
    
  end
  
endmodule
