module TopModule (
    input logic clk,
    input logic areset,
    input logic bump_left,
    input logic bump_right,
    output logic walk_left,
    output logic walk_right
);

    // State Encoding
    localparam STATE_LEFT  = 2'b00;
    localparam STATE_RIGHT = 2'b01;

    // State Register and Next State Logic
    logic [1:0] current_state;
    logic [1:0] next_state;

    // 1. Sequential Logic (State Register)
    // Asynchronous reset to STATE_LEFT
    always @(posedge clk or posedge areset) begin
        if (areset) begin
            current_state <= STATE_LEFT;
        end else begin
            current_state <= next_state;
        end
    end

    // 2. Combinational Logic: Next State Determination
    always @(*)
    begin
        next_state = current_state;

        case (current_state)
            STATE_LEFT:
                // Currently walking left
                // Bump Left -> Switch to Right
                if (bump_left) begin
                    next_state = STATE_RIGHT;
                end
                // Bump Right -> Switch to Left (Only if not already forced to Right by bump_left)
                else if (bump_right) begin
                    next_state = STATE_LEFT;
                end
                // Otherwise, stay in current state
                else begin
                    next_state = STATE_LEFT;
                end

            STATE_RIGHT:
                // Currently walking right
                // Bump Left -> Switch to Right
                if (bump_left) begin
                    next_state = STATE_RIGHT;
                end
                // Bump Right -> Switch to Left
                else if (bump_right) begin
                    next_state = STATE_LEFT;
                end
                // Otherwise, stay in current state
                else begin
                    next_state = STATE_RIGHT;
                end
        endcase
    end

    // 3. Combinational Logic: Output Generation (Moore Machine)
    // Output depends ONLY on the current state
    always @(*)
    begin
        walk_left = 1'b0;
        walk_right = 1'b0;

        case (current_state)
            STATE_LEFT:
                walk_left = 1'b1;
            STATE_RIGHT:
                walk_right = 1'b1;
        endcase
    end

endmodule