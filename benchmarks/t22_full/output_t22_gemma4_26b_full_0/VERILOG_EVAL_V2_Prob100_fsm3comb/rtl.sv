module TopModule(
    input  logic       in,
    input  logic [1:0] state,
    output logic [1:0] next_state,
    output logic       out
);

    // State encodings
    localparam logic [1:0] STATE_A = 2'b00;
    localparam logic [1:0] STATE_B = 2'b01;
    localparam logic [1:0] STATE_C = 2'b10;
    localparam logic [1:0] STATE_D = 2'b11;

    // Combinational logic for next_state
    always @(*) begin
        case (state)
            STATE_A: begin
                if (in == 1'b0) next_state = STATE_A;
                else           next_state = STATE_B;
            end
            STATE_B: begin
                if (in == 1'b0) next_state = STATE_C;
                else           next_state = STATE_B;
            end
            STATE_C: begin
                if (in == 1'b0) next_state = STATE_A;
                else           next_state = STATE_D;
            end
            STATE_D: begin
                if (in == 1'b0) next_state = STATE_C;
                else           next_state = STATE_B;
            end
            default: next_state = STATE_A;
        endcase
    end

    // Combinational logic for Moore output
    always @(*) begin
        case (state)
            STATE_D: out = 1'b1;
            default: out = 1'b0;
        endcase
    end

endmodule