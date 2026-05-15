module TopModule (p1a, p1b, p1c, p1d, p1e, p1f, p2a, p2b, p2c, p2d, p1y, p2y);

    // Port declarations
    input p1a, p1b, p1c, p1d, p1e, p1f;
    input p2a, p2b, p2c, p2d;
    output p1y, p2y;

    // Three-input AND gate for p1y
    wire and1_out;
    assign and1_out = p1a & p1b & p1c;
    wire and2_out;
    assign and2_out = p1d & p1e & p1f;
    // OR the two AND outputs
    assign p1y = and1_out | and2_out;

    // Two two-input AND gates for p2y and OR
    wire and3_out;
    assign and3_out = p2a & p2b;
    wire and4_out;
    assign and4_out = p2c & p2d;
    assign p2y = and3_out | and4_out;

endmodule