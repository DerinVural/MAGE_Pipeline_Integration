module TopModule(
    input  logic       clk,
    input  logic       areset,
    input  logic       predict_valid,
    input  logic [6:0] predict_pc,
    output logic       predict_taken,
    output logic [6:0] predict_history,
    input  logic       train_valid,
    input  logic       train_taken,
    input  logic       train_mispredicted,
    input  logic [6:0] train_history,
    input  logic [6:0] train_pc
);

    // Pattern History Table: 128 entries, 2-bit saturating counters
    logic [1:0] pht [0:127];
    // Global History Register
    logic [6:0] ghr;

    // Initialize PHT and GHR to avoid X-propagation in simulation
    initial begin
        for (int i = 0; i < 128; i++) begin
            pht[i] = 2'b01;
        end
        ghr = 7'b0;
    end

    // Internal wires for combinational prediction logic
    logic [6:0] pred_idx_wire;
    logic [1:0] pred_pht_val;

    // Sequential Logic: PHT Update and GHR Update
    always @(posedge clk or posedge areset) begin
        if (areset) begin
            ghr <= 7'b0;
            for (int i = 0; i < 128; i++) begin
                pht[i] <= 2'b01;
            end
        end else begin
            // 1. PHT Update (Training)
            if (train_valid) begin
                logic [6:0] train_idx;
                train_idx = train_pc ^ train_history;
                if (train_taken) begin
                    if (pht[train_idx] < 2'b11) 
                        pht[train_idx] <= pht[train_idx] + 1'b1;
                end else begin
                    if (pht[train_idx] > 2'b00) 
                        pht[train_idx] <= pht[train_idx] - 1'b1;
                end
            end

            // 2. GHR Update
            // Priority: Training Misprediction Recovery > Prediction Update
            if (train_valid && train_mispredicted) begin
                ghr <= train_history;
            end else if (predict_valid) begin
                // Shift in the bit that was predicted (MSB of current counter)
                // pred_pht_val is the combinational value of the entry
                ghr <= {ghr[5:0], pred_pht_val[1]};
            end
        end
    end

    // Combinational Logic for Prediction
    always @(*) begin
        pred_idx_wire = predict_pc ^ ghr;
        pred_pht_val = pht[pred_idx_wire];
        
        if (predict_valid) begin
            predict_taken = pred_pht_val[1];
            predict_history = ghr;
        end else begin
            predict_taken = 1'b0;
            predict_history = 7'b0;
        end
    end

endmodule