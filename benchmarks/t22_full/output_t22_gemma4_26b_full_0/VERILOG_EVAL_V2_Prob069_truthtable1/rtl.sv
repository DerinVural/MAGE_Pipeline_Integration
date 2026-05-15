module TopModule(
    input  logic x3,
    input  logic x2,
    input  logic x1,
    output logic f
);

    // Combinational logic implementation based on the derived Boolean expression
    // f = (!x3 & x2) | (x3 & x1)
    assign f = ((~x3) & x2) | (x3 & x1);

endmodule