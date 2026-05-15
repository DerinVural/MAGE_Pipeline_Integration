module TopModule (
    input clk,
    input resetn,
    input in,
    output out
);

    // Register to hold the 4-stage shift register
    logic [3:0] shift_reg;

    // Sequential logic for the shift register
    always @(posedge clk, negedge resetn) begin
        if (!resetn)
            shift_reg <= 4'b0;
        else
            shift_reg <= {shift_reg[2:0], in};
    end

    // Output is the last stage of the shift register
    assign out = shift_reg[3];

endmodule