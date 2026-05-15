module TopModule ( // Interface matching TopModule_if
    input  logic clk,
    input  logic reset,
    input  logic [7:0] in,
    output logic done
);

    // State Definition (3 bytes received requires 4 states minimum: Wait, Byte1, Byte2, DonePulse)
    typedef enum logic [1:0] 
    {
        S_WAIT,      // Waiting for the first byte (in[3] == 1)
        S_BYTE1_RECEIVED,
        S_BYTE2_RECEIVED,
        S_DONE_PULSE // State to hold 'done' high for one cycle after Byte 3
    }
    state_t;

    // State Registers and Next State Logic
    state_t state, state_next;

    // Initialize state to a known value
    initial begin
        state = S_WAIT;
    end

    // Sequential Logic: State Register Update
    always @(posedge clk)
    begin
        if (reset)
            state <= S_WAIT;
        else
            state <= state_next;
    end

    // Combinational Logic: Next State Logic
    always @(*)
    begin
        state_next = state;

        case (state)
            S_WAIT:
                // Look for the start byte: in[3] == 1
                if (in[3] == 1)
                    state_next = S_BYTE1_RECEIVED;
                else
                    state_next = S_WAIT;

            S_BYTE1_RECEIVED:
                // Byte 1 received. Move to waiting for Byte 2
                state_next = S_BYTE2_RECEIVED;

            S_BYTE2_RECEIVED:
                // Byte 2 received. Move to the pulse state to signal done after Byte 3
                state_next = S_DONE_PULSE;

            S_DONE_PULSE:
                // Message complete, transition back to waiting for a new message start
                state_next = S_WAIT;

            default: state_next = S_WAIT;
        endcase
    end

    // Combinational Logic: Output Logic
    always @(*)
    begin
        done = 1'b0;
        // Signal done in the cycle immediately after the third byte was received
        if (state == S_DONE_PULSE)
            done = 1'b1;
    end

endmodule