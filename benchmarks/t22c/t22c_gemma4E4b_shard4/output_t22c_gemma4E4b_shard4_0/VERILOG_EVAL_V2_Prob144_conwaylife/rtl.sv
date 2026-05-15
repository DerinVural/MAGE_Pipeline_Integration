module TopModule (
    input  logic clk,
    input  logic load,
    input  logic [255:0] data,
    output logic [255:0] q
);

    // Internal registers and wires
    logic [255:0] q_current; // Holds the current state Q
    logic [255:0] q_next;   // Holds the state after one time step

    // Initialization: Initialize current state to zero to avoid X propagation on first cycle
    initial begin
        q_current = 256'h0;
    end

    // ----------------------------------------------------------
    // 1. Combinational Logic: Calculate Next State (q_next) based on q_current
    // This simulates the 256 independent cellular rules.
    // ----------------------------------------------------------
    always_comb begin
        q_next = 256'h0; // Default initialization ensures all outputs are driven

        // Iterate over all 16*16 = 256 cells
        for (int i = 0; i < 256; i = i + 1) begin
            // Cell coordinates (Row r, Column c)
            int r = i / 16;
            int c = i % 16;

            int neighbor_count = 0;

            // Define the 8 neighbor offsets (dr, dc)
            int dr_offsets[] = {-1, -1, -1, 0, 0, 1, 1, 1};
            int dc_offsets[] = {-1, 0, 1, -1, 1, -1, 0, 1};
            
            // Check all 8 neighbors
            for (int k = 0; k < 8; k = k + 1) begin
                int dr = dr_offsets[k];
                int dc = dc_offsets[k];

                // Toroidal row wrapping
                int nr = (r + dr + 16) % 16;
                // Toroidal column wrapping
                int nc = (c + dc + 16) % 16;

                // Calculate the index of the neighbor cell (nr, nc)
                int neighbor_idx = nr * 16 + nc;
                
                // Check if the neighbor is alive in the current state
                if (q_current[neighbor_idx]) begin
                    neighbor_count = neighbor_count + 1;
                end
            end

            // Apply Game of Life rules for cell i
            logic next_state_i = 1'b0;
            case (neighbor_count)
                1: next_state_i = 1'b0; // Rule (1): 0-1 neighbor -> Dead
                2: next_state_i = q_current[i]; // Rule (2): 2 neighbors -> Unchanged
                3: next_state_i = 1'b1; // Rule (3): 3 neighbors -> Alive
                default: next_state_i = 1'b0; // Rule (4): 4+ neighbors -> Dead
            endcase

            // Assign the calculated state to the i-th bit of q_next
            q_next[i] = next_state_i;
        end
    end

    // ----------------------------------------------------------
    // 2. Sequential Logic: State Update (q_current)
    // ----------------------------------------------------------
    always_ff @(posedge clk)
    begin
        if (load) begin
            // Load initial state
            q_current <= data;
        end else begin
            // Advance simulation by one timestep
            q_current <= q_next;
        end
    end

    // ----------------------------------------------------------
    // 3. Output Assignment
    // ----------------------------------------------------------
    // The output q reflects the current state
    assign q = q_current;

endmodule