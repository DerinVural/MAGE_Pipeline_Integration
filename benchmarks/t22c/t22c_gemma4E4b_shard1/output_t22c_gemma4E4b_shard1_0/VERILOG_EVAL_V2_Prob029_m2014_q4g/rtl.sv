module TopModule (
    input  logic in1,
    input  logic in2,
    input  logic in3,
    output logic out
);

    // Intermediate wire for the XNOR operation between in1 and in2
    logic xnor_intermediate;

    // XNOR(in1, in2) = (in1 AND in2) OR (NOT in1 AND NOT in2)
    assign xnor_intermediate = (in1 & in2) | (~in1 & ~in2);

    // Final output: XOR of the XNOR result and in3
    assign out = xnor_intermediate ^ in3;

endmodule