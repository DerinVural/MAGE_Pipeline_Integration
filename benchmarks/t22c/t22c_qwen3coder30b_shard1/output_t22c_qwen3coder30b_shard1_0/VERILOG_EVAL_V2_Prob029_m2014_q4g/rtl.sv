module TopModule (
    input  logic in1,
    input  logic in2,
    input  logic in3,
    output logic out
);

    // Implement the described circuit:
    // XNOR of in1 and in2 -> XOR with in3 -> out
    assign out = (in1 ~^ in2) ^ in3;

endmodule