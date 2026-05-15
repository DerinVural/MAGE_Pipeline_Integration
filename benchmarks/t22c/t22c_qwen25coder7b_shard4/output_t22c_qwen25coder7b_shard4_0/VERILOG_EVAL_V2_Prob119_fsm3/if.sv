module stimulus_gen (
	input clk,
	output logic in,
	output logic areset,
	output reg[511:0] wavedrom_title,
	output reg wavedrom_enable,
	input tb_match
);