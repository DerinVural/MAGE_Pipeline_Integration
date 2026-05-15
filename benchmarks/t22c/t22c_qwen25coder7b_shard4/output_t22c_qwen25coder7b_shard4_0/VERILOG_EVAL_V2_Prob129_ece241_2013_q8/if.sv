module stimulus_gen (
	input clk,
	output logic aresetn,
	output logic x,
	output reg[511:0] wavedrom_title,
	output reg wavedrom_enable,
	input tb_match
);