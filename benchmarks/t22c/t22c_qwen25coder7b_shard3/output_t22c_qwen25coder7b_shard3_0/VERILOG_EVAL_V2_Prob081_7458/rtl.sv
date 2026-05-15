module TopModule (
    input logic p1a,
    input logic p1b,
    input logic p1c,
    input logic p1d,
    input logic p1e,
    input logic p1f,
    input logic p2a,
    input logic p2b,
    input logic p2c,
    input logic p2d,
    output logic p1y,
    output logic p2y
);

    // Intermediate signals for AND gates
    logic and1;
    logic and2;
    logic and3;
    logic and4;
    logic and5;
    logic and6;
    logic and7;
    logic and8;

    // First set of AND gates
    assign and1 = p1a & p1b & p1c;
    assign and2 = p1d & p1e & p1f;

    // Second set of AND gates
    assign and3 = p2a & p2b;
    assign and4 = p2c & p2d;

    // Intermediary signals for OR gates
    logic or1;
    logic or2;

    // OR gates combining the results of AND gates
    assign or1 = and1 | and2;
    assign or2 = and3 | and4;

    // Final outputs
    assign p1y = or1;
    assign p2y = or2;

endmodule;