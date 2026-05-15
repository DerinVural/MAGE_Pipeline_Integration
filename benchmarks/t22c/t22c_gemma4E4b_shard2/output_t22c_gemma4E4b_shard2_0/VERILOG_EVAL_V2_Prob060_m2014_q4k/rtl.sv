module TopModule (
    input logic clk,
    input logic resetn,
    input logic in,
    output logic out
);

    // 4-bit shift register storage
    logic [3:0] shift_reg;

    // The output is taken from the Most Significant Bit (MSB) of the register
    assign out = shift_reg[3];

    // Sequential logic: Registered updates on positive clock edge
    always @(posedge clk)
    begin
        if (!resetn) begin
            // Active-low synchronous reset
            shift_reg <= 4'b0000;
        end else begin
            // Shift operation: New input 'in' enters the LSB (bit 0).
            // Existing bits shift left (towards MSB).
            // {shift_reg[2:0], in} takes bits [2], [1], [0] and appends 'in' at bit 0.
            shift_reg <= {shift_reg[2:0], in};
        end
    end

endmodule