module TopModule(
    input  logic       in,
    input  logic [9:0] state,
    output logic [9:0] next_state,
    output logic       out1,
    output logic       out2
);

    // Combinational logic for next_state
    // next_state[i] is 1 if any active state transitions to state i
    always @(*) begin
        next_state = 10'b0;

        // S0 transitions
        if (state[0]) begin
            if (in) next_state[1] = 1'b1;
            else     next_state[0] = 1'b1;
        end
        // S1 transitions
        if (state[1]) begin
            if (in) next_state[2] = 1'b1;
            else     next_state[0] = 1'b1;
        end
        // S2 transitions
        if (state[2]) begin
            if (in) next_state[3] = 1'b1;
            else     next_state[0] = 1'b1;
        end
        // S3 transitions
        if (state[3]) begin
            if (in) next_state[4] = 1'b1;
            else     next_state[0] = 1'b1;
        end
        // S4 transitions
        if (state[4]) begin
            if (in) next_state[5] = 1'b1;
            else     next_state[0] = 1'b1;
        end
        // S5 transitions
        if (state[5]) begin
            if (in) next_state[6] = 1'b1;
            else     next_state[8] = 1'b1;
        end
        // S6 transitions
        if (state[6]) begin
            if (in) next_state[7] = 1'b1;
            else     next_state[9] = 1'b1;
        end
        // S7 transitions
        if (state[7]) begin
            if (in) next_state[7] = 1'b1;
            else     next_state[0] = 1'b1;
        end
        // S8 transitions
        if (state[8]) begin
            if (in) next_state[1] = 1'b1;
            else     next_state[0] = 1'b1;
        end
        // S9 transitions
        if (state[9]) begin
            if (in) next_state[1] = 1'b1;
            else     next_state[0] = 1'b1;
        end
    end

    // Combinational logic for outputs
    // If multiple states are active, the outputs are the OR of the outputs of each active state
    always @(*) begin
        out1 = 1'b0;
        out2 = 1'b0;

        // S7 (0, 1)
        if (state[7]) begin
            out1 = out1 | 1'b0;
            out2 = out2 | 1'b1;
        end
        // S8 (1, 0)
        if (state[8]) begin
            out1 = out1 | 1'b1;
            out2 = out2 | 1'b0;
        end
        // S9 (1, 1)
        if (state[9]) begin
            out1 = out1 | 1'b1;
            out2 = out2 | 1'b1;
        end
    end

endmodule