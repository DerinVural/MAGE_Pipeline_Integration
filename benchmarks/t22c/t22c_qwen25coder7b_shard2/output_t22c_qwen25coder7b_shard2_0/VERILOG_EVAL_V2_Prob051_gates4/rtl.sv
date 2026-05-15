module TopModule (
    input logic [3:0] in,
    output logic out_and,
    output logic out_or,
    output logic out_xor,
    output logic [511:0] wavedrom_title,
    output logic wavedrom_enable
);

    // Combinational logic for AND gate
    assign out_and = in[0] & in[1] & in[2] & in[3];

    // Combinational logic for OR gate
    assign out_or = in[0] | in[1] | in[2] | in[3];

    // Combinational logic for XOR gate
    assign out_xor = in[0] ^ in[1] ^ in[2] ^ in[3];

    // Wavedrom related outputs
    assign wavedrom_title = "All combinations";
    assign wavedrom_enable = 1'b1;

endmodule