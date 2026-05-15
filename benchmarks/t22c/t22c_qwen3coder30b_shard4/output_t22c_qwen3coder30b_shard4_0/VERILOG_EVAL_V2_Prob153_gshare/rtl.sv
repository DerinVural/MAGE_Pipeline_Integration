module TopModule (
    input logic clk,
    input logic areset,

    input logic predict_valid,
    input logic [6:0] predict_pc,
    output logic predict_taken,
    output logic [6:0] predict_history,

    input logic train_valid,
    input logic train_taken,
    input logic train_mispredicted,
    input logic [6:0] train_history,
    input logic [6:0] train_pc
);

    // Global history register (7 bits)
    logic [6:0] ghr;
    
    // Pattern history table (128 entries, 2-bit saturating counters)
    logic [1:0] pht [0:127];
    
    // Internal signals
    logic [6:0] index;
    logic [1:0] pht_entry;
    logic predict_taken_reg;
    logic [6:0] predict_history_reg;
    
    // Compute hash index from PC and GHR
    assign index = predict_pc ^ ghr;
    
    // Read from PHT
    assign pht_entry = pht[index];
    
    // Predict branch direction
    always @(*) begin
        if (pht_entry == 2'b11 || pht_entry == 2'b10)
            predict_taken_reg = 1'b1;
        else
            predict_taken_reg = 1'b0;
    end
    
    // Update predict_taken and predict_history
    assign predict_taken = predict_taken_reg;
    assign predict_history = predict_history_reg;
    
    // Sequential logic
    always @(posedge clk or posedge areset) begin
        if (areset) begin
            ghr <= 7'b0;
            predict_history_reg <= 7'b0;
        end else begin
            // Handle prediction
            if (predict_valid) begin
                predict_history_reg <= ghr;
            end
            
            // Handle training
            if (train_valid) begin
                // Update GHR with actual branch outcome
                if (train_mispredicted) begin
                    // Recover GHR to state before misprediction
                    ghr <= train_history;
                end else begin
                    // Update GHR with actual branch outcome
                    ghr <= {ghr[5:0], train_taken};
                end
                
                // Update PHT
                case (pht_entry)
                    2'b00: if (train_taken) pht[index] <= 2'b01;
                    2'b01: if (train_taken) pht[index] <= 2'b10;
                    2'b10: if (~train_taken) pht[index] <= 2'b01;
                    2'b11: if (~train_taken) pht[index] <= 2'b10;
                endcase
            end
        end
    end

endmodule