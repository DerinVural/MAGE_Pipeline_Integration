module TopModule(
    input  logic clk,
    input  logic enable,
    input  logic S,
    input  logic A,
    input  logic B,
    input  logic C,
    output logic Z
);

    // 8-bit shift register
    // Q[0] is the first bit, Q[7] is the last bit
    logic [7:0] Q;

    // Initialize register to avoid X
    initial begin
        Q <= 8'b0;
    end

    // Sequential logic for shift register
    always @(posedge clk) begin
        if (enable) begin
            // S feeds Q[0], then Q[1] <= Q[0], etc.
            // This shifts bits from index 0 towards index 7
            Q[0] <= S;
            Q[1] <= Q[0];
            Q[2] <= Q[1];
            Q[3] <= Q[2];
            Q[4] <= Q[3];
            Q[5] <= Q[4];
            Q[6] <= Q[5];
            Q[7] <= Q[6];
        end
    end

    // Combinational logic for 8x1 multiplexer
    // ABC = 000 -> Z = Q[0]
    // ABC = 001 -> Z = Q[1]
    // ...
    // ABC = 111 -> Z = Q[7]
    logic [2:0] select;
    assign select = {A, B, C};

    always @(*) begin
        case (select)
            3'b000: Z = Q[0];
            3'b001: Z = Q[1];
            3'b010: Z = Q[2];
            3'b011: Z = Q[3];
            3'b100: Z = Q[4];
            3'b101: Z = Q[5];
            3'b110: Z = Q[6];
            3'b111: Z = Q[7];
            default: Z = 1'b0;
        endcase
    end

endmodule