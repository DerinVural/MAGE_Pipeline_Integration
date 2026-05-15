module TopModule (
    input  logic       clk,
    input  logic       areset,
    input  logic       train_valid,
    input  logic       train_taken,
    output logic [1:0] state
);

    // Sequential logic for the saturating counter
    always @(posedge clk or posedge areset) begin
        if (areset) begin
            // Asynchronous reset to weakly not-taken (2'b01)
            state <= 2'b01;
        end else begin
            if (train_valid) begin
                if (train_taken) begin
                    // Increment if not at maximum (3)
                    if (state < 2'b11) begin
                        state <= state + 1'b1;
                    end
                end else begin
                    // Decrement if not at minimum (0)
                    if (state > 2'b00) begin
                        state <= state - 1'b1;
                    end
                end
            end
            // If train_valid is 0, state remains unchanged
        end
    end

endmodule