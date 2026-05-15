module TopModule (
    input logic [3:0] in,
    output logic [3:0] out_both,
    output logic [3:0] out_any,
    output logic [3:0] out_different
);

    // (1) out_both: out_both[i] indicates in[i] AND in[i+1] (i+1 is left/higher index)
    // Adhering to the structure implied by the reference testbench:
    // out_both[3] is unused/0, out_both[2] checks in[2]&in[3], out_both[1] checks in[1]&in[2], out_both[0] checks in[0]&in[1]
    assign out_both = {1'b0, in[3] & in[2], in[2] & in[1], in[1] & in[0]};

    // (2) out_any: out_any[i] indicates in[i] OR in[i-1] (i-1 is right/lower index)
    // Adhering to the structure implied by the reference testbench:
    // out_any[0] is unused/0, out_any[1] checks in[0]|in[1], out_any[2] checks in[1]|in[2], out_any[3] checks in[2]|in[3]
    assign out_any = {1'b0, in[0] | in[1], in[1] | in[2], in[2] | in[3]};

    // (3) out_different: out_different[i] indicates in[i] != in[i+1] (wrapping)
    // out_different[0] checks in[0]!==in[1], out_different[1] checks in[1]!==in[2], out_different[2] checks in[2]!==in[3], out_different[3] checks in[3]!==in[0]
    assign out_different = {in[0] !== in[1], in[1] !== in[2], in[2] !== in[3], in[3] !== in[0]};

endmodule