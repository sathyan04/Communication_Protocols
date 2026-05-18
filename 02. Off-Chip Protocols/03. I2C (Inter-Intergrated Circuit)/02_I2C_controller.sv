module i2c_controller #(
  parameter CLK_FREQ = 50_000_000,
  parameter I2C_FREQ = 100_000
)(
  input  wire       clk,
  input  wire       rst_n,

  input  wire       start,
  input  wire       rw,
  input  wire [6:0] addr,
  input  wire [7:0] data_in,

  output reg  [7:0] data_out,
  output reg        busy,
  output reg        done,
  output reg        ack_error,

  inout  wire       sda,	// Bi-directional Serial Data Line
  output wire		scl
);

  localparam DIVIDER = CLK_FREQ / (I2C_FREQ * 2);
  reg [$clog2(DIVIDER)-1:0] clk_cnt;
  reg scl_tick;
  reg scl_prev;

  wire scl_rising;
  wire scl_falling;

  reg sda_en;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      clk_cnt  <= 0;
      scl_tick <= 1;
    end
    else begin
      if (clk_cnt == DIVIDER-1) begin
        clk_cnt  <= 0;
        scl_tick <= ~scl_tick;
      end
      else begin
        clk_cnt  <= clk_cnt + 1'b1;
      end
    end
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      scl_prev <= 0;
    else
      scl_prev <= scl_tick;
  end

  assign scl_rising = (~scl_prev && scl_tick);
  assign scl_falling = (scl_prev && ~scl_tick);

  assign sda = sda_en ? 1'b0 : 1'bz;
  assign scl = scl_tick;

  reg [2:0] state;

  reg [7:0] shift_reg;
  reg [2:0] bit_count;
  reg ack_received;

  localparam idle 			= 0;
  localparam start_state 	= 1;
  localparam address 		= 2;
  localparam ack1 			= 3;
  localparam write 			= 4;
  localparam read 			= 5;
  localparam ack2 			= 6;
  localparam stop 			= 7;

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      busy		<= 0;
      done		<= 0;
      ack_error	<= 0;
      data_out	<= 0;
      sda_en	<= 0;
      shift_reg	<= 0;
      bit_count	<= 0;
      state		<= idle;
    end
    else begin
      case(state)

        idle:begin
          busy		<= 0;
          done		<= 0;
          ack_error	<= 0;
          data_out	<= 0;
          sda_en	<= 0;
          shift_reg	<= 0;
          bit_count	<= 0;
          if(start) begin
            busy	<= 1;
            state	<= start_state;
          end
          else begin
            busy	<= 0;
            state	<= idle;
          end
        end

        start_state:begin
          sda_en	<= 1;
          shift_reg	<= {addr,rw};
          bit_count	<= 0;
          state		<= address;
        end

        address:begin
          if(scl_falling) begin
            shift_reg	<= {shift_reg[6:0],1'b0};
            sda_en	<= (shift_reg[7]==0);
            if(bit_count == 7) begin
              bit_count	<= 0;
              sda_en	<= 0;	// end of the 8th cycle - slave takes control
              state		<= ack1;
            end
            else begin
              bit_count	<= bit_count + 1'b1;
              state		<= address;
            end
          end
        end

        ack1:begin
          if(scl_rising) begin
            ack_received	<= sda;
          end

          if(scl_falling) begin

            if(ack_received == 1)begin	// NACK
              ack_error		<= 1;
              state			<= stop;
            end

            else begin
              bit_count		<= 0;
              if(rw)begin
                state		<= read;
              end
              else begin
                shift_reg	<= data_in;
                state		<= write;
              end
            end

          end
        end

        write:begin
          if(scl_falling) begin
            shift_reg	<= {shift_reg[6:0],1'b0};
            sda_en		<= (shift_reg[7]==0);
            if(bit_count == 7) begin
              bit_count	<= 0;
              sda_en	<= 0;
              state		<= ack2;
            end
            else begin
              bit_count	<= bit_count + 1'b1;
              state		<= write;
            end
          end
        end

        read:begin
          sda_en		<= 0;
          if(scl_rising)begin
            shift_reg	<= {shift_reg[6:0],sda};
            if(bit_count == 7) begin
              data_out	<= {shift_reg[6:0],sda};
              bit_count	<= 0;
              state		<= ack2;
            end
            else begin
              bit_count	<= bit_count + 1'b1;
              state		<= read;
            end
          end
        end

        ack2:begin
          if(rw)begin	// Read
            if(scl_falling)
              state			<= stop;
          end

          else begin	// Write
            if(scl_rising) begin
              ack_received	<= sda;
            end
            if(scl_falling) begin
              state			<= stop;
              if(ack_received == 1)	// NACK
                ack_error	<= 1;
            end
          end

        end
        
        stop:begin
          sda_en	<= 0;
          if(scl_tick)begin
            busy	<= 0;
            done	<= 1;
            state	<= idle;
          end
        end

        default: state<=idle;

      endcase
    end
  end
endmodule
