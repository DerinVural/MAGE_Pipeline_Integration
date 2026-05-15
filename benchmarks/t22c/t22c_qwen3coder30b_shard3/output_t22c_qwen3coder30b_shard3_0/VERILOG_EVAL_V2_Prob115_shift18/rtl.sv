module TopModule (
    input clk,
    input load,
    input ena,
    input [1:0] amount,
    input [63:0] data,
    output [63:0] q
);

    // Internal signal to store the shifted value
    logic [63:0] shift_reg;

    // Sequential logic
    always @(posedge clk) begin
        if (load)
            shift_reg <= data;
        else if (ena) begin
            case (amount)
                2'b00: shift_reg <= {shift_reg[62:0], 1'b0}; // Shift left by 1
                2'b01: shift_reg <= {shift_reg[55:0], 8'b0}; // Shift left by 8
                2'b10: shift_reg <= {{1{shift_reg[63]}}, shift_reg[63:1]}; // Arithmetic right by 1
                2'b11: shift_reg <= {{8{shift_reg[63]}}, shift_reg[63:8]}; // Arithmetic right by 8
            endcase
        end
    end

    // Output assignment
    assign q = shift_reg;

endmodule