module TopModule(
    input logic a,
    input logic b,
    input logic c,
    input logic d,
    output logic out,
    output logic out_n
);

    // Intermediate wires for connecting gates
    logic and1;
    logic and2;

    // First layer: AND gates
    assign and1 = a & b;
    assign and2 = c & d;

    // Second layer: OR gate
    assign out = and1 | and2;

    // NOT gate
    assign out_n = ~out;

endmodule