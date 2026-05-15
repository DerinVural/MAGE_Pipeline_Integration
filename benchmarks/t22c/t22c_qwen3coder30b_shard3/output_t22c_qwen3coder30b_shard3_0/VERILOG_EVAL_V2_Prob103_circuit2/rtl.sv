module TopModule (
    input logic a,
    input logic b,
    input logic c,
    input logic d,
    output logic q
);

    // Using direct implementation of truth table using bitwise operations
    assign q = (~a & ~b & ~c & ~d) |
               (~a & ~b & c & d) |
               (~a & b & ~c & ~d) |
               (~a & b & ~c & d) |
               (~a & b & c & ~d) |
               (a & ~b & ~c & d) |
               (a & ~b & c & ~d) |
               (a & b & ~c & ~d) |
               (a & b & c & d);

endmodule