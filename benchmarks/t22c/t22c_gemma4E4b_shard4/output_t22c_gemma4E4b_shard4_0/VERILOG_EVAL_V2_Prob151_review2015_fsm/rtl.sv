module TopModule (
    input  logic clk,
    input  logic reset,
    input  logic data,
    input  logic done_counting,
    input  logic ack,
    output logic shift_ena,
    output logic counting,
    output logic done
);

    // State Encoding (Need enough states for pattern matching + operational phases)
    localparam STATE_IDLE       = 3'b000;
    localparam STATE_DETECT_1   = 3'b001;
    localparam STATE_DETECT_11  = 3'b010;
    localparam STATE_DETECT_110 = 3'b011;
    localparam STATE_SHIFT_IN   = 3'b100; // 4 cycles of shift_ena
    localparam STATE_COUNTING   = 3'b101;
    localparam STATE_DONE_WAIT  = 3'b110;
    localparam STATE_RESET_WAIT = 3'b111; // Acknowledgment received

    // State Registers
    logic [2:0] state;
    logic [2:0] state_next;

    // Helper counter for the 4-cycle shift sequence
    logic [1:0] shift_count;

    // Outputs
    assign shift_ena = (state == STATE_SHIFT_IN);
    assign counting = (state == STATE_COUNTING);
    assign done = (state == STATE_DONE_WAIT);

    // State Register Logic (Sequential)
    always @(posedge clk)
    begin
        if (reset)
            state <= STATE_IDLE;
        else
            state <= state_next;
    end

    // Shift Counter Register Logic (Sequential, only relevant in STATE_SHIFT_IN)
    always @(posedge clk)
    begin
        if (state == STATE_SHIFT_IN && shift_count < 2'b11) // Count 0, 1, 2, 3 (4 cycles)
            shift_count <= shift_count + 1'b1;
        else if (state != STATE_SHIFT_IN) 
            shift_count <= 2'b00; // Reset counter when not in shift state
    end

    // Next State Logic (Combinational)
    always @(*)
    begin
        state_next = state;

        case (state)
            STATE_IDLE:
                // Start detection on '1'
                if (data == 1'b1) 
                    state_next = STATE_DETECT_1;
                else
                    state_next = STATE_IDLE;

            STATE_DETECT_1:
                // Need '1' next
                if (data == 1'b1) 
                    state_next = STATE_DETECT_11;
                else
                    state_next = STATE_IDLE; // Pattern broken

            STATE_DETECT_11:
                // Need '0' next
                if (data == 1'b0) 
                    state_next = STATE_DETECT_110;
                else
                    state_next = STATE_DETECT_1; // Stuck on '1'

            STATE_DETECT_110:
                // Need '1' to complete '1101'
                if (data == 1'b1) 
                    state_next = STATE_SHIFT_IN; // Pattern detected
                else
                    state_next = STATE_IDLE; // Pattern broken

            STATE_SHIFT_IN:
                // Must count for exactly 4 cycles
                if (shift_count == 2'b11) 
                    state_next = STATE_COUNTING;
                else
                    state_next = STATE_SHIFT_IN;

            STATE_COUNTING:
                // Wait for done_counting signal
                if (done_counting == 1'b1) 
                    state_next = STATE_DONE_WAIT;
                else
                    state_next = STATE_COUNTING;

            STATE_DONE_WAIT:
                // Wait for acknowledgement
                if (ack == 1'b1) 
                    state_next = STATE_RESET_WAIT;
                else
                    state_next = STATE_DONE_WAIT;

            STATE_RESET_WAIT:
                // Acknowledgment received, return to search state
                state_next = STATE_IDLE;

            default: 
                state_next = STATE_IDLE;
        endcase
    end

    // Initialization of state register (Requirement 3)
    initial begin
        state = STATE_IDLE;
        shift_count = 2'b00;
    end

endmodule