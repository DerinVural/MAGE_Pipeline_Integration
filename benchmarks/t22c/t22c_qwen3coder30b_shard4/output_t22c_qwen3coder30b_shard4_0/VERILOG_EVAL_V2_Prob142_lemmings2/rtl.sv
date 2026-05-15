module TopModule (
    input  logic clk,
    input  logic areset,
    input  logic bump_left,
    input  logic bump_right,
    input  logic ground,
    output logic walk_left,
    output logic walk_right,
    output logic aaah
);

    // Define states
    localparam WALK_LEFT  = 2'b00;
    localparam WALK_RIGHT = 2'b01;
    localparam FALLING    = 2'b10;

    // State register
    logic [1:0] state, next_state;

    // Sequential logic
    always @(posedge clk, negedge areset) begin
        if (~areset)
            state <= WALK_LEFT;
        else
            state <= next_state;
    end

    // Combinational logic for next state
    always @(*) begin
        case (state)
            WALK_LEFT: begin
                if (!ground)
                    next_state = FALLING;
                else if (bump_left || bump_right)
                    next_state = WALK_RIGHT;
                else
                    next_state = WALK_LEFT;
            end

            WALK_RIGHT: begin
                if (!ground)
                    next_state = FALLING;
                else if (bump_left || bump_right)
                    next_state = WALK_LEFT;
                else
                    next_state = WALK_RIGHT;
            end

            FALLING: begin
                if (ground)
                    next_state = (state == WALK_LEFT) ? WALK_LEFT : WALK_RIGHT;
                else
                    next_state = FALLING;
            end

            default: next_state = WALK_LEFT;
        endcase
    end

    // Output logic (Moore machine)
    always @(*) begin
        walk_left = 1'b0;
        walk_right = 1'b0;
        aaah = 1'b0;

        case (state)
            WALK_LEFT: begin
                walk_left = 1'b1;
            end

            WALK_RIGHT: begin
                walk_right = 1'b1;
            end

            FALLING: begin
                aaah = 1'b1;
            end

            default: ;
        endcase
    end

endmodule