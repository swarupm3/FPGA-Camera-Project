module testbench(); //even though the testbench doesn't create any hardware, it still needs to be a module

	timeunit 10ns;	// This is the amount of time represented by #1 
	timeprecision 1ns;

	logic clk;
    logic start_fsm;
    logic reset;

    wire  sda;
    logic scl;
			
	sccb_control test(.*);


	initial begin: CLOCK_INITIALIZATION
		clk = 1;
	end 

	always begin : CLOCK_GENERATION
		#1 clk = ~clk;
	end

	initial begin : TEST_VECTORS
    start_fsm = 1'b0;
    reset     = 1'b1;     
    
    
    repeat (10) @(posedge clk);
    reset = 1'b0;         
    

    repeat (50) @(posedge clk);
    
   
    start_fsm = 1'b1;
    repeat (200) @(posedge clk);
    start_fsm = 1'b0;
    
    
    repeat (3000000) @(posedge clk);

  $finish();
end


endmodule


