module TopModule (
    input  logic in,
    input  logic [3:0] state,
    output logic [3:0] next_state,
    output logic out
);

    // One-hot encoding definitions
    localparam STATE_A = 4'b0001;
    localparam STATE_B = 4'b0010;
    localparam STATE_C = 4'b0100;
    localparam STATE_D = 4'b1000;

    // Combinational logic for next state and output
    always @* begin
        // Default assignments to prevent latch inference
        next_state = 4'b0000;
        out = 1'b0;

        case (state)
            STATE_A:
                next_state = (in == 0) ? STATE_A : STATE_B;
                out = 1'b0;

            STATE_B:
                next_state = (in == 0) ? STATE_C : STATE_B;
                out = 1'b0;

            STATE_C:
                next_state = (in == 0) ? STATE_A : STATE_D;
                out = 1'b0;

            STATE_D:
                next_state = (in == 0) ? STATE_C : STATE_B;
                out = 1'b1;

            default:
                next_state = 4'b0000;
                out = 1'b0;
        endcase
    end

endmodule