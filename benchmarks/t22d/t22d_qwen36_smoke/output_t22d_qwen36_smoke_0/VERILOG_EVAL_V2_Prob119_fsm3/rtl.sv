module TopModule (
    input logic clk,
    input logic areset,
    input logic in,
    output logic out
);

    localparam STATE_A = 2'b00;
    localparam STATE_B = 2'b01;
    localparam STATE_C = 2'b10;
    localparam STATE_D = 2'b11;

    logic [1:0] state;
    logic [1:0] state_next;

    // Sequential logic for state register with asynchronous reset
    always @(posedge clk or posedge areset) begin
        if (areset)
            state <= STATE_A;
        else
            state <= state_next;
    end

    // Combinational logic for next state calculation
    always @(*) begin
        state_next = state;
        case (state)
            STATE_A: state_next = in ? STATE_B : STATE_A;
            STATE_B: state_next = in ? STATE_B : STATE_C;
            STATE_C: state_next = in ? STATE_D : STATE_A;
            STATE_D: state_next = in ? STATE_B : STATE_C;
            default: state_next = STATE_A;
        endcase
    end

    // Moore output logic
    assign out = (state == STATE_D);

endmodule