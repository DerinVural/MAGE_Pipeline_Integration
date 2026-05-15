module TopModule(
    input  logic clk,
    input  logic areset,
    input  logic predict_valid,
    input  logic predict_taken,
    input  logic train_mispredicted,
    input  logic train_taken,
    input  logic [31:0] train_history,
    output logic [31:0] predict_history
);

    // Internal register to hold the history state
    logic [31:0] predict_history_reg;

    // Assign the internal register to the output port
    assign predict_history = predict_history_reg;

    // Sequential logic for history update
    always @(posedge clk or posedge areset) begin
        if (areset)
        begin
            // Asynchronous reset sets history to zero
            predict_history_reg <= 32'h0;
        end
        else begin
            // 1. Misprediction takes precedence
            if (train_mispredicted)
            begin
                // Load new history: {History Before Mispredict, Actual Taken Bit}
                // train_history is 32 bits, train_taken is 1 bit. 
                // Concatenating them places train_history in MSB and train_taken in LSB (index 0).
                predict_history_reg <= {train_history, train_taken};
            end
            // 2. Prediction update (Shift in) if no misprediction
            else if (predict_valid)
            begin
                // Shift in predict_taken (youngest branch) at LSB (index 0).
                // Old history bits shift left: {History[30:0], new_bit}
                predict_history_reg <= {predict_history_reg[30:0], predict_taken};
            end
            // 3. Hold state if no updates occur
            else begin
                predict_history_reg <= predict_history_reg;
            end
        end
    end

endmodule