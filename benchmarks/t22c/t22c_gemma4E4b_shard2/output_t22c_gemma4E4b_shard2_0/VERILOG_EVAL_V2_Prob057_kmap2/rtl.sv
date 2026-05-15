module TopModule (
    input  logic a,
    input  logic b,
    input  logic c,
    input  logic d,
    output logic out
);

    // Implementation based on the K-map truth table (Sum of Minterms where out = 1):
    // Minterms: m0, m1, m2, m4, m7, m8, m9, m13, m14, m15

    assign out = ( (~a & ~b & ~c & ~d)  || // m0: 00/00 -> 1
                   (~a & ~b & ~c & d)  || // m1: 00/01 -> 1
                   (~a & ~b & c & ~d)  || // m2: 00/10 -> 1
                   (~a & b & ~c & ~d)  || // m4: 01/00 -> 1
                   (~a & b & c & d)  || // m7: 01/11 -> 1
                   (a & ~b & ~c & ~d)  || // m8: 10/00 -> 1
                   (a & ~b & ~c & d)  || // m9: 10/01 -> 1
                   (a & b & ~c & d)  || // m13: 11/01 -> 1
                   (a & b & c & ~d)  || // m14: 11/10 -> 1
                   (a & b & c & d) );   // m15: 11/11 -> 1

endmodule