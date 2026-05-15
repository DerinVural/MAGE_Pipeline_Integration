module TopModule (
    input  logic in,
    input  logic [1:0] state,
    output logic [1:0] next_state,
    output logic out
);

    // State definitions based on the specification
    localparam STATE_A = 2'b00;
    localparam STATE_B = 2'b01;
    localparam STATE_C = 2'b10;
    localparam STATE_D = 2'b11;

    // Wires to hold calculated next state and output
    logic [1:0] next_state_calc;
    logic out_calc;

    // Combinational Logic for Next State
    always @* begin
        next_state_calc = state;
        case (state)
            STATE_A: begin
                if (in == 0) next_state_calc = STATE_A; // A -> A
                else next_state_calc = STATE_B;        // A -> B
            end
            STATE_B: begin
                if (in == 0) next_state_calc = STATE_C; // B -> C
                else next_state_calc = STATE_B;        // B -> B
            end
            STATE_C: begin
                if (in == 0) next_state_calc = STATE_A; // C -> A
                else next_state_calc = STATE_D;        // C -> D
            end
            STATE_D: begin
                if (in == 0) next_state_calc = STATE_C; // D -> C
                else next_state_calc = STATE_B;        // D -> B
            end
            default: begin
                next_state_calc = STATE_A; // Safety default
            end
        endcase
    end

    // Combinational Logic for Output (Moore Machine)
    always @* begin
        out_calc = 1'b0; // Default output
        case (state)
            STATE_A: out_calc = 1'b0;
            STATE_B: out_calc = 1'b0;
            STATE_C: out_calc = 1'b0;
            STATE_D: out_calc = 1'b1;
        endcase
    end

    // Assign calculated values to output ports
    assign next_state = next_state_calc;
    assign out = out_calc;

endmodule