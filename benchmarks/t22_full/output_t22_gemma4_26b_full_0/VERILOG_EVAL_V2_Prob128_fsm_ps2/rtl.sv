module TopModule(
    input  logic       clk,
    input  logic       reset,
    input  logic [7:0] in,
    output logic       done
);

    // State encoding
    localparam STATE_SEARCH      = 2'b00;
    localparam STATE_WAIT_B2     = 2'b01;
    localparam STATE_WAIT_B3     = 2'b10;
    localparam STATE_SIGNAL_DONE = 2'b11;

    logic [1:0] state;
    logic [1:0] state_next;

    // Sequential logic
    always @(posedge clk) begin
        if (reset) begin
            state <= STATE_SEARCH;
        end else begin
            state <= state_next;
        end
    end

    // Next state combinational logic
    always @(*) begin
        state_next = state;
        case (state)
            STATE_SEARCH:
                if (in[3] == 1'b1) begin
                    state_next = STATE_WAIT_B2;
                end else begin
                    state_next = STATE_SEARCH;
                end
            
            STATE_WAIT_B2:
                state_next = STATE_WAIT_B3;

            STATE_WAIT_B3:
                state_next = STATE_SIGNAL_DONE;

            STATE_SIGNAL_DONE:
                // After signaling done, we look for the next message.
                // We check if the byte that caused the 'done' (the 3rd byte) 
                // could also be the start of a new message.
                // However, standard FSM for stream parsing usually transitions 
                // back to search to avoid ambiguity unless specified.
                // Let's check if the current 'in' (which is the 3rd byte) 
                // could be the 1st byte of the next message.
                // But the spec says 'signal done in the cycle immediately AFTER
                // the third byte'. This implies the transition is:
                // B1 (in[3]=1) -> B2 -> B3 -> Done (cycle after B3).
                // In the cycle of 'done', we are effectively consuming the 3rd byte.
                // To handle overlapping or back-to-back, we check in[3] again.
                if (in[3] == 1'b1) begin
                    state_next = STATE_WAIT_B2;
                end else begin
                    state_next = STATE_SEARCH;
                end

            default:
                state_next = STATE_SEARCH;
        endcase
    end

    // Output logic
    always @(*) begin
        if (state == STATE_SIGNAL_DONE) begin
            done = 1'b1;
        end else begin
            done = 1'b0;
        end
    end

endmodule