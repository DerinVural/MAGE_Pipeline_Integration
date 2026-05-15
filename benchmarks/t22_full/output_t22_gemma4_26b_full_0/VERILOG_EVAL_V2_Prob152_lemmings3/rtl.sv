module TopModule(
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

    // State definitions
    localparam STATE_WALK_L      = 4'd0;
    localparam STATE_WALK_R      = 4'd1;
    localparam STATE_DIG_L      = 4'd2;
    localparam STATE_DIG_R      = 4'd3;
    localparam STATE_FALL_L     = 4'd4;
    localparam STATE_FALL_R     = 4'd5;
    localparam STATE_FALL_DIG_L = 4'd6;
    localparam STATE_FALL_DIG_R = 4'd7;

    logic [3:0] state;

    // Initialize state to avoid X
    initial begin
        state = STATE_WALK_L;
    end

    // Sequential logic
    always @(posedge clk or posedge areset) begin
        if (areset) begin
            state <= STATE_WALK_L;
        end else begin
            case (state)
                STATE_WALK_L:
                    if (!ground) 
                        state <= STATE_FALL_L;
                    else if (dig) 
                        state <= STATE_DIG_L;
                    else if (bump_left || bump_right) begin
                        if (bump_left && bump_right) 
                            state <= STATE_WALK_R;
                        else if (bump_left) 
                            state <= STATE_WALK_R;
                        else // bump_right
                            state <= STATE_WALK_L;
                        // Wait, the spec: bump_left -> walk right. bump_right -> walk left.
                        // If both: 'it will still switch directions'.
                        // If was L, switch to R. If was R, switch to L.
                        // Let's re-read: 'If it's bumped on the left... it will walk right. If it's bumped on the right... it will walk left. 
                        // If it's bumped on both sides... it will still switch directions.'
                        // This means if state is WALK_L, bump_left -> WALK_R, bump_right -> WALK_L, both -> WALK_R (switch).
                        // Actually, if bump_left is 1, it's Right. If bump_right is 1, it's Left. 
                        // If both are 1, it 'switches'. If it was L, it becomes R. If it was R, it becomes L.
                        // Let's implement: 
                        // if (bump_left && bump_right) state <= (state == STATE_WALK_L) ? STATE_WALK_R : STATE_WALK_L;
                        // else if (bump_left) state <= STATE_WALK_R;
                        // else if (bump_right) state <= STATE_WALK_L;
                    end
                // Let's rewrite the logic more carefully.
            endcase
        end
    end

    // Re-implementing logic based on strict precedence: 
    // 1. Fall (ground=0) 
    // 2. Dig (dig=1) 
    // 3. Switch direction (bumps)

    always @(posedge clk or posedge areset) begin
        if (areset) begin
            state <= STATE_WALK_L;
        end else begin
            case (state)
                STATE_WALK_L:
                    if (!ground) 
                        state <= STATE_FALL_L;
                    else if (dig) 
                        state <= STATE_DIG_L;
                    else if (bump_left || bump_right) begin
                        if (bump_left && bump_right) 
                            state <= STATE_WALK_R; // Switch from L to R
                        else if (bump_left) 
                            state <= STATE_WALK_R; // Bump left -> walk right
                        else 
                            state <= STATE_WALK_L; // Bump right -> walk left
                    end

                STATE_WALK_R:
                    if (!ground) 
                        state <= STATE_FALL_R;
                    else if (dig) 
                        state <= STATE_DIG_R;
                    else if (bump_left || bump_right) begin
                        if (bump_left && bump_right) 
                            state <= STATE_WALK_L; // Switch from R to L
                        else if (bump_left) 
                            state <= STATE_WALK_R; // Bump left -> walk right
                        else 
                            state <= STATE_WALK_L; // Bump right -> walk left
                    end

                STATE_DIG_L:
                    if (!ground) 
                        state <= STATE_FALL_DIG_L;
                    // else stay in DIG_L

                STATE_DIG_R:
                    if (!ground) 
                        state <= STATE_FALL_DIG_R;
                    // else stay in DIG_R

                STATE_FALL_L:
                    if (ground) 
                        state <= STATE_WALK_L;
                    // else stay in FALL_L

                STATE_FALL_R:
                    if (ground) 
                        state <= STATE_WALK_R;
                    // else stay in FALL_R

                STATE_FALL_DIG_L:
                    if (ground) 
                        state <= STATE_WALK_L;
                    // else stay in FALL_DIG_L

                STATE_FALL_DIG_R:
                    if (ground) 
                        state <= STATE_WALK_R;
                    // else stay in FALL_DIG_R

                default: state <= STATE_WALK_L;
            endcase
        end
    end

    // Moore Outputs
    always @(*) begin
        walk_left  = 1'b0;
        walk_right = 1'b0;
        aaah       = 1'b0;
        digging    = 1'b0;

        case (state)
            STATE_WALK_L:      walk_left  = 1'b1;
            STATE_WALK_R:      walk_right = 1'b1;
            STATE_DIG_L:       digging    = 1'b1;
            STATE_DIG_R:       digging    = 1'b1;
            STATE_FALL_L:      aaah       = 1'b1;
            STATE_FALL_R:      aaah       = 1'b1;
            STATE_FALL_DIG_L:  aaah       = 1'b1;
            STATE_FALL_DIG_R:  aaah       = 1'b1;
            default: ;
        endcase
    end

endmodule