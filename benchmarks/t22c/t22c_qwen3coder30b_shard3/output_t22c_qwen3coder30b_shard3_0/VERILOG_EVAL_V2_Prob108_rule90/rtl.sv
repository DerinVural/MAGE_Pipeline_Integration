module TopModule (
    input clk,
    input load,
    input [511:0] data,
    output logic [511:0] q
);

    // Register to hold the current state
    logic [511:0] q_reg;

    // Combinational logic to calculate next state
    always @(*) begin
        // Initialize next state
        logic [511:0] q_next;
        
        // For each cell, compute XOR of left and right neighbors
        // q[-1] is 0, q[512] is 0
        for (int i = 0; i < 512; i = i + 1) begin
            logic left, right;
            
            // Get left neighbor (q[-1] = 0)
            if (i == 0)
                left = 1'b0;
            else
                left = q_reg[i-1];
            
            // Get right neighbor (q[512] = 0)
            if (i == 511)
                right = 1'b0;
            else
                right = q_reg[i+1];
            
            // Apply Rule 90: center = left XOR right
            q_next[i] = left ^ right;
        end
        
        // Assign next state
        q = q_next;
    end

    // Sequential logic to load or update
    always @(posedge clk) begin
        if (load)
            q_reg <= data;
        else
            q_reg <= q;
    end

endmodule