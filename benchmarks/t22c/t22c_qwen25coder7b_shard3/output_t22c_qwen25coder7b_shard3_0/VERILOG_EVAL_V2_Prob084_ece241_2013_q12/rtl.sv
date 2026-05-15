module TopModule (
    input  logic clk,
    input  logic enable,
    input  logic S,
    input  logic A,
    input  logic B,
    input  logic C,
    output logic Z
);

// 8-bit shift register
logic [7:0] shift_reg;
always_ff @(posedge clk or negedge enable) begin
    if (!enable)
        shift_reg <= 8'b0;
    else if (S)
        shift_reg <= {shift_reg[6:0], 1'b1};
    else
        shift_reg <= {shift_reg[6:0], 1'b0};
end

// Multiplexer
always @(*) begin
    unique case ({A, B, C})
        3'b000: Z = shift_reg[0];
        3'b001: Z = shift_reg[1];
        3'b010: Z = shift_reg[2];
        3'b011: Z = shift_reg[3];
        3'b100: Z = shift_reg[4];
        3'b101: Z = shift_reg[5];
        3'b110: Z = shift_reg[6];
        3'b111: Z = shift_reg[7];
        default: Z = 1'bz;
    endcase
end

endmodule