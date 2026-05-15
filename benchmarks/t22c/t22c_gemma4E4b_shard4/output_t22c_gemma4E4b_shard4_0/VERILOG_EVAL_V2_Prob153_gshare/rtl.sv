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

    // --- Parameters and Constants ---
    localparam PHT_SIZE = 128;
    localparam COUNTER_BITS = 2;

    // --- State Registers ---
    // Global History Register (GHR): 7 bits
    logic [6:0] ghr;

    // Pattern History Table (PHT): 128 entries, 2-bit counters
    logic [COUNTER_BITS-1:0] pht[PHT_SIZE:0];

    // --- Combinational Logic: Prediction ---
    // Calculate PHT index using XOR of PC and GHR
    logic [6:0] pht_index_predict;
    assign pht_index_predict = predict_pc ^ ghr;

    // Read PHT and determine prediction
    logic [COUNTER_BITS-1:0] pht_read_predict;
    assign pht_read_predict = pht[pht_index_predict];

    // Predict Taken if counter >= 2 (i.e., 10 or 11)
    assign predict_taken = pht_read_predict[1]; // MSB of 2-bit counter

    // Output history is the current GHR value
    assign predict_history = ghr;

    // --- Initialization Block (Non-reset initialization) ---
    initial begin
        // Initialize PHT counters to 00 (Strongly Not Taken)
        for (int i = 0; i < PHT_SIZE; i = i + 1) begin
            pht[i] = 2'b00;
        end
        // Initialize GHR to 0
        ghr = 7'b0;
    end

    // --- Sequential Logic: GHR Update and PHT Update ---
    always @(posedge clk)
    begin
        if (areset)
        begin
            // Asynchronous high reset
            ghr <= 7'b0;
            // Reset PHT counters to 00 (Strongly Not Taken)
            for (int i = 0; i < PHT_SIZE; i = i + 1) begin
                pht[i] <= 2'b00;
            end
        end
        else
        begin
            // 1. GHR Update (Update based on training outcome)
            if (train_valid) begin
                // Update GHR based on the true outcome known during training.
                // {ghr[5:0], train_taken} shifts the old history and appends the new outcome.
                ghr <= {ghr[5:0], train_taken};
            end

            // 2. PHT Update (Training)
            if (train_valid) begin
                // Variables declared in scope of sequential block
                logic [6:0] pht_index_train;
                logic [COUNTER_BITS-1:0] counter_in;
                logic [COUNTER_BITS-1:0] counter_out;

                // Calculate index using current GHR value
                pht_index_train = train_pc ^ ghr;

                // Read current PHT state
                counter_in = pht[pht_index_train];

                if (train_taken) begin // Branch was Taken
                    case (counter_in) 
                        2'b00: counter_out = 2'b01; // Not Taken -> Weakly Taken
                        2'b01: counter_out = 2'b10; // Weakly Taken -> Weakly Taken
                        2'b10: counter_out = 2'b11; // Weakly Taken -> Strongly Taken
                        2'b11: counter_out = 2'b11; // Strongly Taken -> Strongly Taken
                        default: counter_out = 2'b00;
                    endcase
                end else begin // Branch was Not Taken
                    case (counter_in) 
                        2'b00: counter_out = 2'b00; // Strongly Not Taken -> Strongly Not Taken
                        2'b01: counter_out = 2'b00; // Weakly Not Taken -> Strongly Not Taken
                        2'b10: counter_out = 2'b01; // Weakly Taken -> Weakly Not Taken
                        2'b11: counter_out = 2'b10; // Strongly Taken -> Weakly Taken
                        default: counter_out = 2'b00;
                    endcase
                end
                pht[pht_index_train] <= counter_out;
            end
        end
    end

endmodule