module TopModule(
    input  logic clk,
    input  logic reset,
    input  logic w,
    output logic z
);

    // State definitions
    localparam logic [2:0] STATE_A = 3'd0;
    localparam logic [2:0] STATE_B = 3'd1;
    localparam logic [2:0] STATE_C = 3'd2;
    localparam logic [2:0] STATE_D = 3'd3;
    localparam logic [2:0] STATE_E = 3'd4;
    localparam logic [2:0] STATE_F = 3'd5;

    // State registers
    logic [2:0] current_state;
    logic [2:0] next_state;

    // State Flip-Flops
    always @(posedge clk) begin
        if (reset) begin
            current_state <= STATE_A;
        end else begin
            current_state <= next_state;
        end
    end

    // Next State Logic
    always @(*) begin
        next_state = current_state; // Default hold state
        case (current_state)
            STATE_A:
                if (w == 1'b1) next_state = STATE_B;
                else           next_state = STATE_A;
            STATE_B:
                if (w == 1'b1) next_state = STATE_C;
                else           next_state = STATE_D;
            STATE_C:
                if (w == 1'b1) next_state = STATE_E;
                else           next_state = STATE_D;
            STATE_D:
                if (w == 1'b1) next_state = STATE_F;
                else           next_state = STATE_A;
            STATE_E:
                if (w == 1'b1) next_state = STATE_E;
                else           next_state = STATE_D;
            STATE_F:
                if (w == 1'b1) next_state = STATE_C;
                else           next_state = STATE_D;
            default:
                next_state = STATE_A;
        endcase
    end

    // Output Logic
    // Based on spec: A(0), B(0), C(0), D(0), E(1), F(1)
    always @(*) begin
        case (current_state)
            STATE_E, STATE_F:
                z = 1'b1;
            default:
                z = 1'b0;
        endcase
    end

endmodule