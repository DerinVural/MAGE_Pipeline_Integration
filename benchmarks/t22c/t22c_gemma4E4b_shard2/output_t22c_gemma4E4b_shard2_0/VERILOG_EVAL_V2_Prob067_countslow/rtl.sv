module TopModule (
    input  logic clk,
    input  logic reset,
    input  logic slowena,
    output logic [3:0] q
);

    // Internal register to hold the counter state
    logic [3:0] counter_reg;

    // Initialize the counter to 0 at simulation start (Constraint 3)
    initial begin
        counter_reg = 4'b0000;
    end

    // Sequential logic for the decade counter
    always @(posedge clk)
    begin
        if (reset)
        begin
            // Synchronous reset to 0
            counter_reg <= 4'b0000;
        end
        else if (slowena)
        begin
            // Counter increments only when slowena is high
            // Decade counter logic (0 -> 9 -> 0)
            if (counter_reg == 4'd9)
            begin
                counter_reg <= 4'b0000;
            end
            else
            begin
                counter_reg <= counter_reg + 1'b1;
            end
        end
        // If slowena is low, counter_reg <= counter_reg (hold state) is implied if no assignment is made
        // or explicitly written if preferred for clarity, but leaving it out is fine for hold behavior.
    end

    // Output assignment
    assign q = counter_reg;

endmodule