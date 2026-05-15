module TopModule(
    input  logic clk,
    input  logic areset,
    input  logic bump_left,
    input  logic bump_right,
    output logic walk_left,
    output logic walk_right
);

    // State definitions
    localparam STATE_LEFT  = 1'b0;
    localparam STATE_RIGHT = 1'b1;

    // State register
    logic state;

    // Sequential logic for state transitions
    always @(posedge clk or posedge areset) begin
        if (areset) begin
            state <= STATE_LEFT;
        end else begin
            if (bump_left && bump_right) begin
                // If bumped on both sides, switch direction
                state <= ~state;
            end else if (bump_left) begin
                // Bumped on left -> walk right
                state <= STATE_RIGHT;
            end else if (bump_right) begin
                // Bumped on right -> walk left
                state <= STATE_LEFT;
            end else begin
                // No bump -> stay in current state
                state <= state;
            end
        end
    end

    // Combinational logic for Moore outputs
    always @(*) begin
        if (state == STATE_LEFT) begin
            walk_left  = 1'b1;
            walk_right = 1'b0;
        end else begin
            walk_left  = 1'b0;
            walk_right = 1'b1;
        end
    end

endmodule