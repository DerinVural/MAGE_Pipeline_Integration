module TopModule (
    input  logic clk,
    input  logic reset,
    input  logic data,
    output logic [3:0] count,
    output logic counting,
    output logic done,
    input  logic ack
);

    // FSM States
    localparam STATE_SEARCH    = 3'd0;
    localparam STATE_GET_DELAY = 3'd1;
    localparam STATE_COUNTING  = 3'd2;
    localparam STATE_DONE      = 3'd3;
    localparam STATE_WAIT_ACK  = 3'd4;

    logic [2:0] state;
    logic [3:0] pattern_reg;
    logic [1:0] shift_cnt;
    logic [3:0] delay_reg;
    logic [13:0] timer_cnt;

    // Initialize signals to avoid X in simulation
    initial begin
        state = STATE_SEARCH;
        pattern_reg = 4'b0000;
        shift_cnt = 2'b00;
        delay_reg = 4'b0000;
        timer_cnt = 14'd0;
    end

    // Sequential logic
    always @(posedge clk) begin
        if (reset) begin
            state <= STATE_SEARCH;
            pattern_reg <= 4'b0000;
            shift_cnt <= 2'b00;
            delay_reg <= 4'b0000;
            timer_cnt <= 14'd0;
        end else begin
            case (state)
                STATE_SEARCH:
                    begin
                        pattern_reg <= {pattern_reg[2:0], data};
                        if ({pattern_reg[2:0], data} == 4'b1101) begin
                            state <= STATE_GET_DELAY;
                            shift_cnt <= 2'd0;
                            delay_reg <= 4'd0;
                        end else begin
                            state <= STATE_SEARCH;
                        end
                    end

                STATE_GET_DELAY:
                    begin
                        // Shift in 4 bits, MSB first
                        // To achieve MSB first, the first bit comes in and is shifted left
                        delay_reg <= {delay_reg[2:0], data};
                        if (shift_cnt == 2'd3) begin
                            state <= STATE_COUNTING;
                            shift_cnt <= 2'd0;
                            timer_cnt <= 14'd0;
                        end else begin
                            shift_cnt <= shift_cnt + 1'b1;
                        end
                    end

                STATE_COUNTING:
                    begin
                        // Total cycles = (delay + 1) * 1000
                        // timer_cnt goes from 0 to target-1
                        if (timer_cnt == (delay_reg + 4'd1) * 1000 - 1) begin
                            state <= STATE_DONE;
                            timer_cnt <= 14'd0;
                        end else begin
                            timer_cnt <= timer_cnt + 1'b1;
                        end
                    end

                STATE_DONE:
                    begin
                        // State is DONE, timer is finished.
                        // We stay in DONE or transition to WAIT_ACK.
                        // Spec says: "assert done ... and waits until input ack is 1"
                        // We'll treat STATE_DONE and STATE_WAIT_ACK together or just check ack in DONE.
                        if (ack) begin
                            state <= STATE_SEARCH;
                            pattern_reg <= 4'b0000;
                        end else begin
                            state <= STATE_DONE;
                        end
                    end

                default:
                    begin
                        state <= STATE_SEARCH;
                    end
            endcase
        end
    end

    // Combinational output logic
    always @(*)
    begin
        counting = (state == STATE_COUNTING);
        done     = (state == STATE_DONE);
        
        if (state == STATE_COUNTING) begin
            // count = delay for 1000 cycles, then delay-1, etc.
            // timer_cnt / 1000 will be 0 for the first 1000 cycles (0-999)
            // 1 for next 1000 (1000-1999), etc.
            count = delay_reg - (timer_cnt / 1000);
        end else begin
            count = 4'b0000;
        end
    end

endmodule