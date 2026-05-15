module TopModule (
    input  logic [5:0] y,
    input  logic w,
    output logic Y1,
    output logic Y3
);

    // The outputs Y1 and Y3 are the inputs to the state flip-flops y[1] and y[3].
    // Based on the transition table provided:
    // State A (y[0]) --w=1--> B (y[1])
    // State B (y[1]) --w=0--> D (y[3])
    // State C (y[2]) --w=0--> D (y[3])
    // State D (y[3]) --w=1--> F (y[5])
    // State E (y[4]) --w=0--> D (y[3])
    // State F (y[5]) --w=0--> D (y[3])

    // Derive Y1 (next state for y[1]):
    // y[1] is next if current state is A and w is 1.
    // Y1 = y[0] & w

    // Derive Y3 (next state for y[3]):
    // y[3] is next if current state is B and w is 0,
    // OR current state is C and w is 0,
    // OR current state is E and w is 0,
    // OR current state is F and w is 0.
    // Y3 = (y[1] | y[2] | y[4] | y[5]) & ~w

    always @(*) begin
        Y1 = (y[0] & w);
        Y3 = (y[1] | y[2] | y[4] | y[5]) & (~w);
    end

endmodule