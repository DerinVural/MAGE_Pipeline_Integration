module TopModule (
    input clk,
    input areset,
    input bump_left,
    input bump_right,
    input ground,
    input dig,
    output logic walk_left,
    output logic walk_right,
    output logic aaah,
    output logic digging
);

    // State definitions
    localparam WALK_LEFT   = 3'd0;
    localparam WALK_RIGHT  = 3'd1;
    localparam FALLING     = 3'd2;
    localparam DIGGING     = 3'd3;
    localparam SPLAT       = 3'd4;

    // State registers
    logic [2:0] state, next_state;
    logic [4:0] fall_count;
    
    // Initialize state to WALK_LEFT on reset
    initial begin
        state = WALK_LEFT;
        fall_count = 5'd0;
    end

    // State transition logic
    always @(*) begin
        next_state = state;
        
        // Default case for all states
        case (state)
            WALK_LEFT: begin
                if (bump_left || bump_right) begin
                    next_state = WALK_RIGHT;
                end
                else if (!ground) begin
                    next_state = FALLING;
                end
                else if (dig) begin
                    next_state = DIGGING;
                end
            end
            
            WALK_RIGHT: begin
                if (bump_left || bump_right) begin
                    next_state = WALK_LEFT;
                end
                else if (!ground) begin
                    next_state = FALLING;
                end
                else if (dig) begin
                    next_state = DIGGING;
                end
            end
            
            FALLING: begin
                if (ground) begin
                    // Check if splat condition (more than 20 cycles)
                    if (fall_count > 5'd20) begin
                        next_state = SPLAT;
                    end
                    else begin
                        // Resume walking in same direction
                        if (state == WALK_LEFT) begin
                            next_state = WALK_LEFT;
                        end
                        else begin
                            next_state = WALK_RIGHT;
                        end
                    end
                end
            end
            
            DIGGING: begin
                if (!ground) begin
                    next_state = FALLING;
                end
                else if (bump_left || bump_right) begin
                    // Bump while digging doesn't change direction
                    // Stay in DIGGING state
                end
            end
            
            SPLAT: begin
                // Stay in SPLAT state indefinitely
            end
        endcase
    end

    // Sequential logic for state and counter
    always @(posedge clk or posedge areset) begin
        if (areset) begin
            state <= WALK_LEFT;
            fall_count <= 5'd0;
        end
        else begin
            state <= next_state;
            
            // Update fall counter
            if (state == FALLING) begin
                fall_count <= fall_count + 1'b1;
            end
            else begin
                fall_count <= 5'd0;
            end
        end
    end

    // Output logic
    always @(*) begin
        walk_left = 1'b0;
        walk_right = 1'b0;
        aaah = 1'b0;
        digging = 1'b0;
        
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
            
            DIGGING: begin
                digging = 1'b1;
            end
            
            SPLAT: begin
                // All outputs are 0
            end
        endcase
    end

endmodule