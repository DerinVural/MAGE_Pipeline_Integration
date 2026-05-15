`timescale 1ps/1ps
module tb();
	logic clk=0;
	initial forever #5 clk=~clk;

	logic reset;
	logic in;
	logic disc_ref, disc_dut;
	logic flag_ref, flag_dut;
	logic err_ref, err_dut;

	reg [2:0] state_queue [0:9];
	reg [2:0] disc_queue [0:9];
	reg [2:0] flag_queue [0:9];
	reg [2:0] err_queue [0:9];
	reg [2:0] reset_queue [0:9];
	enumuration {INIT=0, ST1=1, ST2=2, ST3=3, ST4=4, ST5=5, ST6=6} state;

	localparam MAX_QUEUE_SIZE=10;
	integer queue_ptr=0;

	initial begin reset=1; in=0; @(posedge clk);
	repeat(800) @(posedge clk, negedge clk) begin reset=!($random&31); in=|($random&7); end
	#1 $finish;
	end

	RefModule golden (
	.clk(clk), .reset(reset), .in(in),
	.disc(disc_ref), .flag(flag_ref), .err(err_ref));

	TopModule dut (
	.clk(clk), .reset(reset), .in(in),
	.disc(disc_dut), .flag(flag_dut), .err(err_dut));

	reg [10:0] errors=0; reg [20:0] error_time;

	always @(posedge clk, negedge clk) begin
		if (queue_ptr >= MAX_QUEUE_SIZE-1) begin
			for (int i=0; i<MAX_QUEUE_SIZE-1; i++) begin
				state_queue[i] = state_queue[i+1];
			end
		end
		state_queue[queue_ptr] = {disc_dut, flag_dut, err_dut};
		disc_queue[queue_ptr] = disc_dut;
		flag_queue[queue_ptr] = flag_dut;
		err_queue[queue_ptr] = err_dut;
		reset_queue[queue_ptr] = reset;
		queue_ptr = queue_ptr+1;
	
		if ((disc_ref !== disc_dut) || (flag_ref !== flag_dut) || (err_ref !== err_dut)) begin
			if (errors==0) error_time = $time;
			errors = errors+1;
		end
	end

	enumuration { disc_ref=0, flag_ref=1, err_ref=2 } golden_output;

	always @* golden_output = {disc_ref, flag_ref, err_ref};

	always @* tb_match = (golden_output === (golden_output ^ {disc_dut, flag_dut, err_dut} ^ golden_output));

	initial begin $dumpfile("wave.vcd"); $dumpvars(1,tb); end

	initial begin // Final display
		if (errors==0) $display("SIMULATION PASSED");
		else $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", errors, error_time);
	end

	initial begin #1000000 $finish; end
endmodule