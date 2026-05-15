module TopModule (
    input logic clk,
    input logic areset,
    input logic predict_valid,
    input logic predict_taken,
    input logic train_mispredicted,
    input logic train_taken,
    input logic [31:0] train_history,
    output logic [31:0] predict_history
);

    // Internal register to hold the branch history
    logic [31:0] history_reg;

    // Update the history register based on predictions
    always @(posedge clk or posedge areset) begin
        if (areset)
            history_reg <= 0;
        else if (predict_valid)
            history_reg <= {history_reg[30:0], predict_taken};
    end

    // Handle mispredictions by loading the train_history register
    always @(posedge clk or posedge areset) begin
        if (areset)
            history_reg <= 0;
        else if (train_mispredicted)
            history_reg <= {train_history, train_taken};
    end

    // Provide the current state of the branch history
    assign predict_history = history_reg;

endmodule