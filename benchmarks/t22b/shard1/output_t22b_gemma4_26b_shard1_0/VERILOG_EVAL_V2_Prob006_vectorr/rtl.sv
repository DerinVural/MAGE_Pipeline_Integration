module TopModule (
    input  logic [7:0] in,
    output logic [7:0] out
);

    // Reversing the bit order using concatenation
    assign out = {in[0], in[1], in[2], in[3], in[4], in[5], in[6], in[7]};

endmodule