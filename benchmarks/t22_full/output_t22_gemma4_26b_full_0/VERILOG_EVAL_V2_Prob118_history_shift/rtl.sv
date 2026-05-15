module TopModule(
    input  logic        clk,
    input  logic        areset,
    input  logic        predict_valid,
    input  logic        predict_taken,
    input  logic        train_mispredicted,
    input  logic        train_taken,
    input  logic [31:0] train_history,
    output logic [31:0] predict_history
);

    // Internal history register
    logic [31:0] history_reg;

    // Initialize history to 0 to avoid X in simulation
    initial begin
        history_reg = 32'h0;
    end

    // Sequential logic for history update
    always @(posedge clk or posedge areset) begin
        if (areset) begin
            // Asynchronous reset
            history_reg <= 32'h0;
        end else begin
            // Misprediction takes precedence over prediction
            if (train_mispredicted) begin
                // Load history after completion: 
                // "history before (train_history) concatenated with actual result (train_taken)"
                // To maintain 32-bit width, we take the lower 31 bits of train_history and append train_taken.
                history_reg <= {train_history[30:0], train_taken};
            end else if (predict_valid) begin
                // Shift in predict_taken to LSB
                // predict_history[0] is the direction of the youngest branch.
                history_reg <= {history_reg[30:0], predict_taken};
            end
        end
    end

    // Continuous assignment for output
    assign predict_history = history_reg;

endmodule