module stimulus_gen (
    input clk,
    output logic a, b, sel_b1, sel_b2,
    output [511:0] wavedrom_title,
    output reg wavedrom_enable
);