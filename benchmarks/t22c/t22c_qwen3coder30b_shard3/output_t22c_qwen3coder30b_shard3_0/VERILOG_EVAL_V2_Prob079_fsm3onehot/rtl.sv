module TopModule (
    input  logic in,
    input  logic [3:0] state,
    output logic [3:0] next_state,
    output logic out
);

    // One-hot state encoding
    localparam logic [3:0] A = 4'b0001;
    localparam logic [3:0] B = 4'b0010;
    localparam logic [3:0] C = 4'b0100;
    localparam logic [3:0] D = 4'b1000;

    // Combinational logic for next state
    always @(*) begin
        case (state)
            A: next_state = (in) ? B : A;
            B: next_state = (in) ? B : C;
            C: next_state = (in) ? D : A;
            D: next_state = (in) ? B : C;
            default: next_state = 4'b0000;
        endcase
    end

    // Combinational logic for output
    always @(*) begin
        case (state)
            A: out = 1'b0;
            B: out = 1'b0;
            C: out = 1'b0;
            D: out = 1'b1;
            default: out = 1'b0;
        endcase
    end

endmodule