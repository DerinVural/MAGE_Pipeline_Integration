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

    // State definitions
    localparam STATE_L_G = 2'b00; // Walking Left, Grounded
    localparam STATE_R_G = 2'b01; // Walking Right, Grounded
    localparam STATE_L_F = 2'b10; // Falling, last was Left
    localparam STATE_R_F = 2'b11; // Falling, last was Right

    logic [1:0] state;
    logic [1:0] next_state;

    // Initialize state to prevent X in simulation
    initial begin
        state = STATE_L_G;
    end

    // Sequential logic with asynchronous reset
    always @(posedge clk or posedge areset) begin
        if (areset) begin
            state <= STATE_L_G;
        end else begin
            state <= next_state;
        end
    end

    // Combinational logic for next state
    always @(*) begin
        next_state = state;
        case (state)
            STATE_L_G: begin
                if (!ground) begin
                    next_state = STATE_L_F;
                end else begin
                    if (bump_left && bump_right) begin
                        next_state = STATE_R_G; // Switch direction
                    end else if (bump_left) begin
                        next_state = STATE_R_G; // Bump left -> walk right
                    end else if (bump_right) begin
                        next_state = STATE_L_G; // Bump right -> walk left (already is)
                    end else begin
                        next_state = STATE_L_G;
                    end
                end
            end
            STATE_R_G: begin
                if (!ground) begin
                    next_state = STATE_R_F;
                end else begin
                    if (bump_left && bump_right) begin
                        next_state = STATE_L_G; // Switch direction
                    end else if (bump_left) begin
                        next_state = STATE_R_G; // Bump left -> walk right (already is)
                    end else if (bump_right) begin
                        next_state = STATE_L_G; // Bump right -> walk left
                    end else begin
                        next_state = STATE_R_G;
                    end
                end
            end
            STATE_L_F: begin
                if (ground) begin
                    next_state = STATE_L_G;
                end else begin
                    next_state = STATE_L_F;
                end
            end
            STATE_R_F: begin
                if (ground) begin
                    next_state = STATE_R_G;
                end else begin
                    next_state = STATE_R_F;
                end
            end
            default: next_state = STATE_L_G;
        endcase
    end

    // Moore output logic
    always @(*) begin
        walk_left  = 1'b0;
        walk_right = 1'b0;
        aaah       = 1'b0;

        case (state) 
            STATE_L_G: walk_left  = 1'b1;
            STATE_R_G: walk_right = 1'b1;
            STATE_L_F: aaah       = 1'b1;
            STATE_R_F: aaah       = 1'b1;
        endcase
    end

endmodule