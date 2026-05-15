module TopModule (
    input  logic in,
    output logic out
);

    // A wire behavior means the output is directly connected to the input.
    assign out = in;

endmodule