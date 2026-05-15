module TopModule(
    input logic in,
    output logic out
);

    // The module should behave like a wire, meaning the output directly follows the input.
    assign out = in;

endmodule