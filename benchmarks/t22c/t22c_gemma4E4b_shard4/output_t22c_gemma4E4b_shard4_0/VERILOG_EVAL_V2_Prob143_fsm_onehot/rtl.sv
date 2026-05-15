module TopModule (
    input  logic in,
    input  logic [9:0] state,
    output logic [9:0] next_state,
    output logic out1,
    output logic out2
);

    // ----------------------------------------------------------------
    // 1. Next State Logic Implementation
    // next_state[j] is 1 if the machine transitions to Sj.
    // ----------------------------------------------------------------
    always @* begin
        next_state = 10'b0;

        // S0 (state[0]): (0, 0) --0--> S0; (0, 0) --1--> S1
        if (state[0]) begin
            if (in == 0) next_state[0] = 1;
            if (in == 1) next_state[1] = 1;
        end

        // S1 (state[1]): (0, 0) --0--> S0; (0, 0) --1--> S2
        if (state[1]) begin
            if (in == 0) next_state[0] = 1;
            if (in == 1) next_state[2] = 1;
        end

        // S2 (state[2]): (0, 0) --0--> S0; (0, 0) --1--> S3
        if (state[2]) begin
            if (in == 0) next_state[0] = 1;
            if (in == 1) next_state[3] = 1;
        end

        // S3 (state[3]): (0, 0) --0--> S0; (0, 0) --1--> S4
        if (state[3]) begin
            if (in == 0) next_state[0] = 1;
            if (in == 1) next_state[4] = 1;
        end

        // S4 (state[4]): (0, 0) --0--> S0; (0, 0) --1--> S5
        if (state[4]) begin
            if (in == 0) next_state[0] = 1;
            if (in == 1) next_state[5] = 1;
        end

        // S5 (state[5]): (0, 0) --0--> S8; (0, 0) --1--> S6
        if (state[5]) begin
            if (in == 0) next_state[8] = 1;
            if (in == 1) next_state[6] = 1;
        end

        // S6 (state[6]): (0, 0) --0--> S9; (0, 0) --1--> S7
        if (state[6]) begin
            if (in == 0) next_state[9] = 1;
            if (in == 1) next_state[7] = 1;
        end

        // S7 (state[7]): (0, 1) --0--> S0; (0, 1) --1--> S7
        if (state[7]) begin
            if (in == 0) next_state[0] = 1;
            if (in == 1) next_state[7] = 1;
        end

        // S8 (state[8]): (1, 0) --0--> S0; (1, 0) --1--> S1
        if (state[8]) begin
            if (in == 0) next_state[0] = 1;
            if (in == 1) next_state[1] = 1;
        end

        // S9 (state[9]): (1, 1) --0--> S0; (1, 1) --1--> S1
        if (state[9]) begin
            if (in == 0) next_state[0] = 1;
            if (in == 1) next_state[1] = 1;
        end
    end

    // ----------------------------------------------------------------
    // 2. Output Logic Implementation (Combinational)
    // Outputs are ORed if multiple states are active.
    // ----------------------------------------------------------------
    always @* begin
        // Default outputs are 0
        out1 = 1'b0;
        out2 = 1'b0;

        // S0 (0, 0)
        if (state[0]) begin
            out1 = out1 | 1'b0;
            out2 = out2 | 1'b0;
        end

        // S1 (0, 0)
        if (state[1]) begin
            out1 = out1 | 1'b0;
            out2 = out2 | 1'b0;
        end

        // S2 (0, 0)
        if (state[2]) begin
            out1 = out1 | 1'b0;
            out2 = out2 | 1'b0;
        end

        // S3 (0, 0)
        if (state[3]) begin
            out1 = out1 | 1'b0;
            out2 = out2 | 1'b0;
        end

        // S4 (0, 0)
        if (state[4]) begin
            out1 = out1 | 1'b0;
            out2 = out2 | 1'b0;
        end

        // S5 (0, 0)
        if (state[5]) begin
            out1 = out1 | 1'b0;
            out2 = out2 | 1'b0;
        end

        // S6 (0, 0)
        if (state[6]) begin
            out1 = out1 | 1'b0;
            out2 = out2 | 1'b0;
        end

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