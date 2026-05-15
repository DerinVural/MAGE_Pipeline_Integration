module TopModule (input [2:0] y, input w, output logic Y1);
    // State parameters
    localparam S_A = 3'b000;
    localparam S_B = 3'b001;
    localparam S_C = 3'b010;
    localparam S_D = 3'b011;
    localparam S_E = 3'b100;
    localparam S_F = 3'b101;

    logic [2:0] next_state;

    // Combinational next state logic
    always @(*) begin
        next_state = S_A; // default
        case (y)
            S_A: begin
                if (!y[0]) next_state = S_B;
                else next_state = S_A;
            end
            S_B: begin
                if (!y[0]) begin
                    next_state = y[2] ? S_D : S_C;
                end else begin
                    next_state = y[2] ? S_D : S_A;
                end
            end
            S_C: begin
                if (!y[0]) next_state = S_E;
                else next_state = S_D;
            end
            S_D: begin
                if (!y[0]) next_state = S_F;
                else next_state = S_A;
            end
            S_E: begin
                if (w) begin
                    if (!y[0]) next_state = S_E;
                    else next_state = S_D;
                end else begin
                    // Assuming no transition specified for w=0 in E, stay in E
                    next_state = S_E;
                end
            end
            S_F: begin
                if (w) begin
                    if (!y[0]) next_state = S_C;
                    else next_state = S_D;
                end else begin
                    // Assuming no transition specified for w=0 in F, stay in F
                    next_state = S_F;
                end
            end
            default: next_state = S_A;
        endcase
    end

    assign Y1 = next_state[1];
endmodule