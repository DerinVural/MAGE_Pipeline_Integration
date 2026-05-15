module TopModule (
    input  logic clk,
    input  logic areset,
    input  logic bump_left,
    input  logic bump_right,
    input  logic ground,
    input  logic dig,
    output logic walk_left,
    output logic walk_right,
    output logic aaah,
    output logic digging
);

    // --- State Definitions ---
    localparam S_INIT = 3'b000;
    localparam S_WL   = 3'b001; // Walking Left
    localparam S_WR   = 3'b010; // Walking Right
    localparam S_FL   = 3'b011; // Falling (Direction tracked by current_direction)
    localparam S_FR   = 3'b100; // Falling (Direction tracked by current_direction)
    localparam S_DL   = 3'b101; // Digging Left
    localparam S_DR   = 3'b110; // Digging Right
    localparam S_SP   = 3'b111; // Splattered

    // --- Internal Signals ---
    logic [2:0] state, state_next;
    logic [4:0] fall_counter; // Counter for max 20 cycles (0 to 31)
    logic current_direction;  // L=0, R=1. Used to resume direction after fall/dig.

    // --- Register Declarations ---
    // Sequential logic registered on positive clock edge
    always @(posedge clk)
    begin
        if (areset)
        begin
            state <= S_INIT;
            fall_counter <= 0;
            current_direction <= 0; // Default to Left per reset requirement
        end
        else
        begin
            state <= state_next;
            
            // Update fall counter logic
            if (state == S_FL || state == S_FR) begin
                if (ground) begin
                    fall_counter <= 0; // Reset counter upon hitting ground
                end else begin
                    fall_counter <= fall_counter + 1;
                end
            end

            // Update direction tracking ONLY when transitioning into a WALKING state
            if (state_next == S_WL) current_direction <= 0;
            else if (state_next == S_WR) current_direction <= 1;
        end
    end

    // Initialization block for non-reset path to prevent X values
    initial begin
        state = S_INIT;
        fall_counter = 0;
        current_direction = 0;
    end

    // --- Next State Logic (Combinational) ---
    always @(*)
    begin
        state_next = state;

        case (state) 
            S_INIT: begin
                // Initial state defaults to walking left upon exiting reset
                state_next = S_WL;
            end

            S_WL: begin // Walking Left
                // Precedence 1: Digging
                if (dig && ground) begin
                    state_next = S_DL;
                // Precedence 2: Bumping Right
                end else if (bump_right) begin
                    state_next = S_WR;
                // Precedence 3: Falling (Ground disappears)
                end else if (!ground) begin
                    state_next = S_FL; // Falling maintains current direction (Left)
                end
                // Otherwise, stay S_WL
                end

            S_WR: begin // Walking Right
                // Precedence 1: Digging
                if (dig && ground) begin
                    state_next = S_DR;
                // Precedence 2: Bumping Left
                end else if (bump_left) begin
                    state_next = S_WL;
                // Precedence 3: Falling (Ground disappears)
                end else if (!ground) begin
                    state_next = S_FR; // Falling maintains current direction (Right)
                end
                // Otherwise, stay S_WR
                end

            S_FL: begin // Falling
                // Precedence 1: Splatter Check
                if (fall_counter >= 20) begin
                    state_next = S_SP;
                // Precedence 2: Ground Reappears
                end else if (ground) begin
                    // Resume walking in the direction stored when entering fall
                    if (current_direction == 0) state_next = S_WL;
                    else state_next = S_WR;
                // Otherwise, continue falling
                end
            end

            S_FR: begin // Falling
                // Precedence 1: Splatter Check
                if (fall_counter >= 20) begin
                    state_next = S_SP;
                // Precedence 2: Ground Reappears
                end else if (ground) begin
                    // Resume walking in the direction stored when entering fall
                    if (current_direction == 0) state_next = S_WL;
                    else state_next = S_WR;
                // Otherwise, continue falling
                end
            end

            S_DL: begin // Digging Left
                // Precedence 1: Ground disappears (Fall)
                if (!ground) begin
                    // Direction stored when entering dig (which originated from a walk state)
                    if (current_direction == 0) state_next = S_FL; 
                    else state_next = S_FR;
                // Precedence 2: Digging stops
                end else if (!dig) begin
                    // If dig input goes low while grounded, revert to walking in the same direction
                    if (current_direction == 0) state_next = S_WL;
                    else state_next = S_WR;
                // Otherwise, continue digging
                end
            end

            S_DR: begin // Digging Right
                // Precedence 1: Ground disappears (Fall)
                if (!ground) begin
                    // Direction stored when entering dig
                    if (current_direction == 0) state_next = S_FL; 
                    else state_next = S_FR;
                // Precedence 2: Digging stops
                end else if (!dig) begin
                    if (current_direction == 0) state_next = S_WL;
                    else state_next = S_WR;
                // Otherwise, continue digging
                end
            end

            S_SP: begin // Splattered - remains here until reset
                state_next = S_SP;
            end
        endcase
    end

    // --- Output Logic (Moore Machine) ---
    always @(*)
    begin
        // Default outputs are 0
        walk_left = 1'b0;
        walk_right = 1'b0;
        aaah = 1'b0;
        digging = 1'b0;

        case (state) 
            S_WL: begin
                walk_left = 1'b1;
                digging = 1'b1;
            end
            S_WR: begin
                walk_right = 1'b1;
                digging = 1'b1;
            end
            S_FL: begin
                aaah = 1'b1;
            end
            S_FR: begin
                aaah = 1'b1;
            end
            S_DL: begin
                digging = 1'b1;
            end
            S_DR: begin
                digging = 1'b1;
            end
            S_SP: begin
                // All outputs are 0
            end
            S_INIT: begin
                // Remain in initial state output configuration (0s)
            end
        endcase
    end

endmodule