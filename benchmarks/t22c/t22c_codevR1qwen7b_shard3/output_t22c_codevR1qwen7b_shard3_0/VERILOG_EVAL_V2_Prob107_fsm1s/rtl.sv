module TopModule(input clk, input reset, input in, output logic out);

localparam STATE_B = 1'b1;
localparam STATE_A = 1'b0;

reg state, next_state;

// State register
always @(posedge clk) begin
    if (reset)
        state <= STATE_B;
    else
        state <= next_state;
end

// Next state logic
always @(*) begin
    case (state)
        STATE_B: next_state = (in) ? STATE_B : STATE_A;
        STATE_A: next_state = (in) ? STATE_A : STATE_B;
        default: next_state = STATE_B;
    endcase
end

// Output logic (Moore, depends only on state)
always @(*) begin
    case (state)
        STATE_B: out = 1'b1;
        STATE_A: out = 1'b0;
        default: out = 1'b1;
    endcase
end

endmodule