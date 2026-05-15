module TopModule (
    input  logic [7:0] in,
    output logic [7:0] out
);

    // Reverses the bit ordering of the 8-bit input.
    // The LSB of 'in' (in[0]) becomes the MSB of 'out' (out[7]).
    // The MSB of 'in' (in[7]) becomes the LSB of 'out' (out[0]).
    assign out = {in[0], in[1], in[2], in[3], in[4], in[5], in[6], in[7]};

endmodule