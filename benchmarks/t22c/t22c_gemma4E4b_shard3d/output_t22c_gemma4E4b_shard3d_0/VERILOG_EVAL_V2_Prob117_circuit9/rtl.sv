module TopModule (
    input  logic clk,
    input  logic a,
    output logic [2:0] q
);

    // Register to hold the output state
    logic [2:0] q_reg;

    // Initialization block to set the known initial state (4 = 100)
    initial begin
        q_reg = 3'b100; // Initial state observed at T=5ns is 4
    end

    // Sequential logic triggered by positive clock edge
    always @(posedge clk)
    begin
        if (a == 1'b1)
        begin
            // Hold state if a is high
            q_reg <= q_reg;
        end
        else begin
            // Increment state if a is low (a == 0)
            // Observed sequence: 4 -> 5 -> 6 -> 0 -> 1
            if (q_reg == 3'b110) // If current state is 6
            begin
                q_reg <= 3'b000; // Wrap to 0
            end
            else if (q_reg == 3'b111) // Handle potential overflow if counter reaches 7 (though not observed)
            begin
                q_reg <= 3'b000; 
            end
            else
            begin
                q_reg <= q_reg + 1'b1;
            end
        end
    end

    // Assign the registered output to the port
    assign q = q_reg;

endmodule