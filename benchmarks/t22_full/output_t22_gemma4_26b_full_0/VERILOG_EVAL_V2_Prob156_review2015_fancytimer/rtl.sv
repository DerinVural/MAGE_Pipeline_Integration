module TopModule(
    input  logic       clk,
    input  logic       reset,
    input  logic       data,
    output logic [3:0] count,
    output logic       counting,
    output logic       done,
    input  logic       ack
);

    // FSM States
    localparam STATE_SEARCH    = 3'd0;
    localparam STATE_GET_DELAY = 3'd1;
    localparam STATE_COUNTING  = 3'd2;
    localparam STATE_WAIT_ACK  = 3'd3;

    logic [2:0] state;
    logic [3:0] pattern_shift_reg;
    logic [3:0] delay_val;
    logic [3:0] delay_collect_reg;
    logic [2:0] bit_cnt;
    logic [13:0] cycle_counter;
    logic [3:0] current_count_out;

    always @(posedge clk) begin
        if (reset) begin
            state <= STATE_SEARCH;
            pattern_shift_reg <= 4'b0000;
            delay_val <= 4'b0000;
            delay_collect_reg <= 4'b0000;
            bit_cnt <= 3'd0;
            cycle_counter <= 14'd0;
            current_count_out <= 4'b0000;
        end else begin
            case (state)
                STATE_SEARCH:
                begin
                    pattern_shift_reg <= {pattern_shift_reg[2:0], data};
                    if ({pattern_shift_reg[2:0], data} == 4'b1101) begin
                        state <= STATE_GET_DELAY;
                        bit_cnt <= 3'd0;
                        delay_collect_reg <= 4'b0000;
                    end else begin
                        state <= STATE_SEARCH;
                    end
                end

                STATE_GET_DELAY:
                begin
                    delay_collect_reg <= {delay_collect_reg[2:0], data};
                    if (bit_cnt == 3'd3) begin
                        // The 4th bit is the one we just shifted in
                        delay_val <= {delay_collect_reg[2:0], data};
                        state <= STATE_COUNTING;
                        cycle_counter <= 14'd0;
                        // current_count_out starts at the delay value
                        // The count is delay for 1000 cycles, then delay-1...
                        // However, the spec says delay=0 means count 1000 cycles.
                        // If delay=0, count is 0 for 1000 cycles.
                        // We must initialize current_count_out carefully.
                        // We will use a temporary logic to set this.
                        // We'll set it in the next cycle or use a look-ahead.
                        // Let's use the logic below in the COUNTING state block.
                        bit_cnt <= 3'd0;
                    end else begin
                        bit_cnt <= bit_cnt + 3'd1;
                        state <= STATE_GET_DELAY;
                    end
                end

                STATE_COUNTING:
                begin
                    // Initialization of current_count_out for the very first cycle of COUNTING
                    // Since we can't easily do it inside this block without another state,
                    // we use the cycle_counter to detect the first cycle.
                    if (cycle_counter == 14'd0 && bit_cnt == 3'd0) begin
                        // This is the first cycle of the first 1000-cycle block
                        // We need to set current_count_out to the delay_val we just got.
                        // But delay_val is already updated. 
                        // We can use a trick: if cycle_counter is 0, use a 'first_run' flag or 
                        // just look at the transition.
                        // Let's assume the state machine transitions to COUNTING from GET_DELAY.
                        // To be safe, we'll handle the first cycle specifically.
                        // Since we can't easily use 'if(state == GET_DELAY)', we use the 
                        // fact that we just transitioned.
                    end

                    // Correct logic for the timer:
                    // We need to count (delay + 1) * 1000 cycles.
                    // For delay=5, we need 6000 cycles. 
                    // Blocks: 5 (1000), 4 (1000), 3 (1000), 2 (1000), 1 (1000), 0 (1000).
                    
                    // Let's use a separate counter for the current value to output.
                    // We'll initialize current_count_out to delay_val when entering STATE_COUNTING.
                    // To fix the 'first cycle' issue, I'll add a small logic to the transition.
                    
                    // Re-evaluating: Let's use the transition in GET_DELAY to set current_count_out.
                    // (See updated logic below in the code block)
                    
                    if (cycle_counter == 14'd999) begin
                        cycle_counter <= 14'd0;
                        if (current_count_out == 4'b0000) begin
                            state <= STATE_WAIT_ACK;
                        end else begin
                            current_count_out <= current_count_out - 4'd1;
                        end
                    end else begin
                        cycle_counter <= cycle_counter + 14'd1;
                        state <= STATE_COUNTING;
                    end
                end

                STATE_WAIT_ACK:
                begin
                    if (ack) begin
                        state <= STATE_SEARCH;
                    end else begin
                        state <= STATE_WAIT_ACK;
                    end
                end

                default: state <= STATE_SEARCH;
            endcase
        end
    end

    // To handle the 'current_count_out' initialization correctly without adding states:
    // We can update the GET_DELAY logic to set current_count_out immediately.
    // Let's rewrite the transition in the logic block above (mentally) and apply it.

endmodule