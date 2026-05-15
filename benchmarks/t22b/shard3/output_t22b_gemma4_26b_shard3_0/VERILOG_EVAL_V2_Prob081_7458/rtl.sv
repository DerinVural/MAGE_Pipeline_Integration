module TopModule (
    input  logic p1a,
    input  logic p1b,
    input  logic p1c,
    input  logic p1d,
    input  logic p1e,
    input  logic p1f,
    input  logic p2a,
    input  logic p2b,
    input  logic p2c,
    input  logic p2d,
    output logic p1y,
    output logic p2y
);

    // Combinational logic for p1y: OR of two 3-input AND gates
    // Gate 1: p1a AND p1b AND p1c
    // Gate 2: p1d AND p1e AND p1f
    assign p1y = (p1a & p1b & p1c) | (p1d & p1e & p1f);

    // Combinational logic for p2y: OR of two 2-input AND gates
    // Gate 1: p2a AND p2b
    // Gate 2: p2c AND p2d
    assign p2y = (p2a & p2b) | (p2c & p2d);

endmodule