module TopModule (
    input  logic clk,
    input  logic areset,
    input  logic load,
    input  logic ena,
    input  logic [3:0] data,
    output logic [3:0] q
);

    // Sequential logic for shift register
    logic [3:0] shift_reg;
    always @(posedge clk) begin
        if (areset)
            shift_reg <= 0;
        else if (load)
            shift_reg <= data;
        else if (ena)
            shift_reg <= {shift_reg[2:0], 1'b0};
    end

    // Assign output
    assign q = shift_reg;

endmodule;