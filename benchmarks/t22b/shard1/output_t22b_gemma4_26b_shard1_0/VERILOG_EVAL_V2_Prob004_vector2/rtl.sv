module TopModule (
    input  logic [31:0] in,
    output logic [31:0] out
);

    // Combinational logic to reverse byte order
    // Byte 0: in[7:0], Byte 1: in[15:8], Byte 2: in[23:16], Byte 3: in[31:24]
    // New order: Byte 3, Byte 2, Byte 1, Byte 0
    always @(*) begin
        out = {in[7:0], in[15:8], in[23:16], in[31:24]};
    end

endmodule