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

    // State definitions
    localparam STATE_WALK_L  = 3'd0;
    localparam STATE_WALK_R  = 3'd1;
    localparam STATE_FALL    = 3'd2;
    localparam STATE_DIG     = 3'd3;
    localparam STATE_SPLAT   = 3'd4;

    logic [2:0] state;
    logic dir; // 0 for Left, 1 for Right
    logic [7:0] fall_timer;

    // Initialize signals to avoid X
    initial begin
        state = STATE_WALK_L;
        dir = 1'b0;
        fall_timer = 8'd0;
    end

    // Sequential logic
    always @(posedge clk or posedge areset) begin
        if (areset) begin
            state <= STATE_WALK_L;
            dir <= 1'b0;
            fall_timer <= 8'd0;
        end else begin
            case (state)
                STATE_WALK_L:
                    if (!ground) begin
                        state <= STATE_FALL;
                        fall_timer <= 8'd1;
                    end else if (dig) begin
                        state <= STATE_DIG;
                    end else if (bump_left || bump_right) begin
                        dir <= 1'b1;
                        state <= STATE_WALK_R;
                    end else begin
                        state <= STATE_WALK_L;
                    end

                STATE_WALK_R:
                    if (!ground) begin
                        state <= STATE_FALL;
                        fall_timer <= 8'd1;
                    end else if (dig) begin
                        state <= STATE_DIG;
                    end else if (bump_left || bump_right) begin
                        dir <= 1'b0;
                        state <= STATE_WALK_L;
                    end else begin
                        state <= STATE_WALK_R;
                    end

                STATE_FALL:
                    if (!ground) begin
                        fall_timer <= fall_timer + 8'd1;
                    end else begin
                        // Ground reappears
                        if (fall_timer > 8'd20) begin
                            state <= STATE_SPLAT;
                        end else if (dig) begin
                            state <= STATE_DIG;
                        end else begin
                            if (dir == 1'b0) state <= STATE_WALK_L;
                            else state <= STATE_WALK_R;
                        end
                        fall_timer <= 8'd0;
                    end

                STATE_DIG:
                    if (!ground) begin
                        state <= STATE_FALL;
                        fall_timer <= 8'd1;
                    end else begin
                        state <= STATE_DIG;
                    end

                STATE_SPLAT:
                    state <= STATE_SPLAT;

                default:
                    state <= STATE_WALK_L;
            endcase
        end
    end

    // Combinational output logic (Moore machine)
    always @(*) begin
        walk_left = 1'b0;
        walk_right = 1'b0;
        aaah = 1'b0;
        digging = 1'b0;

        if (state != STATE_SPLAT) begin
            case (state)
                STATE_WALK_L:
                    walk_left = 1'b1;
                STATE_WALK_R:
                    walk_right = 1'b1;
                STATE_FALL:
                    aaah = 1'b1;
                STATE_DIG:
                    digging = 1'b1;
            endcase
        end else begin
            // In SPLAT state, all outputs are 0
            walk_left = 1'b0;
            walk_right = 1'b0;
            aaah = 1'b0;
            digging = 1'b0;
        end
    end

endmodule