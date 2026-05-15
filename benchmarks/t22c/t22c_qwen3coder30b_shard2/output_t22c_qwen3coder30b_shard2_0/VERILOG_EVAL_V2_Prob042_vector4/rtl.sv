module TopModule (
    input  [7:0] in,
    output [31:0] out
);

    // Sign extend 8-bit input to 32-bit output
    // Replicate the sign bit (bit 7) 24 times and concatenate with the original 8 bits
    assign out = { {24{in[7]}}, in };

endmodule