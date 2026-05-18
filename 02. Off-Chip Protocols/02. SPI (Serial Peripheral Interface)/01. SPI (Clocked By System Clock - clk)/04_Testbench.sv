module testbench();
  parameter sys_clk = 50_000_000;
  parameter spi_clk = 10_000_000;
  
  reg clk;
  reg rst_n;
  reg start;
  reg [7:0] main_tx_data;
  reg [7:0] subnode_tx_data;
  
  wire [7:0] main_rx_data;
  wire [7:0] subnode_rx_data;
  wire done;
  wire data_valid;
  
  top_module #(.sys_clk(sys_clk), 
               .spi_clk(spi_clk)
              ) tm (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .main_tx_data(main_tx_data),
    .subnode_tx_data(subnode_tx_data),
    .main_rx_data(main_rx_data),
    .subnode_rx_data(subnode_rx_data),
    .done(done),
    .data_valid(data_valid)
  );
  
  initial begin
    clk = 0;
    forever #10 clk = ~clk;
  end
  
  initial begin
    $dumpfile("spiprotocol.vcd");
    $dumpvars(0);
    
    rst_n 			= 0;
    #20;
    rst_n 			= 1;
    
    start 			= 1;
    
    main_tx_data 	= 8'd120;
    subnode_tx_data	= 8'd70;
    
    $display("\n\tBefore Transmission:");
    $display("\tMain	: %0d", main_tx_data);
    $display("\tSubnode	: %0d", subnode_tx_data);
    
    @(posedge done);
    @(posedge data_valid);  
    
    start			= 0;
    
    $display("\n\tAfter Transmission:");
    $display("\tMain	: %0d", main_rx_data);
    $display("\tSubnode	: %0d\n", subnode_rx_data);

    $finish;
  end
  
endmodule
