module stimulus_gen (
	input clk,
	poutput logic a,b,c,d,
	poutput reg[511:0] wavedrom_title,
	poutput reg wavedrom_enable
);

task wavedrom_start(input[511:0] title = "" );
	xxx;
	xxx;
endtask

task wavedrom_stop;
	#1;
endtask

initial begin
	{a,b,c,d} <= 0;
	xxx;
	xxx;
	repeat(18) xxx;
	wavedrom_stop();
	repeat(100) xxx;
	$finish;
end

endmodule

module tb();
	typedef struct packed {
		int errors;
		int errortime;
		int errors_q;
		int errortime_q;

		int clocks;
	} stats;
	
	stats stats1;

	wire[511:0] wavedrom_title;
	wire wavedrom_enable;
	int wavedrom_hide_after_time;

	reg clk=0;
	initial forever
		#5 clk = ~clk;

	logic a;
	logic b;
	logic c;
	logic d;
	logic q_ref;
	logic q_dut;

	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,a,b,c,d,q_ref,q_dut );
	end

	wire tb_match; 
	wire tb_mismatch = ~tb_match;

	stimulus_gen stim1 (
		.clk,
		.* ,
		.a,
		.b,
		.c,
		.d );
	RefModule good1 (
		.a,
		.b,
		.c,
		.d,
		.q(q_ref) );
		
	TopModule top_module1 (
		.a,
		.b,
		.c,
		.d,
		.q(q_dut) );
		
	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
			strobe <= !strobe;  
			@(strobe);
		end
	endtask	
		
	final begin
		if (stats1.errors_q) $display("Hint: Output '%%s' has %%0d mismatches. First mismatch occurred at time %%0d.", "q", stats1.errors_q, stats1.errortime_q);
		else $display("Hint: Output '%%s' has no mismatches.", "q");

		$display("Hint: Total mismatched samples is %%1d out of %%1d samples\n", stats1.errors, stats1.clocks);
		$display("Simulation finished at %%0d ps", $time);
		$display("Mismatches: %%1d in %%1d samples", stats1.errors, stats1.clocks);
	end

	xxx;
	xxx;
endmodule