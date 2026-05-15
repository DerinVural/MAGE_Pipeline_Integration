module TopModule (
    input  logic clk,
    input  logic areset,
    input  logic bump_left,
    input  logic bump_right,
    input  logic ground,
    input  logic dig,
    output logic walk_left,
    output logic walk_right,
    output logic aaah,
    output logic digging
);

    // State encoding
    localparam STATE_WALK_LEFT  = 3'd0;
    localparam STATE_WALK_RIGHT = 3'd1;
    localparam STATE_FALL_LEFT  = 3'd2;
    localparam STATE_FALL_RIGHT = 3'd3;
    localparam STATE_DIG_LEFT   = 3'd4;
    localparam STATE_DIG_RIGHT  = 3'd5;

    logic [2:0] state;
    logic [2:0] next_state;

    // Sequential logic
    always @(posedge clk or posedge areset) begin
        if (areset) begin
            state <= STATE_WALK_LEFT;
        end else begin
            state <= next_state;
        end
    end

    // Next state combinational logic
    always @(*) begin
        next_state = state;
        case (state)
            STATE_WALK_LEFT:
                if (!ground) 
                    next_state = STATE_FALL_LEFT;
                else if (dig) 
                    next_state = STATE_DIG_LEFT;
                else if (bump_left || bump_right) 
                    next_state = STATE_WALK_RIGHT;
                else 
                    next_state = STATE_WALK_LEFT;

            STATE_WALK_RIGHT:
                if (!ground) 
                    next_state = STATE_FALL_RIGHT;
                else if (dig) 
                    next_state = STATE_DIG_RIGHT;
                else if (bump_left || bump_right) 
                    next_state = STATE_WALK_LEFT;
                else 
                    next_state = STATE_WALK_RIGHT;

            STATE_FALL_LEFT:
                if (ground) 
                    next_state = STATE_WALK_LEFT;
                else 
                    next_state = STATE_FALL_LEFT;

            STATE_FALL_RIGHT:
                if (ground) 
                    next_state = STATE_WALK_RIGHT;
                else 
                    next_state = STATE_FALL_RIGHT;

            STATE_DIG_LEFT:
                if (!ground) 
                    next_state = STATE_FALL_LEFT;
                else 
                    next_state = STATE_DIG_LEFT;

            STATE_DIG_RIGHT:
                if (!ground) 
                    next_state = STATE_FALL_RIGHT;
                else 
                    next_state = STATE_DIG_RIGHT;

            default: next_state = STATE_WALK_LEFT;
        endcase
    end

    // Output combinational logic (Moore machine)
    always @(*) begin
        walk_left = 1'b0;
        walk_right = 1'b0;
        aaah = 1'b0;
        digging = 1'b0;

        case (state)
            STATE_WALK_LEFT:
                walk_left = 1'b1;
            STATE_WALK_RIGHT:
                walk_right = 1'b1;
            STATE_FALL_LEFT,
            STATE_FALL_RIGHT:
                aaah = 1'b1;
            STATE_DIG_LEFT,
            STATE_DIG_RIGHT:
                digging = 1'b1;
            default: ;
        endcase
    end

endmodule