module tb();
	parameter INPUT_WIDTH = 1;
	parameter OUTPUT_WIDTH = 32;
	logic clk = 0;
	logic areset;
	logic predict_valid;
	logic predict_taken;
	logic train_mispredicted;
	logic train_taken;
	logic [31:0] train_history;
	logic [OUTPUT_WIDTH-1:0] predict_history;
	wire tb_match;
	wire tb_mismatch = ~tb_match;

	logic [511:0] wavedrom_title;
	logic wavedrom_enable;
	int wavedrom_hide_after_time;

	initial forever
		#5 clk = ~clk;

	...

endmodule