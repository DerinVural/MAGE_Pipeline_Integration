module TopModule (
    input clk,
    input areset,
    input train_valid,
    input train_taken,
    output logic [1:0] state
);

    // Sequential logic for the counter
    always @(posedge clk or posedge areset) begin
        if (areset)
            state <= 2'b01;  // Reset to weakly not taken
        else if (train_valid) begin
            if (train_taken)
                state <= (state == 2'b11) ? 2'b11 : state + 1;
            else
                state <= (state == 2'b00) ? 2'b00 : state - 1;
        end
    end

endmodule