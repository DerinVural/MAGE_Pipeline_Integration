module TopModule (
    input logic clk,
    input logic reset,
    input logic [31:0] in,
    output logic [31:0] out,
    output logic [511:0] wavedrom_title,
    output logic wavedrom_enable
);