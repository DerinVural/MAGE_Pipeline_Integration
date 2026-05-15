module TopModule (
    input clk,
    input reset,
    input data,
    input done_counting,
    input ack,
    output logic shift_ena,
    output logic counting,
    output logic done
);

    // State definitions
    localparam IDLE = 3'd0;
    localparam DETECT = 3'd1;
    localparam SHIFT_ENA = 3'd2;
    localparam COUNTING = 3'd3;
    localparam DONE_WAIT = 3'd4;
    localparam ACK_WAIT = 3'd5;

    logic [2:0] state, next_state;
    logic [3:0] shift_count;
    logic [3:0] shift_reg;

    // Initialize states and counters
    initial begin
        state = IDLE;
        shift_count = 0;
        shift_reg = 4'b0;
        shift_ena = 0;
        counting = 0;
        done = 0;
    end

    // State transition
    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    // Next state logic
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (shift_reg == 4'b1101) begin
                    next_state = DETECT;
                end
            end
            DETECT: begin
                if (shift_count == 4) begin
                    next_state = SHIFT_ENA;
                end else begin
                    next_state = DETECT;
                end
            end
            SHIFT_ENA: begin
                if (shift_count == 4) begin
                    next_state = COUNTING;
                end else begin
                    next_state = SHIFT_ENA;
                end
            end
            COUNTING: begin
                if (done_counting) begin
                    next_state = DONE_WAIT;
                end else begin
                    next_state = COUNTING;
                end
            end
            DONE_WAIT: begin
                done = 1;
                if (ack) begin
                    next_state = IDLE;
                end else begin
                    next_state = DONE_WAIT;
                end
            end
            default: next_state = IDLE;
        endcase
    end

    // Combinational outputs for shift_reg and shift_count
    always @(posedge clk) begin
        if (state == IDLE) begin
            shift_reg <= {shift_reg[2:0], data};
        end else if (state == DETECT) begin
            shift_reg <= {shift_reg[2:0], data};
        end
    end

    // Counter for shift_ena and counting duration
    always @(posedge clk) begin
        if (state == IDLE || state == DONE_WAIT) begin
            shift_count <= 0;
        end else if (state == DETECT || state == SHIFT_ENA) begin
            if (shift_count < 4) begin
                shift_count <= shift_count + 1;
            end
        end
    end

    // Output logic
    always @(*) begin
        shift_ena = 0;
        counting = 0;
        done = 0;
        case (state)
            SHIFT_ENA: shift_ena = 1;
            COUNTING: counting = 1;
            DONE_WAIT: done = 1;
            default: begin
                shift_ena = 0;
                counting = 0;
                done = 0;
            end
        endcase
    end

endmodule