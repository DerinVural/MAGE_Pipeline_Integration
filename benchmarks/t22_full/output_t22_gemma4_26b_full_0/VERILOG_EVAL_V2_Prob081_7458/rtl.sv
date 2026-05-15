module TopModule(
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

    // Logic for p1y: OR of two 3-input AND gates
    // AND1: p1a, p1b, p1c
    // AND2: p1d, p1e, p1f
    assign p1y = (p1a & p1b & p1c) | (p1d & p1e & p1f);

    // Logic for p2y: OR of two 2-input AND gates
    // AND3: p2a, p2b
    // AND4: p2c, p2d
    assign p2y = (p2a & p2b) | (p2c & p2d);

endmodule