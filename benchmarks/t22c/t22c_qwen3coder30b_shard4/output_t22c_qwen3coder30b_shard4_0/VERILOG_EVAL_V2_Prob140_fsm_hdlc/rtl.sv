module TopModule (
    input clk,
    input reset,
    input in,
    output reg disc,
    output reg flag,
    output reg err
);

    // State definitions
    localparam S_IDLE   = 3'd0;
    localparam S_ONE    = 3'd1;
    localparam S_TWO    = 3'd2;
    localparam S_THREE  = 3'd3;
    localparam S_FOUR   = 3'd4;
    localparam S_FIVE   = 3'd5;
    localparam S_SIX    = 3'd6;
    localparam S_SEVEN  = 3'd7;

    // Current state register
    logic [2:0] state;
    logic [2:0] next_state;

    // Initialize state to IDLE
    initial begin
        state = S_IDLE;
    end

    // Sequential logic for state register
    always @(posedge clk) begin
        if (reset)
            state <= S_IDLE;
        else
            state <= next_state;
    end

    // Combinational logic for next state and outputs
    always @(*) begin
        // Default assignments
        next_state = state;
        disc = 1'b0;
        flag = 1'b0;
        err = 1'b0;

        case (state)
            S_IDLE: begin
                if (in)
                    next_state = S_ONE;
                else
                    next_state = S_IDLE;
            end

            S_ONE: begin
                if (in)
                    next_state = S_TWO;
                else
                    next_state = S_IDLE;
            end

            S_TWO: begin
                if (in)
                    next_state = S_THREE;
                else
                    next_state = S_IDLE;
            end

            S_THREE: begin
                if (in)
                    next_state = S_FOUR;
                else
                    next_state = S_IDLE;
            end

            S_FOUR: begin
                if (in)
                    next_state = S_FIVE;
                else
                    next_state = S_IDLE;
            end

            S_FIVE: begin
                if (in)
                    next_state = S_SIX;
                else
                    next_state = S_IDLE;
            end

            S_SIX: begin
                if (in)
                    next_state = S_SEVEN;
                else begin
                    // Detected 0 after 5 1s -> discard
                    disc = 1'b1;
                    next_state = S_IDLE;
                end
            end

            S_SEVEN: begin
                if (in)
                    next_state = S_SEVEN;
                else begin
                    // Detected 0 after 6 1s -> flag
                    flag = 1'b1;
                    next_state = S_IDLE;
                end
            end

            default:
                next_state = S_IDLE;
        endcase

        // Handle error condition: 7 or more consecutive 1s
        if (state == S_SEVEN && in)
            err = 1'b1;
    end

endmodule