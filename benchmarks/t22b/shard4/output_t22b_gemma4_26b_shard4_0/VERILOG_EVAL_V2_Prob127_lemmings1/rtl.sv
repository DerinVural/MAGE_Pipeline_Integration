module TopModule (
    input  logic clk,
    input  logic areset,
    input  logic bump_left,
    input  logic bump_right,
    output logic walk_left,
    output logic walk_right
);

    // State encoding
    localparam STATE_WALK_LEFT  = 1'b0;
    localparam STATE_WALK_RIGHT = 1'b1;

    // State register
    logic state;

    // Initialize state to avoid X
    initial begin
        state = STATE_WALK_LEFT;
    end

    // Sequential logic for state transition
    always @(posedge clk or posedge areset) begin
        if (areset) begin
            state <= STATE_WALK_LEFT;
        end else begin
            if (bump_left) begin
                state <= STATE_WALK_RIGHT;
            end else if (bump_right) begin
                state <= STATE_WALK_LEFT;
            end
            // else: stay in current state
        end
    end

    // Combinational logic for Moore outputs
    always @(*) begin
        if (state == STATE_WALK_LEFT) begin
            walk_left  = 1'b1;
            walk_right = 1'b0;
        end else begin
            walk_left  = 1'b0;
            walk_right = 1'b1;
        end
    end

endmodule