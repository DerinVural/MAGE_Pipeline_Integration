module TopModule (
    input logic clk,
    input logic areset,
    input logic in,
    output logic out
);

    localparam STATE_A = 1'b0;
    localparam STATE_B = 1'b1;

    logic state;
    logic state_next;

    // Sequential logic
    always @(posedge clk or posedge areset) begin
        if (areset)
            state <= STATE_B;
        else
            state <= state_next;
    end

    // Next state combinational logic
    always @(*) begin
        case (state)
            STATE_B: state_next = in ? STATE_B : STATE_A;
            STATE_A: state_next = in ? STATE_A : STATE_B;
        endcase
    end

    // Output combinational logic
    always @(*) begin
        out = state;
    end

endmodule