module TopModule (
    input clk,
    input reset,
    input w,
    output logic z
);

    // Define states using localparam
    localparam [2:0] STATE_A = 3'b000;
    localparam [2:0] STATE_B = 3'b001;
    localparam [2:0] STATE_C = 3'b010;
    localparam [2:0] STATE_D = 3'b011;
    localparam [2:0] STATE_E = 3'b100;
    localparam [2:0] STATE_F = 3'b101;

    // Current state register
    logic [2:0] state;
    logic [2:0] state_next;

    // Sequential logic for state register
    always @(posedge clk) begin
        if (reset)
            state <= STATE_A;
        else
            state <= state_next;
    end

    // Combinational logic for next state
    always @(*) begin
        case (state)
            STATE_A:
                state_next = (w == 0) ? STATE_B : STATE_A;
            STATE_B:
                state_next = (w == 0) ? STATE_C : STATE_D;
            STATE_C:
                state_next = (w == 0) ? STATE_E : STATE_D;
            STATE_D:
                state_next = (w == 0) ? STATE_F : STATE_A;
            STATE_E:
                state_next = (w == 0) ? STATE_E : STATE_D;
            STATE_F:
                state_next = (w == 0) ? STATE_C : STATE_D;
            default:
                state_next = STATE_A;
        endcase
    end

    // Output logic
    always @(*) begin
        case (state)
            STATE_A, STATE_B, STATE_C, STATE_D, STATE_F:
                z = 0;
            STATE_E:
                z = 1;
            default:
                z = 0;
        endcase
    end

endmodule