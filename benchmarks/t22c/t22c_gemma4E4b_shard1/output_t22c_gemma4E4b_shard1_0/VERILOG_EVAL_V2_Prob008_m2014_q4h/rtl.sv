module TopModule(
    input  logic in,
    output logic out
);

    // The output must be assigned the same value as the input combinationally.
    assign out = in;

endmodule