module spi_slave
  (  
    input wire		clk,
    input wire		rst_n,

    input wire 		sclk,
    input wire 		cs_n,
    input wire 		mosi,
    
    output reg miso,

    input wire [7:0] tx_data,
    output reg [7:0] rx_data,

    output reg data_valid
  );

  // fsm states for transmission
  localparam idle 		= 2'd0;
  localparam transfer 	= 2'd1;
  localparam over		= 2'd2;
  
  reg [1:0]	state;
  reg [3:0]	count;
  reg [7:0]	tx_shift;
  reg [7:0]	rx_shift;

  wire 		sclk_rise; 	// to detect the rising edge
  wire		sclk_fall; 	// to detect the falling edge
  wire 		cs_n_fall;	// to detect the falling of chip select  
  
  reg 		cs_n_prev;
  reg 		sclk_prev; // previous clock edge
  
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      cs_n_prev		<= 1;
    end
    else begin
      cs_n_prev		<= cs_n;
    end
  end

  assign cs_n_fall = !cs_n & cs_n_prev; 
  
  //when cs_n is 0 and its previous value is 1 : to detect whether cs_n is actually in its falling edge or not

  // Edge detection block
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      sclk_prev	<= 0;
    end
    else begin
      sclk_prev	<= sclk;
    end
  end

  assign sclk_rise	= (!sclk_prev) & sclk; // 0 to 1; Rising edge
  assign sclk_fall	= sclk_prev & (!sclk); // 1 to 0; Falling edge

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      miso				<= 0;
      data_valid		<= 0;
      rx_data			<= 0;
      count				<= 0;
      tx_shift			<= 0;
      rx_shift			<= 0;

      state				<= idle;
    end

    else begin

      case(state)

        idle: begin
          data_valid	<= 0;
          if(cs_n_fall) begin
            tx_shift	<= tx_data;
            rx_shift	<= 0;
            count		<= 0;
            state		<= transfer;
          end
          else begin
            state		<= idle;
          end
        end

        transfer: begin
          if(!cs_n) begin
            
            if(sclk_rise) begin // sampling
              rx_shift	<= {rx_shift[6:0],mosi};
              if(count	== 8) begin
                state	<= over;
              end
              else begin
                count	<= count + 1'b1;  
              end
            end
            
            if(sclk_fall) begin // shifting
              miso		<= tx_shift[7];
              tx_shift	<= {tx_shift[6:0], 1'b0};
            end
            
          end
          
          else begin
            count		<= 0;
            rx_shift	<= 0;
            state		<= idle;
          end
          
        end

        over: begin
          rx_data		<= rx_shift;
          count			<= 0;
          data_valid	<= 1;
          state			<= idle;
        end

        default: begin
          state	<= idle;
        end

      endcase

    end

  end

endmodule
