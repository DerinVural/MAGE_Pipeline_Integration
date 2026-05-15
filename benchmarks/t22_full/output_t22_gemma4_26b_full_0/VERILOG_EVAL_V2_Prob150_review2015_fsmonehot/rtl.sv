module TopModule(
    input  logic d,
    input  logic done_counting,
    input  logic ack,
    input  logic [9:0] state,
    output logic B3_next,
    output logic S_next,
    output logic S1_next,
    output logic Count_next,
    output logic Wait_next,
    output logic done,
    output logic counting,
    output logic shift_ena
);

    // One-hot state encoding
    // (S, S1, S11, S110, B0, B1, B2, B3, Count, Wait)
    localparam logic [9:0] STATE_S     = 10'b0000000001;
    localparam logic [9:0] STATE_S1    = 10'b0000000010;
    localparam logic [9:0] STATE_S11   = 10'b0000000100;
    localparam logic [9:0] STATE_S110  = 10'b0000001000;
    localparam logic [9:0] STATE_B0    = 10'b0000010000;
    localparam logic [9:0] STATE_B1    = 10'b0000100000;
    localparam logic [9:0] STATE_B2    = 10'b0001000000;
    localparam logic [9:0] STATE_B3    = 10'b0010000000;
    localparam logic [9:0] STATE_COUNT = 10'b0100000000;
    localparam logic [9:0] STATE_WAIT  = 10'b1000000000;

    logic [9:0] next_state;

    // Next state combinational logic
    always @(*) begin
        next_state = 10'b0;
        if (state & STATE_S) begin
            if (d) next_state = STATE_S1;
            else   next_state = STATE_S;
        end
        else if (state & STATE_S1) begin
            if (d) next_state = STATE_S11;
            else   next_state = STATE_S;
        end
        else if (state & STATE_S11) begin
            if (d) next_state = STATE_S11;
            else   next_state = STATE_S110;
        end
        else if (state & STATE_S110) begin
            if (d) next_state = STATE_B0;
            else   next_state = STATE_S;
        end
        else if (state & STATE_B0) begin
            next_state = STATE_B1;
        end
        else if (state & STATE_B1) begin
            next_state = STATE_B2;
        end
        else if (state & STATE_B2) begin
            next_state = STATE_B3;
        end
        else if (state & STATE_B3) begin
            next_state = STATE_COUNT;
        end
        else if (state & STATE_COUNT) begin
            if (done_counting) next_state = STATE_WAIT;
            else                next_state = STATE_COUNT;
        end
        else if (state & STATE_WAIT) begin
            if (ack) next_state = STATE_S;
            else     next_state = STATE_WAIT;
        end
        else begin
            // Default/don't care case: stay in S if no state matches
            next_state = STATE_S;
        end
    end

    // Output logic (Moore machine: outputs depend on current state)
    // However, the spec asks for shift_ena, counting, and done based on current state.
    // And specific next_state signals.

    // shift_ena is 1 in B0, B1, B2, B3
    assign shift_ena = (state & (STATE_B0 | STATE_B1 | STATE_B2 | STATE_B3)) != 0;
    
    // counting is 1 in Count state
    assign counting = (state & STATE_COUNT) != 0;
    
    // done is 1 in Wait state
    assign done = (state & STATE_WAIT) != 0;

    // Next-state indicators
    assign B3_next   = (next_state & STATE_B3)   != 0;
    assign S_next    = (next_state & STATE_S)    != 0;
    assign S1_next   = (next_state & STATE_S1)   != 0;
    assign Count_next = (next_state & STATE_COUNT) != 0;
    assign Wait_next  = (next_state & STATE_WAIT)  != 0;

endmodule