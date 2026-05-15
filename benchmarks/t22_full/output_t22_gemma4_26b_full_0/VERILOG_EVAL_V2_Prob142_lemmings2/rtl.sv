module TopModule(
    input  logic clk,
    input  logic areset,
    input  logic bump_left,
    input  logic bump_right,
    input  logic ground,
    output logic walk_left,
    output logic walk_right,
    output logic aaah
);

    // State encoding
    localparam STATE_WALK_LEFT  = 2'b00;
    localparam STATE_WALK_RIGHT = 2'b01;
    localparam STATE_FALL_LEFT  = 2'b10;
    localparam STATE_FALL_RIGHT = 2'b11;

    logic [1:0] state;
    logic [1:0] state_next;

    // Sequential logic for state transition
    always @(posedge clk or posedge areset) begin
        if (areset) begin
            state <= STATE_WALK_LEFT;
        end else begin
            state <= state_next;
        end
    end

    // Combinational logic for next state
    always @(*) begin
        state_next = state;
        case (state)
            STATE_WALK_LEFT:
                if (!ground) begin
                    state_next = STATE_FALL_LEFT;
                end else if (bump_left) begin
                    state_next = STATE_WALK_RIGHT;
                end else begin
                    state_next = STATE_WALK_LEFT;
                end

            STATE_WALK_RIGHT:
                if (!ground) begin
                    state_next = STATE_FALL_RIGHT;
                end else if (bump_right) begin
                    state_next = STATE_WALK_LEFT;
                end else begin
                    state_next = STATE_WALK_RIGHT;
                end

            STATE_FALL_LEFT:
                if (ground) begin
                    state_next = STATE_WALK_LEFT;
                end else begin
                    state_next = STATE_FALL_LEFT;
                end

            STATE_FALL_RIGHT:
                if (ground) begin
                    state_next = STATE_WALK_RIGHT;
                end else begin
                    state_next = STATE_FALL_RIGHT;
                end

            default:
                state_next = STATE_WALK_LEFT;
        endcase
    end

    // Combinational logic for Moore outputs
    always @(*) begin
        walk_left  = 1'b0;
        walk_right = 1'b0;
        aaah       = 1'b0;

        case (state)
            STATE_WALK_LEFT:
                walk_left = 1'b1;
            STATE_WALK_RIGHT:
                walk_right = 1'b1;
            STATE_FALL_LEFT,
            STATE_FALL_RIGHT:
                aaah = 1'b1;
            default:
                begin
                    walk_left  = 1'b0;
                    walk_right = 1'b0;
                    aaah       = 1'b0;
                end
        endcase
    end

endmodule