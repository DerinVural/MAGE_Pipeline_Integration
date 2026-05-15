module TopModule (
    input  logic clk,
    input  logic areset,
    input  logic bump_left,
    input  logic bump_right,
    input  logic ground,
    output logic walk_left,
    output logic walk_right,
    output logic aaah
);

    // State Encoding (4 states required to track direction during fall)
    typedef enum logic [1:0] {
        STATE_L_WALK, // Walking Left
        STATE_R_WALK, // Walking Right
        STATE_L_FALL, // Falling, last direction was Left
        STATE_R_FALL  // Falling, last direction was Right
    } state_t;

    // State Registers
    state_t current_state, next_state;

    // --- Sequential Logic (State Register) ---
    // Asynchronous reset on areset positive edge
    always @(posedge clk or posedge areset) begin
        if (areset) begin
            current_state <= STATE_L_WALK; // Reset to walk left
        end else begin
            current_state <= next_state;
        end
    end

    // --- Combinational Logic (Next State Decoder) ---
    always @* begin
        next_state = current_state;

        case (current_state) 
            STATE_L_WALK:
                if (ground == 1'b0) begin
                    // Start falling
                    next_state = STATE_L_FALL;
                end else begin
                    // Ground is present (walking)
                    if (bump_left) begin
                        // Bump left -> switch to right
                        next_state = STATE_R_WALK;
                    end else if (bump_right) begin
                        // Bump right -> switch to left
                        next_state = STATE_L_WALK;
                    end else begin
                        // Continue walking left
                        next_state = STATE_L_WALK;
                    end
                end

            STATE_R_WALK:
                if (ground == 1'b0) begin
                    // Start falling
                    next_state = STATE_R_FALL;
                end else begin
                    // Ground is present (walking)
                    if (bump_left) begin
                        // Bump left -> switch to right
                        next_state = STATE_R_WALK;
                    end else if (bump_right) begin
                        // Bump right -> switch to left
                        next_state = STATE_L_WALK;
                    end else begin
                        // Continue walking right
                        next_state = STATE_R_WALK;
                    end
                end

            STATE_L_FALL:
                if (ground == 1'b1) begin
                    // Ground reappears, resume previous direction (Left)
                    next_state = STATE_L_WALK;
                end else begin
                    // Still falling, maintain state
                    next_state = STATE_L_FALL;
                end

            STATE_R_FALL:
                if (ground == 1'b1) begin
                    // Ground reappears, resume previous direction (Right)
                    next_state = STATE_R_WALK;
                end else begin
                    // Still falling, maintain state
                    next_state = STATE_R_FALL;
                end

            default: begin
                // Safety/Unreachable state handling
                next_state = STATE_L_WALK;
            end
        endcase
    end

    // --- Combinational Logic (Output Decoder - Moore Machine) ---
    always @* begin
        // Default assignments to ensure no latches
        walk_left = 1'b0;
        walk_right = 1'b0;
        aaah = 1'b0;

        case (current_state) 
            STATE_L_WALK:
                walk_left = 1'b1;

            STATE_R_WALK:
                walk_right = 1'b1;

            STATE_L_FALL:
                aaah = 1'b1;

            STATE_R_FALL:
                aaah = 1'b1;
        endcase
    end

endmodule