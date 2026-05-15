```systemverilog
module TopModule (
    input logic clk,
    input logic reset,
    input logic in,
    output logic out
);

localparam STATE_A = 1'b0;
localparam STATE_B = 1'b1;

logic state;
logic state_next;

always_ff @(posedge clk or posedge reset) begin
    if (reset)
        state <= STATE_B;
    else
        state <= state_next;
end

always_comb begin
    state_next = state;
    case(state)
        STATE_A:
            if (in)
                state_next = STATE_A;
            else
                state_next = STATE_B;
        STATE_B:
            if (in)
                state_next = STATE_B;
            else
                state_next = STATE_A;
        default:
            state_next = STATE_B;
    endcase
end

always_comb begin
    out = (state == STATE_B);
end

endmodule
```