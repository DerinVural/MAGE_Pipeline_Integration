module TopModule(
    input  logic        clk,
    input  logic        areset,
    input  logic        predict_valid,
    input  logic [6:0]  predict_pc,
    output logic        predict_taken,
    output logic [6:0]  predict_history,
    input  logic        train_valid,
    input  logic        train_taken,
    input  logic        train_mispredicted,
    input  logic [6:0]  train_history,
    input  logic [6:0]  train_pc
);

    // PHT: 128 entries, 2-bit counters
    logic [1:0] pht [0:127];
    logic [6:0] ghr;

    // Combinational logic for prediction
    logic [6:0] pred_index;
    logic [1:0] pred_pht_val;

    assign pred_index = predict_pc ^ ghr;
    assign pred_pht_val = pht[pred_index];

    // Output assignments
    // predict_taken is 1 if the counter is 2 or 3
    assign predict_taken = (pred_pht_val >= 2'b10);
    // predict_history is the GHR used to make the prediction
    assign predict_history = ghr;

    // Sequential logic for GHR and PHT
    always @(posedge clk or posedge areset) begin
        if (areset) begin
            ghr <= 7'b0;
            for (int i = 0; i < 128; i++) begin
                pht[i] <= 2'b01; // Initialize PHT to a neutral state (weakly not taken or weakly taken? spec doesn't say, but 01 is common)
            end
        end else begin
            // 1. Update PHT
            if (train_valid) begin
                logic [6:0] t_idx;
                t_idx = train_pc ^ train_history;
                if (train_taken) begin
                    if (pht[t_idx] < 2'b11) 
                        pht[t_idx] <= pht[t_idx] + 1'b1;
                end else begin
                    if (pht[t_idx] > 2'b00) 
                        pht[t_idx] <= pht[t_idx] - 1'b1;
                end
            end

            // 2. Update GHR
            // Priority: training misprediction recovery > prediction speculative update
            if (train_valid && train_mispredicted) begin
                ghr <= train_history;
            end else if (predict_valid) begin
                // Speculative update: shift in the predicted outcome
                ghr <= {ghr[5:0], predict_taken};
            end
        end
    end

    // Note: The spec says PHT is initialized but doesn't specify the value. 
    // 2'b01 (weakly not taken) is a safe default.
    // The initialization of PHT in the reset block is necessary for a clean start.

endmodule