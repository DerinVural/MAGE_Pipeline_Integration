module stimulus_gen (
    input logic clk,
    output logic areset,
    output logic predict_valid,
    output logic predict_taken,
    output logic train_mispredicted,
    output logic train_taken,
    output logic [31:0] train_history,
    input tb_match,
    output logic [511:0] wavedrom_title,
    output logic wavedrom_enable,
    output logic wavedrom_hide_after_time
);

localparam TRAIN = 0, PREDICT = 1;

logic state;
logic [31:0] timer;
logic error_detected;
logic [31:0] history_reg;
logic [31:0] history_reg_temp;

initial begin
    state = TRAIN;
    timer = 0;
    error_detected = 0;
    history_reg = 0;
    areset = 1;
    predict_valid = 0;
    train_mispredicted = 0;
    train_taken = 0;
    wavedrom_title = 0;
    wavedrom_enable = 0;
    wavedrom_hide_after_time = 0;
end

always @(posedge clk) begin
    if (timer >= 1000) begin
        areset <= 0;
        timer <= 0;
    end else begin
        timer <= timer + 1;
    end
end

always @(posedge clk) begin
    if (areset) begin
        state <= TRAIN;
        timer <= 0;
    end else begin
        timer <= timer + 1;
        case (state)
            TRAIN: if (timer % 50 == 0) state <= PREDICT;
            PREDICT: begin
                if (timer % 100 == 0) state <= TRAIN;
                if (timer % 10 == 0 && !error_detected) begin
                    predict_valid <= 1;
                    predict_taken <= (timer % 2 == 0);
                end
            end
        endcase
    end
end

always @(posedge clk) begin
    if (train_mispredicted) begin
        history_reg <= {history_reg[30:0], train_taken};
    end else if (predict_valid && tb_match && !train_mispredicted) begin
        history_reg <= {history_reg[30:0], predict_taken};
    end
end

assign train_history = history_reg;

always @(posedge clk) begin
    if (timer >= 10000 && !error_detected) begin
        error_detected <= 1;
        wavedrom_title <= "Timeout";
        wavedrom_enable <= 1;
        wavedrom_hide_after_time <= 5000;
    end
end

always @(posedge clk) begin
    if (state == PREDICT && predict_valid)
        wavedrom_enable <= 1;
    else if (error_detected)
        wavedrom_enable <= 0;
end

endmodule

module tb();
    reg clk;
    reg tb_match;
    wire [31:0] train_history;
    wire [31:0] predict_history;
endmodule