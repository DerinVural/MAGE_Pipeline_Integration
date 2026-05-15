module TopModule(
    input  logic [31:0] in,
    output logic [31:0] out
);

    // The requirement is to reverse the byte order of the 32-bit vector.
    // Input Bytes: [B3(31:24)] [B2(23:16)] [B1(15:8)] [B0(7:0)]
    // Desired Output: [B0] [B1] [B2] [B3]
    
    assign out = {in[7:0], in[15:8], in[23:16], in[31:24]};

endmodule