module TopModule (
    input  logic [1023:0] in,
    input  logic [7:0]    sel,
    output logic [3:0]    out
);

    // The module implements a 256-to-1 multiplexer.
    // Each mux input is 4 bits wide.
    // The base index is sel * 4.
    // We use the indexed part-select operator [base_expr +: width] 
    // where width is a constant (4).

    assign out = in[sel * 4 +: 4];

endmodule