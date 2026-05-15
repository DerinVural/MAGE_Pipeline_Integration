module TopModule (
    input logic clk,
    input logic a,
    input logic b,
    input logic reset,  // Declare the reset port
    output logic q,
    output logic state
);

    // State definitions
    localparam STATE_0 = 1'b0;
    localparam STATE_1 = 1'b1;

    // State register
    logic state_reg;
    always @(posedge clk) begin
        if (reset)
            state_reg <= STATE_0;
        else
            state_reg <= state_next;
    end

    // Initial block to initialize state_reg to a known value
    initial state_reg = STATE_0;

    // Next state logic
    logic state_next;
    always @(*) begin
        case ({a, b})
            2'b00: state_next = STATE_0;
            2'b01: state_next = STATE_0;
            2'b10: state_next = state_reg;
            2'b11: state_next = STATE_1;
            default: state_next = state_reg;
        endcase
    end

    // Output logic
    always @(*) begin
        q = state_reg;
        state = state_reg;
    end

endmodule