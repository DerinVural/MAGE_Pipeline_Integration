module TopModule (
    input [3:0] in,
    output [3:0] out_both,
    output [3:0] out_any,
    output [3:0] out_different
);

    // out_both: Each bit indicates if both current and left neighbor are 1
    // out_both[3] is undefined since in[3] has no left neighbor
    assign out_both[3] = 1'b0;
    assign out_both[2] = in[2] & in[3];
    assign out_both[1] = in[1] & in[2];
    assign out_both[0] = in[0] & in[1];

    // out_any: Each bit indicates if current or right neighbor is 1
    // out_any[0] is undefined since in[0] has no right neighbor
    assign out_any[0] = 1'b0;
    assign out_any[1] = in[1] | in[0];
    assign out_any[2] = in[2] | in[1];
    assign out_any[3] = in[3] | in[2];

    // out_different: Each bit indicates if current differs from left neighbor with wraparound
    // out_different[3] = in[3] != in[0]
    assign out_different[3] = in[3] ^ in[0];
    assign out_different[2] = in[2] ^ in[3];
    assign out_different[1] = in[1] ^ in[2];
    assign out_different[0] = in[0] ^ in[1];

endmodule