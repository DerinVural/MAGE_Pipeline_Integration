module TopModule(
    input logic clk,
    input logic reset,
    input logic in,
    output logic out
);

    // Define states
    localparam STATE_A = 1'b0;
    localparam STATE_B = 1'b1;

    // State register
    logic state;
    logic state_next;

    // Next state logic
    always @(*) begin
        case (state)
            STATE_B: state_next = (in) ? STATE_B : STATE_A;
            STATE_A: state_next = (in) ? STATE_A : STATE_B;
        endcase
    end

    // Output logic
    always @(*) begin
        case (state)
            STATE_B: out = 1'b1;
            STATE_A: out = 1'b0;
        endcase
    end

    // Sequential logic
    always @(posedge clk) begin
        if (reset)
            state <= STATE_B;
        else
            state <= state_next;
    end

endmodule