module TopModule (
    input  logic a,
    input  logic b,
    output logic out_and,
    output logic out_or,
    output logic out_xor,
    output logic out_nand,
    output logic out_nor,
    output logic out_xnor,
    output logic out_anotb
);

    // (1) out_and: a and b
    assign out_and = a & b;

    // (2) out_or: a or b
    assign out_or = a | b;

    // (3) out_xor: a xor b
    assign out_xor = a ^ b;

    // (4) out_nand: a nand b (NOT (a AND b))
    assign out_nand = ~(a & b);

    // (5) out_nor: a nor b (NOT (a OR b))
    assign out_nor = ~(a | b);

    // (6) out_xnor: a xnor b (Equivalent to a == b)
    assign out_xnor = ~(a ^ b);

    // (7) out_anotb: a and-not b (a AND NOT b)
    assign out_anotb = a & ~b;

endmodule