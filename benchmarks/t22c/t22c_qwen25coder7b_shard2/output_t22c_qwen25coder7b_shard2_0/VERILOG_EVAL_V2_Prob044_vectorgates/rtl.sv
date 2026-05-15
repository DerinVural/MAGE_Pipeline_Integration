module TopModule (
    logic [2:0] a,
    logic [2:0] b,
    logic [2:0] out_or_bitwise,
    logic out_or_logical,
    logic [5:0] out_not
);

    // Combinational logic for bitwise OR of a and b
    assign out_or_bitwise = a | b;

    // Combinational logic for logical OR of a and b
    assign out_or_logical = a || b;

    // Combinational logic for inverse of a and b
    logic [2:0] not_a;
    logic [2:0] not_b;
    assign not_a = ~a;
    assign not_b = ~b;

    // Structural connections for out_not
    assign out_not = {not_b, not_a};

endmodule