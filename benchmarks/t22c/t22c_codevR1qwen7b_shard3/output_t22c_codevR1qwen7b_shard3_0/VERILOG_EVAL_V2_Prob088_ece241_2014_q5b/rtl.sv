module TopModule (clk, areset, x, z);
    input logic clk;
    input logic areset;
    input logic x;
    output logic z;

    // One-hot states
    localparam STATE_A = 2'b10;
    localparam STATE_B = 2'b01;

    logic [1:0] state, next_state;

    // State register with async reset
    always_ff @(posedge clk or posedge areset) begin
        if (areset) begin
            state <= STATE_A;
        end else begin
            state <= next_state;
        end
    end

    // Combinational next state logic
    always_comb begin
        case (state)
            STATE_A: next_state = x ? STATE_B : STATE_A;
            STATE_B: next_state = x ? STATE_B : STATE_B;
            default: next_state = STATE_A;
        endcase
    end

    // Mealy output logic
    always_comb begin
        case (state)
            STATE_A: z = x ? 1'b1 : 1'b0;
            STATE_B: z = x ? 1'b0 : 1'b1;
            default: z = 1'b0;
        endcase
    end
endmodule