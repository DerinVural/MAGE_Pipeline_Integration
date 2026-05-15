module TopModule (
    input  logic in1,
    input  logic in2,
    input  logic in3,
    output logic out
);

    // Stage 1: XNOR gate (in1 and in2)
    // Stage 2: XOR gate (Stage 1 output and in3)
    assign out = (in1 ~^ in2) ^ in3;

endmodule