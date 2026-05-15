module TopModule (
    input  logic        clk,
    input  logic        load,
    input  logic        ena,
    input  logic [1:0]  amount,
    input  logic [63:0] data,
    output logic [63:0] q
);
endmodule