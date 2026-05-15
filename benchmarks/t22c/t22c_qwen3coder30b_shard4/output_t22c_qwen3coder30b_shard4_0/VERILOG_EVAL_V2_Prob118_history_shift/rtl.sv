module TopModule (
    input clk,
    input areset,
    input predict_valid,
    input predict_taken,
    input train_mispredicted,
    input train_taken,
    input [31:0] train_history,
    output [31:0] predict_history
);

    logic [31:0] history;

    always @(posedge clk or negedge areset) begin
        if (!areset)
            history <= 32'd0;
        else if (train_mispredicted) begin
            // Load history with train_history concatenated with train_taken
            history <= {train_history[30:0], train_taken};
        end
        else if (predict_valid) begin
            // Shift in predict_taken from LSB side
            history <= {history[30:0], predict_taken};
        end
    end

    assign predict_history = history;

endmodule