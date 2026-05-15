module TopModule (
    input clk,
    input reset,
    input in,
    output out
);

    // Define states
    localparam STATE_A = 2'b00;
    localparam STATE_B = 2'b01;
    localparam STATE_C = 2'b10;
    localparam STATE_D = 2'b11;

    // State register
    logic [1:0] state, next_state;

    // Initialize state
    initial begin
        state = STATE_A;
    end

    // Sequential logic - state register
    always @(posedge clk) begin
        if (reset)
            state <= STATE_A;
        else
            state <= next_state;
    end

    // Combinational logic - next state
    always @(*) begin
        case (state)
            STATE_A: begin
                if (in)
                    next_state = STATE_B;
                else
                    next_state = STATE_A;
            end
            STATE_B: begin
                if (in)
                    next_state = STATE_B;
                else
                    next_state = STATE_C;
            end
            STATE_C: begin
                if (in)
                    next_state = STATE_D;
                else
                    next_state = STATE_A;
            end
            STATE_D: begin
                if (in)
                    next_state = STATE_B;
                else
                    next_state = STATE_C;
            end
        endcase
    end

    // Output logic
    assign out = (state == STATE_D) ? 1'b1 : 1'b0;

endmodule