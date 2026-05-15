module TopModule(
    input logic x,
    input logic y,
    output logic z
);

    // The waveform corresponds to the XNOR operation: z is 1 when x and y are the same (both 0 or both 1).
    assign z = (x == y);

endmodule