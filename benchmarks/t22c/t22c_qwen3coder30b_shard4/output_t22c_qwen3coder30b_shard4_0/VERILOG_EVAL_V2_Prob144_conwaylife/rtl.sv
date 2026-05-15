module TopModule (
    input clk,
    input load,
    input [255:0] data,
    output [255:0] q
);

    logic [255:0] q_reg;
    logic [255:0] q_next;

    // Sequential logic
    always @(posedge clk) begin
        if (load)
            q_reg <= data;
        else
            q_reg <= q_next;
    end

    // Generate next state
    always @(*) begin
        q_next = 0;
        for (integer i = 0; i < 256; i++) begin
            integer row;
            integer col;
            integer neighbors;
            integer neighbor_row;
            integer neighbor_col;
            integer neighbor_idx;
            
            row = i / 16;
            col = i % 16;
            neighbors = 0;
            
            // Check all 8 neighbors with toroidal boundary conditions
            for (integer di = -1; di <= 1; di++) begin
                for (integer dj = -1; dj <= 1; dj++) begin
                    if (!(di == 0 && dj == 0)) begin
                        neighbor_row = (row + di + 16) % 16;
                        neighbor_col = (col + dj + 16) % 16;
                        neighbor_idx = neighbor_row * 16 + neighbor_col;
                        neighbors = neighbors + q_reg[neighbor_idx];
                    end
                end
            end
            
            // Apply Game of Life rules
            if (q_reg[i]) begin
                // Cell is alive
                if (neighbors < 2 || neighbors > 3)
                    q_next[i] = 0;
                else
                    q_next[i] = 1;
            end else begin
                // Cell is dead
                if (neighbors == 3)
                    q_next[i] = 1;
                else
                    q_next[i] = 0;
            end
        end
    end

    // Output assignment
    assign q = q_reg;

endmodule