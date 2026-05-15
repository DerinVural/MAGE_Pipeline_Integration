module TopModule (
    input  logic p1a,
    input  logic p1b,
    input  logic p1c,
    input  logic p1d,
    input  logic p2a,
    input  logic p2b,
    input  logic p2c,
    input  logic p2d,
    output logic p1y,
    output logic p2y
);

    // Implementation of the first 4-input NAND gate (7420 part 1)
    // Y = NOT (A AND B AND C AND D)
    assign p1y = ~(p1a & p1b & p1c & p1d);

    // Implementation of the second 4-input NAND gate (7420 part 2)
    // Y = NOT (A AND B AND C AND D)
    assign p2y = ~(p2a & p2b & p2c & p2d);

endmodule