module TopModule (input logic clk, input logic reset, input logic w, output logic z);
    // Define states using localparam
    localparam STATE_A = 3'b000;
    localparam STATE_B = 3'b001;
    localparam STATE_C = 3'b010;
    localparam STATE_D = 3'b011;
    localparam STATE_E = 3'b100;
    localparam STATE_F = 3'b101;

    // State and next_state registers
    logic [2:0] state, next_state;

    // Sequential state transition with synchronous reset
    always @(posedge clk) begin
        if (reset) begin
            state <= STATE_A;
        end else begin
            state <= next_state;
        end
    end

    // Combinational next state logic
    always @(*) begin
        case (state)
            STATE_A: next_state = w ? STATE_B : STATE_A;
            STATE_B: next_state = w ? STATE_C : STATE_D;
            STATE_C: next_state = w ? STATE_E : STATE_D;
            STATE_D: next_state = w ? STATE_F : STATE_A;
            STATE_E: next_state = w ? STATE_E : STATE_D;
            STATE_F: next_state = w ? STATE_C : STATE_D;
            default: next_state = STATE_A;
        endcase
    end

    // Output logic: Assuming z=1 in states E and F based on transitions
    assign z = (state == STATE_E) || (state == STATE_F);
endmodule