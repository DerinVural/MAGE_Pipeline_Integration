module TopModule (
    input  clk,
    input  reset,
    input  data,
    output [3:0] count,
    output counting,
    output done,
    input  ack
);

    // States
    localparam ST_SEARCH   = 4'd0;
    localparam ST_SHIFT    = 4'd1;
    localparam ST_COUNTING = 4'd2;
    localparam ST_WAIT_ACK = 4'd3;

    // Internal signals
    logic [3:0] state, state_next;
    logic [3:0] shift_reg;
    logic [3:0] delay;
    logic [10:0] counter;
    logic [3:0] count_out;

    // Sequential logic
    always @(posedge clk) begin
        if (reset)
            state <= ST_SEARCH;
        else
            state <= state_next;
    end

    // Shift register for detecting pattern 1101
    always @(posedge clk) begin
        if (reset) begin
            shift_reg <= 4'd0;
        end else begin
            shift_reg <= {shift_reg[2:0], data};
        end
    end

    // Counter for timing
    always @(posedge clk) begin
        if (reset) begin
            counter <= 11'd0;
        end else begin
            if (state == ST_COUNTING) begin
                if (counter == 0) begin
                    counter <= 11'd0;
                end else begin
                    counter <= counter - 1;
                end
            end else begin
                counter <= 11'd0;
            end
        end
    end

    // Delay register
    always @(posedge clk) begin
        if (reset) begin
            delay <= 4'd0;
        end else begin
            if (state == ST_SHIFT && shift_reg == 4'b1101) begin
                delay <= shift_reg;
            end
        end
    end

    // Count output
    always @(*) begin
        if (state == ST_COUNTING) begin
            count_out = delay;
        end else begin
            count_out = 4'd0;
        end
    end

    // State transition logic
    always @(*) begin
        state_next = state;
        case (state)
            ST_SEARCH: begin
                if (shift_reg == 4'b1101) begin
                    state_next = ST_SHIFT;
                end
            end
            ST_SHIFT: begin
                // After 4 bits, go to counting
                state_next = ST_COUNTING;
            end
            ST_COUNTING: begin
                if (counter == 0) begin
                    state_next = ST_WAIT_ACK;
                end
            end
            ST_WAIT_ACK: begin
                if (ack) begin
                    state_next = ST_SEARCH;
                end
            end
        endcase
    end

    // Outputs
    assign counting = (state == ST_COUNTING);
    assign done = (state == ST_WAIT_ACK);
    assign count = count_out;

endmodule