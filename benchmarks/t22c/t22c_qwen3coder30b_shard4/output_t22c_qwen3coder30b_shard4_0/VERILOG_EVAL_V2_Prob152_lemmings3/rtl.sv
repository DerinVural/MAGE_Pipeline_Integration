module TopModule(
    input logic clk,
    input logic areset,
    input logic bump_left,
    input logic bump_right,
    input logic ground,
    input logic dig,
    output logic walk_left,
    output logic walk_right,
    output logic aaah,
    output logic digging
);

    // Define states
    localparam IDLE_WALK_LEFT   = 2'b00;
    localparam IDLE_WALK_RIGHT  = 2'b01;
    localparam FALLING          = 2'b10;
    localparam DIGGING          = 2'b11;

    // Current state register
    logic [1:0] state;
    logic [1:0] next_state;

    // Sequential logic
    always @(posedge clk or posedge areset) begin
        if (areset)
            state <= IDLE_WALK_LEFT;
        else
            state <= next_state;
    end

    // Next state logic
    always @(*) begin
        // Default assignments
        next_state = state;
        
        // Determine if falling occurs (highest precedence)
        if (state != FALLING && !ground) begin
            next_state = FALLING;
        end
        // Determine if digging occurs (medium precedence)
        else if (state != DIGGING && ground && dig) begin
            next_state = DIGGING;
        end
        // Determine if direction change occurs (lowest precedence)
        else if ((state == IDLE_WALK_LEFT && bump_right) || 
                 (state == IDLE_WALK_RIGHT && bump_left)) begin
            if (state == IDLE_WALK_LEFT)
                next_state = IDLE_WALK_RIGHT;
            else
                next_state = IDLE_WALK_LEFT;
        end
        // Resume walking after falling
        else if (state == FALLING && ground) begin
            if (state == IDLE_WALK_LEFT)
                next_state = IDLE_WALK_LEFT;
            else
                next_state = IDLE_WALK_RIGHT;
        end
        // End digging when ground disappears
        else if (state == DIGGING && !ground) begin
            next_state = FALLING;
        end
    end

    // Output logic (Moore machine)
    always @(*) begin
        walk_left = 1'b0;
        walk_right = 1'b0;
        aaah = 1'b0;
        digging = 1'b0;
        
        case (state)
            IDLE_WALK_LEFT: begin
                walk_left = 1'b1;
            end
            IDLE_WALK_RIGHT: begin
                walk_right = 1'b1;
            end
            FALLING: begin
                aaah = 1'b1;
            end
            DIGGING: begin
                digging = 1'b1;
            end
        endcase
    end

endmodule