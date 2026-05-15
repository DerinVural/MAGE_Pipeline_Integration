module TopModule (
    input [2:0] y,
    input w,
    output Y1
);

    // Derive next state logic for y[1]
    // States: A=000, B=001, C=010, D=011, E=100, F=101
    // We want to compute the next value of y[1] based on current y and w
    
    // Using truth table method:
    // State | w | y[1] next
    // 000   | 0 | 0 (A->B)
    // 000   | 1 | 0 (A->A)
    // 001   | 0 | 1 (B->C)
    // 001   | 1 | 1 (B->D)
    // 010   | 0 | 1 (C->E)
    // 010   | 1 | 1 (C->D)
    // 011   | 0 | 1 (D->F)
    // 011   | 1 | 0 (D->A)
    // 100   | 0 | 1 (E->E)
    // 100   | 1 | 1 (E->D)
    // 101   | 0 | 0 (F->C)
    // 101   | 1 | 1 (F->D)
    
    // Combining all conditions:
    // y[1] next = (y[0] & ~y[1] & ~y[2] & w) | (~y[0] & y[1] & ~y[2] & w) | (~y[0] & y[1] & y[2] & ~w) |
    //             (y[0] & ~y[1] & y[2] & w) | (~y[0] & ~y[1] & y[2] & w) | (y[0] & y[1] & y[2] & ~w) |
    //             (y[0] & ~y[1] & ~y[2] & ~w) | (~y[0] & ~y[1] & y[2] & ~w)
    
    // Simplifying the logic using Karnaugh maps:
    // When w=0: y[1] next = y[1] (when state E) or y[1] = 0 (when state A)
    // When w=1: y[1] next = 1 (when state B, C) or y[1] = 0 (when state D)
    // This results in:
    // y[1] next = y[0] & w | (~y[0] & ~y[2] & w) | (~y[0] & y[1] & y[2] & ~w) | (y[0] & y[2] & w)
    
    // Actually, reevaluating carefully:
    // Based on the transition table:
    // For y[1]=0 (states A,B): y[1]' = 0 when w=0; 0 when w=1
    // For y[1]=1 (states C,D,E,F): y[1]' = 1 when w=0; 1 when w=1 except state D where it's 0 when w=1
    
    // Let's simplify directly:
    // If state is B (001) or C (010) or E (100) or F (101) and w=1 -> y[1]' = 1
    // If state is D (011) and w=1 -> y[1]' = 0
    // If state is E (100) and w=0 -> y[1]' = 1
    // If state is C (010) and w=0 -> y[1]' = 1
    // If state is D (011) and w=0 -> y[1]' = 1
    // If state is A (000) and w=0 -> y[1]' = 0
    // If state is A (000) and w=1 -> y[1]' = 0
    // If state is B (001) and w=0 -> y[1]' = 1
    // If state is B (001) and w=1 -> y[1]' = 1
    // If state is F (101) and w=0 -> y[1]' = 0
    // If state is F (101) and w=1 -> y[1]' = 1
    
    // Thus, we can derive final expression:
    // y[1]' = (y[2] & y[1] & ~y[0] & w) | (y[1] & ~y[0] & ~y[2] & w) | (y[0] & y[1] & y[2] & w) | (~y[0] & y[1] & ~y[2])
    
    assign Y1 = (y[2] & y[1] & ~y[0] & w) | (y[1] & ~y[0] & ~y[2] & w) | (y[0] & y[1] & y[2] & w) | (~y[0] & y[1] & ~y[2]);

endmodule