module spi_master #(
  parameter sys_clk = 50_000_000,
  parameter spi_clk = 10_000_000)
  (  
    input wire		clk,
    input wire		rst_n,

    input wire		start,
    input wire [1:0]mode,
    input wire [7:0]tx_data,
    output reg [7:0]rx_data,
    output reg 		done,

    //spi data lines
    output reg 		sclk,	// serial clock from the system clock
    output reg 		mosi,	// main out - subnode in
    input wire		miso,	// main in - subnode out
    output reg 		cs_n	// chip select
  );

  localparam div_twice 		= 2 * spi_clk;
  localparam base_count 	= sys_clk / div_twice; // integer value of the half cycle
  localparam remainder_step	= sys_clk % div_twice;
  localparam rem_width		= $clog2(div_twice) + 1'b1;

  reg [rem_width-1:0] 	remainder_acc;
  reg [31:0] 			half_count;
  reg [31:0] 			target_count; // temporary variable to store the base_count

  reg [1:0]	state;
  reg [3:0]	count;
  reg [7:0]	tx_shift;
  reg [7:0]	rx_shift;

  reg 		sclk_prev; // previous clock edge

  // fsm states for transmission
  localparam idle 		= 2'd0;
  localparam transfer 	= 2'd1;
  localparam over		= 2'd2;

  wire 		sclk_rise; 	// to detect the rising edge
  wire		sclk_fall; 	// to detect the falling edge
  
  reg		sample; // sampling variable
  reg		shift;	// shifting variable	
  reg		a; 			// mode detecting temporary variable

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

  // clock divider block to generate the sclk from the system clk          
  reg enable; // for enabling the generation of sclk

  always @(posedge clk or negedge rst_n) begin

    case(mode)

      2'b00: begin	// mode 0 : logic low
        a		<= 0;
        sample 	<= sclk_rise;
        shift	<= sclk_fall;
      end

      2'b01: begin	// mode 1 : logic low
        a		<= 0;
        sample 	<= sclk_fall;
        shift	<= sclk_rise;
      end

      2'b10: begin	// mode 2 : logic high
        a		<= 1;
        sample 	<= sclk_fall;
        shift	<= sclk_rise;
      end

      2'b11: begin	// mode 3 : logic high
        a		<= 1;
        sample 	<= sclk_rise;
        shift	<= sclk_fall;
      end
      
    endcase

    if (!rst_n) begin
      half_count 	<= 0;
      remainder_acc <= 0;
      sclk 			<= a;
      target_count 	<= base_count;
    end 

    else begin

      if (enable) begin  

        if (half_count 	== target_count - 1) begin
          half_count 	<= 0;
          sclk 			<= ~sclk;

          if (remainder_step != 0) begin

            if (remainder_acc + remainder_step >= div_twice) begin
              target_count 	<= base_count + 1;
              remainder_acc	<= remainder_acc + remainder_step - div_twice;
            end 

            else begin
              target_count	<= base_count;
              remainder_acc	<= remainder_acc + remainder_step;
            end

          end

          else begin
            target_count <= base_count;
          end

        end 

        else begin
          half_count <= half_count + 1;
        end

      end

      else begin
        sclk 			<= a;
        half_count		<= 0;
        target_count	<= base_count;
      end

    end

  end

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      mosi		<= 0;
      cs_n		<= 1;
      done		<= 0;
      enable	<= 0;
      rx_data	<= 0;
      count		<= 0;
      tx_shift	<= 0;
      rx_shift	<= 0;

      state		<= idle;
    end

    else begin

      case(state)

        idle: begin
          done	<= 0;
          if(start) begin
            tx_shift	<= tx_data;
            rx_shift	<= 0;
            enable		<= 1;
            cs_n		<= 0;
            state		<= transfer;
          end
          else begin
            state		<= idle;
          end
        end

        transfer: begin
          if(sample) begin // sampling
            rx_shift	<= {rx_shift[6:0],miso};
            if(count	== 8) begin
              state	<= over;
            end
            else begin
              count		<= count + 1'b1;  
            end
          end
          if(shift) begin // shifting
            mosi		<= tx_shift[7];
            tx_shift	<= {tx_shift[6:0], 1'b0};
          end
        end

        over: begin
          cs_n		<= 1;
          rx_data	<= rx_shift;
          enable	<= 0;
          count		<= 0;
          done		<= 1;
          state		<= idle;
        end

        default: begin
          state	<= idle;
        end

      endcase

    end

  end

endmodule
