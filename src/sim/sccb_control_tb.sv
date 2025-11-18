module testbench(); //even though the testbench doesn't create any hardware, it still needs to be a module

	timeunit 10ns;	// This is the amount of time represented by #1 
	timeprecision 1ns;

	// These signals are internal because the processor will be 
	// instantiated as a submodule in testbench.
	logic clk;
    logic start_fsm;
    logic reset;

    wire  sda;
    logic scl;
			
	// Instantiating the DUT (Device Under Test)
	// Make sure the module and signal names match with those in your design
	// Note that if you called the 8-bit version something besides 'Processor'
	// You will need to change the module name
	sccb_control test(.*);


	initial begin: CLOCK_INITIALIZATION
		clk = 1;
	end 

	// Toggle the clock
	// #1 means wait for a delay of 1 timeunit, so simulation clock is 50 MHz technically 
	// half of what it is on the FPGA board 

	// Note: Since we do mostly behavioral simulations, timing is not accounted for in simulation, however
	// this is important because we need to know what the time scale is for how long to run
	// the simulation
	always begin : CLOCK_GENERATION
		#1 clk = ~clk;
	end

	initial begin: TEST_VECTORS
        start_fsm <= 1'b0;
        reset <= 1'b0;
    
		repeat (4) @(posedge clk);
        start_fsm <= 1'b1;
        repeat (4) @(posedge clk);
        start_fsm <= 1'b0;
        repeat (30000) @(posedge clk);
		
		$finish(); //this task will end the simulation if the Vivado settings are properly configured


	end

endmodule


