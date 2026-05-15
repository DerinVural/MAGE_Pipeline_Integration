module TopModule(
    input  logic in1,
    input  logic in2,
    input  logic in3,
    output logic out
);

    // Intermediate signal for the XNOR gate
    logic xnor_out;

    // Step 1: XNOR of in1 and in2
    assign xnor_out = ~(in1 ^ in2);

    // Step 2: XOR the result with in3
    assign out = xnor_out ^ in3;

endmodule