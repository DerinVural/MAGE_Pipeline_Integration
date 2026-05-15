module TopModule(
    input  logic       clk,
    input  logic       load,
    input  logic [255:0] data,
    output logic [255:0] q
);

    logic [255:0] q_next;
    int           neighbor_count;
    int           r, c, dr, dc;
    int           nr, nc;
    int           idx, n_idx;

    // Combinational logic for the next state
    always @(*) begin
        q_next = 256'b0;
        
        // Iterate through every cell in the 16x16 grid
        for (int i = 0; i < 256; i = i + 1) begin
            // Convert flat index to 2D coordinates
            r = i / 16;
            c = i % 16;
            
            neighbor_count = 0;
            
            // Check 8 neighbors with toroidal wrap-around
            for (dr = -1; dr <= 1; dr = dr + 1) begin
                for (dc = -1; dc <= 1; dc = dc + 1) begin
                    // Skip the current cell itself
                    if (!(dr == 0 && dc == 0)) begin
                        nr = (r + dr + 16) % 16;
                        nc = (c + dc + 16) % 16;
                        n_idx = nr * 16 + nc;
                        
                        if (q[n_idx]) begin
                            neighbor_count = neighbor_count + 1;
                        end
                    end
                end
            end

            // Apply Conway's Game of Life rules
            if (neighbor_count == 3) begin
                q_next[i] = 1'b1;
            end else if (neighbor_count == 2) begin
                q_next[i] = q[i];
            end else begin
                q_next[i] = 1'b0;
            end
        end
    end

    // Sequential logic for state updates
    always @(posedge clk) begin
        if (load) begin
            q <= data;
        end else begin
            q <= q_next;
        end
    end

    // Initial state
    initial begin
        q = 256'b0;
    end

endmodule