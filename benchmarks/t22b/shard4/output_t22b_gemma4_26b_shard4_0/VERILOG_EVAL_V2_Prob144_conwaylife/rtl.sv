module TopModule (
    input  logic        clk,
    input  logic        load,
    input  logic [255:0] data,
    output logic [255:0] q
);

    logic [255:0] q_reg;
    logic [255:0] q_next;

    // Variables for combinational logic loops
    integer r, c, i, j, dr, dc, neighbors;

    // Initialize q_reg to 0 to avoid X propagation
    initial begin
        q_reg = 256'b0;
    end

    // Sequential logic
    always @(posedge clk) begin
        if (load) begin
            q_reg <= data;
        end else begin
            q_reg <= q_next;
        end
    end

    // Combinational logic for next state
    always @(*) begin
        q_next = 256'b0;
        for (r = 0; r < 16; r = r + 1) begin
            for (c = 0; c < 16; c = c + 1) begin
                neighbors = 0;
                
                // Check all 8 neighbors with modulo 16 for toroid
                for (i = -1; i <= 1; i = i + 1) begin
                    for (j = -1; j <= 1; j = j + 1) begin
                        // Avoid the cell itself (i=0, j=0)
                        if (!(i == 0 && j == 0)) begin
                            // Calculate wrapped coordinates
                            // Adding 16 handles negative results from (r + i)
                            dr = (r + i + 16) % 16;
                            dc = (c + j + 16) % 16;
                            
                            if (q_reg[dr * 16 + dc]) begin
                                neighbors = neighbors + 1;
                            end
                        end
                    end
                end

                // Apply Game of Life rules
                if (neighbors == 3) begin
                    q_next[r * 16 + c] = 1'b1;
                end else if (neighbors == 2) begin
                    q_next[r * 16 + c] = q_reg[r * 16 + c];
                end else begin
                    q_next[r * 16 + c] = 1'b0;
                end
            end
        end
    end

    assign q = q_reg;

endmodule