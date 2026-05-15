module TopModule (
    input  logic d,
    input  logic done_counting,
    input  logic ack,
    input  logic [9:0] state, // Current state is provided externally
    output logic B3_next,
    output logic S_next,
    output logic S1_next,
    output logic Count_next,
    output logic Wait_next,
    output logic done,
    output logic counting,
    output logic shift_ena
);

    // Define states using the specified one-hot encoding structure.
    // Using the derived assignments based on the prompt's requirements.
    localparam STATE_S    = 10'b0000000001;
    localparam STATE_S1   = 10'b0000000010;
    localparam STATE_S11  = 10'b0000000100;
    localparam STATE_S110 = 10'b0000001000;
    localparam STATE_B0   = 10'b0001000000;
    localparam STATE_B1   = 10'b0010000000;
    localparam STATE_B2   = 10'b0100000000;
    localparam STATE_B3   = 10'b1000000000;
    localparam STATE_COUNT = 10'b0110000000;
    localparam STATE_WAIT = 10'b1000000001;

    // Wires to hold the calculated next state and outputs
    logic [9:0] state_next;
    
    // --- Combinational Logic: Next State Derivation ---
    always @(*)
    begin
        state_next = state; // Default: stay in current state

        case (state)
            STATE_S:
                if (d == 0) state_next = STATE_S;
                else state_next = STATE_S1;

            STATE_S1:
                if (d == 0) state_next = STATE_S;
                else state_next = STATE_S11;

            STATE_S11:
                if (d == 0) state_next = STATE_S110;
                else state_next = STATE_S11;

            STATE_S110:
                if (d == 0) state_next = STATE_S;
                else state_next = STATE_B0;

            STATE_B0:
                state_next = STATE_B1; // Always go to next cycle

            STATE_B1:
                state_next = STATE_B2; // Always go to next cycle

            STATE_B2:
                state_next = STATE_B3; // Always go to next cycle

            STATE_B3:
                state_next = STATE_COUNT; // Always go to next cycle

            STATE_COUNT:
                if (done_counting == 0) state_next = STATE_COUNT;
                else state_next = STATE_WAIT;

            STATE_WAIT:
                if (ack == 0) state_next = STATE_WAIT;
                else state_next = STATE_S;

            default: state_next = STATE_S; // Safety catch
        endcase
    end

    // --- Combinational Logic: Output Derivation (Moore Machine) ---
    always @(*)
    begin
        // Default assignments (Outputs are 0 unless specified)
        B3_next = 1'b0;
        S_next = 1'b0;
        S1_next = 1'b0;
        Count_next = 1'b0;
        Wait_next = 1'b0;
        done = 1'b0;
        counting = 1'b0;
        shift_ena = 1'b0;

        // 1. Next State Assertions (Which state we are moving to)
        if (state_next == STATE_B3) B3_next = 1'b1;
        if (state_next == STATE_S) S_next = 1'b1;
        if (state_next == STATE_S1) S1_next = 1'b1;
        if (state_next == STATE_COUNT) Count_next = 1'b1;
        if (state_next == STATE_WAIT) Wait_next = 1'b1;

        // 2. Current State Outputs (Moore Machine)
        if (state == STATE_B0 || state == STATE_B1 || state == STATE_B2 || state == STATE_B3)
            shift_ena = 1'b1;

        if (state == STATE_COUNT)
            counting = 1'b1;

        if (state == STATE_WAIT)
            done = 1'b1;

    end

endmodule