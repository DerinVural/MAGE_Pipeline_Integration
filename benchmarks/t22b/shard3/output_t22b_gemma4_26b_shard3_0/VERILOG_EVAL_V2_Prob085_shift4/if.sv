module TopModule (
    input  logic clk,
    input  logic areset,
    input  logic load,
    input  logic ena,
    input  logic [3:0] data,
    output logic [3:0] q
);