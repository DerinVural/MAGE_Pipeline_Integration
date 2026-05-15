module TopModule (
    input [5:0] y,
    input w,
    output Y1,
    output Y3
);

    // Deriving the logic for Y1 and Y3 based on one-hot encoded states
    // y[5] = F, y[4] = E, y[3] = D, y[2] = C, y[1] = B, y[0] = A
    
    // Y1 is the input for y[1] flip-flop
    // y[1] = B should be set when coming from A with w=1
    assign Y1 = y[0] & w;
    
    // Y3 is the input for y[3] flip-flop
    // y[3] = D should be set when coming from B, C, E, or F with w=0
    assign Y3 = (y[1] | y[2] | y[4] | y[5]) & ~w;

endmodule