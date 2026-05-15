module TopModule (
    input clk,
    input areset,
    input predict_valid,
    input [6:0] predict_pc,
    output logic predict_taken,
    output logic [6:0] predict_history,
    input train_valid,
    input train_taken,
    input train_mispredicted,
    input [6:0] train_history,
    input [6:0] train_pc
);

    // Parameters for PHT
    localparam PHT_SIZE = 128;
    localparam COUNTER_WIDTH = 2;
    localparam STATE_IDLE = 0;
    localparam STATE_PREDICT = 1;
    localparam STATE_TRAIN = 2;

    // Internal signals
    logic [6:0] history_reg;
    logic [COUNTER_WIDTH-1:0] pht [0:PHT_SIZE-1];
    logic [1:0] state, next_state;

    // PHT index calculation
    logic [6:0] pht_index;
    assign pht_index = predict_pc ^ history_reg;

    // Counter update logic
    always @(*) begin
        if (pht[pht_index] == 2'b00) begin
            predict_taken = 0;
        end else if (pht[pht_index] == 2'b11) begin
            predict_taken = 1;
        end else begin
            predict_taken = pht[pht_index][1];
        end
    end

    // State machine sequential logic
    always @(posedge clk) begin
        if (areset) begin
            state <= STATE_IDLE;
            history_reg <= 7'b0;
            for (int i = 0; i < PHT_SIZE; i++) begin
                pht[i] <= 2'b10;
            end
        end else begin
            state <= next_state;
        end
    end

    // Next state logic
    always @(*) begin
        next_state = state;
        case (state)
            STATE_IDLE: begin
                if (predict_valid) begin
                    next_state = STATE_PREDICT;
                end else if (train_valid) begin
                    next_state = STATE_TRAIN;
                end else begin
                    next_state = STATE_IDLE;
                end
            end
            STATE_PREDICT: begin
                history_reg = (history_reg << 1) | predict_taken;
                next_state = STATE_IDLE;
            end
            STATE_TRAIN: begin
                if (train_mispredicted) begin
                    history_reg = train_history;
                end
                if (train_valid) begin
                    if (train_taken) begin
                        if (pht[train_pc ^ train_history] < 2'b11) begin
                            pht[train_pc ^ train_history] = pht[train_pc ^ train_history] + 1;
                        end
                    end else begin
                        if (pht[train_pc ^ train_history] > 2'b00) begin
                            pht[train_pc ^ train_history] = pht[train_pc ^ train_history] - 1;
                        end
                    end
                end
                next_state = STATE_IDLE;
            end
            default: next_state = STATE_IDLE;
        endcase
    end

    // Combinational prediction output
    assign predict_history = history_reg;

endmodule