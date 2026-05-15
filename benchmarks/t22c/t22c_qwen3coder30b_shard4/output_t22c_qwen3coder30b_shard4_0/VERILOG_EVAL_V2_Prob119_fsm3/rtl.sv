module TopModule (
    input clk,
    input areset,
    input in,
    output logic out
);

    // Define states
    localparam STATE_A = 2'b00;
    localparam STATE_B = 2'b01;
    localparam STATE_C = 2'b10;
    localparam STATE_D = 2'b11;

    // State register
    logic [1:0] state, state_next;

    // Next state combinational logic
    always @(*) begin
        case (state)
            STATE_A: state_next = (in) ? STATE_B : STATE_A;
            STATE_B: state_next = (in) ? STATE_B : STATE_C;
            STATE_C: state_next = (in) ? STATE_D : STATE_A;
            STATE_D: state_next = (in) ? STATE_B : STATE_C;
        endcase
    end

    // Output logic
    always @(*) begin
        case (state)
            STATE_A: out = 1'b0;
            STATE_B: out = 1'b0;
            STATE_C: out = 1'b0;
            STATE_D: out = 1'b1;
        endcase
    end

    // Sequential logic
    always @(posedge clk or posedge areset) begin
        if (areset)
            state <= STATE_A;
        else
            state <= state_next;
    end

endmodule