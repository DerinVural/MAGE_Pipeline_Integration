module TopModule(
    input  logic [3:0] in,
    output logic [3:0] out_both,
    output logic [3:0] out_any,
    output logic [3:0] out_different
);

    // Combinational logic for out_both
    // out_both[i] indicates if in[i] and in[i+1] are both 1.
    // out_both[3] has no left neighbor.
    always @(*) begin
        out_both[3] = 1'b0;
        out_both[2] = in[2] & in[3];
        out_both[1] = in[1] & in[2];
        out_both[0] = in[0] & in[1];
    end

    // Combinational logic for out_any
    // out_any[i] indicates if in[i] or in[i-1] is 1.
    // out_any[0] has no right neighbor.
    always @(*) begin
        out_any[0] = 1'b0;
        out_any[1] = in[1] | in[0];
        out_any[2] = in[2] | in[1];
        out_any[3] = in[3] | in[2];
    end

    // Combinational logic for out_different
    // out_different[i] indicates if in[i] is different from its neighbor to the left.
    // The vector wraps around: in[3]'s left neighbor is in[0].
    always @(*) begin
        out_different[3] = in[3] ^ in[0];
        out_different[2] = in[2] ^ in[3];
        out_different[1] = in[1] ^ in[2];
        out_different[0] = in[0] ^ in[1];
    end

endmodule