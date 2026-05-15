module TopModule (
    input clk,
    input shift_ena,
    input count_ena,
    input data,
    output [3:0] q
);

    // Internal signal for the shift register
    logic [3:0] shift_reg;

    // Initialize the shift register to 0
    initial begin
        shift_reg = 4'b0000;
    end

    // Sequential logic for shift register
    always @(posedge clk) begin
        if (shift_ena) begin
            // Shift in data from MSB
            shift_reg <= {data, shift_reg[3:1]};
        end
        else if (count_ena) begin
            // Decrement the value
            shift_reg <= shift_reg - 1;
        end
        // If neither control is active, no change
    end

    // Assign output
    assign q = shift_reg;

endmodule