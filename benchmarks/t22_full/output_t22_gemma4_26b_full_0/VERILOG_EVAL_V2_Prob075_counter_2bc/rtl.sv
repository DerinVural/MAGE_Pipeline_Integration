module TopModule(
    input  logic       clk,
    input  logic       areset,
    input  logic       train_valid,
    input  logic       train_taken,
    output logic [1:0] state
);

    // Sequential logic for the saturating counter
    // The reset is asynchronous and active-high
    always @(posedge clk or posedge areset) begin
        if (areset) begin
            // Reset to weakly not-taken (2'b01)
            state <= 2'b01;
        end else begin
            if (train_valid) begin
                if (train_taken) begin
                    // Increment and saturate at 3 (2'b11)
                    if (state != 2'b11) begin
                        state <= state + 2'b01;
                    end else begin
                        state <= 2'b11;
                    end
                end else begin
                    // Decrement and saturate at 0 (2'b00)
                    if (state != 2'b00) begin
                        state <= state - 2'b01;
                    end else begin
                        state <= 2'b00;
                    end
                end
            end else begin
                // If not training, keep current value
                state <= state;
            end
        end
    end

endmodule