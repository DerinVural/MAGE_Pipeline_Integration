module TopModule (
    input  logic clk,
    input  logic areset,
    input  logic j,
    input  logic k,
    output logic out
);

    // State encoding
    localparam STATE_OFF = 1'b0;
    localparam STATE_ON  = 1'b1;

    // State registers
    logic state;
    logic state_next;

    // Initialize state to avoid X
    initial begin
        state = STATE_OFF;
    end

    // Sequential logic for state transition
    always @(posedge clk or posedge areset) begin
        if (areset) begin
            state <= STATE_OFF;
        end else begin
            state <= state_next;
        end
    end

    // Combinational logic for next state
    always @(*) begin
        state_next = state;
        case (state)
            STATE_OFF: begin
                if (j == 1'b1) begin
                    state_next = STATE_ON;
                end else begin
                    state_next = STATE_OFF;
                end
            end
            STATE_ON: begin
                if (k == 1'b1) begin
                    state_next = STATE_OFF;
                end else begin
                    state_next = STATE_ON;
                end
            end
            default: state_next = STATE_OFF;
        endcase
    end

    // Output logic (Moore machine: output depends only on current state)
    always @(*) begin
        if (state == STATE_ON) begin
            out = 1'b1;
        end else begin
            out = 1'b0;
        end
    end

endmodule