module TopModule (
    input  logic        d,
    input  logic        done_counting,
    input  logic        ack,
    input  logic [9:0]  state,
    output logic        B3_next,
    output logic        S_next,
    output logic        S1_next,
    output logic        Count_next,
    output logic        Wait_next,
    output logic        done,
    output logic        counting,
    output logic        shift_ena
);

    // The module implements combinational logic for a Moore State Machine.
    // The state bits are: S=0, S1=1, S11=2, S110=3, B0=4, B1=5, B2=6, B3=7, Count=8, Wait=9

    // Next-state logic signals
    // S_next: Assert when next-state is S state
    // S1_next: Assert when next-state is S1 state
    // B3_next: Assert when next-state is B3 state
    // Count_next: Assert when next-state is Count state
    // Wait_next: Assert when next-state is Wait state

    always @(*) begin
        // Initialize outputs to 0 to avoid latches
        S_next      = 1'b0;
        S1_next     = 1'b0;
        B3_next     = 1'b0;
        Count_next  = 1'b0;
        Wait_next   = 1'b0;

        // Transitions from S (bit 0)
        if (state[0]) begin
            if (d) S1_next = 1'b1;
            else    S_next = 1'b1;
        end
        // Transitions from S1 (bit 1)
        else if (state[1]) begin
            if (d) /* next is S11 (bit 2) */ ;
            else    S_next = 1'b1;
        end
        // Transitions from S11 (bit 2)
        else if (state[2]) begin
            if (d) /* next is S11 (bit 2) */ ;
            else    /* next is S110 (bit 3) */ ;
        end
        // Transitions from S110 (bit 3)
        else if (state[3]) begin
            if (d) /* next is B0 (bit 4) */ ;
            else    S_next = 1'b1;
        end
        // Transitions from B0 (bit 4)
        else if (state[4]) begin
            /* next is B1 (bit 5) */ ;
        end
        // Transitions from B1 (bit 5)
        else if (state[5]) begin
            /* next is B2 (bit 6) */ ;
        end
        // Transitions from B2 (bit 6)
        else if (state[6]) begin
            B3_next = 1'b1;
        end
        // Transitions from B3 (bit 7)
        else if (state[7]) begin
            Count_next = 1'b1;
        end
        // Transitions from Count (bit 8)
        else if (state[8]) begin
            if (done_counting) Wait_next = 1'b1;
            else                Count_next = 1'b1;
        end
        // Transitions from Wait (bit 9)
        else if (state[9]) begin
            if (ack) S_next = 1'b1;
            else     Wait_next = 1'b1;
        end
    end

    // Re-calculating the specific required next-state logic based on the combinational logic derivation
    // S_next: (state[0] & ~d) | (state[1] & ~d) | (state[3] & ~d) | (state[9] & ack)
    // S1_next: (state[0] & d)
    // B3_next: (state[6])
    // Count_next: (state[7]) | (state[8] & ~done_counting)
    // Wait_next: (state[8] & done_counting) | (state[9] & ~ack)

    always @(*) begin
        S_next      = (state[0] & ~d) | (state[1] & ~d) | (state[3] & ~d) | (state[9] & ack);
        S1_next     = (state[0] & d);
        B3_next     = state[6];
        Count_next  = state[7] | (state[8] & ~done_counting);
        Wait_next   = (state[8] & done_counting) | (state[9] & ~ack);
    end

    // Moore outputs (based on current state)
    // done: output logic (Wait state is bit 9)
    // counting: output logic (Count state is bit 8)
    // shift_ena: output logic (B0, B1, B2, B3 are bits 4, 5, 6, 7)

    assign done      = state[9];
    assign counting  = state[8];
    assign shift_ena = state[4] | state[5] | state[6] | state[7];

endmodule