module TopModule(
    input  logic [5:0] y,
    input  logic w,
    output logic Y1,
    output logic Y3
);

    // Y1 is the input to flip-flop y[1].
    // Based on the transition table, y[1] is set when current state is A (y[0]) and w is 1.
    assign Y1 = y[0] & w;

    // Y3 is the input to flip-flop y[3].
    // Based on the transition table, y[3] is set when:
    // - B (y[1]) and w=0
    // - C (y[2]) and w=0
    // - E (y[4]) and w=0
    // - F (y[5]) and w=0
    assign Y3 = (y[1] | y[2] | y[4] | y[5]) & (~w);

endmodule