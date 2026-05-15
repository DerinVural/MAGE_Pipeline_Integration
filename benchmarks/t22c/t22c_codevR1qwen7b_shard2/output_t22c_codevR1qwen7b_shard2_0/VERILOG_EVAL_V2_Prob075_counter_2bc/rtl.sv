module TopModule (
    input clk,
    input areset,
    input train_valid,
    input train_taken,
    output logic [1:0] state
);

    // Initialize state to 01 on reset, else update logic
    logic [1:0] next_state;

    always @(*) begin
        if (areset) begin
            next_state = 2'b01;
        end else begin
            if (!train_valid) begin
                next_state = state;
            end else begin
                if (train_taken) begin
                    next_state = (state == 2'b11) ? state : state + 1;
                end else begin
                    next_state = (state == 2'b00) ? state : state - 1;
                end
            end
        end
    end

    // Sequential logic with asynchronous reset
    always @(posedge clk or posedge areset) begin
        if (areset) begin
            state <= 2'b01;
        end else begin
            state <= next_state;
        end
    end

endmodule