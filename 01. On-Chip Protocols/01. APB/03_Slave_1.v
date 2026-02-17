module apb_slave1(
  input PCLK,PRESETn,PENABLE,PSEL,PWRITE,
  input [8:0]PADDR,
  input [7:0]PWDATA,
  output [7:0]PRDATA1,
  output reg PREADY1
);
  
  reg [7:0] reg_addr;
  reg [7:0] mem [0:255];
  
  assign PRDATA1 = mem[PADDR[7:0]];
  
  always @(posedge PCLK)begin
    if(!PRESETn)
      PREADY1 <= 0;
    else if(PSEL && PENABLE && !PWRITE)begin
      PREADY1 <= 1;
      reg_addr <= PADDR[7:0];
    end
    else if(PSEL && PENABLE && PWRITE)begin
      PREADY1 <= 1;
      mem[PADDR[7:0]] <= PWDATA;
    end
    else
      PREADY1 <= 0;
  end
  
endmodule
