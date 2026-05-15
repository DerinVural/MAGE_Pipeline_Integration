module tb();
	parameter int WIDTH = 4;
	logic clk;
	logic reset;
	logic [WIDTH-1:0] q;

	wire[511:0] wavedrom_title;
	wire wavedrom_enable;

	initial begin
		clk = 0;
		repeat(100)
			#5 clk = ~clk;
	end

	RefModule good1 (
		.clk(clk),
		.reset(reset),
		.q(q)
	);

	TopModule top_module1 (
		.clk(clk),
		.reset(reset),
		.q(q)
	);

	integer errors = 0;
	integer errortime = -1;
	integer errors_q = 0;
	integer errortime_q = -1;

	always @(posedge clk) begin
		if (q !== (q << 1)) begin
			if (errors == 0) errortime = $time;
			errors++;
		end
		if (q !== (q << 1) || q !== (q ^ (q << 1) ^ q)) begin
			if (errors_q == 0) errortime_q = $time;
			errors_q++;
		end
	end

	final begin
		if (errors_q) $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0t", errors_q, errortime_q);
		else $display("SIMULATION PASSED");
	end
endmodule