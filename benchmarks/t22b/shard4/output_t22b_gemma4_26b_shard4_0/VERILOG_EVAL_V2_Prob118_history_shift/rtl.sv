module TopModule (
    input  logic clk,
    input  logic areset,
    input  logic predict_valid,
    input  logic predict_taken,
    input  logic train_mispredicted,
    input  logic train_taken,
    input  logic [31:0] train_history,
    output logic [31:0] predict_history
);

    // Internal register for history
    logic [31:0] history_reg;

    // Initialize to 0 to avoid X in simulation
    initial begin
        history_reg = 32'h0;
    end

    // Sequential logic for history update
    always @(posedge clk or posedge areset) begin
        if (areset) begin
            history_reg <= 32'h0;
        end else begin
            if (train_mispredicted) begin
                // Misprediction takes precedence.
                // Load history after the completion of the mispredicted branch.
                // This is (history before the branch) concatenated with (actual result).
                // train_history is the history before the mispredicted branch.
                history_reg <= {train_history[30:0], train_taken};
            end else if (predict_valid) begin
                // Shift in predict_taken to the LSB side.
                // predict_history[0] is the direction of the youngest branch.
                history_reg <= {history_reg[30:0], predict_taken};
            end else begin
                // Maintain current state
                history_reg <= history_reg;
            end
        end
    end

    // Continuous assignment for the output
    assign predict_history = history_reg;

endmodule