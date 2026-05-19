module i2c_target #(
  parameter SLV_ADDR = 7'd42
)(
  input  wire       clk,
  input  wire       rst_n,

  inout  wire       sda,	// Bi-directional Serial Data Line
  input  wire		scl,

  input  wire [7:0] data_in,	// External Input for Write Condition
  output reg  [7:0] data_out,	// Master Written - Slave Read

  output reg        busy,
  output reg        done,
  output reg        ack_error	// Acknowledgement from master
);
  reg	rw;
  reg	sda_en;
  wire 	ack_comb;
  reg 	ack1_sent;
  reg 	ack2_sent;
  reg 	ack_received;
  reg 	[2:0] state;
  reg 	[2:0] bit_count;
  reg 	[7:0] shift_reg;
  reg 	scl_prev;
  reg 	sda_prev; 
  wire 	scl_rising;
  wire 	scl_falling;
  reg 	start_det;
  reg 	stop_det;

  localparam idle 		= 0;
  localparam address 	= 1;
  localparam ack1 		= 2;
  localparam write 		= 3;
  localparam read 		= 4;
  localparam ack2 		= 5;
  localparam stop 		= 6;

  assign ack_comb = (state == ack1 && !ack1_sent && (shift_reg[7:1] == SLV_ADDR));
  assign sda = (ack_comb || sda_en) ? 1'b0 : 1'bz;

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      scl_prev	<= 0;
      sda_prev	<= 1;
    end
    else begin
      scl_prev	<= scl;
      sda_prev	<= sda;
    end
  end

  assign scl_rising 	= (~scl_prev && scl);
  assign scl_falling 	= (scl_prev && ~scl);

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      start_det <= 0;
      stop_det  <= 0;
    end
    else begin
      start_det <= scl && sda_prev && ~sda;
      stop_det  <= scl && ~sda_prev && sda;
    end
  end

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      busy		<= 0;
      done		<= 0;
      ack_error	<= 0;
      data_out	<= 0;
      sda_en	<= 0;
      shift_reg	<= 0;
      bit_count	<= 0;
      ack1_sent	<= 0;
      ack2_sent	<= 0;
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
          ack1_sent	<= 0;
          ack2_sent	<= 0;
          if(start_det) begin
            busy	<= 1;
            state	<= address;
          end
          else begin
            busy	<= 0;
            state	<= idle;
          end
        end

        address: begin
          if(scl_rising) begin
            shift_reg	<= {shift_reg[6:0],sda};
            if(bit_count == 7) begin
              bit_count	<= 0;
              state		<= ack1;
            end
            else begin
              bit_count	<= bit_count + 1'b1;
              state		<= address;
            end
          end
        end

        ack1: begin
          if(scl_falling) begin	// slave takes the control of sda line from the master at the end of the 8th clock pulse
            if(!ack1_sent)begin // Negedge of 8th Pulse
              if(shift_reg[7:1] == SLV_ADDR) begin
                sda_en		<= 1;
                ack1_sent	<= 1;
                rw			<= shift_reg[0];
              end
              else begin
                sda_en		<= 0;
                ack_error	<= 1;
                state		<= stop;
              end
            end
            else begin	// Negedge of 9th pulse
              sda_en		<= 0;	// slave releases the sda line control
              ack1_sent		<= 0;
              if(rw) begin
                shift_reg	<= data_in;  
                state		<= read;
              end
              else begin
                state		<= write;
              end
            end
          end  
        end

        write:begin
          if(scl_rising)begin
            shift_reg	<= {shift_reg[6:0],sda};
            if(bit_count == 7) begin
              data_out	<= {shift_reg[6:0],sda};
              bit_count	<= 0;
              state		<= ack2;
            end
            else begin
              bit_count	<= bit_count + 1'b1;
              state		<= write;
            end
          end
        end

        read: begin
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
              state		<= read;
            end
          end
        end

        ack2:begin
          if(rw) begin	// Slave Write - Master Read
            if(scl_rising) begin
              ack_received	<= sda;
            end
            if(scl_falling) begin
              state			<= stop;
              if (ack_received == 1)
                ack_error	<= 1;
            end
          end
          else begin	// Master Write - Slave Read
            if(scl_falling) begin
              if(!ack2_sent)begin
                sda_en	<= 1;
                ack2_sent<=1;
              end
              else begin
                sda_en	<= 0;
                ack2_sent	<=0;
                state	<= stop;
              end
            end
          end
        end

        stop: begin
          if(stop_det) begin
            busy	<= 0;
            done	<= 1;
            state	<= idle;
          end
          else
            state	<= stop;
        end

        default: state	<= idle;

      endcase

    end
  end
endmodule
