module TopModule(
    input  logic [31:0] in,
    output logic [31:0] out
);

    // Reversing the byte order:
    // Byte 0: in[7:0]   -> goes to out[31:24]
    // Byte 1: in[15:8]  -> goes to out[23:16]
    // Byte 2: in[23:16] -> goes to out[15:8]
    // Byte 3: in[31:24] -> goes to out[7:0]
    // Wait, the requirement is to reverse byte order.
    // Input bytes: B3 (31:24), B2 (23:16), B1 (15:8), B0 (7:0)
    // Output bytes should be: B0, B1, B2, B3
    // So out[31:24] = B0, out[23:16] = B1, out[15:8] = B2, out[7:0] = B3
    // Actually, 'reverse the byte order' usually means 
    // if input is [B3, B2, B1, B0], output is [B0, B1, B2, B3].
    // Let's map:
    // out[31:24] = in[7:0]
    // out[23:16] = in[15:8]
    // out[15:8]  = in[23:16]
    // out[7:0]   = in[31:24]

    assign out = {in[7:0], in[15:8], in[23:16], in[31:24]};

endmodule