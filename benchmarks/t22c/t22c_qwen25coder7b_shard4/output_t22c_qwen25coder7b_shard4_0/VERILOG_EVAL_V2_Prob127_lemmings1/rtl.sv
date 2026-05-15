module TopModule (input logic clk, input logic areset, input logic bump_left, input logic bump_right, output logic walk_left, output logic walk_right);

    // Define states
    localparam WALK_LEFT = 1'b0;
    localparam WALK_RIGHT = 1'b1;

    // Internal signals
    logic current_state, next_state;
    logic [1:0] bump;

    // Initialize internal signals
    initial begin
        current_state = WALK_LEFT;
        bump = 2'b00;
    end

    // Clock edges
    always_ff @(posedge clk) begin
        if (areset)
            current_state <= WALK_LEFT;
        else
            current_state <= next_state;
        bump <= {bump_left, bump_right};
    end

    // State transition logic
    always_comb begin
        next_state = current_state;
        case (current_state)
            WALK_LEFT: begin
                if (bump == 2'b11 || bump_left)
                    next_state = WALK_RIGHT;
            end
            WALK_RIGHT: begin
                if (bump == 2'b11 || bump_right)
                    next_state = WALK_LEFT;
            end
            default: next_state = WALK_LEFT;
        endcase
    end

    // Output logic
    always_comb begin
        walk_left = (current_state == WALK_LEFT);
        walk_right = (current_state == WALK_RIGHT);
    end

endmodule;