module TopModule(
    input  logic clk,
    input  logic areset,
    input  logic bump_left,
    input  logic bump_right,
    output logic walk_left,
    output logic walk_right
);

    // State definitions
    localparam STATE_WALK_LEFT  = 1'b0;
    localparam STATE_WALK_RIGHT = 1'b1;

    // State register
    logic current_state;
    logic next_state;

    // Sequential logic: State transition with asynchronous reset
    always @(posedge clk or posedge areset) begin
        if (areset) begin
            current_state <= STATE_WALK_LEFT;
        end else begin
            current_state <= next_state;
        end
    end

    // Combinational logic: Next state logic
    always @(*) begin
        next_state = current_state;
        case (current_state) 
            STATE_WALK_LEFT: begin
                // If bumped on left OR bumped on right, switch to right
                if (bump_left || bump_right) begin
                    next_state = STATE_WALK_RIGHT;
                end else begin
                    next_state = STATE_WALK_LEFT;
                end
            end
            STATE_WALK_RIGHT: begin
                // If bumped on left OR bumped on right, switch to left
                if (bump_left || bump_right) begin
                    next_state = STATE_WALK_LEFT;
                end else begin
                    next_state = STATE_WALK_RIGHT;
                end
            end
            default: begin
                next_state = STATE_WALK_LEFT;
            end
        endcase
    end

    // Combinational logic: Moore outputs
    always @(*) begin
        walk_left  = 1'b0;
        walk_right = 1'b0;
        case (current_state) 
            STATE_WALK_LEFT: begin
                walk_left  = 1'b1;
                walk_right = 1'b0;
            end
            STATE_WALK_RIGHT: begin
                walk_left  = 1'b0;
                walk_right = 1'b1;
            end
            default: begin
                walk_left  = 1'b1;
                walk_right = 1'b0;
            end
        endcase
    end

endmodule