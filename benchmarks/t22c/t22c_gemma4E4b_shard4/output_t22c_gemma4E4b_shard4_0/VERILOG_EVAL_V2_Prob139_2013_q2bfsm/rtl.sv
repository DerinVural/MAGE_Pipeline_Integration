module TopModule (
    input  logic clk,
    input  logic resetn,
    input  logic x,
    input  logic y,
    output logic f,
    output logic g
);

    // --- State Definitions (Using integer mapping) ---
    localparam STATE_A         = 4'b0000; // Initial state / Reset
    localparam STATE_B         = 4'b0001; // F=1 pulse cycle
    localparam STATE_X1        = 4'b0010; // Saw x=1 (Start sequence)
    localparam STATE_X0        = 4'b0011; // Saw x=0 (after x=1)
    localparam STATE_X1_Done   = 4'b0100; // Saw x=1, 0, 1. G=1 next cycle.
    localparam STATE_Y_WAIT_1  = 4'b0101; // G=1, waiting for y=1 (Cycle 1)
    localparam STATE_Y_WAIT_2  = 4'b0110; // G=1, waiting for y=1 (Cycle 2)
    localparam STATE_Y_PERM_HIGH = 4'b0111; // G=1 permanently
    localparam STATE_Y_PERM_LOW  = 4'b1000; // G=0 permanently

    // --- Registers ---
    logic [3:0] state_reg;
    logic [3:0] state_next;

    // Initialize state register to the reset state (STATE_A)
    initial begin
        state_reg = STATE_A;
    end

    // --- Sequential Logic (State Register) ---
    always @(posedge clk)
    begin
        if (!resetn) begin
            state_reg <= STATE_A;
        end else begin
            state_reg <= state_next;
        end
    end

    // --- Combinational Logic (Next State Logic) ---
    always @(*)
    begin
        state_next = state_reg;

        case (state_reg)
            STATE_A: begin
                if (resetn) begin
                    // Transition to F pulse state upon reset de-assertion
                    state_next = STATE_B;
                end
            end

            STATE_B: begin
                // F pulse done, start monitoring X sequence
                state_next = STATE_X1; 
            end

            STATE_X1: begin // Last seen x=1
                if (x == 1'b1) begin
                    state_next = STATE_X1; // 1 -> 1
                end else begin // x=0
                    state_next = STATE_X0; // 1 -> 0
                end
            end

            STATE_X0: begin // Last seen x=0
                if (x == 1'b1) begin
                    // Sequence 1, 0, 1 complete. G=1 on next cycle.
                    state_next = STATE_X1_Done;
                end else begin // x=0
                    // Sequence broken. Restart sequence check, last seen x=0
                    state_next = STATE_X0;
                end
            end

            STATE_X1_Done: begin
                // X sequence complete. G=1 next cycle. Start monitoring Y.
                state_next = STATE_Y_WAIT_1;
            end

            STATE_Y_WAIT_1: begin // G=1 active. Cycle 1 of 2.
                if (y == 1'b1) begin
                    state_next = STATE_Y_PERM_HIGH; // Y found early
                end else begin
                    state_next = STATE_Y_WAIT_2; // Continue waiting
                end
            end

            STATE_Y_WAIT_2: begin // G=1 active. Cycle 2 of 2.
                if (y == 1'b1) begin
                    state_next = STATE_Y_PERM_HIGH; // Y found within 2 cycles
                end else begin
                    state_next = STATE_Y_PERM_LOW; // Y not found within 2 cycles
                end
            end

            STATE_Y_PERM_HIGH: begin
                state_next = STATE_Y_PERM_HIGH; // Stay high
            end

            STATE_Y_PERM_LOW: begin
                state_next = STATE_Y_PERM_LOW; // Stay low
            end

            default: begin
                state_next = STATE_A; // Safety default
            end
        endcase
    end

    // --- Output Logic ---
    // f is high only for one cycle after reset de-assertion
    assign f = (state_reg == STATE_B) ? 1'b1 : 1'b0;

    // g is high during the X_Done state transition (next cycle), and while in Y_WAIT_1/2 or Y_PERM_HIGH
    assign g = (state_reg == STATE_X1_Done) || 
                 (state_reg == STATE_Y_WAIT_1) || 
                 (state_reg == STATE_Y_WAIT_2) || 
                 (state_reg == STATE_Y_PERM_HIGH) ? 1'b1 : 1'b0;

endmodule