module TopModule(
    input  logic [31:0] in,
    output logic [31:0] out
);

    // Reversing the byte order:
    // Input bits [31:24] -> Output bits [7:0]
    // Input bits [23:16] -> Output bits [15:8]
    // Input bits [15:8]  -> Output bits [23:16]
    // Input bits [7:0]   -> Output bits [31:24]

    assign out = {in[7:0], in[15:8], in[23:16], in[31:24]};

endmodule