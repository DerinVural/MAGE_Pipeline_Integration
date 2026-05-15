module stimulus_gen (input clk, output logic in1, in2);
module tb();
	reg clk;
	logic in1, in2;
	logic out_ref, out_dut;
	wire tb_match, tb_mismatch;
	TopModule top_module1 (.in1(in1), .in2(in2), .out(out_dut));
	RefModule good1 (.in1(in1), .in2(in2), .out(out_ref));
