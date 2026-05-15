module TopModule (
    input logic clk,
    input logic areset,
    input logic bump_left,
    input logic bump_right,
    input logic ground,
    output logic walk_left,
    output logic walk_right,
    output logic aaah
);

    // Define states
    localparam STATE_LEFT = 0;
    localparam STATE_RIGHT = 1;

    // State and next state registers
    logic state, next_state;

    // State register with asynchronous reset
    always @(posedge clk or posedge areset) begin
        if (areset) begin
            state <= STATE_LEFT;
        end else begin
            state <= next_state;
        end
    end

    // Next state logic
    always @(*) begin
        case (state)
            STATE_LEFT: begin
                // Current state is left; check for bumps
                if (bump_left || bump_right) begin
                    // If bump on both, still toggle; else, check which
                    if (bump_left && bump_right) begin
                        next_state = STATE_RIGHT; // Both bump, switch to right
                    end else if (bump_left) begin
                        next_state = STATE_RIGHT; // Only left bump, switch right
                    end else if (bump_right) begin
                        next_state = STATE_LEFT; // Only right bump, switch left
                    end else begin
                        next_state = STATE_LEFT; // No bump, stay left
                    end
                end else begin
                    next_state = STATE_LEFT;
                end
            end
            STATE_RIGHT: begin
                // Current state is right; check for bumps
                if (bump_left || bump_right) begin
                    if (bump_left && bump_right) begin
                        next_state = STATE_LEFT; // Both bump, switch to left
                    end else if (bump_left) begin
                        next_state = STATE_LEFT; // Left bump, switch left
                    end else if (bump_right) begin
                        next_state = STATE_RIGHT; // Right bump, switch right
                    end else begin
                        next_state = STATE_RIGHT;
                    end
                end else begin
                    next_state = STATE_RIGHT;
                end
            end
            default: next_state = STATE_LEFT;
        endcase
    end

    // Combinational output logic (Moore outputs)
    always @(*) begin
        case (state)
            STATE_LEFT: begin
                walk_left = 1'b1;
                walk_right = 1'b0;
                aaah = ~ground;
            end
            STATE_RIGHT: begin
                walk_left = 1'b0;
                walk_right = 1'b1;
                aaah = ~ground;
            end
            default: begin
                walk_left = 1'b1;
                walk_right = 1'b0;
                aaah = 1'b0;
            end
        endcase
    end

endmodule
