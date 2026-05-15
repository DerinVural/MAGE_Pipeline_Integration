module TopModule(
    input  logic a,
    input  logic b,
    input  logic c,
    input  logic d,
    output logic out,
    output logic out_n
);

    // Intermediate wires for the first layer (AND gates)
    logic and_ab;
    logic and_cd;

    // First layer: AND gates
    assign and_ab = a & b;
    assign and_cd = c & d;

    // Second layer: OR gate
    assign out = and_ab | and_cd;

    // Inverted output
    assign out_n = ~out;

endmodule