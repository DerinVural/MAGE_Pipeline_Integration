`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
	input clk,
	output logic [254:0] in,
	output reg[511:0] wavedrom_title,
	output reg wavedrom_enable	
);

task wavedrom_start(input[511:0] title = "");
endtask
	
	task wavedrom_stop;
		#1;
	endtask		
	
	initial begin
		in <= 255'h0;
		wavedrom_start("");
		@(posedge clk, negedge clk) in <= 255'h0;
		@(posedge clk, negedge clk) in <= 255'h0;
		@(posedge clk, negedge clk) in <= 255'h1;
		@(posedge clk, negedge clk) in <= 255'h1;
		@(posedge clk, negedge clk) in <= 255'h3;
		@(posedge clk, negedge clk) in <= 255'h3;
		@(posedge clk, negedge clk) in <= 255'h7;
		@(posedge clk, negedge clk) in <= 255'haaaa;
		@(posedge clk, negedge clk) in <= 255'hf00000;
		@(posedge clk, negedge clk) in <= 255'h0;
		wavedrom_stop();
		repeat (200) @(posedge clk, negedge clk) begin
			in <= {$random, $random, $random, $random, $random, $random, $random, $random};
		end
		@(posedge clk);
		in <= '0;
		@(posedge clk)
		in <= '1;
		@(posedge clk)
		#1 $finish;
	end

endmodule

module tb();
	you_type_your_code_here

endmodule