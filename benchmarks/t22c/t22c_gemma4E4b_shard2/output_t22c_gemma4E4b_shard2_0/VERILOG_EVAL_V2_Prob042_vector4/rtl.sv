module TopModule (
    input logic [7:0] in,
    output logic [31:0] out
);

    // Sign extension: Replicate the MSB (in[7]) 24 times, followed by the 8-bit input.
    // {24{in[7]}} creates 24 copies of the bit in[7].
    // Concatenation combines these 24 bits with the 8-bit 'in' to form 32 bits.
    assign out = { {24{in[7]}}, in };

endmodule