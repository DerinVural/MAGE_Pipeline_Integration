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

    // State encoding
    localparam STATE_WALK_L    = 4'd0;
    localparam STATE_WALK_R    = 4'd1;
    localparam STATE_FALL_L    = 4'd2;
    localparam STATE_FALL_R    = 4'd3;
    localparam STATE_DIG_L     = 4'd4;
    localparam STATE_DIG_R     = 4'd5;
    localparam STATE_SPLAT     = 4'd6;

    logic [3:0] state;
    logic [7:0] fall_counter;

    // Sequential logic for state and counter
    always @(posedge clk or posedge areset) begin
        if (areset) begin
            state <= STATE_WALK_L;
            fall_counter <= 8'd0;
        end else begin
            case (state)
                STATE_WALK_L:
                    if (!ground) begin
                        state <= STATE_FALL_L;
                        fall_counter <= 8'd1;
                    end else if (dig) begin
                        state <= STATE_DIG_L;
                    end else if (bump_left) begin
                        state <= STATE_WALK_R;
                    end else if (bump_right) begin
                        state <= STATE_WALK_L;
                    end else begin
                        state <= STATE_WALK_L;
                    end

                STATE_WALK_R:
                    if (!ground) begin
                        state <= STATE_FALL_R;
                        fall_counter <= 8'd1;
                    end else if (dig) begin
                        state <= STATE_DIG_R;
                    end else if (bump_left) begin
                        state <= STATE_WALK_R;
                    end else if (bump_right) begin
                        state <= STATE_WALK_L;
                    end else begin
                        state <= STATE_WALK_R;
                    end

                STATE_FALL_L,
                STATE_FALL_R:
                    if (ground) begin
                        if (fall_counter > 8'd20) begin
                            state <= STATE_SPLAT;
                        end else begin
                            state <= (state == STATE_FALL_L) ? STATE_WALK_L : STATE_WALK_R;
                        end
                        fall_counter <= 8'd0;
                    end else begin
                        fall_counter <= fall_counter + 8'd1;
                    end

                STATE_DIG_L,
                STATE_DIG_R:
                    if (!ground) begin
                        state <= (state == STATE_DIG_L) ? STATE_FALL_L : STATE_FALL_R;
                        fall_counter <= 8'd1;
                    end else begin
                        state <= state;
                    end

                STATE_SPLAT:
                    state <= STATE_SPLAT;

                default:
                    state <= STATE_WALK_L;
            endcase
        end
    end

    // Output logic (Moore machine)
    always @(*) begin
        walk_left = 1'b0;
        walk_right = 1'b0;
        aaah = 1'b0;
        digging = 1'b0;

        case (state) 
            STATE_WALK_L: walk_left = 1'b1;
            STATE_WALK_R: walk_right = 1'b1;
            STATE_FALL_L, STATE_FALL_R: aaah = 1'b1;
            STATE_DIG_L, STATE_DIG_R:  digging = 1'b1;
            STATE_SPLAT: ;
            default: ;
        endcase
    end

    // Refinement for Digging output: 
    // The spec says "continue digging until it reaches the other side (ground=0). At that point... it will fall".
    // My state machine handles the transition. 
    // However, the output 'digging' is 1 during the DIG states.
    // Also, if the Lemming is in STATE_WALK but dig=1, it's not digging yet, it's walking. 
    // Digging output is specifically for the 'digging' action.
    // Wait, the prompt says: "A Lemming can dig if it is currently walking on ground... and will continue digging until ground=0".
    // So digging is an active state.

endmodule