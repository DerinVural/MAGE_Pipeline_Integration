module TopModule(
    input  logic x,
    input  logic y,
    output logic z
);

    // The boolean function is z = (x ^ y) & x
    assign z = (x ^ y) & x;

endmodule