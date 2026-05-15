module TopModule (
    input  logic a,
    input  logic b,
    input  logic c,
    input  logic d,
    output logic out,
    output logic out_n
);

    // Intermediate wires for the two AND gates
    logic w1;
    logic w2;

    // Layer 1: Two AND gates
    assign w1 = a & b;
    assign w2 = c & d;

    // Layer 2: OR the two AND outputs to get 'out'
    assign out = w1 | w2;

    // Inverted output
    assign out_n = ~out;

endmodule