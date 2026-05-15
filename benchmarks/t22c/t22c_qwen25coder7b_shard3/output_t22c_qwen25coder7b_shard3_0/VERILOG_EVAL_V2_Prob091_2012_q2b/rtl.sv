module top_module (
    input logic clk,
    input logic w,
    input logic [5:0] y,
    input logic reset,
    output logic Y1,
    output logic Y3
);

    // Decode the one-hot encoded state
    logic [2:0] state;
    always_comb begin
        state = y[2:0];
    end

    // Sequential logic for state
    logic [2:0] state_reg;
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            state_reg <= 3'b000;
        else
            state_reg <= state;
    end

    // Combinational logic for Y1 and Y3
    logic Y1_comb;
    logic Y3_comb;
    always @(*) begin
        case(state_reg)
            3'b000: begin Y1_comb = 0; Y3_comb = 0; end
            3'b001: begin Y1_comb = 1; Y3_comb = 0; end
            3'b010: begin Y1_comb = 0; Y3_comb = 0; end
            3'b011: begin Y1_comb = 0; Y3_comb = 1; end
            3'b100: begin Y1_comb = 0; Y3_comb = 0; end
            3'b101: begin Y1_comb = 0; Y3_comb = 0; end
            default: begin Y1_comb = 0; Y3_comb = 0; end
        endcase
    end

    // Assign the combinational logic to the outputs
    assign Y1 = Y1_comb;
    assign Y3 = Y3_comb;

endmodule