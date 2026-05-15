module TopModule (
    input clk,
    input areset,
    input train_valid,
    input train_taken,
    output logic [1:0] state
);

    // The counter state register
    logic [1:0] counter;

    // Initialize counter to a known value (00) before reset is asserted, as per requirement 3.
    initial begin
        counter = 2'b00;
    end

    // Sequential Logic (Asynchronous Reset)
    always @(posedge clk or posedge areset) begin
        if (areset) begin
            // Reset to weakly not-taken (2'b01)
            counter <= 2'b01;
        end else begin
            // Standard clocked behavior
            if (train_valid) begin
                if (train_taken) begin
                    // Increment, saturating at 3 (11)
                    if (counter < 2'b11) begin
                        counter <= counter + 1;
                    end
                    // If counter is already 3, it stays 3 (no change needed)
                end else begin
                    // Decrement, saturating at 0 (00)
                    if (counter > 2'b00) begin
                        counter <= counter - 1;
                    end
                    // If counter is already 0, it stays 0 (no change needed)
                end
            end
            // If train_valid == 0, the counter holds its value (implicit, as no assignment is made)
        end
    end

    // Output assignment
    assign state = counter;

endmodule