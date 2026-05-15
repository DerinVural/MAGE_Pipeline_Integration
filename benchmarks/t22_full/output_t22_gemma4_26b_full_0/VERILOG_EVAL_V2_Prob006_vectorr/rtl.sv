module TopModule(
    input  logic [7:0] in,
    output logic [7:0] out
);

    // Combinational logic to reverse the bit order
    // in[0] -> out[7], in[1] -> out[6], ..., in[7] -> out[0]
    always @(*) begin
        out = {in[0], in[1], in[2], in[3], in[4], in[5], in[6], in[7]};
    end

endmodule