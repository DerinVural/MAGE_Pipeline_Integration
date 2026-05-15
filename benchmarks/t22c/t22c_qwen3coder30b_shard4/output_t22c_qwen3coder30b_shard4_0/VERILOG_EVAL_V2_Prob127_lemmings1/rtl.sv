module TopModule (
    input clk,
    input areset,
    input bump_left,
    input bump_right,
    output logic walk_left,
    output logic walk_right
);

    // Define states
    localparam WALK_LEFT = 1'b0;
    localparam WALK_RIGHT = 1'b1;

    // State register
    logic current_state;
    logic next_state;

    // Sequential logic: state register
    always @(posedge clk or posedge areset) begin
        if (areset)
            current_state <= WALK_LEFT;
        else
            current_state <= next_state;
    end

    // Next state logic
    always @(*) begin
        if (current_state == WALK_LEFT) begin
            if (bump_left)
                next_state = WALK_RIGHT;
            else
                next_state = WALK_LEFT;
        end else begin // current_state == WALK_RIGHT
            if (bump_right)
                next_state = WALK_LEFT;
            else
                next_state = WALK_RIGHT;
        end
    end

    // Output logic
    always @(*) begin
        if (current_state == WALK_LEFT) begin
            walk_left = 1'b1;
            walk_right = 1'b0;
        end else begin
            walk_left = 1'b0;
            walk_right = 1'b1;
        end
    end

endmodule