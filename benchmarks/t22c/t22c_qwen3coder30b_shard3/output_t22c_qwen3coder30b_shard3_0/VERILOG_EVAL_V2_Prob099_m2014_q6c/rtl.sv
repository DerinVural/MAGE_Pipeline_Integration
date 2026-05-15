module TopModule (
    input [5:0] y,
    input w,
    output logic Y1,
    output logic Y3
);

    // Based on the state transition diagram and one-hot encoding:
    // Y1 corresponds to y[1] (state B)
    // Y3 corresponds to y[3] (state D)
    
    // Analyzing transitions for Y1 (state B):
    // From A (y=000001): w=0 -> B (y[1]=1), w=1 -> A (y[1]=0)
    // From B (y=000010): w=0 -> C (y[1]=0), w=1 -> D (y[1]=0)
    // From C (y=000100): w=0 -> E (y[1]=0), w=1 -> D (y[1]=0)
    // From D (y=001000): w=0 -> F (y[1]=0), w=1 -> A (y[1]=0)
    // From E (y=010000): w=0 -> E (y[1]=0), w=1 -> D (y[1]=0)
    // From F (y=100000): w=0 -> C (y[1]=0), w=1 -> D (y[1]=0)
    
    // Simplified: Y1 = y[0] & ~w  // A state transition to B when w=0
    
    // Analyzing transitions for Y3 (state D):
    // From A (y=000001): w=0 -> B (y[3]=0), w=1 -> A (y[3]=0)
    // From B (y=000010): w=0 -> C (y[3]=0), w=1 -> D (y[3]=1)
    // From C (y=000100): w=0 -> E (y[3]=0), w=1 -> D (y[3]=1)
    // From D (y=001000): w=0 -> F (y[3]=0), w=1 -> A (y[3]=0)
    // From E (y=010000): w=0 -> E (y[3]=0), w=1 -> D (y[3]=1)
    // From F (y=100000): w=0 -> C (y[3]=0), w=1 -> D (y[3]=1)
    
    // Simplified: Y3 = (y[1] | y[2] | y[4] | y[5]) & w
    
    assign Y1 = y[0] & ~w;
    assign Y3 = (y[1] | y[2] | y[4] | y[5]) & w;

endmodule