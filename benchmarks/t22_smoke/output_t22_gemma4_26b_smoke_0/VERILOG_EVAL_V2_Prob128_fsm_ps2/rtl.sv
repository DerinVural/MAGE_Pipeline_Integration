module TopModule(
    input  logic       clk,
    input  logic       reset,
    input  logic [7:0] in,
    output logic       done
);

    // State definitions
    localparam STATE_IDLE  = 2'b00;
    localparam STATE_BYTE2 = 2'b01;
    localparam STATE_BYTE3 = 2'b10;
    localparam STATE_DONE  = 2'b11;

    logic [1:0] state;
    logic [1:0] state_next;

    // Sequential logic
    always @(posedge clk) begin
        if (reset) begin
            state <= STATE_IDLE;
        end else begin
            state <= state_next;
        end
    end

    // Next state combinational logic
    always @(*) begin
        state_next = state;
        case (state)
            STATE_IDLE:
                if (in[3])
                    state_next = STATE_BYTE2;
                else
                    state_next = STATE_IDLE;

            STATE_BYTE2:
                state_next = STATE_BYTE3;

            STATE_BYTE3:
                state_next = STATE_DONE;

            STATE_DONE:
                if (in[3])
                    state_next = STATE_BYTE2;
                else
                    state_next = STATE_IDLE;

            default:
                state_next = STATE_IDLE;
        endcase
    end

    // Output logic
    // done is high in the cycle immediately after the third byte is received.
    // Since the transition to STATE_DONE happens after the 3rd byte is clocked in,
    // being in STATE_DONE means the 3rd byte was received in the previous cycle.
    always @(*) begin
        if (state == STATE_DONE) 
            done = 1'b1;
        else
            done = 1'b0;
    end

endmodule