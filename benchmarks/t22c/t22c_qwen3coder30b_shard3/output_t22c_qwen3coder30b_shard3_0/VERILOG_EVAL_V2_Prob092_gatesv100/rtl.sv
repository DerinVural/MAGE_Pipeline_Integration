module TopModule (
    input  [99:0] in,
    output [99:0] out_both,
    output [99:0] out_any,
    output [99:0] out_different
);

    // out_both: Each bit is 1 if both the current bit and its left neighbor are 1
    // out_both[99] is 0 because there is no left neighbor
    assign out_both = { {1{1'b0}}, {99{in[98:0] & in[99:1]}} };

    // out_any: Each bit is 1 if either the current bit or its right neighbor is 1
    // out_any[0] is 0 because there is no right neighbor
    assign out_any = { {1{1'b0}}, {99{in[99:1] | in[98:0]}} };

    // out_different: Each bit is 1 if the current bit is different from its left neighbor
    // For wrapping, in[0]'s left neighbor is in[99]
    assign out_different = { (in[0] ^ in[99]), {99{in[99:1] ^ in[98:0]}} };

endmodule