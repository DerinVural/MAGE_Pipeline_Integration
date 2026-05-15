module TopModule(
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

    // Parameters
    localparam INDEX_WIDTH = 7;
    localparam TABLE_SIZE = 128;
    localparam COUNTER_BITS = 2;

    // Registers
    logic [INDEX_WIDTH-1:0] global_history;
    logic [TABLE_SIZE*COUNTER_BITS-1:0] pht;
    logic [COUNTER_BITS-1:0] counter;

    // Signals
    reg [INDEX_WIDTH-1:0] index;
    logic [COUNTER_BITS-1:0] old_counter;
    logic [COUNTER_BITS-1:0] new_counter;
    reg [INDEX_WIDTH-1:0] old_index;
    logic [COUNTER_BITS-1:0] train_counter;

    // Initialize PHT and Global History
    initial begin
        pht <= 0;
        global_history <= 0;
    end

    // Reset logic
    always_ff @(posedge clk or posedge areset) begin
        if (areset) begin
            global_history <= 0;
        end else begin
            global_history <= predict_history;
        end
    end

    // Prediction
    always_comb begin
        index = predict_pc ^ global_history;
        old_counter = pht[(index * COUNTER_BITS)];
        predict_taken = old_counter == 2'b11 ? 1'b1 : 1'b0;
        predict_history = global_history;
    end

    // Training
    always @(posedge clk) begin
        if (train_valid) begin
            index = train_pc ^ global_history;
            old_counter = pht[(index * COUNTER_BITS)];
            new_counter = train_taken ? (old_counter == 2'b11 ? old_counter : old_counter + 1) : (old_counter == 2'b00 ? old_counter : old_counter - 1);
            pht[(index * COUNTER_BITS)] <= new_counter;
        end
    end

endmodule;