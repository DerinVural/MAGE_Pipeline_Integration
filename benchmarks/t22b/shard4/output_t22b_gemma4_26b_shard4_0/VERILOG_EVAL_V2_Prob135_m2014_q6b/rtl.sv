module TopModule (
    input  logic [2:0] y,
    input  logic       w,
    output logic       Y1
);

    // The problem asks to implement the next-state logic for y[1].
    // Y1 is the output, which is defined as the value of the next state's y[1].

    always @(*) begin
        case (y) 
            3'b000: Y1 = 1'b0; // A: next state B(001) or A(000) -> y[1]=0
            3'b001: Y1 = 1'b1; // B: next state C(010) or D(011) -> y[1]=1
            3'b010: Y1 = w ? 1'b1 : 1'b0; // C: next state E(100) or D(011) -> y[1]=0 if w=0, 1 if w=1
            3'b011: Y1 = 1'b0; // D: next state F(101) or A(000) -> y[1]=0
            3'b100: Y1 = w ? 1'b1 : 1'b0; // E: next state E(100) or D(011) -> y[1]=0 if w=0, 1 if w=1
            3'b101: Y1 = 1'b1; // F: next state C(010) or D(011) -> y[1]=1
            default: Y1 = 1'b0;
        endcase
    end

endmodule