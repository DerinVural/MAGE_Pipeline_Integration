module TopModule (
    input  logic [99:0] in,
    output logic [99:0] out_both,
    output logic [99:0] out_any,
    output logic [99:0] out_different
);

    always @(*) begin
        // out_both calculation
        // out_both[i] = in[i] & in[i+1]. out_both[99] = 0.
        out_both[99] = 1'b0;
        out_both[98:0] = in[98:0] & in[99:1];

        // out_any calculation
        // out_any[i] = in[i] | in[i-1]. out_any[0] = 0.
        out_any[0] = 1'b0;
        out_any[99:1] = in[99:1] | in[98:0];

        // out_different calculation
        // out_different[i] = in[i] ^ in[i+1] (with wrap around for 99)
        // out_different[99] uses in[0] as neighbor to left.
        out_different[99] = in[99] ^ in[0];
        out_different[98:0] = in[98:0] ^ in[99:1];
    end

endmodule