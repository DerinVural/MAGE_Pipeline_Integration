module TopModule (
    input  clk,
    input  areset,
    input  in,
    output logic out
);

    // Define states
    localparam STATE_A = 2'b00;
    localparam STATE_B = 2'b01;
    localparam STATE_C = 2'b10;
    localparam STATE_D = 2'b11;

    // State registers
    logic [1:0] current_state, next_state;

    // Initialize state registers
    initial begin
        current_state = STATE_A;
    end

    // Sequential logic with async reset
    always @(posedge clk or posedge areset) begin
        if (areset) begin
            current_state <= STATE_A;
        end else begin
            current_state <= next_state;
        end
    end

    // Combinational next state logic
    always @(*) begin
        case (current_state)
            STATE_A: next_state = in ? STATE_B : STATE_A;
            STATE_B: next_state = in ? STATE_B : STATE_C;
            STATE_C: next_state = in ? STATE_D : STATE_A;
            STATE_D: next_state = in ? STATE_B : STATE_C;
            default: next_state = STATE_A;
        endcase
    end

    // Output logic
    always @(*) begin
        case (current_state)
            STATE_A: out = 0;
            STATE_B: out = 0;
            STATE_C: out = 0;
            STATE_D: out = 1;
            default: out = 0;
        endcase
    end

endmodule