module TopModule (
    input  logic a,
    input  logic b,
    input  logic c,
    input  logic d,
    output logic out,
    output logic out_n
);

    // Intermediate wires for the AND gate outputs
    logic and_1;
    logic and_2;

    // First layer: Two AND gates
    assign and_1 = a & b;
    assign and_2 = c & d;

    // Second layer: OR gate feeding 'out'
    assign out = and_1 | and_2;

    // Third layer: Inverted output
    assign out_n = ~out;

endmodule