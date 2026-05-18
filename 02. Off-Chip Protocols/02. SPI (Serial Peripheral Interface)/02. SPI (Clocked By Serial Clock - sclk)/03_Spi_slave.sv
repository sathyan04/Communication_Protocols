module spi_slave (  
    input wire rst_n,
    input wire sclk,
    input wire cs_n,
    input wire mosi,
    output reg miso,
    
    input wire [7:0] tx_data,
    output reg [7:0] rx_data,
    
    output reg data_valid
);
  
  reg [3:0] count;
  reg [7:0] tx_shift;
  reg [7:0] rx_shift;
  
  reg cs_n_prev;
  wire cs_n_fall;
  
  // Block to sample the data at the rising edge of sclk
  always @(posedge sclk or negedge rst_n) begin
    
    if(!rst_n) begin
      count			<= 0;
      rx_shift		<= 0;
      data_valid	<= 0;
      rx_data		<= 0;
    end
    
    else if (!cs_n) begin
      rx_shift		<= {rx_shift[6:0], mosi};
      if(count == 8) begin
        count		<= 0;
        data_valid	<= 1;
        rx_data		<= {rx_shift[6:0], mosi};
      end
      else begin
        count		<= count + 1'b1;
        data_valid	<= 0;
      end
    end
    
    else begin
      count			<= 0;
      data_valid	<= 0;
      rx_shift		<= 0;
      rx_data		<= 0;
    end
    
  end
    
  always @(posedge sclk or negedge rst_n) begin
    if(!rst_n) begin
      cs_n_prev		<= 1;
    end
    else begin
      cs_n_prev		<= cs_n;
    end
  end
  
  assign cs_n_fall = !cs_n & cs_n_prev; 
  //when cs_n is 0 and its previous value is 1 : to detect whether cs_n is actually in its falling edge or not
  
  always @(posedge sclk or negedge rst_n) begin
    if(!rst_n) begin
      tx_shift		<= 0;
    end
    else if (cs_n_fall) begin
      tx_shift		<= tx_data;
    end
    else if (!cs_n) begin
      tx_shift		<= {tx_shift[6:0],1'b0};
    end
  end
  
  // Block used for shifting the transferred bits in the falling edge of sclk 
  always @(negedge sclk or negedge rst_n) begin
    if(!rst_n) begin
      miso	<= 0;
    end
    else if (!cs_n) begin
      miso	<= tx_shift[7];
    end
    else begin
      miso	<= 0;
    end
  end
  
endmodule
