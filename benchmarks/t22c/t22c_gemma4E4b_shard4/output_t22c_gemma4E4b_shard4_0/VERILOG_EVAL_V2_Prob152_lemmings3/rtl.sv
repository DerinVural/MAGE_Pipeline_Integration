module TopModule(
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

    // State Encoding (5 states require 3 bits: 000 to 100)
    localparam S_WALK_L = 3'b000;
    localparam S_WALK_R = 3'b001;
    localparam S_FALL   = 3'b010;
    localparam S_DIG_L  = 3'b011;
    localparam S_DIG_R  = 3'b100;

    // --- State Registers and Memory ---
    logic [2:0] current_state, next_state;
    
    // Memory to store the Lemming's preferred walking direction (0=Left, 1=Right).
    logic dir_mem_l;

    // Initialization Block (Requirement #3)
    initial begin
        current_state = S_WALK_L;
        dir_mem_l = 1'b0;
    end

    // Sequential Logic (State Register & Memory Update)
    always @(posedge clk)
    begin
        if (areset)
        begin
            current_state <= S_WALK_L; // Reset to walk left
            dir_mem_l <= 1'b0;          // Initialize direction memory to Left
        end
        else
        begin
            current_state <= next_state;
            
            // Update direction memory only when transitioning into a stable walking state 
            case (next_state) 
                S_WALK_L: dir_mem_l <= 1'b0;
                S_WALK_R: dir_mem_l <= 1'b1;
                S_DIG_L: dir_mem_l <= 1'b0;
                S_DIG_R: dir_mem_l <= 1'b1;
                default: dir_mem_l <= dir_mem_l; // Preserve direction during falling or unknown state
            endcase
        end
    end

    // Next State Combinational Logic
    always @(*)
    begin
        next_state = current_state;

        // 1. HIGHEST PRECEDENCE: FALLING (ground=0)
        if (ground == 0) begin
            next_state = S_FALL; // Always fall if ground disappears
        end

        // 2. SECOND PRECEDENCE: DIGGING (ground=1 and dig=1)
        else if (ground == 1 && dig == 1) begin
            // Digging continues in the previous direction memory
            if (dir_mem_l == 1'b0) begin
                next_state = S_DIG_L;
            end else begin
                next_state = S_DIG_R;
            end
        end

        // 3. LOWEST PRECEDENCE: WALKING / BUMPING (ground=1 and dig=0)
        else if (ground == 1 && dig == 0) begin
            case (current_state) 
                S_WALK_L:
                begin
                    // Bump Left -> Switch to Right
                    if (bump_left) next_state = S_WALK_R;
                    // Bump Right -> Switch to Left
                    else if (bump_right) next_state = S_WALK_L;
                    // No bump -> Stay
                    else next_state = S_WALK_L;
                end
                S_WALK_R:
                begin
                    // Bump Left -> Switch to Left
                    if (bump_left) next_state = S_WALK_L;
                    // Bump Right -> Switch to Right
                    else if (bump_right) next_state = S_WALK_R;
                    // No bump -> Stay
                    else next_state = S_WALK_R;
                end
                // If in a non-walking state but ground reappears (e.g., falling back to ground), resume walking
                S_FALL: begin
                    // Resume walking in the direction remembered before falling
                    if (dir_mem_l == 1'b0) next_state = S_WALK_L;
                    else next_state = S_WALK_R;
                end
                S_DIG_L, S_DIG_R: begin
                    // If digging stops (dig=0) while on ground, resume walking in the direction of the last active dig state
                    if (current_state == S_DIG_L) next_state = S_WALK_L;
                    else next_state = S_WALK_R;
                end
                default: next_state = S_WALK_L; // Should not happen
            endcase
        end
    end

    // Moore Output Logic (Outputs depend only on current_state)
    always @(*)
    begin
        // Default outputs
        walk_left = 1'b0;
        walk_right = 1'b0;
        aaah = 1'b0;
        digging = 1'b0;

        case (current_state)
            S_WALK_L: begin
                walk_left = 1'b1;
            end
            S_WALK_R: begin
                walk_right = 1'b1;
            end
            S_FALL: begin
                aaah = 1'b1;
            end
            S_DIG_L: begin
                digging = 1'b1;
            end
            S_DIG_R: begin
                digging = 1'b1;
            end
        endcase
    end

endmodule